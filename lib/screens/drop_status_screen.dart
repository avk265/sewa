// lib/screens/drop_status_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DropStatusScreen extends StatefulWidget {
  final String binId;
  const DropStatusScreen({super.key, required this.binId});

  @override
  State<DropStatusScreen> createState() => _DropStatusScreenState();
}

class _DropStatusScreenState extends State<DropStatusScreen> {
  bool isProcessing = true;
  Map<String, dynamic>? result;

  @override
  void initState() {
    super.initState();
    _waitForHardware();
  }

  Future<void> _waitForHardware() async {
    // In a real app, you might use a WebSocket here.
    // For a simple simulator, we wait 5 seconds (simulating the user dropping & bin closing)
    await Future.delayed(const Duration(seconds: 5));
    
    final res = await ApiService.getProfile(); // Fetch updated history/points
    if (mounted && res["success"]) {
      setState(() {
        result = res["user"]["history"].first; // Get the latest deposit
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: isProcessing 
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.green),
                const SizedBox(height: 20),
                Text("Bin ${widget.binId} is open...", style: const TextStyle(fontSize: 18)),
                const Text("Please drop your items and close the lid."),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 100),
                const SizedBox(height: 20),
                const Text("Waste Recycled!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text("Weight: ${result?['weight']} kg"),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, "/dashboard"),
                  child: const Text("Back to Dashboard"),
                )
              ],
            ),
      ),
    );
  }
}