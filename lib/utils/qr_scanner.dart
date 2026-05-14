import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // 🟢 Added for debugPrint

class ApiService {
  // ⚠️ CHANGE THIS WHEN USING DEVICE (Android)
  static const String baseUrl = "https://sewa-o947.onrender.com"; // For Web/Chrome
  // For Android Emulator → http://10.0.2.2:3000

  // ================= TOKEN STORAGE =================
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }

  // ================= DECODER =================
  static Future<Map<String, dynamic>> _decodeResponse(http.Response res) async {
    try {
      if (res.body.trim().startsWith("<")) {
        return {"success": false, "message": "Server returned HTML. Check route URL."};
      }
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) return data;
      return {"success": false, "message": "Unexpected response format"};
    } catch (e) {
      return {"success": false, "message": "Invalid JSON from server"};
    }
  }

  // ================= API METHODS =================

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      final data = await _decodeResponse(res);

      if (data["success"] == true && data["token"] != null) {
        await saveToken(data["token"]);
      }

      return data;
    } catch (e) {
      return {"success": false, "message": "Server error"};
    }
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String mobile,
    String address,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "mobile": mobile,
          "address": address,
        }),
      );

      return await _decodeResponse(res); 
    } catch (e) {
      return {"success": false, "message": "Server error"};
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      return {"success": false, "message": "Not logged in"};
    }

    final res = await http.get(
      Uri.parse("$baseUrl/profile"),
      headers: {
        "Authorization": "Bearer $token", 
        "Content-Type": "application/json"
      },
    );

    if (res.statusCode == 401) {
      return {"success": false, "message": "Unauthorized"};
    }

    return await _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> updateProfile(Map data) async {
    try {
      final token = await _getToken();
      if (token == null) return {"success": false, "message": "Not logged in"};

      final res = await http.patch(
        Uri.parse("$baseUrl/update-profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(data),
      );
      return await _decodeResponse(res);
    } catch (e) {
      return {"success": false, "message": "Error updating profile"};
    }
  }

  static Future<List<dynamic>> getNearestBins(double lat, double lng) async {
    final token = await _getToken();
    if (token == null) return [];

    final res = await http.get(
      Uri.parse("$baseUrl/nearest-bins?lat=$lat&lng=$lng"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = await _decodeResponse(res);
    if (data["success"] == true && data["nearestBins"] is List) {
      return data["nearestBins"];
    }
    return [];
  }

  // ================= ADMIN / STATS =================

  static Future<List> getUserContributions(String userId) async {
    final res = await http.get(Uri.parse("$baseUrl/contributions/$userId"));
    return jsonDecode(res.body);
  }

  static Future<List> getPickupRequests() async {
    final res = await http.get(Uri.parse("$baseUrl/admin/pickups"));
    return jsonDecode(res.body);
  }

  static Future<void> markBinPicked(String binId) async {
    await http.post(
      Uri.parse("$baseUrl/admin/pickup-done"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"binId": binId}),
    );
  }

  // ================= NEW IOT SIMULATOR METHOD =================
  
  // 🟢 Fixed: Merged unlockBin and scanToOpen into one clean method using _getToken()
  static Future<bool> unlockBin(String binId) async {
    try {
      final token = await _getToken(); 
      if (token == null) {
        debugPrint("Unlock Error: No token found. User not logged in.");
        return false;
      }

      final response = await http.post(
        Uri.parse("$baseUrl/bin/scan-to-open"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({"binId": binId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["success"] == true;
      }
      return false;
    } catch (e) {
      debugPrint("Unlock Error: $e");
      return false;
    }
  }

// 🟢 Phase 3: Redeem the Healthcare Game
  static Future<Map<String, dynamic>> redeemGame() async {
    try {
      final token = await _getToken();
      final res = await http.post(
        Uri.parse("$baseUrl/redeem-game"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      );
      return await _decodeResponse(res);
    } catch (e) {
      return {"success": false, "message": "Connection error"};
    }
  }

  // 🟢 Phase 4: Save Game Progress to Cloud
  static Future<void> updateGameLevel(int newLevel) async {
    try {
      final token = await _getToken();
      await http.post(
        Uri.parse("$baseUrl/update-game-progress"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"newLevel": newLevel}),
      );
    } catch (e) {
      debugPrint("Failed to save progress");
    }
  }
}
