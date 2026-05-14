import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ContributionHistoryScreen extends StatelessWidget {
  const ContributionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Contributions"),
        elevation: 0,
      ),
      body: FutureBuilder(
        // Use getProfile() since the backend includes the 'history' array securely via the token
        future: ApiService.getProfile(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          
          if (snapshot.hasError || snapshot.data == null || snapshot.data["success"] != true) {
            return const Center(child: Text("Failed to load history."));
          }

          // Extract the history array from the user profile data
          final List history = snapshot.data["user"]["history"] ?? [];

          if (history.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.recycling, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No contributions yet!",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text("Scan a bin to start recycling."),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: history.length,
            itemBuilder: (_, i) {
              final item = history[i];
              
              // Safely parse data matching our Node.js schema
              final double weight = (item['weight'] ?? 0).toDouble();
              final String binId = item['binId'] ?? "Unknown Bin";
              final int points = (weight * 10).toInt(); // 10 pts per kg
              
              // Format the date nicely
              String formattedDate = "Unknown Date";
              if (item['date'] != null) {
                DateTime parsedDate = DateTime.parse(item['date']);
                formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(parsedDate);
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    radius: 25,
                    child: Icon(Icons.eco, color: Colors.white),
                  ),
                  title: Text(
                    "$weight kg Recycled",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📍 Bin: $binId"),
                        Text("🕒 $formattedDate", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "+$points",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: Colors.green, 
                          fontSize: 18
                        ),
                      ),
                      const Text("pts", style: TextStyle(fontSize: 12, color: Colors.green)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}