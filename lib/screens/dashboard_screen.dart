import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'profile_screen.dart';
import 'bmi_screen.dart';
import 'progress_screen.dart';
import 'workout_screen.dart';
import 'gps_tracking_screen.dart';
import 'water_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  final String userId; 

  const DashboardScreen({super.key, required this.userId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; 

  final List<Map<String, dynamic>> healthTips = [
    {
      'title': 'Daily Health Tip',
      'desc': 'Small steps every day\nlead to big changes.',
      'sub': 'Stay consistent, stay strong!',
      'colors': [const Color(0xFF00E5FF), const Color(0xFF0088FF)],
    },
    {
      'title': 'Hydration is Key',
      'desc': 'Drink at least 2 liters\nof water daily.',
      'sub': 'Keep your body hydrated!',
      'colors': [const Color(0xFF9D50BB), const Color(0xFF6E00FF)],
    },
    {
      'title': 'Rest & Recover',
      'desc': 'Quality sleep is vital\nfor muscle growth.',
      'sub': 'Aim for 7-8 hours tonight.',
      'colors': [const Color(0xFFFF9800), const Color(0xFFFF5722)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    // --- SENARAI SKRIN UNTUK TAB NAVIGASI ---
    final List<Widget> pages = [
      _buildDashboardHome(screenHeight, screenWidth), // Tab 0: Home
      const ProgressScreen(),
      const HistoryScreen(),                          // Tab 2: Summary/History
      SettingsScreen(userId: widget.userId),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF090E17),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00E5FF),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Summary'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  // --- KANDUNGAN ASAL DASHBOARD (SYNC SECARA LIVE DENGAN STREAMBUILDER) ---
  Widget _buildDashboardHome(double screenHeight, double screenWidth) {
    return SafeArea(
      child: StreamBuilder<DocumentSnapshot>(
        // Guna .snapshots() untuk Live Sync
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
          }

          String displayName = "User";
          String initial = "U";
          String? profileImageUrl; 
          
          // Data untuk Progress Sync
          int waterIntake = 0;
          int completedWorkouts = 0;
          int totalWorkouts = 3;
          int caloriesBurned = 0;

          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>; 
            
            // Uruskan Nama & Gambar Profil
            if (data.containsKey('name') && data['name'] != null) {
              String fetchedName = data['name'].toString().trim();
              if (fetchedName.isNotEmpty) {
                List<String> nameParts = fetchedName.split(' ');
                displayName = nameParts.length > 2 ? '${nameParts.first} ${nameParts.last}' : fetchedName;
                initial = displayName[0].toUpperCase();
              }
            }
            if (data.containsKey('profile_image_url') && data['profile_image_url'] != null) {
              profileImageUrl = data['profile_image_url'];
            }

            // --- TANGKAP DATA UNTUK PROGRESS SYNC ---
            // 1. Data Air
            waterIntake = data.containsKey('water_intake') ? data['water_intake'] : 0;
            
            // 2. Data Senaman
            List<dynamic> exercises = data.containsKey('exercises') ? data['exercises'] : [];
            completedWorkouts = exercises.where((e) => e['isCompleted'] == true).length;
            totalWorkouts = exercises.isEmpty ? 3 : exercises.length;

            // 3. Data Kalori (Simulasi dinamik berdasarkan jumlah senaman siap)
            caloriesBurned = data.containsKey('calories_burned') ? data['calories_burned'] : (completedWorkouts * 120);
          }

          // Format Air dari ml ke Liter
          String waterDisplay = (waterIntake / 1000).toStringAsFixed(1);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.065, vertical: screenHeight * 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello, $displayName!', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                          const Text('Ready to crush your goals today?', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) =>  ProfileScreen(userId: widget.userId))), 
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFF00E5FF),
                        backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                        child: profileImageUrl == null 
                            ? Text(initial, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)) 
                            : null,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: screenHeight * 0.03),

                // --- SLIDER TIPS ---
                SizedBox(
                  height: 160,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.93), 
                    itemCount: healthTips.length,
                    padEnds: false, 
                    itemBuilder: (context, index) {
                      final tip = healthTips[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 15),
                        padding: EdgeInsets.all(screenWidth * 0.05),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(colors: tip['colors'] as List<Color>, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(children: [const Icon(Icons.lightbulb_outline, color: Colors.white, size: 20), const SizedBox(width: 8), Text(tip['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))]),
                            const SizedBox(height: 10),
                            Text(tip['desc'] as String, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            Text(tip['sub'] as String, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                // --- YOUR PROGRESS (LIVE SYNC DATA) ---
                const Text('Your Progress', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(color: const Color(0xFF131A26), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniProgress(Icons.local_fire_department, const Color(0xFFFF9800), 'Calories', '$caloriesBurned', '/ 2k kcal'),
                      _buildMiniProgress(Icons.fitness_center, const Color(0xFF9D50BB), 'Workouts', '$completedWorkouts', '/ $totalWorkouts'),
                      _buildMiniProgress(Icons.water_drop, const Color(0xFF03A9F4), 'Water', '$waterDisplay L', '/ 2.5 L'),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                // --- MODULE GRID ---
                Row(
                  children: [
                    Expanded(
                      child: _buildModuleCard(context, 'BMI Calculator', 'Track your BMI', Icons.calculate, const Color(0xFF00E5FF), () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const BmiScreen()));
                      })
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildModuleCard(context, 'Gym Workout', 'Build your strength', Icons.fitness_center, const Color(0xFF9D50BB), () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkoutScreen()));
                      })
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildModuleCard(context, 'Outdoor Run', 'Track GPS & pace', Icons.directions_run, const Color(0xFFFF9800), () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const GpsTrackingScreen()));
                      })
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildModuleCard(context, 'Water', 'Track water intake', Icons.water_drop, const Color(0xFF03A9F4), () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const WaterScreen()));
                      })
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniProgress(IconData icon, Color color, String title, String value, String subtitle) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  // --- WIDGET KAD MODUL INTERAKTIF ---
  Widget _buildModuleCard(
    BuildContext context, 
    String title, 
    String subtitle, 
    IconData icon, 
    Color color, 
    VoidCallback onTap, 
  ) {
    return Card(
      key: ValueKey(title),
      color: const Color(0xFF131A26),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: onTap, 
        borderRadius: BorderRadius.circular(24),
        splashColor: color.withValues(alpha: 0.1), 
        highlightColor: color.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.withValues(alpha: 0.7), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}