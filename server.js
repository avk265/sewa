require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const http = require("http");
const { Server } = require("socket.io");
const WebSocket = require('ws');

const app = express();
const server = http.createServer(app);

const io = require("socket.io")(server, {
    cors: {
        origin: "*", // 🟢 Allows Flutter to connect
        methods: ["GET", "POST"]
    },
  transports: ['websocket', 'polling']
});
app.set("socketio", io);

app.use(express.static(__dirname));
app.use(express.json()); 
app.use(express.urlencoded({ extended: true }));
app.use(cors());

const JWT_SECRET = process.env.JWT_SECRET || "sewa_super_secret_2026";
const MONGO_URI = process.env.MONGO_URI || "mongodb://localhost:27017/sewa";

// ===================== 1. ROOT ROUTE =====================
app.get("/", (req, res) => {
    res.send(`
        <div style="font-family: sans-serif; text-align: center; padding-top: 100px; background: #e8f5e9; height: 100vh; margin:0;">
            <h1 style="color: #2e7d32; font-size: 3rem;">♻️ SEWA Cloud Core Live</h1>
            <p style="font-size: 1.2rem; color: #555;">Processing Mobile, Admin, and Smart Glove Data</p>
            <div style="margin-top: 20px; padding: 20px; display: inline-block; background: white; border-radius: 15px; box-shadow: 0 4px 10px rgba(0,0,0,0.1);">
                <strong>Status:</strong> <span style="color: green;">Online</span> | <strong>Port:</strong> 3000
            </div>
        </div>
    `);
});

// ===================== 2. DATABASE MODELS =====================


const User = mongoose.model("User", new mongoose.Schema({
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    address: { type: String, default: "" }, // 👈 NEW: Used for grouping
    communityName: { type: String, default: null }, // 👈 NEW: Assigned by Admin
    greenPoints: { type: Number, default: 0 }, 
    gloveId: { type: String, default: null }, 
    rehabGameExpiry: { type: Date, default: null },
    rehabGameLevel: { type: Number, default: 1 }, 
    recycledItemsCount: { type: Number, default: 0 },
}, { timestamps: true }));

// New Campaign Model for Community Goals/Raffles
const Campaign = mongoose.model("Campaign", new mongoose.Schema({
    title: { type: String, required: true },
    description: { type: String, required: true },
    communityName: { type: String, required: true }, // Links to the user's community
    type: { type: String, enum: ['GOAL', 'RAFFLE'], required: true },
    targetPoints: { type: Number, required: true },
    raisedPoints: { type: Number, default: 0 },
    isActive: { type: Boolean, default: true },
    contributors: [{
        userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        pointsDonated: Number
    }]
}));

// B. ADMIN MODEL (Authorities)
const Admin = mongoose.model("Admin", new mongoose.Schema({
      name: { type: String, required: true },
      email: { type: String, required: true, unique: true },
      password: { type: String, required: true },
  }, { timestamps: true }));

// C. SCALABLE ACTIVITY LOG (New: Stores all history separately)
const UserActivity = mongoose.model("UserActivity", new mongoose.Schema({
      userId: { type: mongoose.Schema.Types.ObjectId, required: true },
      type: { type: String, enum: ['DEPOSIT', 'REDEMPTION', 'GAME_UPDATE'], required: true },
      itemName: { type: String, default: null },
      weight: { type: Number, default: null },
      binId: { type: String, default: null },
      points: { type: Number, default: null },
      actionDetail: { type: String, default: null },
      date: { type: Date, default: Date.now }
}));

// D. SMART BIN MODEL
const binSchema = new mongoose.Schema({
    binId: { type: String, required: true, unique: true },
    name: { type: String, required: true },
    lat: { type: Number, required: true },
    lng: { type: Number, required: true },
    currentWeight: { type: Number, default: 0.0 }, 
    maxCapacity: { type: Number, default: 10.0 },
    inventory: [{ itemName: String, weight: Number, depositedBy: String, date: { type: Date, default: Date.now } }]
});

binSchema.virtual('fillLevel').get(function() {
    return Math.min(100, Math.round((this.currentWeight / this.maxCapacity) * 100));
});
binSchema.set('toJSON', { virtuals: true }); 
const Bin = mongoose.model("Bin", binSchema);

// ===================== 3. AUTH MIDDLEWARES =====================


