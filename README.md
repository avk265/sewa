# SEWA - Smart E-Waste Management Application

An end-to-end e-waste management ecosystem designed to streamline the collection of electronic waste. SEWA integrates IoT-enabled smart bins with a reward-based mobile application, promoting circular economy and sustainable waste management.

## Overview

SEWA (Smart E-Waste Application) is a comprehensive platform that bridges the gap between e-waste generators and collection facilities through intelligent IoT hardware and a user-friendly mobile interface. Users can deposit electronic waste into smart bins, get verified through QR codes, and earn rewards for their contributions.

## Features

- **IoT-Enabled Smart Bins**: Simulation of hardware-centric detection systems for e-waste collection
- **QR Code Verification**: Secure user authentication at smart bins for waste deposit verification
- **Reward System**: Mobile app that tracks contributions and provides incentives based on collected e-waste
- **Real-time Tracking**: Monitor waste deposits and rewards in real-time
- **Wallet Management**: Accumulated points/rewards accessible through mobile app
- **User Leaderboard**: Compete with other users based on waste contributions
- **Admin Dashboard**: Monitor bin status, collection data, and user activities

## Technology Stack

### Hardware (Currently Simulated)
- **Microcontroller**: ESP32
- **Sensors**: 
  - Inductive Proximity Sensor (LJ12A3-4-Z/BX)
  - Load Cell (5kg/10kg) with HX711 Amplifier
- **Communication**: WiFi/Bluetooth via ESP32

### Software
- **Mobile Application**: Flutter (Cross-platform iOS/Android)
- **Backend/Server**: Node.js + Express.js
- **Database**: MongoDB
- **Real-time Communication**: Socket.io, WebSocket (ws)
- **Authentication**: JWT (JSON Web Tokens)
- **Security**: bcryptjs for password hashing

---

## Prerequisites

Before setting up SEWA, ensure you have the following installed:

