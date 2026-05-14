import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sewa/services/api_service.dart';
import 'package:sewa/theme.dart'; // Make sure your primaryGreen is here

class ItemScannerScreen extends StatefulWidget {
  const ItemScannerScreen({super.key});

  @override
  State<ItemScannerScreen> createState() => _ItemScannerScreenState();
}

class _ItemScannerScreenState extends State<ItemScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  // 🟢 The actual QR scanning logic using mobile_scanner
  Future<void> _handleScan(BarcodeCapture capture) async {
    if (isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    final String? rawCode = barcodes.firstOrNull?.rawValue;

    if (rawCode != null) {
      setState(() => isProcessing = true);
      cameraController.stop(); // Pause scanning immediately

      String binId = "";
      try {
        // Decode the JSON from the HTML QR code: {"binId":"BIN001"}
        final decodedData = jsonDecode(rawCode);
        binId = decodedData["binId"] ?? rawCode; 
      } catch (e) {
        // Fallback in case the QR code is just plain text "BIN001"
        binId = rawCode;
      }

      // Request the server to unlock the bin
      final bool isUnlocked = await ApiService.unlockBin(binId);

      if (!mounted) return;

      if (isUnlocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Bin Unlocked! Please deposit your waste."),
            backgroundColor: Colors.green,
          ),
        );
        // Go back to the dashboard once unlocked
        Navigator.pop(context); 
      } else {
        _showError("❌ Failed to unlock bin. Try again.");
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    // Wait 2 seconds, then let the user scan again
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => isProcessing = false);
        cameraController.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Unlock Smart Bin"),
        backgroundColor: primaryGreen,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🎯 REAL Camera Viewfinder with your custom design
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black, // Dark background for the camera
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primaryGreen.withOpacity(0.5), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 🟢 The Live Camera Feed using mobile_scanner
                      MobileScanner(
                        controller: cameraController,
                        onDetect: _handleScan,
                      ),
                      
                      // 🟢 Your Custom Frame corners
                      Positioned(top: 20, left: 20, child: _corner(0)),
                      Positioned(top: 20, right: 20, child: _corner(1)),
                      Positioned(bottom: 20, left: 20, child: _corner(2)),
                      Positioned(bottom: 20, right: 20, child: _corner(3)),

                      // Loading overlay when unlocking
                      if (isProcessing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              const Text(
                "Scan Bin QR Code",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              const Text(
                "Point your camera at the QR code displayed on the SEWA bin. It will automatically scan and unlock the lid.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              
              const SizedBox(height: 40),
              
              // 🚀 Flashlight Toggle
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)
                    ),
                  ),
                  onPressed: () => cameraController.toggleTorch(), // Works with mobile_scanner
                  icon: const Icon(Icons.flash_on, size: 28, color: Colors.white),
                  label: const Text(
                    "Toggle Flashlight", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to draw viewfinder corners
  Widget _corner(int rotationMultiplier) {
    return RotatedBox(
      quarterTurns: rotationMultiplier,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: primaryGreen, width: 4),
            left: BorderSide(color: primaryGreen, width: 4),
          ),
        ),
      ),
    );
  }
}