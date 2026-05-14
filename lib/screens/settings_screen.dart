import 'package:flutter/material.dart';
import 'package:sewa/services/api_service.dart';
import 'package:sewa/theme.dart';
import 'package:sewa/widgets/drawer_menu.dart';

class SettingsScreen extends StatefulWidget {
  final Function toggleTheme;
  final bool darkMode;

  const SettingsScreen({
    super.key,
    required this.toggleTheme,
    required this.darkMode,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  
  // 🔐 Secure Logout using ApiService
  Future<void> _handleLogout() async {
    // 1. Close the alert dialog first
    Navigator.pop(context); 

    // 2. Clear token securely
    await ApiService.logout();

    if (!mounted) return;

    // 3. Destroy navigation stack and go to login
    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerMenu(),
      appBar: AppBar(
        title: const Text("Settings"),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 🛠️ PREFERENCES SECTION
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
            child: Text(
              "Preferences",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              activeColor: primaryGreen,
              secondary: Icon(widget.darkMode ? Icons.dark_mode : Icons.light_mode, color: primaryGreen),
              title: const Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.w600)),
              value: widget.darkMode,
              onChanged: (val) => widget.toggleTheme(),
            ),
          ),
          
          const SizedBox(height: 24),

          // 👤 ACCOUNT SECTION
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              "Account",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.pushNamed(context, "/profile"),
                ),
                const Divider(height: 1, indent: 50),
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.orange),
                  title: const Text("My Dump History", style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.pushNamed(context, "/history"),
                ),
                const Divider(height: 1, indent: 50),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Logout"),
                          ],
                        ),
                        content: const Text("Are you sure you want to log out of your account?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                            ),
                            onPressed: _handleLogout, // Trigger the secure logout
                            child: const Text("Logout", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}