require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const http = require("http");
const { Server } = require("socket.io");

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*", credentials: true } });

app.use(express.static(__dirname));
app.use(express.json()); 
app.use(express.urlencoded({ extended: true }));
app.use(cors());

// ===================== 1. ROOT ROUTE =====================
app.get("/", (req, res) => {
    res.send(`
        <div style="font-family: sans-serif; text-align: center; padding-top: 100px; background: #e8f5e9; height: 100vh; margin:0;">
            <h1 style="color: #2e7d32; font-size: 3rem;">♻️ SEWA Backend Live</h1>
            <p style="font-size: 1.2rem; color: #555;">Server is listening for Mobile, Admin, and IoT Simulator connections.</p>
            <div style="margin-top: 20px; padding: 20px; display: inline-block; background: white; border-radius: 15px; box-shadow: 0 4px 10px rgba(0,0,0,0.1);">
                <strong>Status:</strong> <span style="color: green;">Online</span> on Port 3000
            </div>
        </div>
    `);
});

// ===================== 2. CONNECT MONGODB & SEED =====================
mongoose
  .connect(process.env.MONGO_URI)
  .then(async () => {
      console.log("✔️ MongoDB Connected Successfully");
      await seedInitialBins(); // Create bins if they don't exist
  })
  .catch((err) => console.log("❌ MongoDB Connection Error:", err.message));


// ===================== 3. MODELS ==========================

// A. USER MODEL (Slim & Scalable)
const User = mongoose.model("User", new mongoose.Schema({
      name: { type: String, required: true },
      email: { type: String, required: true, unique: true },
      password: { type: String, required: true },
      
      // 🟢 Unified Point Economy
      greenPoints: { type: Number, default: 0 }, 
      
      // 🟢 Rehab Game Memory (Current State Only)
      rehabGameExpiry: { type: Date, default: null },
      rehabGameLevel: { type: Number, default: 1 }, 
      recycledItemsCount: { type: Number, default: 0 },
  }, { timestamps: true }));

// B. ADMIN MODEL (Separated from Users)
const Admin = mongoose.model("Admin", new mongoose.Schema({
      name: { type: String, required: true },
      email: { type: String, required: true, unique: true },
      password: { type: String, required: true },
  }, { timestamps: true }));

// C. HISTORY / ACTIVITY LOG MODEL (Highly Scalable)
const UserActivity = mongoose.model("UserActivity", new mongoose.Schema({
      userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
      type: { type: String, enum: ['DEPOSIT', 'REDEMPTION', 'GAME_UPDATE'], required: true },
      
      // Data attached depending on the type of activity
      itemName: { type: String, default: null },
      weight: { type: Number, default: null },
      binId: { type: String, default: null },
      points: { type: Number, default: null },
      actionDetail: { type: String, default: null },
      
      date: { type: Date, default: Date.now }
}));

// D. BIN MODEL (DYNAMIC)
const binSchema = new mongoose.Schema({
    binId: { type: String, required: true, unique: true },
    name: { type: String, required: true },
    lat: { type: Number, required: true },
    lng: { type: Number, required: true },
    currentWeight: { type: Number, default: 0.0 },
    maxCapacity: { type: Number, default: 10.0 }, // e.g., 10kg max
    inventory: [{ itemName: String, weight: Number, depositedBy: String, date: { type: Date, default: Date.now } }]
});

binSchema.virtual('fillLevel').get(function() {
    return Math.min(100, Math.round((this.currentWeight / this.maxCapacity) * 100));
});
binSchema.set('toJSON', { virtuals: true }); 

const Bin = mongoose.model("Bin", binSchema);

// AUTO-SEED FUNCTION
async function seedInitialBins() {
    const count = await Bin.countDocuments();
    if (count === 0) {
        await Bin.create([
            { binId: "BIN001", name: "Karicode TKM College Bin", lat: 8.914941, lng: 76.632038, maxCapacity: 10.0 },
            { binId: "BIN002", name: "Kollam Railway Station Bin", lat: 8.8915, lng: 76.6217, maxCapacity: 20.0 }
        ]);
        console.log("🌱 Database seeded with initial Smart Bins (BIN001, BIN002)");
    }
}

