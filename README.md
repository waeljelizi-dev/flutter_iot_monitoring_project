# Emkamed IoT Project

An IoT-based solution for real-time monitoring of power parameters (voltage, current, and power) in a high-performance Buck converter. This project integrates embedded systems, cloud services, and mobile applications to provide detailed insights into power delivery and efficiency.

## ⚡ Project Overview

This project aims to:
- Monitor the power output of a Buck converter in real time.
- Collect data such as voltage, current, and power.
- Send data to the cloud for storage and visualization.
- Display analytics and AI-based recommendations in a mobile app.

## 📡 System Architecture

- **ESP32**: Reads sensor data and communicates via MQTT and REST API.
- **Current & Voltage Sensors**: Measures power delivery of the Buck converter.
- **Node.js Server**: Receives sensor data, stores it in a MySQL database, and performs data aggregation.
- **Flutter Mobile App**: Displays real-time monitoring, historical data, and AI-based predictions.
- **MySQL Database**: Stores raw data, statistics, evaluation, and advices.

## 🧠 AI Integration

- Evaluate the data coming to the server using tensorflow.js LTSM model.
- Generates smart energy-saving advice based on historical trends.

## 📱 Mobile App Features (Flutter)
- Real-time power monitoring
- Statistics (Average, Min, Max over time)
- AI Predictions and energy-saving recommendations
- Device management and notifications
- Modern UI with smooth navigation and splash screen

## 🔧 Technologies Used

- **ESP32 (C++)**
- **Node.js + Express**
- **MySQL**
- **MQTT (Mosquitto)**
- **Flutter (Dart)**
- **tensorflow.js** (AI pretrained model for evaluating data and giving advices)

## 📁 Project Structure
  - esp32/ # ESP32 firmware
  - server/ # Node.js server
  - mobile_app/ # Flutter mobile application
  - database/ # MySQL schema and scripts
  - README.md
