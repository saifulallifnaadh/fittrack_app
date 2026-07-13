import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  String _formatDateString(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'Today';
    } else if (targetDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('dd MMM yyyy, EEEE').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Progress History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false, 
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('history')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
          
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No progress recorded yet.', style: TextStyle(color: Colors.grey)));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              
              DateTime recordDate = data.containsKey('date') 
                  ? (data['date'] as Timestamp).toDate() 
                  : DateTime.now();
              String displayDate = _formatDateString(recordDate);

              int waterIntake = data.containsKey('water_intake') ? data['water_intake'] : 0;
              double waterProgress = waterIntake / 2500; 

              List<dynamic> exercises = data.containsKey('exercises') ? data['exercises'] : [];
              int completedWorkouts = exercises.where((e) => e['isCompleted'] == true).length;
              int totalWorkouts = exercises.isEmpty ? 3 : exercises.length; 
              double workoutProgress = totalWorkouts == 0 ? 0 : (completedWorkouts / totalWorkouts);

              // Jarak larian
              double runDistance = data.containsKey('run_distance') ? (data['run_distance'] as num).toDouble() : 0.0;
              double targetRun = 5.0; 
              double runProgress = targetRun == 0 ? 0 : (runDistance / targetRun);

              return Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayDate, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),

                    _buildProgressCard(
                      icon: Icons.water_drop,
                      iconColor: const Color(0xFF03A9F4),
                      title: 'Water Intake',
                      progressText: '$waterIntake / 2500 ml',
                      progressValue: waterProgress,
                      progressColor: const Color(0xFF03A9F4),
                    ),
                    const SizedBox(height: 15),

                    _buildProgressCard(
                      icon: Icons.fitness_center,
                      iconColor: const Color(0xFF9D50BB),
                      title: 'Workout Completed',
                      progressText: '$completedWorkouts / $totalWorkouts',
                      progressValue: workoutProgress,
                      progressColor: const Color(0xFF9D50BB),
                    ),
                    const SizedBox(height: 15),

                    _buildProgressCard(
                      icon: Icons.directions_run,
                      iconColor: const Color(0xFFFF9800),
                      title: 'Outdoor Run',
                      progressText: '${runDistance.toStringAsFixed(2)} / ${targetRun.toInt()} km',
                      progressValue: runProgress,
                      progressColor: const Color(0xFFFF9800),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

      // --- BUTTON DUMMY UNTUK TEST MASUKKAN DATA (BOLEH PADAM SELEPAS INI) ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00E5FF),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () async {
          final now = DateTime.now();
          
          // 1. Masukkan Data Hari Ini (Today)
          final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
          await FirebaseFirestore.instance.collection('users').doc(userId).collection('history').doc(todayStr).set({
            'date': Timestamp.fromDate(now),
            'water_intake': 1500,
            'run_distance': 3.20,
            'exercises': [{'isCompleted': true}, {'isCompleted': true}, {'isCompleted': false}]
          });

          // 2. Masukkan Data Semalam (Yesterday)
          final yesterday = now.subtract(const Duration(days: 1));
          final yesterdayStr = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
          await FirebaseFirestore.instance.collection('users').doc(userId).collection('history').doc(yesterdayStr).set({
            'date': Timestamp.fromDate(yesterday),
            'water_intake': 2500,
            'run_distance': 5.0,
            'exercises': [{'isCompleted': true}, {'isCompleted': true}, {'isCompleted': true}]
          });
        },
      ),
    );
  }

  Widget _buildProgressCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String progressText,
    required double progressValue,
    required Color progressColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF131A26), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
              Text(progressText, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: progressValue > 1.0 ? 1.0 : progressValue,
            backgroundColor: const Color(0xFF090E17),
            color: progressColor,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}