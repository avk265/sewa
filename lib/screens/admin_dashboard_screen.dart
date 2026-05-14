import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late IO.Socket socket;
  List<Map<String, dynamic>> alerts = []; // Changed to Map to handle complex data

  @override
  void initState() {
    super.initState();
    initSocket();
  }

  void initSocket() {
    // 💡 Automatically pulls the IP from your ApiService
    String socketUrl = ApiService.baseUrl; 

    socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) => print('📡 Admin Dashboard: Live Socket Connected'));

    // 🚨 Listen for real-time Simulator Alerts (Full Bins, Access, etc.)
    socket.on('admin-notification', (data) {
      if (mounted) {
        setState(() {
          // Store alert with a timestamp
          alerts.insert(0, {
            'type': data['type'],
            'message': data['message'],
            'time': DateTime.now(),
          });
        });
        _showAlertBanner(data['message']);
      }
    });

    socket.onDisconnect((_) => print('❌ Admin Socket Disconnected'));
  }

  void _showAlertBanner(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Command Center"),
        backgroundColor: Colors.red.shade800,
        actions: [
          IconButton(
            tooltip: "Clear Alerts",
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => setState(() => alerts.clear()),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, "/login"),
          )
        ],
      ),
      body: Column(
        children: [
          // 📊 Status Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border(bottom: BorderSide(color: Colors.red.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Live IoT Feed",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                Chip(
                  label: Text("${alerts.length} New Alerts"),
                  backgroundColor: Colors.red.shade200,
                )
              ],
            ),
          ),

          // 📜 Alerts List
          Expanded(
            child: alerts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      final isCritical = alert['type'] == 'BIN_FULL';

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCritical ? Colors.red : Colors.orange,
                            child: Icon(
                              isCritical ? Icons.report_problem : Icons.sensors,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            alert['message'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Type: ${alert['type']} • ${alert['time'].toString().substring(11, 16)}",
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade200),
          const SizedBox(height: 16),
          const Text(
            "All systems normal.",
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const Text("Waiting for IoT simulator signals...", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
