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
  final int dailyGoal = 2500; // Sasaran 2.5L sehari

  // Fungsi untuk tambah air ke Firestore
  Future<void> _addWater(int amount, int currentWater) async {
    int newTotal = currentWater + amount;
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'water_intake': newTotal,
      }, SetOptions(merge: true)); // Guna merge supaya data lain (nama/umur) tak hilang
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Added $amount ml of water!'),
          backgroundColor: Colors.blueAccent,
          duration: const Duration(seconds: 1),
        ));
      }
    } catch (e) {
      print(e);
    }
  }

  // Fungsi untuk reset air
  Future<void> _resetWater() async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'water_intake': 0,
    }, SetOptions(merge: true));
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
          IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _resetWater),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF03A9F4)));

          // Ambil jumlah air dari database (default 0 kalau belum wujud)
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          int currentWater = data != null && data.containsKey('water_intake') ? data['water_intake'] : 0;
          
          double progress = currentWater / dailyGoal;
          if (progress > 1.0) progress = 1.0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Visual Bulatan Air
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250, height: 250,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 20,
                      backgroundColor: const Color(0xFF131A26),
                      color: const Color(0xFF03A9F4),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    children: [
                      const Icon(Icons.water_drop, color: Color(0xFF03A9F4), size: 50),
                      const SizedBox(height: 10),
                      Text('$currentWater ml', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                      Text('/ $dailyGoal ml', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // Butang Tambah Air
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAddButton('+ 250 ml', 250, currentWater),
                  _buildAddButton('+ 500 ml', 500, currentWater),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddButton(String label, int amount, int currentWater) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF131A26),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF03A9F4), width: 1),
        ),
      ),
      onPressed: () => _addWater(amount, currentWater),
      child: Text(label, style: const TextStyle(color: Color(0xFF03A9F4), fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}