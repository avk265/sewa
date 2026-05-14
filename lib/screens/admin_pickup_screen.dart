import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminPickupScreen extends StatefulWidget {
  const AdminPickupScreen({super.key});

  @override
  State<AdminPickupScreen> createState() => _AdminPickupScreenState();
}

class _AdminPickupScreenState extends State<AdminPickupScreen> {
  late Future<List> _pickupRequests;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  // Refresh the future
  void _loadRequests() {
    setState(() {
      _pickupRequests = ApiService.getPickupRequests();
    });
  }

  Future<void> _handlePickup(String binId) async {
    // 1. Call API
    await ApiService.markBinPicked(binId);
    
    if (!mounted) return;
    
    // 2. Show Success Message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Bin $binId marked as empty!"),
        backgroundColor: Colors.green,
      ),
    );
    
    // 3. Reload the list to remove the picked bin
    _loadRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pickup Requests"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests, // Manual refresh button
          )
        ],
      ),
      body: FutureBuilder<List>(
        future: _pickupRequests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading data. Check server connection."));
          }

          final bins = snapshot.data ?? [];

          if (bins.isEmpty) {
            return const Center(
              child: Text(
                "🎉 All bins are clean! No pickups needed.",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bins.length,
            itemBuilder: (_, i) {
              final bin = bins[i];
              
              // Ensure we don't crash if map keys are missing
              final binId = bin['binId'] ?? bin['id'] ?? 'Unknown';
              final fillLevel = bin['fillLevel'] ?? 0;
              final name = bin['name'] ?? "Smart Bin";

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.delete_sweep, color: Colors.white),
                  ),
                  title: Text("$name ($binId)", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("🚨 Fill Level: $fillLevel%", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    onPressed: () => _handlePickup(binId),
                    child: const Text("Mark Picked", style: TextStyle(color: Colors.white)),
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