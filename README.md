# BlackBox
🏆 Ignition Hackathon 2025: **1st Place Winner**\
Held on `07–08 November 2025`: 18 Hour Build Sprint

## Overview
BlackBox is a mountable telemetry system built for riders.\
It attaches to the rider's helmet and collects real-time motion & location data, streams to a mobile app, logs everything with timestamps, and also classifies riding mode:
- Scooter
- Bike
- Walking/Running
<p align="center" style="display: flex; padding: 1rem; gap: 2rem;">
  <img src="https://github.com/user-attachments/assets/1ad1b918-ab94-4f63-92e6-2785146697d7" height="500px">
  <img src="https://github.com/user-attachments/assets/0c5ae14f-607d-49a2-8988-cef135238d59" height="500px">
</p>


Built in **18 hours**. Fully tested on track during the hackathon.

## About Ignition 1.0

[IGNITION 1.0 ](https://www.linkedin.com/posts/team-vegavath_we-are-excited-to-share-the-success-of-ignition-activity-7396907768693051420-3uaX?utm_source=share&utm_medium=member_desktop&rcm=ACoAAFHwmQQBxncm09wtXtDxs073Kbv84vm2YTc)was `Team Vegavath`’s first flagship overnight **IoT hackathon**, powered by **[ATHER ENERGY](https://www.atherenergy.com/)**.
It was an 18-hour no-sleep build sprint focused on real-world IoT applications. Prototypes had to be fully functional and tested live on the track before judging.\
It wasn’t just coding. It demanded:
- Hardware integration
- Sensor calibration
- Real-time data streaming
- Stress testing on real riders
- A working UI demo – ON THE SPOT

Only one team would walk away with the win.\
We did.

## Problem statement: 
1. Participants must build a wearable telemetry system that attaches to a rider’s helmet, jacket, and/or pants and captures real-time motion and location data.
2. The system must display live information on a mobile app and store all readings with timestamps.
3. The app should also detect whether the rider is on a scooter, a motorcycle, or not riding, based on posture and motion.
4. All prototypes must be fully demonstrable on the test track during the
hackathon.


## Tech Stack

### Hardware:

| Component   | Purpose |
|-|-
| ESP32 | Main MCU (Data processing + WiFi/Bluetooth) |
| MPU6050 | IMU for motion & posture tracking |
| NEO-6M GPS Module | Real-time location tracking |
| 18650 Li-ion Battery | Power supply |
| 0.96 Inch OLED Display | Connection status |

### Software

| Stack   | Purpose |
|-|-
| Arduino C++ | Sensor data acquisition & transmission |
| Flutter (Android) | Mobile UI + Live telemetry |

## Mobile App Features

- Live motion telemetry (acceleration, tilt)
- Live GPS tracking
- Timestamped logging
- Classification model for riding mode (motorcycle / scooter / walking & running)

## Team Members
||
| -------- |
| [Joshua R](https://github.com/joshua-rajj) |
| [Arjun](https://github.com/arjun-com) |
| [Shreyas V](https://github.com/woterr) |
| Abhinav K |



## Results

- First Place Winner; among 59 teams
- Built in 18 hours
- Live tested on track
- Full app + prototype demoed successfully

