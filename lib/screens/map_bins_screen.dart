import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sewa/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// 📌 Ask user to enable GPS + Permissions
Future<bool> handleLocationPermission(BuildContext context) async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enable GPS to continue")),
    );
    await Geolocator.openLocationSettings(); 
    return false;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission required")),
      );
      return false;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Enable location from App Settings")),
    );
    return false;
  }

  return true;
}

/// 🌍 LIVE MAP SCREEN
class MapBinsScreen extends StatefulWidget {
  const MapBinsScreen({super.key});

  @override
  State<MapBinsScreen> createState() => _MapBinsScreenState();
}

class _MapBinsScreenState extends State<MapBinsScreen> {
  List bins = [];
  bool loading = true;
  LatLng? userLocation;
  final MapController _mapController = MapController();
  Map? selectedBin;

  /// Get argument when navigating from nearest screen
  @override
  void didChangeDependencies() {
    selectedBin = ModalRoute.of(context)?.settings.arguments as Map?;
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    checkAndLoad();
  }

  Future<void> checkAndLoad() async {
    bool ok = await handleLocationPermission(context);
    if (ok) loadMapData();
  }

  /// 📌 Load location & nearby bins
  Future<void> loadMapData() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      userLocation = LatLng(pos.latitude, pos.longitude);

      bins = await ApiService.getNearestBins(pos.latitude, pos.longitude);
      if (mounted) setState(() => loading = false);

      // 🟢 FIXED: Safe parsing of selected bin coordinates
      if (selectedBin != null) {
        double destLat = double.tryParse(selectedBin!["lat"].toString()) ?? pos.latitude;
        double destLng = double.tryParse(selectedBin!["lng"].toString()) ?? pos.longitude;
        _mapController.move(LatLng(destLat, destLng), 16);
      } else {
        _mapController.move(userLocation!, 14);
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Turn on GPS and grant permissions")),
      );
    }
  }

  Color markerColor(int fill) {
    if (fill < 40) return Colors.green;
    if (fill < 75) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Smart Bin Live Map")),
      body: loading || userLocation == null
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: userLocation!,
                initialZoom: 14,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.sewa.app',
                ),

                /// 📍 MARKERS
                MarkerLayer(markers: [
                  /// 🧍 USER LOCATION MARKER
                  Marker(
                    width: 40,
                    height: 40,
                    point: userLocation!,
                    child: const Icon(Icons.person_pin_circle,
                        size: 40, color: Colors.blue),
                  ),

                  /// 🗑 BINS MARKERS
                  ...bins.map<Marker>((b) {
                    final bool isSelected = selectedBin != null &&
                        b["name"] == selectedBin!["name"];

                    final Color color = isSelected
                        ? Colors.purple
                        : markerColor(b["fillLevel"] ?? 0);

                    // 🟢 FIXED: Safely parse lat/lng to avoid wrong positions or crashes
                    double bLat = double.tryParse(b["lat"].toString()) ?? 0.0;
                    double bLng = double.tryParse(b["lng"].toString()) ?? 0.0;

                    return Marker(
                      width: 40,
                      height: 40,
                      point: LatLng(bLat, bLng),
                      child: GestureDetector(
                        onTap: () => _showDetails(b, color, bLat, bLng),
                        child: Icon(Icons.location_on, color: color, size: 35),
                      ),
                    );
                  }),
                ]),
              ],
            ),
    );
  }

  /// 🔎 Bottom Detail Info
  void _showDetails(Map b, Color color, double lat, double lng) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Text(
              b["name"] ?? "Unknown Bin",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text("📍 ${b["distanceKm"] ?? 0} km away", style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("♻️ Fill Level: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Icon(Icons.circle, color: color, size: 18),
                const SizedBox(width: 8),
                Text("${b["fillLevel"] ?? 0}%", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ]
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
                  Navigator.pop(context); // Close bottom sheet before navigating
                  navigate(lat, lng); // Pass parsed coordinates securely
                },
                icon: const Icon(Icons.directions, color: Colors.white),
                label: const Text("Navigate to Bin", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            )
        ]),
      ),
    );
  }

  /// 🚗 Open Google Maps Navigation
  Future<void> navigate(double destLat, double destLng) async {
    // 🟢 FIXED: Proper Google Maps Universal URL format for directions
    final Uri url = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng");
    
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
}