// ===================== 4. AUTH MIDDLEWARES ==========================
const auth = (req, res, next) => {
  const token = req.headers.authorization?.split(" ")[1];
  if (!token) return res.status(401).json({ success: false, message: "No token" });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || "sewa_super_secret");
    req.userId = decoded.id;
    req.userRole = decoded.role;
    next();
  } catch {
    return res.status(401).json({ success: false, message: "Invalid token" });
  }
};

const adminOnly = (req, res, next) => {
  if (req.userRole !== "admin") return res.status(403).json({ success: false, message: "Admin access denied" });
  next();
};

// ===================== 5. AUTH & PROFILE ROUTES =========================
app.post("/register", async (req, res) => {
  try {
    const { name, email, password, role } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);

    if (role === "admin") {
        if (await Admin.findOne({ email })) return res.json({ success: false, message: "Admin already exists" });
        await Admin.create({ name, email, password: hashedPassword });
    } else {
        if (await User.findOne({ email })) return res.json({ success: false, message: "User already exists" });
        await User.create({ name, email, password: hashedPassword });
    }
    
    res.json({ success: true, message: "Registration successful" });
  } catch (error) { 
    res.status(500).json({ success: false, message: error.message }); 
  }
});

app.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Check User Collection First
    let user = await User.findOne({ email });
    let role = "user";

    // If not found in Users, check Admin Collection
    if (!user) {
        user = await Admin.findOne({ email });
        role = "admin";
    }
    
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.json({ success: false, message: "Invalid credentials" });
    }
    
    const token = jwt.sign({ id: user._id, role: role }, process.env.JWT_SECRET || "sewa_super_secret");
    res.json({ success: true, token, user, role });
  } catch (error) { 
    res.status(500).json({ success: false, message: error.message }); 
  }
});

app.get("/profile", auth, async (req, res) => {
  try {
    let user = await User.findById(req.userId).select("-password");
    if(!user && req.userRole === "admin") user = await Admin.findById(req.userId).select("-password");
    
    // Fetch user history from the separated collection
    const history = await UserActivity.find({ userId: req.userId }).sort({ date: -1 }).limit(20);
    
    res.json({ success: true, user, history });
  } catch { res.json({ success: false }); }
});

// ===================== 6. IOT BIN SIMULATOR LOGIC ===================

