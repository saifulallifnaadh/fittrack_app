import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'dart:async'; 
import 'profile_screen.dart';
import 'bmi_screen.dart';
import 'progress_screen.dart';
import 'workout_screen.dart';
import 'gps_tracking_screen.dart';
import 'water_screen.dart';
import 'summary_screen.dart';
import 'settings_screen.dart'; 
import 'calorie_tracker_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userId; 

  const DashboardScreen({super.key, required this.userId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; 
  
  // Timers
  Timer? _appUsageTimer; 
  Timer? _sliderTimer;
  
  // Slider properties
  final PageController _tipsController = PageController(viewportFraction: 0.9);
  int _currentTipIndex = 0; 

  // List daily tips health
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
    {
      'title': 'Fuel Your Body',
      'desc': 'Eat a protein-rich meal\nafter your workout.',
      'sub': 'Helps repair and build muscle.',
      'colors': [const Color(0xFFE91E63), const Color(0xFF9C27B0)],
    },
    {
      'title': 'Stay Flexible',
      'desc': 'Don\'t forget to stretch\nbefore and after.',
      'sub': 'Prevents injuries & improves flow.',
      'colors': [const Color(0xFF4CAF50), const Color(0xFF009688)],
    },
    {
      'title': 'Mental Check-in',
      'desc': 'Take a deep breath\nand clear your mind.',
      'sub': 'Stress less, live more.',
      'colors': [const Color(0xFF607D8B), const Color(0xFF3F51B5)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _startUsageTimer();
    _startAutoSlide(); 
  }

  @override
  void dispose() {
    _appUsageTimer?.cancel();
    _sliderTimer?.cancel(); 
    _tipsController.dispose();
    super.dispose();
  }

  // --- AUTO SLIDER LOGIC ---
  void _startAutoSlide() {
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_tipsController.hasClients) {
        int nextPage = _currentTipIndex + 1;
        
        if (nextPage >= healthTips.length) {
          nextPage = 0; 
          _tipsController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        } else {
          _tipsController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  // --- TIMER SYNC DENGAN FIRESTORE ---
  void _startUsageTimer() {
    _appUsageTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('history') 
            .doc(todayStr)        
            .set({
          'active_minutes': FieldValue.increment(1), 
          'date': Timestamp.fromDate(now), 
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Ralat kemas kini app usage: $e");
      }
    });
  }

  String _getDynamicGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    final List<Widget> pages = [
      _buildDashboardHome(screenHeight, screenWidth), 
      const ProgressScreen(),
      const SummaryScreen(),                      
      SettingsScreen(userId: widget.userId),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0D1524),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF00E5FF),
          unselectedItemColor: Colors.grey.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          currentIndex: _selectedIndex,
          onTap: (index) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.grid_view_rounded),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.grid_view_rounded, color: Color(0xFF00E5FF)),
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.analytics_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.analytics, color: Color(0xFF00E5FF)),
              ),
              label: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.pie_chart_outline_rounded),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.pie_chart_rounded, color: Color(0xFF00E5FF)),
              ),
              label: 'Summary',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.tune_rounded),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.settings_rounded, color: Color(0xFF00E5FF)),
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHome(double screenHeight, double screenWidth) {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    return SafeArea(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, userSnapshot) {
          String displayName = "Champion";
          String initial = "C";
          String? profileImageUrl; 

          if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
            final userData = userSnapshot.data!.data() as Map<String, dynamic>; 
            if (userData.containsKey('name') && userData['name'] != null) {
              String fetchedName = userData['name'].toString().trim();
              if (fetchedName.isNotEmpty) {
                List<String> nameParts = fetchedName.split(' ');
                displayName = nameParts.length > 2 ? '${nameParts.first} ${nameParts.last}' : fetchedName;
                initial = displayName[0].toUpperCase();
              }
            }
            if (userData.containsKey('profile_image_url') && userData['profile_image_url'] != null) {
              profileImageUrl = userData['profile_image_url'];
            }
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .collection('history')
                .doc(todayStr)
                .snapshots(),
            builder: (context, historySnapshot) {
              if (historySnapshot.connectionState == ConnectionState.waiting && !userSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
              }

              int waterIntake = 0;
              int completedWorkouts = 0;
              int totalWorkouts = 3;
              int totalCalories = 0; 

              if (historySnapshot.hasData && historySnapshot.data != null && historySnapshot.data!.exists) {
                final historyData = historySnapshot.data!.data() as Map<String, dynamic>;
                
                waterIntake = historyData.containsKey('water_intake') ? historyData['water_intake'] : 0;
                
                List<dynamic> exercises = historyData.containsKey('exercises') ? historyData['exercises'] : [];
                completedWorkouts = exercises.where((e) => e['isCompleted'] == true).length;
                totalWorkouts = exercises.isEmpty ? 3 : exercises.length;
                
                // --- PENYELARASAN KALORI: Baca total_calories, kalau tiada ambil calories_burned ---
                if (historyData.containsKey('total_calories')) {
                  totalCalories = (historyData['total_calories'] as num).toInt();
                } else if (historyData.containsKey('calories_burned')) {
                  totalCalories = (historyData['calories_burned'] as num).toInt();
                }
              }

              double waterDisplayVal = waterIntake / 1000;
              String waterDisplay = waterDisplayVal.toStringAsFixed(1);

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
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
                              Text(
                                _getDynamicGreeting(),
                                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayName,
                                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: widget.userId)));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF9D50BB)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 23,
                              backgroundColor: const Color(0xFF090E17),
                              backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                              child: profileImageUrl == null 
                                  ? Text(initial, style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 18)) 
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: screenHeight * 0.025),

                    // --- AUTO-SLIDER TIPS ---
                    SizedBox(
                      height: 155,
                      child: PageView.builder(
                        controller: _tipsController,
                        itemCount: healthTips.length,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (int index) {
                          setState(() {
                            _currentTipIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final tip = healthTips[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: EdgeInsets.all(screenWidth * 0.05),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: tip['colors'] as List<Color>,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (tip['colors'] as List<Color>)[1].withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.bolt, color: Colors.white, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      (tip['title'] as String).toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.2),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tip['desc'] as String,
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2, letterSpacing: -0.3),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  tip['sub'] as String,
                                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(healthTips.length, (index) {
                        bool isActive = _currentTipIndex == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 6,
                          width: isActive ? 20.0 : 6.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: const Color(0xFF00E5FF).withOpacity(isActive ? 1.0 : 0.2),
                          ),
                        );
                      }),
                    ),

                    SizedBox(height: screenHeight * 0.035),

                    // --- YOUR PROGRESS SECTION ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daily Progress',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00E5FF),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Live Syncing',
                              style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A26),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.04)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildRingProgress(
                            icon: Icons.local_fire_department_rounded,
                            color: const Color(0xFFFF7A00),
                            title: 'Calories',
                            currentValue: totalCalories, 
                            targetValue: 2000,           
                            displayString: '$totalCalories',
                            unit: 'kcal',
                          ),
                          _buildRingProgress(
                            icon: Icons.fitness_center_rounded,
                            color: const Color(0xFFB55DCD),
                            title: 'Workouts',
                            currentValue: completedWorkouts,
                            targetValue: totalWorkouts,
                            displayString: '$completedWorkouts',
                            unit: '/ $totalWorkouts',
                          ),
                          _buildRingProgress(
                            icon: Icons.water_drop_rounded,
                            color: const Color(0xFF00A2FF),
                            title: 'Hydration',
                            currentValue: waterIntake,
                            targetValue: 2500, 
                            displayString: waterDisplay,
                            unit: 'L',
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.035),

                    // --- MODULE GRID ---
                    Row(
                      children: [
                        Expanded(
                          child: InteractiveSpringCard(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BmiScreen())),
                            child: _buildModuleCard(
                              title: 'BMI Check',
                              subtitle: 'Check metrics',
                              icon: Icons.calculate_rounded,
                              color: const Color(0xFF00E5FF),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: InteractiveSpringCard(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkoutScreen())),
                            child: _buildModuleCard(
                              title: 'Gym Workout',
                              subtitle: 'Build power',
                              icon: Icons.fitness_center_rounded,
                              color: const Color(0xFF9D50BB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: InteractiveSpringCard(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GpsTrackingScreen())),
                            child: _buildModuleCard(
                              title: 'Outdoor Run',
                              subtitle: 'GPS tracker',
                              icon: Icons.directions_run_rounded,
                              color: const Color(0xFFFF9800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: InteractiveSpringCard(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WaterScreen())),
                            child: _buildModuleCard(
                              title: 'Water Log',
                              subtitle: 'Stay refreshed',
                              icon: Icons.water_drop_rounded,
                              color: const Color(0xFF03A9F4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    
                    // --- MODUL CALORIE TRACKER ---
                    InteractiveSpringCard(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CalorieTrackerScreen())),
                      child: _buildFullWidthModuleCard(
                        title: 'Daily Calories Tracker',
                        subtitle: 'Log meals, calculate goals & monitor statistics',
                        icon: Icons.local_fire_department_rounded,
                        color: const Color(0xFFFF5722), 
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRingProgress({
    required IconData icon,
    required Color color,
    required String title,
    required num currentValue,
    required num targetValue,
    required String displayString,
    required String unit,
  }) {
    double completionRatio = targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: CircularProgressIndicator(
                value: completionRatio,
                strokeWidth: 5,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(title, style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(displayString, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(width: 2),
            Text(unit, style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: -0.2),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidthModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.withOpacity(0.5), size: 24),
          ],
        ),
      ),
    );
  }
}

class InteractiveSpringCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const InteractiveSpringCard({super.key, required this.child, required this.onTap});

  @override
  State<InteractiveSpringCard> createState() => _InteractiveSpringCardState();
}

class _InteractiveSpringCardState extends State<InteractiveSpringCard> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _scale = 0.94); 
        HapticFeedback.lightImpact(); 
      },
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}