const auth = async (req, res, next) => {
  // 1. Extract Token
  const token = req.headers.authorization?.split(" ")[1];
  if (!token) return res.status(401).json({ success: false, message: "No token" });

  try {
    // 2. Verify JWT
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // 3. DATABASE CHECK: Look in the correct collection
    let account;
    if (decoded.role === "admin") {
      account = await Admin.findById(decoded.id); // 👈 Checks Admin Collection
    } else {
      account = await User.findById(decoded.id);  // 👈 Checks User Collection
    }

    // 4. Validate existence
    if (!account) {
      return res.status(401).json({ success: false, message: "Account not found" });
    }

    // 5. Attach to Request
    req.userId = decoded.id;
    req.userRole = decoded.role;
    req.user = account; // Useful for accessing name/email later
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: "Invalid session" });
  }
};

const adminOnly = (req, res, next) => {
  if (req.userRole !== "admin") return res.status(403).json({ success: false, message: "Admin access denied" });
  next();
};

// ===================== 4. AUTH & PROFILE ROUTES =====================

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
  } catch (error) { res.status(500).json({ success: false, message: error.message }); }
});

app.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    let user = await User.findOne({ email }) || await Admin.findOne({ email });
    const role = (user instanceof Admin) ? "admin" : "user";

    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.json({ success: false, message: "Invalid credentials" });
    }
    
    const token = jwt.sign({ id: user._id, role: role }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ success: true, token, user, role });
  } catch (error) { res.status(500).json({ success: false }); }
});

