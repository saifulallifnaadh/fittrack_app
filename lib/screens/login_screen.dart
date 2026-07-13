import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- TUKAR KE FIREBASE AUTH
import 'dashboard_screen.dart'; 
import 'signup_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isObscure = true; 
  bool _isLoading = false; 

  // --- FUNGSI LOG MASUK (FIREBASE AUTH) ---
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String enteredEmail = _emailController.text.trim();
        String enteredPassword = _passwordController.text.trim();

        // Firebase menguruskan pemeriksaan e-mel dan kata laluan
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: enteredEmail,
          password: enteredPassword,
        );

        if (mounted) {
          if (userCredential.user != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login successful! Welcome back.'), backgroundColor: Colors.green),
            );
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardScreen(userId: userCredential.user!.uid), // Firebase guna .uid
              ),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        // Tangkap ralat spesifik dari Firebase (contoh: Salah password, email tak wujud)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Authentication failed.'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // --- FUNGSI FORGOT PASSWORD (FIREBASE RESET LINK) ---
  void _showForgotPasswordDialog() {
    final forgotFormKey = GlobalKey<FormState>();
    final TextEditingController forgotEmailController = TextEditingController();
    bool isDialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131A26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.lock_reset, color: Color(0xFF00E5FF)),
                  SizedBox(width: 10),
                  Text('Reset Password', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Form(
                key: forgotFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter your registered email. We will send a secure password reset link to your inbox.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    
                    const Text('Email Address', style: TextStyle(color: Colors.white, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: forgotEmailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration(hint: 'example@mail.com', icon: Icons.email_outlined),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDialogLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isDialogLoading ? null : () async {
                    if (forgotFormKey.currentState!.validate()) {
                      setStateDialog(() => isDialogLoading = true);
                      
                      try {
                        // Tembak fungsi hantar e-mel reset password Firebase
                        await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: forgotEmailController.text.trim(),
                        );

                        if (mounted) {
                          Navigator.pop(context); 
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password reset link sent! Please check your email.'), backgroundColor: Colors.green),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        setStateDialog(() => isDialogLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message ?? 'Failed to send reset link.'), backgroundColor: Colors.red),
                        );
                      } catch (e) {
                        setStateDialog(() => isDialogLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: isDialogLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text('Send Link', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
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
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF090E17), 
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.065),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: screenHeight * 0.02),
                  
                  // --- LOGO SECTION ---
                  Center(
                    child: Image.asset(
                      'assets/logo.png',
                      height: screenHeight * 0.30, 
                      width: screenWidth * 0.85,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),

                  const Text('Welcome Back', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('Log in to continue your fitness journey.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 40),

                  // --- EMAIL INPUT ---
                  const Text('Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration(hint: 'Enter your email', icon: Icons.email_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Invalid email format';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- PASSWORD ---
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
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),

                  // --- FORGOT PASSWORD ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog, 
                      child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF00E5FF))),
                    ),
                  ),
                  const SizedBox(height: 30),

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
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Sign In', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- NAVIGATE TO SIGN UP ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?", style: TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignUpScreen()),
                          );
                        },
                        child: const Text('Sign Up', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
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

  InputDecoration _buildInputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey, size: 22),
      filled: true,
      fillColor: const Color(0xFF131A26),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5)),
    );
  }
}