import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'login_screen.dart';

// ==========================================
// 1. SKRIN PROFIL UTAMA (MAIN PROFILE)
// ==========================================
class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            icon: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            label: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('USER').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          String name = userData['name'] ?? 'User';
          String email = userData['email'] ?? 'No email';
          String age = userData['age']?.toString() ?? '0';
          String imageUrl = userData['profile_image'] ?? '';
          String initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // --- AVATAR GLOW DESIGN ---
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF9D50BB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.3), blurRadius: 20, spreadRadius: 5),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: const Color(0xFF131A26),
                    backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty
                        ? Text(initial, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold))
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 30),

                // --- OVERVIEW CARD ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF131A26), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const CircleAvatar(backgroundColor: Color(0xFF0F2537), child: Icon(Icons.person_outline, color: Color(0xFF00E5FF))),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Age', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                Text('$age Years', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.2)),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(backgroundColor: Color(0xFF0F302D), child: Icon(Icons.calendar_month, color: Color(0xFF00E676))),
                            SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Active Days', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                Text('45 Days', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // --- MENU LIST ---
                _buildMenuTile(
                  icon: Icons.person_outline, 
                  color: const Color(0xFF9D50BB), 
                  title: 'Personal Information', 
                  subtitle: 'Update your personal details',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen(userId: userId, userData: userData)));
                  }
                ),
                _buildMenuTile(icon: Icons.track_changes, color: const Color(0xFF00E676), title: 'Goals', subtitle: 'View and update your goals'),
                _buildMenuTile(icon: Icons.bar_chart, color: const Color(0xFFFFB300), title: 'Progress History', subtitle: 'Track your fitness progress'),
                _buildMenuTile(icon: Icons.notifications_none, color: const Color(0xFF00E5FF), title: 'Notifications', subtitle: 'Manage your notifications'),
                _buildMenuTile(icon: Icons.privacy_tip_outlined, color: const Color(0xFFE91E63), title: 'Privacy', subtitle: 'Manage your privacy settings'),
                _buildMenuTile(icon: Icons.settings_outlined, color: const Color(0xFF00E5FF), title: 'Settings', subtitle: 'Customize your app experience'),
              ],
            ),
          );
        }
      ),
    );
  }

  // Helper function (_buildMenuTile) wajib duduk kat dalam ProfileScreen
  Widget _buildMenuTile({required IconData icon, required Color color, required String title, required String subtitle, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Icon(icon, color: color, size: 28),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
    );
  }
}

// ==========================================
// 2. SKRIN EDIT PROFIL (PERSONAL INFORMATION)
// ==========================================
class EditProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userId, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  bool _isObscure = true;
  bool _isUpdating = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _phoneController = TextEditingController(text: widget.userData['phone_number']);
    _ageController = TextEditingController(text: widget.userData['age']?.toString());
    _emailController = TextEditingController(text: widget.userData['email']);
    _passwordController = TextEditingController(text: widget.userData['password']); 
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _verifyToViewPassword() {
    TextEditingController verifyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131A26),
          title: const Text('Verify Identity', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your current password to view it.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 15),
              TextField(
                controller: verifyController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Current Password',
                  hintStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
              onPressed: () {
                if (verifyController.text == widget.userData['password']) {
                  Navigator.pop(context);
                  setState(() {
                    _isObscure = false;
                  });
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect password!'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Verify', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      }
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isUpdating = true);
    try {
      String? imageUrl = widget.userData['profile_image'];

      if (_imageFile != null) {
        String safeUserId = widget.userId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('$safeUserId.jpg');
        
        UploadTask uploadTask = storageRef.putFile(_imageFile!);
        TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('USER').doc(widget.userId).update({
        'name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'profile_image': imageUrl ?? '',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green)
        );
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentImage = widget.userData['profile_image'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), 
          onPressed: () => Navigator.pop(context)
        ),
        title: const Text('Personal Information', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF131A26),
                    backgroundImage: _imageFile != null 
                        ? FileImage(_imageFile!) as ImageProvider 
                        : (currentImage.isNotEmpty ? NetworkImage(currentImage) : null),
                    child: (_imageFile == null && currentImage.isEmpty)
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFF00E5FF), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildTextField('Full Name', _nameController, Icons.person_outline),
            const SizedBox(height: 20),
            _buildTextField('Age', _ageController, Icons.cake_outlined, isNumber: true),
            const SizedBox(height: 20),
            _buildTextField('Phone Number', _phoneController, Icons.phone_android_outlined, isNumber: true),
            const SizedBox(height: 20),
            _buildTextField('Email', _emailController, Icons.email_outlined),
            const SizedBox(height: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isObscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 22),
                    suffixIcon: IconButton(
                      icon: Icon(_isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                      onPressed: () {
                        if (_isObscure) {
                          _verifyToViewPassword();
                        } else {
                          setState(() => _isObscure = true); 
                        }
                      },
                    ),
                    filled: true,
                    fillColor: const Color(0xFF131A26),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isUpdating ? null : _saveChanges,
                child: _isUpdating 
                    ? const SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5)
                      )
                    : const Text('Save Changes', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function (_buildTextField) wajib duduk kat dalam EditProfileScreen
  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey, size: 22),
            filled: true,
            fillColor: const Color(0xFF131A26),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}