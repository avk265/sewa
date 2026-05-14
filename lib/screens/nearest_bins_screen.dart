import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sewa/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class NearestBinsScreen extends StatefulWidget {
  const NearestBinsScreen({super.key});

  @override
  State<NearestBinsScreen> createState() => _NearestBinsScreenState();
}

class _NearestBinsScreenState extends State<NearestBinsScreen> {
  Map<String, dynamic>? nearest;
  bool loading = true;
  Position? userPos;

  @override
  void initState() {
    super.initState();
    loadNearest();
  }

  Future<bool> checkPermission() async {
    bool service = await Geolocator.isLocationServiceEnabled();
    if (!service) return false;

    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied) return false;
    }
    return !(p == LocationPermission.deniedForever);
  }

  Future<void> loadNearest() async {
    bool ok = await checkPermission();
    if (!ok) {
      if (mounted) setState(() => loading = false);
      return;
    }

    try {
      userPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List bins = await ApiService.getNearestBins(userPos!.latitude, userPos!.longitude);

      // 🥇 Choose only the nearest (sorted already from API)
      if (bins.isNotEmpty && mounted) {
        setState(() {
          nearest = bins.first;
          loading = false;
        });
      } else {
        if (mounted) setState(() => loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Color levelColor(int fill) {
    if (fill < 40) return Colors.green;
    if (fill < 75) return Colors.orange;
    return Colors.red;
  }

  /// 🚗 Open Google Maps Navigation (TRULY FIXED)
  Future<void> navigate(double lat, double lng) async {
    // 🟢 FIXED: Real Google Maps Directions URL injected with coordinates
    final Uri url = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw "Could not launch Maps";
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not open maps application."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nearest Bin")),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : nearest == null
              ? const Center(
                  child: Text(
                    "No bin found nearby 😕",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: levelColor(nearest!["fillLevel"] ?? 0),
                              child: const Icon(Icons.delete, size: 40, color: Colors.white),
                            ),
                            const SizedBox(height: 16),

                            Text(
                              nearest!["name"] ?? "Smart Bin",
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 12),
                            Text("📍 ${nearest!["distanceKm"]} km away",
                                style: TextStyle(fontSize: 16, color: Colors.grey[700])),

                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("♻️ Fill Level: ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                                Icon(Icons.circle,
                                    size: 16, color: levelColor(nearest!["fillLevel"] ?? 0)),
                                const SizedBox(width: 6),
                                Text("${nearest!["fillLevel"] ?? 0}%",
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),

                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  // 🟢 FIXED: Safe parsing to prevent app crash if JSON returns a String
                                  double destLat = double.tryParse(nearest!["lat"].toString()) ?? 0.0;
                                  double destLng = double.tryParse(nearest!["lng"].toString()) ?? 0.0;
                                  navigate(destLat, destLng);
                                },
                                icon: const Icon(Icons.directions, color: Colors.white),
                                label: const Text(
                                  "Navigate to Bin",
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}