# SEWA (Smart E-Waste Application)

## Overview
SEWA is an end-to-end e-waste management ecosystem designed to streamline the collection of electronic waste. It integrates IoT-enabled smart bins with a reward-based mobile application. The system focuses on a streamlined, hardware-centric collection model, ensuring secure user verification and accurate e-waste detection without the need for complex machine learning segregation.

## Key Features
* **Simulation of IoT-Enabled Smart Bins & Hardware-Centric Detection**
* **QR Code Verification:** Secure user authentication at the bin using QR code scanning to verify the individual depositing the waste.
* **Reward System:** A mobile application that tracks user contributions and provides incentives based on the collected e-waste.

## Technology Stack
### Hardware(not installed now, just being simulated with html or js)
* ESP32 Microcontroller
* Inductive Proximity Sensor (LJ12A3-4-Z/BX)
* Load Cell (5kg/10kg) with HX711 Amplifier

### Software
* **Mobile Application:** Flutter
* **Backend / Server:** Node.js, Express.js
* **Database:** MongoDB
* **IoT Communication:** HTTP/REST / MQTT

---

## Installation & Setup Guide

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your development machine.
* [Node.js](https://nodejs.org/) and npm installed.
* [MongoDB](https://www.mongodb.com/) instance (local or Atlas).
* [Arduino IDE](https://www.arduino.cc/en/software) configured for ESP32 board programming.

