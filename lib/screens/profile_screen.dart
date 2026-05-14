import 'package:flutter/material.dart';
import 'package:sewa/services/api_service.dart';
import 'package:sewa/theme.dart';
import 'package:sewa/widgets/drawer_menu.dart';

class ProfileScreen extends StatefulWidget {
  final Function toggleTheme;
  const ProfileScreen({super.key, required this.toggleTheme});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;

  // 📌 Controllers
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController mobileCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // 🔐 Load User Data
  Future<void> loadUser() async {
    final res = await ApiService.getProfile();
    
    if (!mounted) return; // ✅ Prevents crash if user leaves screen during load

    if (res["success"] == true && res["user"] != null) {
      setState(() {
        userData = res["user"];
        nameCtrl.text = userData!["name"] ?? "";
        emailCtrl.text = userData!["email"] ?? "";
        mobileCtrl.text = userData!["mobile"] ?? "";
        addressCtrl.text = userData!["address"] ?? "";
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      _showMsg(res["message"] ?? "Failed to load profile");
    }
  }

  // 💾 Update Profile
  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final res = await ApiService.updateProfile({
      "name": nameCtrl.text.trim(),
      "mobile": mobileCtrl.text.trim(),
      "address": addressCtrl.text.trim(),
    });
    
    if (!mounted) return; // ✅ Prevents crash if user leaves screen while saving
    setState(() => _saving = false);

    if (res["success"] == true) {
      _showMsg("✅ Profile updated successfully!");
      loadUser();
    } else {
      _showMsg("❌ ${res["message"] ?? "Update failed"}");
    }
  }

  // 🧾 Snackbar Message
  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerMenu(),
      appBar: AppBar(
        title: const Text("My Profile"),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => widget.toggleTheme(),
            icon: const Icon(Icons.dark_mode),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : Padding(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // 🧑 Avatar + Name + Email + STATS
                    Center(
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundColor: primaryGreen,
                            child: Icon(Icons.person, size: 60, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            nameCtrl.text,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            emailCtrl.text,
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          
                          // ✨ NEW: Eco Stats Display
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _statBadge(Icons.eco, "${userData?['greenPoints'] ?? 0} pts", Colors.green),
                              const SizedBox(width: 12),
                              _statBadge(Icons.recycling, "${userData?['recycledItemsCount'] ?? 0} items", Colors.blue),
                            ],
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    _field("Full Name", Icons.person, nameCtrl,
                        validator: (v) =>
                            v!.isEmpty ? "Name required" : null),

                    _field("Email", Icons.email_rounded, emailCtrl,
                        readOnly: true, // Email shouldn't be easily editable usually
                        validator: (v) => v!.contains("@")
                            ? null
                            : "Valid email required"),

                    _field("Mobile", Icons.phone, mobileCtrl,
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v!.length < 10 ? "Valid phone required" : null),

                    _field("Address", Icons.home, addressCtrl,
                        maxLines: 2,
                        validator: (v) =>
                            v!.isEmpty ? "Address required" : null),

                    const SizedBox(height: 25),

                    _saving
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: primaryGreen))
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                            onPressed: updateProfile,
                            icon: const Icon(Icons.save),
                            label: const Text("Save Changes", style: TextStyle(fontSize: 16)),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  // 🏷️ Mini Stat Badge Widget
  Widget _statBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5))
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // 🧾 Reusable Form Field Builder (Enhanced with Outline Borders)
  Widget _field(
    String label,
    IconData icon,
    TextEditingController ctrl, {
    int maxLines = 1,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        readOnly: readOnly,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: readOnly ? Colors.grey : primaryGreen),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: readOnly, // Gray out field if read-only
          fillColor: readOnly ? Colors.grey.withOpacity(0.1) : null,
        ),
      ),
    );
  }
}