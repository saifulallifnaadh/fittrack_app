import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'profile_screen.dart';
import 'bmi_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userId; 

  const DashboardScreen({super.key, required this.userId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; 

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          // Tarik data user spesifik berdasarkan userId masa login/signup
          future: FirebaseFirestore.instance.collection('USER').doc(widget.userId).get(),
          builder: (context, snapshot) {
            // 1. Paparkan loading spinner sementara tunggu data masuk
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
              );
            }

            // 2. Tangkap ralat awal jika ada masalah (contoh: tiada internet)
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
              );
            }

            // 3. Set nama lalai (default)
            String displayName = "User";

            // 4. Cara paling selamat (Null-Safe) untuk ekstrak data nama
            if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
              final data = snapshot.data!.data(); 
              if (data is Map<String, dynamic> && data.containsKey('name')) {
                String fetchedName = data['name'].toString().trim();
                if (fetchedName.isNotEmpty) {
                  displayName = fetchedName;
                }
              }
            }

            // 5. Ekstrak huruf pertama untuk ikon profil
            String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : "U";

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.065,
                vertical: screenHeight * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.01),
                  
                  // --- HEADER: GREETING & PROFILE PIC ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $displayName !', 
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: screenHeight * 0.005),
                          const Text(
                            'Ready to crush your goals today?',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                      // JADIKAN AVATAR BOLEH DITEKAN (KLIK UNTUK KE PROFILE)
                      GestureDetector(
                        onTap: () {
                          // Navigasi ke skrin Profile
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ProfileScreen(userId: widget.userId)),
                          );
                        },
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFF00E5FF),
                          // Jika ada gambar, papar gambar. Jika takde, papar huruf.
                          backgroundImage: (snapshot.data!.data() as Map<String, dynamic>).containsKey('profile_image') && 
                                           (snapshot.data!.data() as Map<String, dynamic>)['profile_image'] != ''
                              ? NetworkImage((snapshot.data!.data() as Map<String, dynamic>)['profile_image'])
                              : null,
                          child: !(snapshot.data!.data() as Map<String, dynamic>).containsKey('profile_image') || 
                                 (snapshot.data!.data() as Map<String, dynamic>)['profile_image'] == ''
                              ? Text(
                                  initial, 
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: screenHeight * 0.03),

                  // --- DAILY HEALTH TIP CARD ---
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF0088FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Daily Health Tip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        const Text(
                          'Small steps every day\nlead to big changes.',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          'Stay consistent, stay strong!',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // --- YOUR PROGRESS SECTION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Your Progress', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View All', style: TextStyle(color: Color(0xFF00E5FF))),
                      ),
                    ],
                  ),
                  
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniProgress(Icons.local_fire_department, const Color(0xFFFF9800), 'Calories', '350', '/ 2,000 kcal'),
                        _buildMiniProgress(Icons.fitness_center, const Color(0xFF9D50BB), 'Workouts', '3', '/ 5 this week'),
                        _buildMiniProgress(Icons.water_drop, const Color(0xFF03A9F4), 'Water', '1.5 L', '/ 2.5 L'),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // --- MODULE GRID SECTION (BUTANG NAVIGASI) ---
                  Row(
                    children: [
                      Expanded(child: _buildModuleCard(context, 'BMI Calculator', 'Calculate your BMI\nand track progress', Icons.calculate, const Color(0xFF00E5FF), () {
                        // Letak Navigator ke Skrin BMI nanti
                        Navigator.push(
                           context,
                          MaterialPageRoute(builder: (context) => const BmiScreen()),
                        );
                      })),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(child: _buildModuleCard(context, 'Workout', 'Explore workouts\nand build strength', Icons.fitness_center, const Color(0xFF9D50BB), () {
                        // Letak Navigator ke Skrin Workout nanti
                      })),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    children: [
                      Expanded(child: _buildModuleCard(context, 'Calories', 'Track calories and\nachieve your goals', Icons.local_fire_department, const Color(0xFFFF9800), () {
                        // Letak Navigator ke Skrin Calories nanti
                      })),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(child: _buildModuleCard(context, 'Water', 'Track your water\nintake daily', Icons.water_drop, const Color(0xFF03A9F4), () {
                        // Letak Navigator ke Skrin Water nanti
                      })),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      
      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF090E17),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00E5FF),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() { _selectedIndex = index; });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  // Helper Widget untuk 3 stat kecil (Calories, Workouts, Water)
  Widget _buildMiniProgress(IconData icon, Color color, String title, String value, String subtitle) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  // Helper Widget untuk Kad Modul Utama
  Widget _buildModuleCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF131A26),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4)),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}