app.get("/profile", auth, async (req, res) => {
  try {
    const model = (req.userRole === "admin") ? Admin : User;
    const user = await model.findById(req.userId).select("-password");
    
    // 🟢 Fetch Activity from the new separated collection
    const history = await UserActivity.find({ userId: req.userId }).sort({ date: -1 }).limit(25);
    
    res.json({ success: true, user, history });
  } catch { res.json({ success: false }); }
});
// 🟢 PATCH: Dynamic Profile Update
// 🟢 PATCH: Role-Aware Profile Update
app.patch("/update-profile", auth, async (req, res) => {
    try {
        // 🟢 FIX 1: Use the variables set by your 'auth' middleware
        const userId = req.userId; 
        const userRole = req.userRole; 
        const { name, mobile, address } = req.body;

        let updatedRecord;

        if (userRole === 'admin') {
            // 🟢 FIX 2: Ensure 'Admin' is the correct Mongoose Model name
            updatedRecord = await Admin.findByIdAndUpdate(
                userId,
                { $set: { name } },
                { new: true, runValidators: true }
            );
        } else {
            updatedRecord = await User.findByIdAndUpdate(
                userId,
                { $set: { name, mobile, address } },
                { new: true, runValidators: true }
            );
        }

        if (!updatedRecord) {
            return res.status(404).json({ success: false, message: "Account not found in the selected collection" });
        }

        res.json({ 
            success: true, 
            message: "Profile updated successfully", 
            user: updatedRecord 
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});
//====== 🟢 CORRECTED ADMIN: UNIFIED DATA FETCH =====================
// ================= 1. DATABASE MODELS UPDATE =================

// Update existing User Schema to include address and community


// ================= 2. COMMUNITY ROUTES =================

// 🟢 ADMIN: Assign users to a community based on matching address keyword
app.post("/admin/assign-community", auth, adminOnly, async (req, res) => {
    try {
        const { addressKeyword, communityName } = req.body;
        // Find users whose address contains the keyword (case-insensitive)
        const result = await User.updateMany(
            { address: { $regex: addressKeyword, $options: "i" } },
            { $set: { communityName: communityName } }
        );
        res.json({ success: true, message: `Added ${result.modifiedCount} users to ${communityName} community.` });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// 🟢 USER: Fetch campaigns for their specific community
app.get("/community/campaigns", auth, async (req, res) => {
    try {
        const user = await User.findById(req.userId);
        if (!user.communityName) return res.json({ success: true, campaigns: [] });

        const campaigns = await Campaign.find({ communityName: user.communityName, isActive: true });
        res.json({ success: true, campaigns, userBalance: user.greenPoints });
    } catch (error) {
        res.status(500).json({ success: false, message: "Error fetching campaigns" });
    }
});

// 🟢 USER: Donate points to a community campaign
app.post("/community/donate", auth, async (req, res) => {
    try {
        const { campaignId, amount } = req.body;
        const user = await User.findById(req.userId);
        
        if (user.greenPoints < amount) return res.status(400).json({ success: false, message: "Insufficient points" });

        // Deduct points from user, add to campaign
        await User.findByIdAndUpdate(req.userId, { $inc: { greenPoints: -amount } });
        await Campaign.findByIdAndUpdate(campaignId, {
            $inc: { raisedPoints: amount },
            $push: { contributors: { userId: req.userId, pointsDonated: amount } }
        });

        // Log the activity
        await UserActivity.create({
            userId: req.userId, type: 'REDEMPTION', actionDetail: `Donated ${amount} pts to Community Goal`, points: -amount
        });

        res.json({ success: true, message: `Successfully donated ${amount} points!` });
    } catch (error) {
        res.status(500).json({ success: false });
    }
});
// 🟢 server.js - Unified Admin Stats (Public Access)
app.get("/admin/stats", async (req, res) => {
    try {
        // 1. Fetch Users (From the 'users' collection)
        const users = await User.find()
            .select("-password") 
            .sort({ createdAt: -1 });

        // 2. Fetch Bins (From the 'bins' collection)
        const bins = await Bin.find();

        // 3. Fetch Activity Feed (From the 'useractivities' collection)
        // Note: Even though this is an admin route, the activity belongs to 'Users'
        const feed = await UserActivity.find()
            .populate("userId", "name email") 
            .sort({ date: -1 })
            .limit(50);

        // 4. Summary Analytics
        const systemAnalytics = {
            totalCitizens: users.length,
            activeBins: bins.length,
            binsRequiringPickup: bins.filter(b => (b.currentWeight / b.maxCapacity) >= 0.9).length,
            totalKgCollected: bins.reduce((acc, b) => acc + (b.currentWeight || 0), 0).toFixed(2)
        };

        res.json({
            success: true,
            users: users,
            bins: bins,
            feed: feed,
            stats: systemAnalytics
        });

    } catch (error) {
        console.error("🔥 Public Admin Stats Error:", error.message);
        res.status(500).json({ success: false, message: "Error aggregating data" });
    }
});
// ================= 1. UPDATE USER MODEL =================
// Add 'gloveId' to your existing User schema

// ================= 2. ADMIN ROUTE TO PAIR GLOVE =================
// Add this so Admins can assign a specific physical glove to a student
app.post("/admin/assign-glove", auth, adminOnly, async (req, res) => {
    try {
        const { userEmail, gloveId } = req.body;
        const user = await User.findOneAndUpdate(
            { email: userEmail }, 
            { gloveId: gloveId }, 
            { new: true }
        );
        if (!user) return res.status(404).json({ success: false, message: "User not found" });
        res.json({ success: true, message: `Glove ${gloveId} linked to ${user.name}` });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// ================= 3. WEBSOCKET GATEKEEPER =================
// Update your existing WebSocket logic

// 🟢 GET USER-SPECIFIC CONTRIBUTION HISTORY
// 🟢 GET USER-SPECIFIC CONTRIBUTION HISTORY
// 🟢 STANDALONE HISTORY ROUTE
// 🟢 CORRECTED USER HISTORY ROUTE
app.get("/user/history", auth, async (req, res) => {
    try {
        const history = await UserActivity.find({ 
                userId: req.userId,
                type: "DEPOSIT"   // 👈 filter added
            })
            .sort({ date: -1 })
            .limit(50);

        console.log(`✅ Deposit History found for User: ${req.userId} (Count: ${history.length})`);

        res.json({
            success: true,
            history: history
        });

    } catch (error) {
        console.error("🔥 User History Error:", error.message);
        res.status(500).json({ success: false, message: "Server error" });
    }
});
const binAccessSessions={};

app.post("/bin/scan-to-open", auth, async (req, res) => {
  let { binId } = req.body;
  if (typeof binId === 'object' && binId.binId) binId = binId.binId;
  binId = binId.toString().replace(/["'{}]/g, '').trim(); 

  try {

      const bin = await Bin.findOne({ binId });
      if (!bin) return res.status(404).json({ success: false, message: "Bin not found" });

      if (bin.currentWeight >= bin.maxCapacity) {

        console.log(`🚨 Bin ${binId} is full`);

        io.emit("admin-notification", { 
            type: "BIN_FULL", 
            binId,
            message: `CRITICAL: Bin ${binId} full`
        });

        return res.json({ 
            success: false, 
            isFull: true,
            message: "This bin is currently full"
        });

      }

      // ⭐ STORE USER SESSION FOR BIN
      binAccessSessions[binId] = {
          userId: req.userId,
          time: Date.now()
      };

      console.log(`🔓 Unlocking Bin: ${binId} by ${req.userId}`);

      io.emit("admin-notification", { 
          type: "BIN_ACCESS", 
          binId,
          userId: req.userId
      });

      res.json({ success: true });

  } catch (error) {
      res.status(500).json({ success: false });
  }
});
app.get("/bin/scan-to-open/:binId", (req, res) => {

  const binId = req.params.binId;
  const session = binAccessSessions[binId];

  if (!session) {
    return res.json({ active: false });
  }

  if (Date.now() - session.time > 30000) {
    delete binAccessSessions[binId];
    return res.json({ active: false });
  }

  // ✅ SEND ACTIVE SESSION
  res.json({
    active: true,
    userId: session.userId
  });

});

app.get("/bin/status/:binId", async (req, res) => {
    try {
        const bin = await Bin.findOne({ binId: req.params.binId });
        
        if (!bin) {
            return res.status(404).json({ success: false, message: "Bin not found" });
        }

        // 🟢 FIX 1: Define the threshold logic
        const fillLevel = bin.fillLevel || 0;
        const isFull = fillLevel >= 90;

        // 🟢 FIX 2: Only emit if the bin is actually critical
        if (isFull) {
            const io = req.app.get("socketio");
            if (io) {
                io.emit("admin-notification", {
                    type: "BIN_FULL",
                    binId: bin.binId,
                    message: `🚨 ALERT: Bin ${bin.binId} is at ${fillLevel.toFixed(1)}%!`
                });
            }
        }

        // 🟢 FIX 3: Return the calculated data
        res.json({ 
            success: true, 
            currentWeight: bin.currentWeight, 
            maxCapacity: bin.maxCapacity, 
            fillPercentage: fillLevel 
        });

    } catch (error) {
        console.error("🔥 Error in bin status route:", error);
        res.status(500).json({ success: false, message: error.message });
    }
});
app.post("/bin/hardware-deposit", async (req, res) => {

  const { binId, userId, weight, itemName, isMetal } = req.body;

  console.log("📦 Hardware Deposit Request:", req.body);

  if (!isMetal) {
    return res.status(400).json({
      success: false,
      message: "NOT_METAL"
    });
  }

  try {

    if (!binId || !userId || !weight) {
      return res.status(400).json({
        success: false,
        message: "Missing required fields"
      });
    }

    const user = await User.findById(userId);
    const bin = await Bin.findOne({ binId });

    if (!user) {
      console.log("❌ User not found:", userId);
      return res.status(404).json({ success: false, message: "User not found" });
    }

    if (!bin) {
      console.log("❌ Bin not found:", binId);
      return res.status(404).json({ success: false, message: "Bin not found" });
    }

    const numWeight = parseFloat(weight);

    const pointsEarned = Math.floor(
      10 * numWeight * Math.pow(0.95, user.recycledItemsCount || 0)
    );

    await User.findByIdAndUpdate(userId, {
      $inc: {
        greenPoints: pointsEarned,
        recycledItemsCount: 1
      }
    });

    await Bin.findOneAndUpdate(
      { binId },
      {
        $inc: { currentWeight: numWeight },
        $push: {
          inventory: {
            itemName: itemName || "Unknown Item",
            weight: numWeight,
            depositedBy: userId
          }
        }
      }
    );

    await UserActivity.create({
      userId,
      type: "DEPOSIT",
      itemName: itemName || "Unknown Item",
      weight: numWeight,
      binId,
      points: pointsEarned,
      actionDetail: `Recycled ${itemName || "Unknown Item"}`
    });

    delete binAccessSessions[binId];

    const io = req.app.get("socketio");

    io.emit("admin-notification", {
      type: "DEPOSIT_SUCCESS",
      binId,
      message: `${numWeight}kg deposited`
    });

    res.json({
      success: true,
      pointsEarned
    });

  } catch (error) {

    console.error("🔥 Hardware Deposit Error:", error);

    res.status(500).json({
      success: false,
      message: "Deposit failed"
    });

  }

});
// ===================== 6. MAPS & ADMIN =====================

app.get("/nearest-bins", auth, async (req, res) => {
    try {
        const { lat, lng } = req.query;
        const bins = await Bin.find();
        if (!lat || !lng) return res.json({ success: true, nearestBins: bins });

        const calculateDistance = (lat1, lon1, lat2, lon2) => {
            const toRad = (v) => (v * Math.PI) / 180;
            const a = Math.sin(toRad(lat2 - lat1) / 2)**2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(toRad(lon2 - lon1) / 2)**2;
            return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        };

        const sorted = bins.map(b => {
            const d = b.toJSON();
            d.distanceKm = parseFloat(calculateDistance(lat, lng, b.lat, b.lng).toFixed(2));
            return d;
        }).sort((a, b) => a.distanceKm - b.distanceKm);

        res.json({ success: true, nearestBins: sorted });
    } catch (e) { res.status(500).json({ success: false }); }
});

app.post("/admin/empty-bin", auth, adminOnly, async (req, res) => {
    await Bin.findOneAndUpdate({ binId: req.body.binId }, { $set: { currentWeight: 0, inventory: [] } });
    res.json({ success: true, message: "Bin reset" });
});

// ===================== 7. HEALTHCARE REDEMPTION =====================

app.post("/redeem-game", auth, async (req, res) => {
    try {
        const user = await User.findById(req.userId);
        if (user.greenPoints < 100) return res.status(403).json({ success: false, message: "INSUFFICIENT_POINTS" });

        await User.findByIdAndUpdate(req.userId, { 
            $inc: { greenPoints: -100 },
            $set: { rehabGameExpiry: new Date(Date.now() + (60 * 24 * 60 * 60 * 1000)) } 
        });

        await UserActivity.create({
            userId: req.userId, type: 'REDEMPTION', actionDetail: "Unlocked Rehab Game (60 Days)", points: 100
        });

        res.json({ success: true });
    } catch (e) { res.status(500).json({ success: false }); }
});

app.post("/update-game-progress", auth, async (req, res) => {
    const { newLevel } = req.body;
    await User.findByIdAndUpdate(req.userId, { $set: { rehabGameLevel: newLevel } });
    await UserActivity.create({ userId: req.userId, type: 'GAME_UPDATE', actionDetail: `Reached Level ${newLevel}` });
    res.json({ success: true });
});

// ===================== 8. WEBSOCKETS (GLOVE RELAY) =====================

// ===================== 8. GLOVE TO APP BRIDGE =====================

// 🟢 SECTION 8: THE HARDWARE-TO-APP BRIDGE
const wss = new WebSocket.Server({ server, path: "/glove" });

wss.on('connection', (ws) => {
    console.log("🦾 Hardware connected to /glove path");

    ws.on('message', (msg) => {
        try {
            // msg comes from the Hardware Glove (Push)
            const data = JSON.parse(msg);
            
            if (data.protocol === "SEWA_GLOVE_V1") {
                const io = app.get("socketio"); 
                
                // 🌉 THE RELAY: This is what the Dart app "hears"
                // We send the whole 'data' object so Dart gets t, i, m, r, p, ax, ay, az
                io.emit("rehab-game-sync", data);
                
                // 🛡️ User-Specific Security (Optional but recommended)
                // You can also emit to a specific room if you want only one user to hear it
                // io.to(data.userId).emit("rehab-game-sync", data);

                console.log(`📡 Relaying Glove [${data.deviceId}] data to User [${data.userId}]`);
            }
        } catch (e) {
            console.log("Malformed data from ESP32");
        }
    });
});

// Look for your io.on("connection") block
// ===================== 8. UNIFIED SOCKET.IO LOGIC =====================

io.on("connection", (socket) => {
    console.log("🔌 New Client Connected: " + socket.id);

    // 🟢 A. Catch "hardware-alert" (Used by Bin Simulator)
    socket.on("hardware-alert", (data) => {
        console.log("🚨 Bin Alert Received:", data.message);
        io.emit("admin-notification", {
            type: "CRITICAL_ALERT",
            binId: data.binId,
            message: data.message || `Bin ${data.binId} is nearly full!`
        });
    });

    // 🟢 B. Catch direct "admin-notification" (Used when simulator bypasses relay)
    socket.on("admin-notification", (data) => {
    console.log("📢 Direct Admin Notification Relayed:", data.message);
    socket.broadcast.emit("admin-notification", data); // 👈 Safely relays to others
});
    // 🟢 C. Catch "hardware-status" (Used for general bin health/heartbeats)
    socket.on("hardware-status", (data) => {
        console.log("🛰️ Hardware Status Update:", data.binId);
        io.emit("admin-notification", data);
    });

    socket.on("disconnect", () => {
        console.log("❌ Client Disconnected");
    });
});
// ===================== 9. START SERVER =====================

const PORT = process.env.PORT || 3000;
mongoose.connect(MONGO_URI).then(() => {
    server.listen(PORT, "0.0.0.0", () => {
        console.log(`🚀 SEWA SERVER ACTIVE ON PORT ${PORT}`);
    });
});
