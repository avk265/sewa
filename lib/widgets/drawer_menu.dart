import 'package:flutter/material.dart';
import 'package:sewa/services/api_service.dart';
import 'package:sewa/theme.dart';

class DrawerMenu extends StatefulWidget {
  const DrawerMenu({super.key});

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  Map<String, dynamic>? userData;
  bool isProcessing = false; 

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final res = await ApiService.getProfile();
    if (mounted && res["success"] == true) {
      setState(() {
        userData = res["user"];
      });
    }
  }

  Future<void> _handleRedemption() async {
    setState(() => isProcessing = true);
    final res = await ApiService.redeemGame(); 
    setState(() => isProcessing = false);

    if (res["success"] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎉 Rehab Game Unlocked for 60 Days!"), backgroundColor: Colors.green)
      );
      _loadUserData(); // Refresh the points instantly!
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ ${res['message']}"), backgroundColor: Colors.red)
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Parse the Dual-Point and Healthcare Data
    final int currentBalance = userData?["greenPoints"] ?? 0;
    final int lifetimePoints = userData?["greenPoints"] ?? 0;
    final int savedLevel = userData?["rehabGameLevel"] ?? 1;
    
    final String? expiryStr = userData?["rehabGameExpiry"];
    final DateTime? expiryDate = expiryStr != null ? DateTime.parse(expiryStr) : null;
    final bool isGameActive = expiryDate != null && expiryDate.isAfter(DateTime.now());
    
    final bool canAfford = currentBalance >= 100;

    return Drawer(
      child: Column(
        children: [
          // 🌿 CUSTOM GREEN HEADER (Avatar + ListTile style points)
          DrawerHeader(
            decoration: const BoxDecoration(color: primaryGreen),
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // The dynamic initial avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Text(
                    userData?["name"]?.substring(0, 1).toUpperCase() ?? "♻️",
                    style: const TextStyle(fontSize: 26, color: primaryGreen, fontWeight: FontWeight.bold),
                  ),
                ),
                
                // The Points styled like a ListTile on the green background
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15), // Dark overlay for contrast
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.amberAccent, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Balance: $currentBalance pts",
                            style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Lifetime: $lifetimePoints pts",
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 🧭 Navigation Links
          ListTile(
            leading: const Icon(Icons.home_rounded, size: 28),
            title: const Text("Dashboard", style: TextStyle(fontSize: 16)),
            onTap: () => Navigator.pushReplacementNamed(context, "/dashboard"),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, size: 28),
            title: const Text("My Profile", style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context); 
              Navigator.pushNamed(context, "/profile");
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded, size: 28),
            title: const Text("Dump History", style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context); 
              Navigator.pushNamed(context, "/history");
            },
          ),
          
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft, 
              child: Text("HEALTHCARE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))
            ),
          ),

          // 🟢 Dynamic Rehab Game Button
          ListTile(
            leading: Icon(
              isGameActive ? Icons.sports_esports : Icons.lock,
              size: 28,
              color: isGameActive ? Colors.green : (canAfford ? Colors.orange : Colors.grey),
            ),
            title: Text(
              isGameActive ? "Play Rehab Game (Lvl $savedLevel)" : "Unlock Rehab Glove",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isGameActive ? Colors.green : (canAfford ? Colors.black87 : Colors.grey),
              ),
            ),
            subtitle: Text(
              isGameActive 
                  ? "Expires: ${expiryDate.toLocal().toString().split(' ')[0]}" 
                  : "Costs 100 Points",
              style: TextStyle(color: canAfford || isGameActive ? Colors.black54 : Colors.grey, fontSize: 13),
            ),
            trailing: isProcessing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                : null,
            onTap: () {
              if (isGameActive) {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/rehabGame", arguments: savedLevel); 
              } else if (canAfford) {
                _handleRedemption();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Deposit E-Waste to earn 100 points!"), backgroundColor: Colors.orange),
                );
              }
            },
          ),

          // 🟢 Redemption History
          ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.blueGrey, size: 28),
            title: const Text("Redemption History", style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, "/redemptionHistory");
            },
          ),

          const Spacer(),
          const Divider(),

          // 🚪 Logout with Confirmation
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent, size: 28),
            title: const Text(
              "Logout", 
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text("Logout"),
                  content: const Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                      onPressed: () {
                        Navigator.pop(ctx); 
                        _handleLogout(context); 
                      },
                      child: const Text("Logout", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
