import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _imageUrl; // Simpan URL gambar dari Cloudinary
  bool _isLoading = false;
  bool _isAvatarPressed = false;
  
  String _userName = "Loading...";
  String _userEmail = "Loading...";
  String _userAge = "-";
  String _userPhone = "-";

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // --- 1. AMBIL DATA DAN URL GAMBAR DARI FIRESTORE ---
  Future<void> _loadProfileData() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      
      if (docSnapshot.exists && mounted) {
        final data = docSnapshot.data()!;
        setState(() {
          _userName = data['name'] ?? 'User';
          _userEmail = data['email'] ?? 'No email';
          _userAge = data['age']?.toString() ?? '-';
          _userPhone = data['phone_number'] ?? '-';
          // Tarik URL gambar kalau dah ada dalam database
          _imageUrl = data['profile_image_url']; 
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _userName = 'Error Loading');
      }
    }
  }

  // --- 2. MUAT NAIK GAMBAR KE CLOUDINARY & SIMPAN URL KE FIRESTORE ---
  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);

    if (image == null) return; 

    setState(() => _isLoading = true);

    try {
      final File file = File(image.path);
      
      // --- SETUP API CLOUDINARY ---
      const String cloudName = "mfi1getk"; 
      const String uploadPreset = "fitTrack_profile";     
      
      final Uri uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
      final request = http.MultipartRequest("POST", uri);
      
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonMap = jsonDecode(responseString);

      if (response.statusCode == 200) {
        final String secureUrl = jsonMap['secure_url'];

        await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
          'profile_image_url': secureUrl,
        });

        if (mounted) {
          setState(() => _imageUrl = secureUrl);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!'), backgroundColor: Colors.green));
        }
      } else {
        throw Exception(jsonMap['error']['message'] ?? 'Upload failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 3. POPUP EDIT PROFIL ---
  void _showEditProfileDialog() {
    final TextEditingController nameCtrl = TextEditingController(text: _userName);
    final TextEditingController ageCtrl = TextEditingController(text: _userAge);
    final TextEditingController phoneCtrl = TextEditingController(text: _userPhone);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF131A26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: _dialogInputDecoration('Full Name', Icons.person)),
                  const SizedBox(height: 15),
                  TextField(controller: ageCtrl, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: _dialogInputDecoration('Age', Icons.cake)),
                  const SizedBox(height: 15),
                  TextField(controller: phoneCtrl, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.phone, decoration: _dialogInputDecoration('Phone Number', Icons.phone)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                onPressed: isSaving ? null : () async {
                  setStateDialog(() => isSaving = true);
                  try {
                    await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
                      'name': nameCtrl.text.trim(),
                      'age': int.tryParse(ageCtrl.text.trim()) ?? 0,
                      'phone_number': phoneCtrl.text.trim(),
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      _loadProfileData(); 
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    setStateDialog(() => isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                },
                child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black)) : const Text('Save', style: TextStyle(color: Colors.black)),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- 4. POPUP VERIFY IDENTITY ---
  void _showVerificationDialog() {
    final TextEditingController emailCtrl = TextEditingController();
    final TextEditingController phoneCtrl = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF131A26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF00E5FF), width: 1)),
            title: const Text('Verify Identity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dialogInputDecoration('Registered Email', Icons.email_outlined),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dialogInputDecoration('Registered Phone No.', Icons.phone_outlined),
                ),
              ],
            ),
            actions: [
              if (!isVerifying)
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey))
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                onPressed: isVerifying ? null : () async {
                  if (emailCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
                  
                  setStateDialog(() => isVerifying = true);
                  
                  try {
                    // Semak dengan Firestore Data
                    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
                    
                    if (userDoc.exists) {
                      final data = userDoc.data() as Map<String, dynamic>;
                      String savedEmail = data['email']?.toString().trim() ?? '';
                      String savedPhone = data['phone_number']?.toString().trim() ?? '';

                      // Jika padan, tutup popup verify dan buka popup tukar password
                      if (emailCtrl.text.trim() == savedEmail && phoneCtrl.text.trim() == savedPhone) {
                        if (mounted) {
                          Navigator.pop(context); // Tutup dialog verify
                          _showChangePasswordDialog(); // Panggil fungsi tukar password
                        }
                      } else {
                        // Jika tak padan
                        setStateDialog(() => isVerifying = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details do not match!'), backgroundColor: Colors.redAccent));
                        }
                      }
                    }
                  } catch (e) {
                    setStateDialog(() => isVerifying = false);
                  }
                },
                child: isVerifying 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black)) 
                  : const Text('Verify', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- 5. POPUP TUKAR KATA LALUAN ---
  void _showChangePasswordDialog() {
    final TextEditingController passCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF131A26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Change Password', style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: passCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: _dialogInputDecoration('New Password', Icons.lock),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                onPressed: isSaving ? null : () async {
                  if (passCtrl.text.length < 6) return;
                  setStateDialog(() => isSaving = true);
                  try {
                    await FirebaseAuth.instance.currentUser?.updatePassword(passCtrl.text.trim());
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully!'), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    setStateDialog(() => isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                },
                child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black)) : const Text('Update', style: TextStyle(color: Colors.black)),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- 6. LOG OUT ---
  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // --- AVATAR INTERAKTIF ---
              Center(
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _isAvatarPressed = true),
                  onTapUp: (_) {
                    setState(() => _isAvatarPressed = false);
                    _pickAndUploadImage();
                  },
                  onTapCancel: () => setState(() => _isAvatarPressed = false),
                  child: AnimatedScale(
                    scale: _isAvatarPressed ? 0.92 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 130, height: 130,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF03A9F4).withValues(alpha: 0.4), width: 2), boxShadow: [BoxShadow(color: const Color(0xFF03A9F4).withValues(alpha: 0.1), blurRadius: 15, spreadRadius: 2)]),
                        ),
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: const Color(0xFF131A26),
                          backgroundImage: (_imageUrl != null && !_isLoading) ? NetworkImage(_imageUrl!) : null,
                          child: (_imageUrl == null && !_isLoading) ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                        ),
                        if (_isLoading)
                          Container(width: 120, height: 120, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle), child: const Center(child: CircularProgressIndicator(color: Color(0xFF03A9F4)))),
                        Positioned(
                          bottom: 0, right: 5,
                          child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF03A9F4), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.black, size: 16)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 5),
              Text(_userEmail, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              
              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(child: _buildInfoCard('Age', _userAge, Icons.cake)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildInfoCard('Phone', _userPhone, Icons.phone)),
                ],
              ),
              
              const SizedBox(height: 30),
              
              _buildMenuTile('Edit Profile', Icons.edit, _showEditProfileDialog),
              
              // --- UBAH SINI: Halakan ke pop-up Verify Identity terlebih dahulu ---
              _buildMenuTile('Change Password', Icons.lock_reset, _showVerificationDialog),
              
              const SizedBox(height: 20),
              
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: Colors.redAccent.withValues(alpha: 0.1),
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: _handleLogout,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFF131A26), borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF03A9F4), size: 24),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMenuTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: const Color(0xFF131A26), borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF03A9F4)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        onTap: onTap,
      ),
    );
  }

  InputDecoration _dialogInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true, fillColor: const Color(0xFF090E17),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    );
  }
}