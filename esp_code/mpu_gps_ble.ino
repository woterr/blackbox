#include <Wire.h>
#include <TinyGPS++.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <math.h>

// ----------------- OLED CONFIG -----------------
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// ----------------- GPS CONFIG -----------------
#define RXD2 16
#define TXD2 17
#define GPS_BAUD 9600
HardwareSerial gpsSerial(2);
TinyGPSPlus gps;

// ----------------- MPU CONFIG -----------------
Adafruit_MPU6050 mpu;

// ----------------- BLE CONFIG -----------------
BLECharacteristic *pCharacteristic;
BLEServer *pServer;
bool deviceConnected = false;

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// ----------------- LAST GPS DATA -----------------
double lastLat = 0.0, lastLng = 0.0, lastAlt = 0.0, lastSpeed = 0.0, lastHdop = 0.0;
int lastSat = 0;
bool hasFix = false;
unsigned long lastFixTime = 0;

// ----------------- MOTION DETECTION CONFIG -----------------
const int WINDOW_SIZE = 10;
float ax_buf[WINDOW_SIZE], ay_buf[WINDOW_SIZE], az_buf[WINDOW_SIZE];
int buf_index = 0;
bool buf_full = false;

// ----------------- BLE CALLBACKS -----------------
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    deviceConnected = true;
    Serial.println("BLE device connected");
    showStatus("BLE Connected");
  }

  void onDisconnect(BLEServer* pServer) override {
    deviceConnected = false;
    Serial.println("BLE device disconnected, restarting advertising...");
    showStatus("BLE Disconnected");
    pServer->getAdvertising()->start();
  }

  void showStatus(const char *msg) {
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 24);
    display.println(msg);
    display.display();
  }
};

// ----------------- DISPLAY HELPERS -----------------
void showOLED(const String &msg1, const String &msg2 = "", const String &msg3 = "") {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 8);
  display.println(msg1);
  display.setCursor(0, 24);
  display.println(msg2);
  display.setCursor(0, 40);
  display.println(msg3);
  display.display();
}

// ----------------- MOTION FUNCTIONS -----------------
float calcStd(float arr[], int count, float mean) {
  float sumSq = 0;
  for (int i = 0; i < count; i++) sumSq += pow(arr[i] - mean, 2);
  return sqrt(sumSq / count);
}

String detectMotion() {
  int count = buf_full ? WINDOW_SIZE : buf_index;
  if (count < 3) return "Initializing";

  float mean_ax = 0, mean_ay = 0, mean_az = 0;
  for (int i = 0; i < count; i++) {
    mean_ax += ax_buf[i];
    mean_ay += ay_buf[i];
    mean_az += az_buf[i];
  }
  mean_ax /= count;
  mean_ay /= count;
  mean_az /= count;

  float std_ax = calcStd(ax_buf, count, mean_ax);
  float std_ay = calcStd(ay_buf, count, mean_ay);
  float std_az = calcStd(az_buf, count, mean_az);

  float motion_intensity = (std_ax + std_ay + std_az) / 3.0;

  if (motion_intensity < 0.2) return "Stationary";
  else if (motion_intensity < 1.5) return "Walking";
  else return "Running";
}

// ----------------- SETUP -----------------
void setup() {
  Serial.begin(115200);

  // --- OLED ---
  Wire.begin(21, 22);
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("SSD1306 allocation failed"));
    while (true);
  }
  display.clearDisplay();
  showOLED("Initializing...", "GPS + MPU6050 + BLE");

  // --- GPS ---
  gpsSerial.begin(GPS_BAUD, SERIAL_8N1, RXD2, TXD2);

  // --- MPU ---
  if (!mpu.begin(0x68)) {
    showOLED("MPU6050 not found!", "Check wiring.");
    while (1);
  }
  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
  showOLED("MPU6050 ready");

  delay(1000);

  // --- BLE ---
  BLEDevice::init("ESP32_GPS_MPU");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_NOTIFY
  );

  pService->start();
  pServer->getAdvertising()->start();
  Serial.println("BLE ready, waiting for connection...");
  showOLED("BLE Ready", "Waiting for", "connection...");
}

// ----------------- LOOP -----------------
void loop() {
  // Handle GPS input
  while (gpsSerial.available()) gps.encode(gpsSerial.read());

  if (gps.location.isUpdated()) {
    lastLat = gps.location.lat();
    lastLng = gps.location.lng();
    lastAlt = gps.altitude.meters();
    lastSpeed = gps.speed.kmph();
    lastSat = gps.satellites.value();
    lastHdop = gps.hdop.hdop();
    hasFix = gps.location.isValid();
    lastFixTime = millis();
  }

  // Read MPU
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  // Store in rolling buffer
  ax_buf[buf_index] = a.acceleration.x;
  ay_buf[buf_index] = a.acceleration.y;
  az_buf[buf_index] = a.acceleration.z;
  buf_index = (buf_index + 1) % WINDOW_SIZE;
  if (buf_index == 0) buf_full = true;

  // Determine motion state
  String motionState = detectMotion();

  // Show motion on OLED
  showOLED("Motion:", motionState);

  // Build JSON
  String jsonData = "{";
  jsonData += "\"lat\":" + String(lastLat, 6) + ",";
  jsonData += "\"lng\":" + String(lastLng, 6) + ",";
  jsonData += "\"alt\":" + String(lastAlt, 2) + ",";
  jsonData += "\"spd\":" + String(lastSpeed, 2) + ",";
  jsonData += "\"sat\":" + String(lastSat) + ",";
  jsonData += "\"ax\":" + String(a.acceleration.x, 2) + ",";
  jsonData += "\"ay\":" + String(a.acceleration.y, 2) + ",";
  jsonData += "\"az\":" + String(a.acceleration.z, 2) + ",";
  jsonData += "\"gx\":" + String(g.gyro.x, 2) + ",";
  jsonData += "\"gy\":" + String(g.gyro.y, 2) + ",";
  jsonData += "\"gz\":" + String(g.gyro.z, 2) + ",";
  jsonData += "\"temp\":" + String(temp.temperature, 2) + ",";
  jsonData += "\"motion_state\":\"" + motionState + "\"";
  jsonData += "}";

  if (deviceConnected) {
    pCharacteristic->setValue(jsonData.c_str());
    pCharacteristic->notify();
  }

  Serial.println(jsonData);
  delay(10);
}
