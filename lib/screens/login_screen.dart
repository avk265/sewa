import 'package:flutter/material.dart';
import 'package:sewa/theme.dart';
import 'package:sewa/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final Function toggleTheme;
  const LoginScreen({super.key, required this.toggleTheme});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  bool loading = false;
  bool showPass = false;
  
  // 🟢 State to track which login form is active
  bool isAdminLogin = false; 

  Future<void> loginUser() async {
    if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
      _msg("Please enter email & password");
      return;
    }
    setState(() => loading = true);

    final res = await ApiService.login(emailCtrl.text.trim(), passCtrl.text.trim());

    setState(() => loading = false);

    if (res["success"] == true) {
      String role = res["user"]["role"];

      // 🛑 Strict Role Validation
      if (isAdminLogin && role != "admin") {
        _msg("Access Denied: You are not an administrator.");
        return;
      }
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("token", res["token"]);
      
      // 🔐 Route based on role
      if (role == "admin") {
        Navigator.pushReplacementNamed(context, "/adminDashboard");
      } else {
        Navigator.pushReplacementNamed(context, "/dashboard");
      }
    } else {
      _msg(res["message"] ?? "Login failed");
    }
  }

  void _msg(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Dynamic styling based on selected portal
    final Color activeColor = isAdminLogin ? Colors.blueGrey : primaryGreen;
    final String welcomeText = isAdminLogin ? "Authority Portal" : "Welcome to SEWA";
    final IconData topIcon = isAdminLogin ? Icons.admin_panel_settings : Icons.recycling;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // 🔄 Login Type Toggle
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToggleButton("Citizen", !isAdminLogin, Colors.green),
                      _buildToggleButton("Admin", isAdminLogin, Colors.blueGrey),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 🌿 Dynamic App Logo
                Icon(topIcon, size: 100, color: activeColor),
                const SizedBox(height: 10),

                Text(
                  welcomeText,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : activeColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAdminLogin ? "Secure E-Waste Administration" : "Smart E-Waste Management",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 30),

                // 📧 Email
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: isAdminLogin ? "Admin ID (Email)" : "Email",
                    prefixIcon: Icon(Icons.email_rounded, color: activeColor),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: activeColor)),
                  ),
                ),
                const SizedBox(height: 15),

                // 🔐 Password
                TextField(
                  controller: passCtrl,
                  obscureText: !showPass,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock, color: activeColor),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: activeColor)),
                    suffixIcon: IconButton(
                      icon: Icon(showPass ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => showPass = !showPass),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // 🔵 Login Button
                loading
                    ? CircularProgressIndicator(color: activeColor)
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activeColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                          onPressed: loginUser,
                          child: Text(
                            "Secure Login",
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ),
                const SizedBox(height: 15),

                // 🌙 Dark / Light Mode Toggle
                IconButton(
                  onPressed: () => widget.toggleTheme(),
                  icon: Icon(Icons.dark_mode, color: isDark ? Colors.white : Colors.black54),
                ),
                const SizedBox(height: 8),

                // 📝 Register Link (HIDDEN FOR ADMINS)
                if (!isAdminLogin)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("New User?"),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, "/register"),
                        child: Text("Create Account", style: TextStyle(color: primaryGreen)),
                      )
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🎛️ Custom Toggle Button Widget
  Widget _buildToggleButton(String text, bool isSelected, Color activeColor) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isAdminLogin = text == "Admin";
          // Clear fields when switching tabs for security/convenience
          emailCtrl.clear();
          passCtrl.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}