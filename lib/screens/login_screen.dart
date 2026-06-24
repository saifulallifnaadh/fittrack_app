import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // FUNGSI LOG MASUK MENGGUNAKAN EMAIL
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String enteredEmail = _emailController.text.trim();
        String enteredPassword = _passwordController.text.trim();

        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('USER')
            .where('email', isEqualTo: enteredEmail)
            .limit(1)
            .get();

        if (mounted) {
          if (querySnapshot.docs.isNotEmpty) {
            DocumentSnapshot userDoc = querySnapshot.docs.first;
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            
            if (userData['password'] == enteredPassword) {
              String userId = userDoc.id;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Login successful!'), backgroundColor: Colors.green),
              );
              
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DashboardScreen(userId: userId),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Incorrect password. Please try again.'), backgroundColor: Colors.red),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email not found. Please Sign Up first.'), backgroundColor: Colors.orange),
            );
          }
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

  // --- FUNGSI FORGOT PASSWORD BARU (VERIFY EMAIL + PHONE) ---
  void _showForgotPasswordDialog() {
    final forgotFormKey = GlobalKey<FormState>();
    final TextEditingController forgotEmailController = TextEditingController();
    final TextEditingController forgotPhoneController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    bool isVerified = false; // Status untuk check dah verify atau belum
    bool isDialogLoading = false;
    String verifiedUserId = '';
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false, // User kena tekan cancel, tak boleh klik luar
      builder: (context) {
        // StatefulBuilder digunakan supaya popup dialog ni boleh berubah interface dia
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131A26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(isVerified ? Icons.lock_reset : Icons.security, color: const Color(0xFF00E5FF)),
                  const SizedBox(width: 10),
                  Text(isVerified ? 'Create New Password' : 'Verify Account', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: forgotFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isVerified 
                          ? 'Authentication successful. Please enter your new password below.'
                          : 'Enter your registered email and phone number to verify your identity.',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      
                      // JIKA BELUM VERIFY: Tunjuk input Email & Nombor Telefon
                      if (!isVerified) ...[
                        const Text('Email Address', style: TextStyle(color: Colors.white, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: forgotEmailController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.emailAddress,
                          decoration: _buildInputDecoration(hint: 'example@mail.com', icon: Icons.email_outlined),
                          validator: (value) => value!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        const Text('Phone Number', style: TextStyle(color: Colors.white, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: forgotPhoneController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.phone,
                          decoration: _buildInputDecoration(hint: 'e.g. 0123456789', icon: Icons.phone_android_outlined),
                          validator: (value) => value!.isEmpty ? 'Required' : null,
                        ),
                      ] 
                      // JIKA DAH VERIFY: Tunjuk input Password Baru
                      else ...[
                        const Text('New Password', style: TextStyle(color: Colors.white, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: obscureNew,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration(hint: 'New Password', icon: Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
                              onPressed: () => setStateDialog(() => obscureNew = !obscureNew),
                            ),
                          ),
                          validator: (value) => value!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        const Text('Confirm Password', style: TextStyle(color: Colors.white, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirm,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration(hint: 'Confirm Password', icon: Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
                              onPressed: () => setStateDialog(() => obscureConfirm = !obscureConfirm),
                            ),
                          ),
                          validator: (value) {
                            if (value!.isEmpty) return 'Required';
                            if (value != newPasswordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
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

                      // FASA 1: PROSES VERIFY DALAM FIREBASE
                      if (!isVerified) {
                        try {
                          String email = forgotEmailController.text.trim();
                          String phone = forgotPhoneController.text.trim();

                          // Tembak Firebase: Cari akaun yang ada Email DAN Phone Number ni
                          QuerySnapshot query = await FirebaseFirestore.instance
                              .collection('USER')
                              .where('email', isEqualTo: email)
                              .where('phone_number', isEqualTo: phone)
                              .limit(1)
                              .get();

                          if (query.docs.isNotEmpty) {
                            // Akaun Dijumpai! Tukar state ke bahagian Password Baru
                            setStateDialog(() {
                              isVerified = true;
                              verifiedUserId = query.docs.first.id; // Simpan ID untuk update nanti
                              isDialogLoading = false;
                            });
                          } else {
                            // Akaun Tak Dijumpai / Salah Detail
                            setStateDialog(() => isDialogLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Account not found. Please check your details.'), backgroundColor: Colors.red),
                            );
                          }
                        } catch (e) {
                          setStateDialog(() => isDialogLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      } 
                      // FASA 2: PROSES UPDATE PASSWORD BARU
                      else {
                        try {
                          // Update password baru ke dalam Firebase
                          await FirebaseFirestore.instance
                              .collection('USER')
                              .doc(verifiedUserId)
                              .update({'password': newPasswordController.text.trim()});

                          Navigator.pop(context); // Tutup dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password updated successfully! You can now log in.'), backgroundColor: Colors.green),
                          );
                        } catch (e) {
                          setStateDialog(() => isDialogLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                  child: isDialogLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : Text(isVerified ? 'Update' : 'Verify', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                      height: screenHeight * 0.22, 
                      width: screenWidth * 0.75,
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

                  // --- FORGOT PASSWORD TERCETUS DI SINI ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog, // Panggil fungsi dialog tadi
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5)),
    );
  }
}