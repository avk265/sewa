import 'package:flutter/material.dart';
import 'package:sewa/services/api_service.dart';
import 'package:intl/intl.dart'; 

class RedemptionHistoryScreen extends StatefulWidget {
  const RedemptionHistoryScreen({super.key});

  @override
  State<RedemptionHistoryScreen> createState() => _RedemptionHistoryScreenState();
}

class _RedemptionHistoryScreenState extends State<RedemptionHistoryScreen> {
  List<dynamic> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    // 🟢 The redemption history is already embedded inside the User profile from our Server update!
    final res = await ApiService.getProfile();
    
    if (mounted && res["success"] == true) {
      setState(() {
        // Reverse the list so the newest redemptions show up at the top
        history = List.from(res["user"]["redemptionHistory"] ?? []).reversed.toList();
        isLoading = false;
      });
    } else {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load history"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Redemption History"),
        backgroundColor: Colors.blueGrey, 
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueGrey))
          : history.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    
                    // Parse and format the date safely
                    DateTime date = DateTime.now();
                    try {
                      date = DateTime.parse(item["date"]).toLocal();
                    } catch (e) {
                      debugPrint("Date parse error");
                    }
                    final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(date);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        ),
                        title: Text(
                          item["action"] ?? "Unknown Action", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(formattedDate, style: const TextStyle(color: Colors.grey)),
                        ),
                        trailing: Text(
                          "-${item['pointsDeducted']} pts",
                          style: const TextStyle(
                            color: Colors.redAccent, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 18
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text(
            "No redemptions yet",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text(
            "Deposit e-waste to earn points\nand unlock healthcare rewards!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}