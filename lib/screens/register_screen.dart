import 'package:flutter/material.dart';
import 'package:sewa/services/api_service.dart';
import 'package:sewa/theme.dart';

class RegisterScreen extends StatefulWidget {
  final Function toggleTheme;
  const RegisterScreen({super.key, required this.toggleTheme});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController mobileCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  bool _loading = false;
  bool _showPass = false;

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final res = await ApiService.register(
        nameCtrl.text.trim(),
        emailCtrl.text.trim(),
        passCtrl.text.trim(),
        mobileCtrl.text.trim(),
        addressCtrl.text.trim(),
      );

      if (!mounted) return;

      if (res["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Registration Successful! Please login."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, "/login");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ ${res["message"] ?? "Registration failed"}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Server error: Check connection."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode), 
            onPressed: () => widget.toggleTheme()
          )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_alt_1_rounded, size: 80, color: primaryGreen),
                  const SizedBox(height: 16),
                  Text(
                    "Join SEWA",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Start your e-waste recycling journey",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  _buildTextField(
                    label: "Full Name",
                    icon: Icons.person,
                    controller: nameCtrl,
                    validator: (v) => v!.isEmpty ? "Enter your name" : null,
                  ),

                  _buildTextField(
                    label: "Email",
                    icon: Icons.email,
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => !v!.contains("@") ? "Enter valid email" : null,
                  ),

                  _buildTextField(
                    label: "Mobile Number",
                    icon: Icons.phone,
                    controller: mobileCtrl,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.length < 10 ? "Enter valid phone number" : null,
                  ),

                  _buildTextField(
                    label: "Address",
                    icon: Icons.home,
                    controller: addressCtrl,
                    maxLines: 2,
                    validator: (v) => v!.isEmpty ? "Enter your address" : null,
                  ),

                  // Password Field (Custom handling for visibility toggle)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: passCtrl,
                      obscureText: !_showPass,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock, color: primaryGreen),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _showPass = !_showPass),
                        ),
                      ),
                      validator: (v) => v!.length < 6 ? "Password must be at least 6 chars" : null,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _loading
                      ? const CircularProgressIndicator(color: primaryGreen)
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                            onPressed: registerUser,
                            child: const Text(
                              "Register", 
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)
                            ),
                          ),
                        ),
                  
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, "/login"),
                        child: const Text("Login here", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🧾 Helper Widget to clean up the form code
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12)
          ),
        ),
        validator: validator,
      ),
    );
  }
}