app.get("/bin/status/:binId", async (req, res) => {
    try {
        const bin = await Bin.findOne({ binId: req.params.binId });
        if (!bin) return res.status(404).json({ success: false, message: "Bin not found" });
        
        res.json({ success: true, currentWeight: bin.currentWeight, maxCapacity: bin.maxCapacity, fillPercentage: bin.fillLevel });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// A. MOBILE APP SCANS QR -> TRIGGER UNLOCK
app.post("/bin/scan-to-open", auth, async (req, res) => {
  let { binId } = req.body;
  
  if (typeof binId === 'object' && binId.binId) binId = binId.binId;
  if (typeof binId === 'string') binId = binId.replace(/["'{}]/g, '').trim(); 

  try {
      const bin = await Bin.findOne({ binId: binId });
      if (!bin) return res.status(404).json({ success: false, message: "Bin not found" });

      // 🛑 CAPACITY CHECK GATEKEEPER
      if (bin.currentWeight >= bin.maxCapacity) {
          console.log(`⛔ Unlock Denied -> Bin: [${binId}] is FULL.`);
          
          // Alert Admins instantly
          io.emit("admin-notification", { 
              type: "BIN_FULL", 
              message: `🚨 ALERT: ${bin.name} (${binId}) is at maximum capacity!`, 
              binId: binId
          });

          // Return HTML Payload to Flutter
          return res.json({ 
              success: false, 
              isFull: true,
              message: "BIN_FULL",
              html: `
                  <div style="font-family: sans-serif; text-align: center; padding: 40px 20px; background-color: #ffebee; border-radius: 12px;">
                      <h1 style="color: #d32f2f; font-size: 2.5rem; margin-bottom: 10px;">⛔ Bin is Full!</h1>
                      <p style="color: #555; font-size: 1.2rem; line-height: 1.5;">This SEWA bin has reached its maximum capacity of ${bin.maxCapacity}kg.</p>
                      <p style="color: #555; font-size: 1rem;">The administration team has been notified. Please locate the nearest available bin using the map.</p>
                  </div>
              `
          });
      }

      console.log(`📡 Unlock request -> Bin: [${binId}] | User: [${req.userId}]`);
      
      io.emit("admin-notification", { 
        type: "BIN_ACCESS", 
        message: `🔓 Unlock Request`, 
        binId: binId, 
        userId: req.userId 
      });
      
      res.json({ success: true });

  } catch (error) {
      res.status(500).json({ success: false, message: "Server error checking bin status." });
  }
});

// C. HARDWARE DEPOSIT -> ADD OBJECT TO BIN
app.post("/bin/hardware-deposit", async (req, res) => {
  let { binId, userId, weight, itemName, isMetal } = req.body;
  
  console.log(`\n📥 Incoming Drop -> Item: [${itemName}], Metal: [${isMetal}], Weight: [${weight}kg]`);

  if (isMetal === false) {
      console.log("❌ Rejected: No metal detected.");
      return res.status(400).json({ success: false, message: "Validation Failed: Not Metal." });
  }

  try {
    if (!userId) return res.status(400).json({ success: false, message: "User ID is missing." });

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ success: false, message: "User not found." });

    const recycleCount = user.recycledItemsCount || 0;
    const pointsEarned = Math.floor(10.0 * weight * Math.pow(0.9, recycleCount));

    user.greenPoints = (user.greenPoints || 0) + pointsEarned;
    user.recycledItemsCount = recycleCount + 1;
    await user.save();

    // 🟢 Log to separated UserActivity collection
    await UserActivity.create({
        userId: user._id,
        type: 'DEPOSIT',
        itemName: itemName || "Hardware",
        weight: parseFloat(weight),
        binId: binId,
        points: pointsEarned
    });

    const bin = await Bin.findOne({ binId: binId });
    if (bin) {
        bin.currentWeight += parseFloat(weight);
        if (bin.currentWeight >= bin.maxCapacity) {
            bin.currentWeight = bin.maxCapacity; 
            
            // Trigger Full Alert to Admins on deposit
            io.emit("admin-notification", { 
                type: "BIN_FULL", 
                message: `🚨 ALERT: Deposit caused ${bin.name} (${binId}) to reach maximum capacity!`, 
                binId: binId
            });
        }
        
        bin.inventory = bin.inventory || [];
        bin.inventory.push({
            itemName: itemName || "Hardware",
            weight: parseFloat(weight),
            depositedBy: userId
        });
        await bin.save();
    }

    io.emit("admin-notification", { 
        type: "BIN_STATUS_UPDATE", status: "CLOSED", 
        message: `Success! ${itemName} secured.`, binId: binId
    });

    res.json({ success: true, pointsEarned, greenPoints: user.greenPoints });

  } catch (e) {
    console.error("🔥 Server Error:", e.message);
    res.status(500).json({ success: false, message: e.message });
  }
});

// ===================== 7. DYNAMIC MAP & ROUTING ========================

app.get("/bins/map", auth, async (req, res) => {
  try {
      const bins = await Bin.find(); 
      res.json({ success: true, bins });
  } catch (error) {
      res.status(500).json({ success: false });
  }
});

app.get("/nearest-bins", auth, async (req, res) => {
    try {
        const { lat, lng } = req.query;
        const bins = await Bin.find(); 
        
        if (!lat || !lng) return res.json({ success: true, nearestBins: bins });

        const userLat = parseFloat(lat);
        const userLng = parseFloat(lng);

        const calculateDistance = (lat1, lon1, lat2, lon2) => {
            const toRad = (v) => (v * Math.PI) / 180;
            const a = Math.sin(toRad(lat2 - lat1) / 2) ** 2 + 
                      Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(toRad(lon2 - lon1) / 2) ** 2;
            return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        };

        const sorted = bins.map(b => {
            const doc = b.toJSON(); 
            doc.distanceKm = parseFloat(calculateDistance(userLat, userLng, b.lat, b.lng).toFixed(2));
            return doc;
        }).sort((a, b) => a.distanceKm - b.distanceKm);

        res.json({ success: true, nearestBins: sorted });
    } catch (error) {
        res.status(500).json({ success: false });
    }
});

app.get("/admin/stats", auth, adminOnly, async (req, res) => {
  try {
      const users = await User.find().select("-password");
      const totalBins = await Bin.countDocuments();
      res.json({ success: true, users, totalBins });
  } catch (error) {
      res.status(500).json({ success: false });
  }
});

// ===================== HEALTHCARE REDEMPTION ROUTES =====================
app.post("/redeem-game", auth, async (req, res) => {
    try {
        const user = await User.findById(req.userId);
        const THRESHOLD = 100;

        const currentPoints = user.greenPoints || 0;

        if (user.rehabGameExpiry && user.rehabGameExpiry > new Date()) {
            return res.status(400).json({ success: false, message: "Game already unlocked." });
        }
        
        if (currentPoints < THRESHOLD) {
            return res.status(403).json({ success: false, message: `Need ${THRESHOLD} points to unlock.` });
        }

        user.greenPoints = currentPoints - THRESHOLD;
        user.rehabGameExpiry = new Date(Date.now() + (60 * 24 * 60 * 60 * 1000)); // 60 Days
        await user.save();

        // 🟢 Log Redemption to separated UserActivity collection
        await UserActivity.create({
            userId: user._id,
            type: 'REDEMPTION',
            actionDetail: "Unlocked 60-Day Rehab Game",
            points: THRESHOLD
        });

        res.json({ success: true, message: "Rehab Game Unlocked!", greenPoints: user.greenPoints });
    } catch (e) { 
        res.status(500).json({ success: false, message: "Server error" }); 
    }
});

app.post("/update-game-progress", auth, async (req, res) => {
    try {
        const { newLevel } = req.body;
        const user = await User.findById(req.userId);
        if (newLevel > user.rehabGameLevel) {
            user.rehabGameLevel = newLevel;
            await user.save();
            
            // Log progression
            await UserActivity.create({
                userId: user._id,
                type: 'GAME_UPDATE',
                actionDetail: `Reached Level ${newLevel}`
            });
        }
        res.json({ success: true, level: user.rehabGameLevel });
    } catch (e) { res.status(500).json({ success: false }); }
});

// ===================== 8. WEBSOCKETS (FORCE BROADCAST) ==========================
io.on("connection", (socket) => {
  socket.on("hardware-status", (data) => {
    console.log("📢 Relay Status:", data.status);
    io.emit("admin-notification", data); 
  });
});

// ===================== GLOVE RELAY BROKER =====================
const WebSocket = require('ws');

const wss = new WebSocket.Server({ server: server, path: "/glove" });

wss.on('connection', (ws) => {
    console.log("🔗 Device Connected to Glove Relay!");

    ws.on('message', (message) => {
        wss.clients.forEach((client) => {
            if (client !== ws && client.readyState === WebSocket.OPEN) {
                client.send(message.toString());
            }
        });
    });

    ws.on('close', () => console.log("❌ Device disconnected from Relay"));
});

const PORT = 3000;
server.listen(PORT, "0.0.0.0", () =>
  console.log(`🚀 SEWA Server running at http://0.0.0.0:${PORT}`)
);
