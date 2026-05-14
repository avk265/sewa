import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:sewa/services/api_service.dart';

class RehabGameScreen extends StatefulWidget {
  final int startingLevel;
  const RehabGameScreen({super.key, required this.startingLevel});

  @override
  State<RehabGameScreen> createState() => _RehabGameScreenState();
}

class _RehabGameScreenState extends State<RehabGameScreen> {
  late WebSocketChannel channel;
  int currentLevel = 1;
  
  // 🟢 All 8-DOF Sensor Variables
  int thumb = 0, indexFinger = 0, middle = 0, ring = 0, pinky = 0;
  int ax = 0, ay = 0, az = 0;

  // 🟢 Point this to your Ngrok URL (Must start with wss:// and end with /glove)
  final String cloudRelayURL = "https://sewa-o947.onrender.com/glove"; 

  @override
  void initState() {
    super.initState();
    currentLevel = widget.startingLevel;
    
    // Connect to the Cloud Relay
    channel = WebSocketChannel.connect(Uri.parse(cloudRelayURL));
    channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (mounted) {
        setState(() {
          thumb = data["t"] ?? 0;
          indexFinger = data["i"] ?? 0;
          middle = data["m"] ?? 0;
          ring = data["r"] ?? 0;
          pinky = data["p"] ?? 0;
          ax = data["ax"] ?? 0;
          ay = data["ay"] ?? 0;
          az = data["az"] ?? 0;
        });
        _checkLevelCompletion();
      }
    });
  }

  // 🟢 The Therapy Progression Logic
  void _checkLevelCompletion() {
    // Level 1: Index finger isolation
    if (currentLevel == 1 && indexFinger > 60) _levelUp();
    
    // Level 2: Pinch Grip (Thumb + Index)
    if (currentLevel == 2 && thumb > 60 && indexFinger > 60) _levelUp();
    
    // Level 3: Full Fist (All 5 fingers closed)
    if (currentLevel == 3 && thumb > 50 && indexFinger > 50 && middle > 50 && ring > 50 && pinky > 50) _levelUp();
    
    // Level 4: Wrist Rotation (Using MPU X/Y axis absolute tilt)
    if (currentLevel == 4 && (ax.abs() > 10000 || ay.abs() > 10000)) _levelUp();
  }

  void _levelUp() async {
    if (currentLevel >= 5) return; // Game Complete
    
    setState(() => currentLevel++);
    
    // 🟢 Save memory to MongoDB so they don't lose progress if they close the app
    await ApiService.updateGameLevel(currentLevel);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🎉 Level Up! Advanced to Level $currentLevel"), backgroundColor: Colors.green)
      );
    }
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stroke Rehab Therapy"), backgroundColor: Colors.teal),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text("Current Level: $currentLevel", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 20),
            
            _buildInstructionCard(),
            const SizedBox(height: 30),

            // 🖐️ Finger Data
            const Text("Hand Metrics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildSensorBar("Thumb", thumb, Colors.redAccent),
            _buildSensorBar("Index Finger", indexFinger, Colors.blueAccent),
            _buildSensorBar("Middle Finger", middle, Colors.orangeAccent),
            _buildSensorBar("Ring Finger", ring, Colors.purpleAccent),
            _buildSensorBar("Pinky Finger", pinky, Colors.pinkAccent),
            
            const SizedBox(height: 30),
            
            // 🔄 Wrist Data (MPU6050)
            const Text("Wrist Kinematics (MPU6050)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAxisData("X-Axis", ax),
                _buildAxisData("Y-Axis", ay),
                _buildAxisData("Z-Axis", az),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    String instruction = "";
    if (currentLevel == 1) {
      instruction = "Task 1: Isolate and close your Index Finger past 60%";
    } else if (currentLevel == 2) instruction = "Task 2: Precision Pinch (Close Thumb and Index Finger)";
    else if (currentLevel == 3) instruction = "Task 3: Power Grip (Close all 5 fingers to make a fist)";
    else if (currentLevel == 4) instruction = "Task 4: Wrist Pronation (Rotate your wrist left or right)";
    else instruction = "🏆 Therapy Complete! Excellent job.";

    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.teal)),
      child: Text(instruction, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal), textAlign: TextAlign.center),
    );
  }

  Widget _buildSensorBar(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: LinearProgressIndicator(
              // Clamp value to prevent UI crashes if hardware sends noisy > 100 data
              value: (value / 100.0).clamp(0.0, 1.0), 
              color: color, 
              backgroundColor: color.withOpacity(0.2), 
              minHeight: 15,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(width: 40, child: Text("  $value%", textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildAxisData(String label, int value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 5),
        Text(value.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}