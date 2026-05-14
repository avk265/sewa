import 'package:flutter/material.dart';
import 'package:sewa/services/api_service.dart';
import 'package:intl/intl.dart'; // Add to pubspec.yaml if not present

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> dumpHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  // 📡 Fetches the latest history array from the profile endpoint
  void _fetchHistory() async {
    final res = await ApiService.getProfile();
    if (mounted) {
      if (res["success"] == true) {
        setState(() {
          // Store history and reverse it to show newest first
          dumpHistory = List.from(res["user"]["history"].reversed);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Dump History"),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : dumpHistory.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: dumpHistory.length,
                  itemBuilder: (context, index) {
                    final item = dumpHistory[index];
                    return _buildHistoryCard(item);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 15),
          const Text("No deposits found yet!", 
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
          const Text("Go scan a bin to start recycling."),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    // Formatting the date from ISO string to readable format
    String formattedDate = "Unknown Date";
    if (item["date"] != null) {
      DateTime dt = DateTime.parse(item["date"]);
      formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.recycling, color: Colors.green),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item["binId"] ?? "Unknown Bin",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Weight: ${item["weight"]} kg",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "+${item["points"] ?? 0}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Text("pts", style: TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}