1. **Node.js** (v14+): [Download](https://nodejs.org/)
2. **npm or yarn**: Comes with Node.js
3. **MongoDB**: [Download](https://www.mongodb.com/try/download/community) or use MongoDB Atlas
4. **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
5. **Git**: [Download](https://git-scm.com/)
6. **Arduino IDE** (optional, for ESP32 development): [Download](https://www.arduino.cc/en/software)

---

## Installation & Setup Guide

### Step 1: Clone the Repository

```bash
git clone https://github.com/avk265/sewa.git
cd sewa
```

### Step 2: Backend Setup

#### 2.1 Install Backend Dependencies

```bash
# Navigate to backend directory (if in separate folder)
cd backend  # or appropriate backend directory

# Install dependencies
npm install
```

This installs all required packages:
- **express** (v5.2.1): Web framework
- **mongoose** (v9.2.3): MongoDB ODM
- **jsonwebtoken** (v9.0.3): JWT authentication
- **bcryptjs** (v3.0.3): Password hashing
- **socket.io** (v4.8.3): Real-time communication
- **ws** (v8.19.0): WebSocket support
- **cors** (v2.8.6): Cross-origin requests
- **dotenv** (v17.3.1): Environment variables
- **nodemon** (v3.1.11): Auto-restart on file changes

#### 2.2 Set Up Environment Variables

Create a `.env` file in the backend directory:

```bash
# ==================== SERVER CONFIGURATION ====================
PORT=5000
NODE_ENV=development

# ==================== DATABASE ====================
# MongoDB Local Connection
MONGO_URI=mongodb://localhost:27017/sewa

# Or MongoDB Atlas (Cloud)
# MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/sewa

# ==================== JWT AUTHENTICATION ====================
JWT_SECRET=your_super_secret_jwt_key_here_change_this
JWT_EXPIRE=7d

# ==================== SOCKET.IO ====================
SOCKET_PORT=5001
CORS_ORIGIN=http://localhost:3000,http://localhost:3001

# ==================== IoT BIN CONFIGURATION ====================
# Bin simulation or actual hardware
BIN_SIMULATION=true
BIN_COMM_PROTOCOL=http  # or mqtt

# ESP32 Configuration (for actual hardware)
ESP32_IP=192.168.1.100
ESP32_PORT=80

# MQTT Configuration (if using MQTT for IoT)
MQTT_BROKER=mqtt://localhost:1883
MQTT_USER=your_mqtt_user
MQTT_PASSWORD=your_mqtt_password

# ==================== REWARD SYSTEM ====================
# Points per kg of e-waste collected
POINTS_PER_KG=10

# Currency conversion (points to monetary value)
POINTS_TO_RUPEES=0.01  # 1 point = 0.01 INR

# ==================== EMAIL (Optional) ====================
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASSWORD=your_app_password
SMTP_FROM=noreply@sewa.com
```

#### 2.3 Start MongoDB

```bash
# Local MongoDB
mongod

# Or using Docker
docker run -d -p 27017:27017 --name mongodb mongo
```

#### 2.4 Start Backend Server

```bash
# Development mode with auto-restart
npm run dev

# Or production mode
npm start
```

Expected output:
```
Server running on port 5000
Connected to MongoDB
Socket.io listening on port 5001
```

### Step 3: Flutter Mobile App Setup

#### 3.1 Create Flutter Project

```bash
flutter create sewa_mobile
cd sewa_mobile
```

#### 3.2 Add Dependencies

Edit `pubspec.yaml` and add:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  socket_io_client: ^2.0.0
  qr_code_scanner: ^1.0.0
  shared_preferences: ^2.2.0
  provider: ^6.0.0
  flutter_dotenv: ^5.1.0
```

Install dependencies:

```bash
flutter pub get
```

#### 3.3 Configure Flutter Environment Variables

Create `.env` file in flutter project root:

```bash
API_URL=http://localhost:5000
SOCKET_URL=http://localhost:5001
```

Load in main.dart:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main async {
  await dotenv.load();
  runApp(const MyApp());
}
```

#### 3.4 Run Flutter App

```bash
# iOS
flutter run -d iPhone

# Android
flutter run -d android

# Web
flutter run -d chrome
```

### Step 4: IoT Hardware Setup (Optional)

For actual ESP32 hardware deployment:

#### 4.1 Install Arduino IDE

- Download from [Arduino official site](https://www.arduino.cc/en/software)
- Install ESP32 board support in Arduino IDE

#### 4.2 ESP32 Code

Upload to ESP32:

```cpp
#include <WiFi.h>
#include <WebServer.h>
#include <HX711.h>

// WiFi credentials
const char* ssid = "YOUR_SSID";
const char* password = "YOUR_PASSWORD";

// HX711 pins
const int DOUT = 19;
const int CLK = 18;

HX711 scale;
WebServer server(80);

void setup() {
  Serial.begin(115200);
  
  // Connect to WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) delay(500);
  
  // Initialize load cell
  scale.begin(DOUT, CLK);
  scale.set_scale(2280.f); // calibration factor
  
  // Setup endpoints
  server.on("/", HTTP_GET, handleRoot);
  server.on("/weight", HTTP_GET, handleWeight);
  server.begin();
}

void loop() {
  server.handleClient();
}

void handleRoot() {
  server.send(200, "text/plain", "ESP32 Smart Bin Running");
}

void handleWeight() {
  if (scale.is_ready()) {
    float weight = scale.get_units(10);
    server.send(200, "application/json", "{\"weight\":" + String(weight) + "}");
  }
}
```

---

## Running the Application

### Prerequisites Check:

```bash
# Verify Node.js
node --version
npm --version

# Verify MongoDB
mongo --version

# Verify Flutter
flutter doctor
```

### Development Environment

**Terminal 1: Start MongoDB**
```bash
mongod
```

**Terminal 2: Start Backend Server**
```bash
cd backend
npm run dev
```

**Terminal 3: Start Flutter Mobile App**
```bash
cd sewa_mobile
flutter run -d chrome  # or your target device
```

### Access Points

- **Backend API**: `http://localhost:5000`
- **Socket.io**: `http://localhost:5001`
- **Flutter Web**: `http://localhost:5000` (after Flutter build)

---

## Project Structure

```
sewa/
├── backend/
│   ├── models/              # MongoDB schemas
│   │   ├── User.js
│   │   ├── Bin.js
│   │   ├── Deposit.js
│   │   ├── Reward.js
│   │   └── ...
│   ├── routes/              # API endpoints
│   │   ├── auth.js
│   │   ├── bins.js
│   │   ├── deposits.js
│   │   ├── rewards.js
│   │   └── ...
│   ├── controllers/         # Business logic
│   ├── middleware/          # Authentication, validation
│   ├── index.js             # Server entry point
│   ├── .env                 # Environment variables
│   └── package.json
│
├── sewa_mobile/             # Flutter mobile app
│   ├── lib/
│   │   ├── screens/         # UI screens
│   │   ├── models/          # Data models
│   │   ├── services/        # API calls
│   │   ├── widgets/         # Reusable components
│   │   └── main.dart        # App entry
│   ├── pubspec.yaml         # Flutter dependencies
│   └── .env                 # Flutter env vars
│
├── hardware/                # ESP32 Arduino code (optional)
│   └── smart_bin.ino
│
└── README.md               # This file
```

---

## API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `POST /api/auth/refresh-token` - Refresh JWT token

### User Management
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update user profile
- `GET /api/users/rewards` - Get user rewards/points

### Smart Bins
- `GET /api/bins` - List all bins
- `GET /api/bins/:id` - Get bin details
- `POST /api/bins/register` - Register new bin
- `PUT /api/bins/:id` - Update bin status
- `GET /api/bins/:id/status` - Get real-time bin status

### Waste Deposits
- `POST /api/deposits` - Record waste deposit
- `GET /api/deposits/:userId` - Get user deposits
- `GET /api/deposits` - Get all deposits (admin)

### Rewards
- `GET /api/rewards/balance` - Get user reward balance
- `POST /api/rewards/redeem` - Redeem rewards
- `GET /api/rewards/history` - Get redemption history

### Admin
- `GET /api/admin/stats` - Dashboard statistics
- `GET /api/admin/bins/analytics` - Bin usage analytics

---

## Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 5000 | Backend server port |
| `MONGO_URI` | mongodb://localhost:27017/sewa | MongoDB connection |
| `JWT_SECRET` | - | Secret key for JWT signing |
| `NODE_ENV` | development | Environment (development/production) |
| `BIN_SIMULATION` | true | Enable bin hardware simulation |
| `POINTS_PER_KG` | 10 | Reward points per kg of waste |
| `POINTS_TO_RUPEES` | 0.01 | Points to currency conversion |

---

## Troubleshooting

### Issue: MongoDB Connection Failed

```
MongoServerError: connect ECONNREFUSED 127.0.0.1:27017
```

**Solution:**
```bash
# Start MongoDB locally
mongod

# Or use MongoDB Atlas cloud connection
# Update MONGO_URI in .env with your Atlas connection string
```

### Issue: Port 5000 Already in Use

```bash
# Find process using port 5000
lsof -i :5000

# Kill process
kill -9 <PID>

# Or change PORT in .env
```

### Issue: Flutter Build Fails

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Run with verbose output
flutter run -v
```

### Issue: JWT Token Expired

- Generate new token by logging in again
- Check `JWT_EXPIRE` in `.env`
- Use refresh token endpoint to get new token

### Issue: QR Code Scanning Not Working

- Check camera permissions in Flutter app
- Ensure `qr_code_scanner` package is properly installed
- Test on physical device (simulators have limited camera support)

---

## Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## Development Roadmap

- [ ] MQTT support for IoT communication
- [ ] Blockchain integration for transparency
- [ ] Advanced analytics dashboard
- [ ] E-waste categorization AI
- [ ] Integration with recycling partners
- [ ] Multiple language support
- [ ] Offline mode for mobile app

---

## Performance Considerations

- **Database**: Use MongoDB indexes on frequently queried fields (userId, binId, timestamp)
- **Socket.io**: Implement room-based architecture for scalability
- **Flutter**: Optimize UI rendering with Provider state management
- **ESP32**: Minimize sensor polling intervals to save battery

---

## Security Best Practices

1. Keep JWT_SECRET secure and rotate periodically
2. Validate all user inputs on backend
3. Use HTTPS in production
4. Implement rate limiting on API endpoints
5. Store sensitive data encrypted in MongoDB
6. Use environment variables for all secrets

---

## License

This project is licensed under the ISC License.

---

## Support

For issues and questions:
- Open an issue on [GitHub Issues](https://github.com/avk265/sewa/issues)
- Check existing issues for solutions
- Review troubleshooting section above

---

**Promoting Circular Economy Through Smart E-Waste Management! ♻️**
