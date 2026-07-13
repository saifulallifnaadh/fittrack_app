import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final int dailyGoal = 2500; 

  // --- DAPATKAN TARIKH HARI INI ---
  String get _todayStr {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> _addWater(int amount, int currentWater) async {
    int newTotal = currentWater + amount;
    
    try {
      // HANTAR KE FOLDER HISTORY (SYNC DENGAN PROGRESS & DASHBOARD)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('history')
          .doc(_todayStr)
          .set({
        'water_intake': newTotal,
        'date': Timestamp.fromDate(DateTime.now()), // Wajib ada untuk Progress History
      }, SetOptions(merge: true)); 
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.water_drop, color: Colors.white),
              const SizedBox(width: 10),
              Text('Glug glug! Added $amount ml of water. 💧', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: const Color(0xFF03A9F4),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _resetWater() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('history')
        .doc(_todayStr)
        .set({
      'water_intake': 0,
      'date': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  String _getMotivationalText(double progress) {
    if (progress == 0) return "Let's start hydrating!";
    if (progress < 0.5) return "Good start! Keep drinking.";
    if (progress < 0.8) return "You're halfway there! 🌊";
    if (progress < 1.0) return "Almost at your daily goal!";
    return "Goal Reached! You're fully hydrated! 🏆";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Water Tracker', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey), 
            onPressed: _resetWater,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // BACA DARI FOLDER HISTORY
        stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('history').doc(_todayStr).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF03A9F4)));

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          int currentWater = data != null && data.containsKey('water_intake') ? data['water_intake'] : 0;
          
          double progress = currentWater / dailyGoal;
          bool isGoalReached = progress >= 1.0;
          if (progress > 1.0) progress = 1.0;

          return SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _getMotivationalText(progress),
                      key: ValueKey<String>(_getMotivationalText(progress)),
                      style: TextStyle(
                        color: isGoalReached ? Colors.greenAccent : Colors.grey,
                        fontSize: 16,
                        fontWeight: isGoalReached ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedProgress, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isGoalReached)
                            Container(
                              width: 260, height: 260,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFF03A9F4).withOpacity(0.4), blurRadius: 40, spreadRadius: 10),
                                ],
                              ),
                            ),
                          SizedBox(
                            width: 250, height: 250,
                            child: CircularProgressIndicator(
                              value: animatedProgress,
                              strokeWidth: 20,
                              backgroundColor: const Color(0xFF131A26),
                              color: isGoalReached ? Colors.greenAccent : const Color(0xFF03A9F4),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            children: [
                              Icon(
                                isGoalReached ? Icons.local_drink : Icons.water_drop, 
                                color: isGoalReached ? Colors.greenAccent : const Color(0xFF03A9F4), 
                                size: 55
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${(animatedProgress * dailyGoal).toInt()} ml', 
                                style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold)
                              ),
                              Text('/ $dailyGoal ml', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 70),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      BouncyWaterButton(
                        label: '+ 250 ml',
                        icon: Icons.local_drink_outlined,
                        onTap: () => _addWater(250, currentWater),
                      ),
                      BouncyWaterButton(
                        label: '+ 500 ml',
                        icon: Icons.water_drop_outlined,
                        onTap: () => _addWater(500, currentWater),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class BouncyWaterButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const BouncyWaterButton({super.key, required this.label, required this.icon, required this.onTap});

  @override
  State<BouncyWaterButton> createState() => _BouncyWaterButtonState();
}

class _BouncyWaterButtonState extends State<BouncyWaterButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap(); 
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0, 
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          decoration: BoxDecoration(
            color: _isPressed ? const Color(0xFF03A9F4).withOpacity(0.2) : const Color(0xFF131A26),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: _isPressed ? const Color(0xFF03A9F4) : const Color(0xFF03A9F4).withOpacity(0.5), 
              width: 2
            ),
            boxShadow: _isPressed ? [] : [
              BoxShadow(
                color: const Color(0xFF03A9F4).withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: const Color(0xFF03A9F4), size: 22),
              const SizedBox(width: 8),
              Text(
                widget.label, 
                style: const TextStyle(color: Color(0xFF03A9F4), fontSize: 18, fontWeight: FontWeight.bold)
              ),
            ],
          ),
        ),
      ),
    );
  }
}