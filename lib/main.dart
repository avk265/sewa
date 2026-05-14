// lib/main.dart
import 'package:flutter/material.dart';
import 'package:sewa/theme.dart';

// Import core screens
import 'package:sewa/screens/splash_screen.dart';
import 'package:sewa/screens/login_screen.dart';
import 'package:sewa/screens/register_screen.dart';
import 'package:sewa/screens/dashboard_screen.dart';
import 'package:sewa/screens/profile_screen.dart';
import 'package:sewa/screens/contribution_history_screen.dart';
import 'package:sewa/screens/map_bins_screen.dart';
import 'package:sewa/screens/nearest_bins_screen.dart';
import 'package:sewa/screens/settings_screen.dart';
import 'package:sewa/screens/admin_dashboard_screen.dart';

// 🟢 FIXED AMBIGUITY: Only one scanner is needed!
import 'package:sewa/screens/scanner_screen.dart'; // The Unified Bin Unlocker
import 'package:sewa/screens/qr_generator_screen.dart'; // My Eco ID / Simulator

// 🟢 NEW HEALTHCARE IMPORTS
import 'package:sewa/screens/rehab_game_screen.dart';
import 'package:sewa/screens/redemption_history_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Theme State Management
  bool isDark = false;

  void toggleTheme() {
    setState(() => isDark = !isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "SEWA Smart E-Waste",
      theme: isDark ? darkTheme : lightTheme,

      // App starts here and decides where to route the user securely
      home: SplashScreen(toggleTheme: toggleTheme),

      // 🗺️ All Application Routes
      routes: {
        "/login": (c) => LoginScreen(toggleTheme: toggleTheme),
        "/register": (c) => RegisterScreen(toggleTheme: toggleTheme),
        "/dashboard": (c) => DashboardScreen(toggleTheme: toggleTheme),
        "/profile": (c) => ProfileScreen(toggleTheme: toggleTheme),
        "/history": (c) => const ContributionHistoryScreen(),
        "/mapBins": (c) => const MapBinsScreen(),
        "/nearestBins": (c) => const NearestBinsScreen(),
        "/settings": (c) => SettingsScreen(toggleTheme: toggleTheme, darkMode: isDark),

        // 🟢 UNAMBIGUOUS SCANNER ROUTE
        // We removed the duplicate /qrScanner and ML placeholder.
        // /scanner now strictly opens the live Bin Unlocker.
        "/scanner": (c) => const ItemScannerScreen(), 
        "/qrGenerator": (c) => const QRGenerateScreen(),

        // 🟢 NEW HEALTHCARE ROUTES
        "/redemptionHistory": (c) => const RedemptionHistoryScreen(),
        "/rehabGame": (context) {
          // Extracts the saved level passed from the Drawer menu
          final args = ModalRoute.of(context)?.settings.arguments as int?;
          return RehabGameScreen(startingLevel: args ?? 1); // Defaults to level 1
        },

        // Admin
        "/adminDashboard": (c) => const AdminDashboardScreen(), 
      },
    );
  }
}
