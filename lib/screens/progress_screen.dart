import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk efek gegaran (Haptic)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  // --- FUNGSI FORMAT TARIKH ---
  String _formatDateString(DateTime recordDate) {
    final now = DateTime.now();
    // Buang komponen masa (jam/minit) untuk perbandingan tarikh yang tepat
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final targetDate = DateTime(recordDate.year, recordDate.month, recordDate.day);

    if (targetDate == today) return 'Today';
    if (targetDate == yesterday) return 'Yesterday';
    return DateFormat('dd MMM yyyy, EEEE').format(recordDate);
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Progress History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: 1.2)),
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          // --- 1. TAPIS (FILTER) DATA MASA DEPAN KELUAR ---
          // Kita cuma ambil rekod Hari Ini dan Hari-hari Sebelumnya sahaja.
          final pastAndPresentDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            DateTime date = data.containsKey('date') ? (data['date'] as Timestamp).toDate() : DateTime.now();
            DateTime targetDate = DateTime(date.year, date.month, date.day);
            
            return !targetDate.isAfter(today); // False kalau tarikh tu masa depan
          }).toList();

          if (pastAndPresentDocs.isEmpty) {
            return _buildEmptyState();
          }

          // --- 2. SUSUN DATA MENURUN (TERKINI DI ATAS) ---
          pastAndPresentDocs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            DateTime dateA = dataA.containsKey('date') ? (dataA['date'] as Timestamp).toDate() : DateTime.now();
            DateTime dateB = dataB.containsKey('date') ? (dataB['date'] as Timestamp).toDate() : DateTime.now();
            return dateB.compareTo(dateA);
          });

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            itemCount: pastAndPresentDocs.length,
            itemBuilder: (context, index) {
              final data = pastAndPresentDocs[index].data() as Map<String, dynamic>;
              DateTime date = data.containsKey('date') ? (data['date'] as Timestamp).toDate() : DateTime.now();
              
              return _buildDailySection(
                _formatDateString(date),
                data['water_intake'] ?? 0,
                data['exercises'] ?? [],
                (data['run_distance'] as num?)?.toDouble() ?? 0.0,
                isToday: _formatDateString(date) == 'Today'
              );
            },
          );
        },
      ),
    );
  }

  // WIDGET PAPARAN JIKA TIADA REKOD
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_run, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 20),
          const Text(
            'No progress recorded yet.', 
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          const Text(
            'Start sweating and hit your goals! 💪', 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5)
          ),
        ],
      )
    );
  }

  // WIDGET KUMPULAN SEHARI (SATU TARIKH)
  Widget _buildDailySection(String title, int water, List<dynamic> exercises, double run, {bool isToday = false}) {
    int completed = exercises.where((e) => e['isCompleted'] == true).length;
    int total = exercises.isEmpty ? 3 : exercises.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Tarikh dengan Efek Glowing (Khas untuk 'Today')
          Padding(
            padding: const EdgeInsets.only(left: 5, bottom: 15),
            child: Row(
              children: [
                Container(
                  width: 10, 
                  height: 10, 
                  decoration: BoxDecoration(
                    color: isToday ? const Color(0xFF00E5FF) : Colors.grey, 
                    shape: BoxShape.circle,
                    boxShadow: isToday ? [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.6), blurRadius: 10)] : [],
                  )
                ),
                const SizedBox(width: 12),
                Text(
                  title.toUpperCase(), 
                  style: TextStyle(
                    color: isToday ? Colors.white : Colors.grey, 
                    fontSize: 14, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 1.5
                  )
                ),
              ],
            ),
          ),
          // Kad-kad Progres (Interaktif)
          _BouncingProgressTile(
            icon: Icons.water_drop, 
            title: 'Water Intake', 
            val: '$water / 2500 ml', 
            progress: (water / 2500).clamp(0.0, 1.0), 
            color: const Color(0xFF03A9F4)
          ),
          _BouncingProgressTile(
            icon: Icons.fitness_center, 
            title: 'Workouts', 
            val: '$completed / $total', 
            progress: total == 0 ? 0 : (completed / total).clamp(0.0, 1.0), 
            color: const Color(0xFF9D50BB)
          ),
          _BouncingProgressTile(
            icon: Icons.directions_run, 
            title: 'Outdoor Run', 
            val: '${run.toStringAsFixed(2)} / 5.0 km', 
            progress: (run / 5).clamp(0.0, 1.0), 
            color: const Color(0xFFFF9800)
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// KELAS KHAS: KAD PROGRES INTERAKTIF (MELANTUN)
// ==========================================================
class _BouncingProgressTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String val;
  final double progress;
  final Color color;

  const _BouncingProgressTile({
    required this.icon, 
    required this.title, 
    required this.val, 
    required this.progress, 
    required this.color
  });

  @override
  State<_BouncingProgressTile> createState() => _BouncingProgressTileState();
}

class _BouncingProgressTileState extends State<_BouncingProgressTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Kalau dah 100%, bar akan penuh dan warna berubah sikit
    bool isCompleted = widget.progress >= 1.0;

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = false);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF131A26),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isCompleted ? widget.color.withOpacity(0.3) : Colors.white.withOpacity(0.03), 
              width: 1.5
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2), 
                blurRadius: 15, 
                offset: const Offset(0, 5)
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10), 
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1), 
                      shape: BoxShape.circle
                    ), 
                    child: Icon(widget.icon, color: widget.color, size: 22)
                  ),
                  const SizedBox(width: 15),
                  Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(
                    widget.val, 
                    style: TextStyle(
                      color: isCompleted ? widget.color : Colors.grey, 
                      fontWeight: FontWeight.bold,
                      fontSize: 14
                    )
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: 8,
                  child: LinearProgressIndicator(
                    value: widget.progress, 
                    color: widget.color, 
                    backgroundColor: const Color(0xFF090E17), 
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}