import 'package:flutter/material.dart';
import 'signup_screen.dart'; // Menghubungkan terus fail SignUp ke dalam skrin Login

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // GlobalKey untuk form validation
  final _formKey = GlobalKey<FormState>();
  
  // Controller untuk simpan data input user (Hanya Email & Password untuk Login)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // State variables
  bool _isObscure = true; // Untuk hide/show password
  bool _isLoading = false; // Untuk button loading state

  // Fungsi Log In
  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulasi proses pengesahan ke pangkalan data
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Successful! Welcome back.'),
            backgroundColor: Color(0xFF00E5FF),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Fungsi untuk memaparkan Dialog Forgot Password (Double Verification - Email & Phone)
  void _showForgotPasswordDialog() {
    final forgotFormKey = GlobalKey<FormState>();
    final TextEditingController forgotEmailController = TextEditingController();
    final TextEditingController forgotPhoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131A26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: Color(0xFF00E5FF)),
              SizedBox(width: 10),
              Text('Reset Password', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: forgotFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your registered email and phone number to verify your account identity.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  
                  // Input Email untuk Forgot Password
                  const Text('Email Address', style: TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: forgotEmailController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInputDecoration(hint: 'example@mail.com', icon: Icons.email_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required field';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Input Phone untuk Forgot Password
                  const Text('Phone Number', style: TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: forgotPhoneController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    decoration: _buildInputDecoration(hint: 'e.g. 0123456789', icon: Icons.phone_android_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required field';
                      if (value.length < 9) return 'Invalid phone number';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (forgotFormKey.currentState!.validate()) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verification link sent to your email and phone!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Verify', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- AUTOSIZE SETUP ---
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.065, 
            vertical: screenHeight * 0.02,   
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: screenHeight * 0.03),
                
                // --- LOGO SECTION ---
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    height: screenHeight * 0.22, 
                    width: screenWidth * 0.75,
                    fit: BoxFit.contain,
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.04),

                // --- WELCOME TEXT ---
                const Text(
                  'Welcome Back', 
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold), 
                  textAlign: TextAlign.center
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to continue your fitness journey', 
                  style: TextStyle(color: Colors.grey, fontSize: 15), 
                  textAlign: TextAlign.center
                ),
                
                SizedBox(height: screenHeight * 0.05),

                // --- EMAIL INPUT ---
                const Text('Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration(hint: 'Enter your email', icon: Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // --- PASSWORD INPUT ---
                const Text('Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isObscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration(hint: 'Enter your password', icon: Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your password';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                
                // --- FORGOT PASSWORD BUTTON ---
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF00E5FF))),
                  ),
                ),
                const SizedBox(height: 15),

                // --- SIGN IN BUTTON ---
                Container(
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF0088FF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24, width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Sign In', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward, color: Colors.black87),
                            ],
                          ),
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.05),

                // --- SIGN UP LINK ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, 
                        minimumSize: const Size(50, 30), 
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignUpScreen()),
                        );
                      },
                      child: const Text("Sign Up", style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                
                SizedBox(height: screenHeight * 0.06),

                // --- BOTTOM FEATURES ROW ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureIcon(Icons.track_changes, "Track\nWorkouts", screenWidth),
                    _buildFeatureIcon(Icons.bar_chart, "Analyze\nProgress", screenWidth),
                    _buildFeatureIcon(Icons.local_fire_department_outlined, "Burn\nCalories", screenWidth),
                    _buildFeatureIcon(Icons.favorite_border, "Stay\nHealthy", screenWidth),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER DECORATION WIDGET ---
  InputDecoration _buildInputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey, size: 22),
      filled: true,
      fillColor: const Color(0xFF131A26),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label, double screenWidth) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth * 0.03), 
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.withOpacity(0.2)), color: const Color(0xFF131A26)),
          child: Icon(icon, color: const Color(0xFF00E5FF), size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}