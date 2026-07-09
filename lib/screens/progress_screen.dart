import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Today\'s Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false, 
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          
          // --- PENGIRAAN DATA AIR ---
          int waterIntake = data != null && data.containsKey('water_intake') ? data['water_intake'] : 0;
          double waterProgress = waterIntake / 2500; 

          // --- PENGIRAAN DATA WORKOUT (Berdasarkan Array) ---
          List<dynamic> exercises = (data != null && data.containsKey('exercises')) 
              ? data['exercises'] 
              : [];
          
          // Kira berapa banyak yang dah 'true'
          int completedWorkouts = exercises.where((e) => e['isCompleted'] == true).length;
          // Set default 3 kalau user belum pernah buka skrin Workout
          int totalWorkouts = exercises.isEmpty ? 3 : exercises.length; 
          double workoutProgress = totalWorkouts == 0 ? 0 : (completedWorkouts / totalWorkouts);

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              const Text('Daily Goals', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // --- KAD PROGRESS AIR ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF131A26), borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.water_drop, color: Color(0xFF03A9F4)),
                            SizedBox(width: 10),
                            Text('Water Intake', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Text('$waterIntake / 2500 ml', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    LinearProgressIndicator(
                      value: waterProgress > 1.0 ? 1.0 : waterProgress,
                      backgroundColor: const Color(0xFF090E17),
                      color: const Color(0xFF03A9F4),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- KAD PROGRESS WORKOUT ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF131A26), borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.fitness_center, color: Color(0xFF9D50BB)),
                            SizedBox(width: 10),
                            Text('Workout Completed', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Text('$completedWorkouts / $totalWorkouts', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    LinearProgressIndicator(
                      value: workoutProgress > 1.0 ? 1.0 : workoutProgress,
                      backgroundColor: const Color(0xFF090E17),
                      color: const Color(0xFF9D50BB),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              ),
              
            ],
          );
        },
      ),
    );
  }
}