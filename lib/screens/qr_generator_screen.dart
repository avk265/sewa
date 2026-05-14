import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';

class QRGenerateScreen extends StatefulWidget {
  const QRGenerateScreen({super.key});

  @override
  State<QRGenerateScreen> createState() => _QRGenerateScreenState();
}

class _QRGenerateScreenState extends State<QRGenerateScreen> {
  Map<String, dynamic>? userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final res = await ApiService.getProfile();
    if (!mounted) return;

    if (res["success"] == true && res["user"] != null) {
      setState(() {
        userData = res["user"];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load user data for QR.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate secure JSON string for the Bin's scanner
    String qrData = "";
    if (userData != null) {
      qrData = jsonEncode({
        "userId": userData!["_id"], // Ensure this matches your MongoDB _id
        "userName": userData!["name"],
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Eco ID"),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : userData == null
              ? const Center(child: Text("Could not generate QR Code."))
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner, size: 60, color: Colors.green),
                        const SizedBox(height: 16),
                        const Text(
                          "Scan at E-Waste Bin",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Hold this QR code up to the scanner on the smart bin to unlock the lid and earn points.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 40),

                        // 🪪 Beautiful QR Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 15,
                                spreadRadius: 5,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              QrImageView(
                                data: qrData,
                                version: QrVersions.auto,
                                size: 240.0,
                                backgroundColor: Colors.white,
                                // Add a nice embedded logo in the center of the QR
                                embeddedImage: const AssetImage('assets/images/recycle_logo.png'), // Optional: Remove if you don't have an asset
                                embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(40, 40)),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                userData!["name"],
                                style: const TextStyle(
                                  fontSize: 20, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87
                                ),
                              ),
                              Text(
                                "Eco Member",
                                style: TextStyle(
                                  fontSize: 16, 
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}