import 'package:flutter/material.dart';
import 'package:sewa/screens/scanner_screen.dart';
import 'package:sewa/services/api_service.dart';
import 'package:sewa/widgets/drawer_menu.dart';
import 'package:geolocator/geolocator.dart'; // 🟢 Added to sync location with Map

class DashboardScreen extends StatefulWidget {
  final Function toggleTheme;
  const DashboardScreen({super.key, required this.toggleTheme});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? userData;
  List<dynamic> nearestBins = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  // 🔄 Fetches Profile and EXACT GPS Location for Bins
  void loadAllData() async {
    setState(() => _isLoading = true);

    // 1. Fetch User Profile
    final profileRes = await ApiService.getProfile();
    
    // 2. Default coordinates (Fallback)
    double lat = 8.9150;
    double lng = 76.6130;

    // 3. 🟢 Get REAL GPS location so Dashboard matches the Map exactly
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          lat = pos.latitude;
          lng = pos.longitude;
        }
      }
    } catch (e) {
      debugPrint("Using fallback location due to GPS limits.");
    }

    // 4. Fetch Nearest Bins using the accurate coordinates
    final binList = await ApiService.getNearestBins(lat, lng);

    if (mounted) {
      setState(() {
        userData = profileRes["success"] == true ? profileRes["user"] : null;
        nearestBins = binList; 
        _isLoading = false;
      });
    }
  }

  // 👉 FIXED: Unambiguous closest bin preview
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerMenu(),
      appBar: AppBar(
        title: const Text("Smart E-Waste"),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode),
            onPressed: () => widget.toggleTheme(),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              onRefresh: () async => loadAllData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _headerCard(),
                    const SizedBox(height: 20),
                    
                    const SizedBox(height: 25),
                    
                    // SECTION 2: Action Buttons
                    const Text("Smart Actions",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _smartButtons(context),
                    
                    const SizedBox(height: 30),
                    
                    // SECTION 3: Points and Stats
                    const Text("Eco Stats",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _ecoStats(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.green,
            child: Icon(Icons.person, size: 35, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hi, ${userData?["name"] ?? "User"} 👋",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Text(
                userData?["mobile"] ?? "Welcome back",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smartButtons(BuildContext context) {
    return Column(
      children: [
        _actionButton(
          title: "Smart Bin Live Map",
          icon: Icons.map_rounded,
          color: Colors.green,
          onTap: () => Navigator.pushNamed(context, "/mapBins"),
        ),
        const SizedBox(height: 10),
        _actionButton(
          title: "Nearest Bins List",
          icon: Icons.location_on,
          color: Colors.blue,
          onTap: () => Navigator.pushNamed(context, "/nearestBins"),
        ),
        const SizedBox(height: 10),
        _actionButton(
  title: "Smart Scanner",
  icon: Icons.qr_code_scanner,
  color: Colors.teal,
  onTap: () async {
    // Navigate to your existing QR Scanner Widget
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ItemScannerScreen()),
    );
    loadAllData(); // Refresh the dashboard stats when they return
  },
),
        const SizedBox(height: 10),
        _actionButton(
          title: "My Dump History",
          icon: Icons.history,
          color: Colors.orange,
          onTap: () => Navigator.pushNamed(context, "/history"),
        ),
      ],
    );
  }

  Widget _actionButton({required String title, required IconData icon, required Color color, required Function onTap}) {
    return InkWell(
      onTap: () => onTap(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: color),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 20, color: color.withOpacity(0.8)),
          ],
        ),
      ),
    );
  }

  Widget _ecoStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statCard("Green Points", userData?["greenPoints"].toString() ?? "0", Icons.eco),
        _statCard("Donated Items", userData?["recycledItemsCount"].toString() ?? "0", Icons.recycling),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, size: 30, color: Colors.green),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(title, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}