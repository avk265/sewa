import 'package:flutter/material.dart';
import 'package:sewa/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  final Function toggleTheme; 

  const SplashScreen({super.key, required this.toggleTheme});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  // 🔐 Check Authentication Status
  Future<void> _checkAuthAndNavigate() async {
    // 1. Minimum 2-second delay for branding visibility
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 2. Check if a token is saved on the device
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    // No token -> Go to Login
    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, "/login");
      return;
    }

    // 3. Token exists! Let's verify it with the server and check their role
    final res = await ApiService.getProfile();
    
    if (!mounted) return;

    if (res["success"] == true && res["user"] != null) {
      // ✅ Token is valid. Route based on role!
      if (res["user"]["role"] == "admin") {
        Navigator.pushReplacementNamed(context, "/adminDashboard");
      } else {
        Navigator.pushReplacementNamed(context, "/dashboard");
      }
    } else {
      // ❌ Token is expired or invalid. Clear it and go to login.
      await ApiService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/login");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.recycling, size: 120, color: Colors.white),
            SizedBox(height: 16),
            Text(
              "SEWA",
              style: TextStyle(
                fontSize: 42, 
                fontWeight: FontWeight.bold, 
                color: Colors.white,
                letterSpacing: 2.0
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Smart E-Waste Management",
              style: TextStyle(
                fontSize: 16, 
                color: Colors.white70,
                fontWeight: FontWeight.w500
              ),
            ),
            SizedBox(height: 50),
            
            // Loading indicator while verifying token
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}