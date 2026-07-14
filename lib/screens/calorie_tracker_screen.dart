import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalorieTrackerScreen extends StatefulWidget {
  const CalorieTrackerScreen({super.key});

  @override
  State<CalorieTrackerScreen> createState() => _CalorieTrackerScreenState();
}

class _CalorieTrackerScreenState extends State<CalorieTrackerScreen> {
  final int _calorieGoal = 2000;
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  String _selectedMealType = 'Breakfast';

  // Konfigurasi Warna & Ikon Dinamik untuk "Wow" Factor
  final Map<String, Map<String, dynamic>> _mealConfigs = {
    'Breakfast': {'icon': Icons.wb_twilight_rounded, 'color': const Color(0xFFFFB300)},
    'Lunch': {'icon': Icons.wb_sunny_rounded, 'color': const Color(0xFF00E5FF)},
    'Dinner': {'icon': Icons.nights_stay_rounded, 'color': const Color(0xFF9D50BB)},
    'Snack': {'icon': Icons.cookie_rounded, 'color': const Color(0xFFE91E63)},
  };

  @override
  void dispose() {
    _foodNameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  String _getTodayString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // --- FUNGSI BARU: SYNC TOTAL KE DASHBOARD (HISTORY COLLECTION) ---
  Future<void> _syncDailyTotalToHistory() async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    if (uid == 'unknown') return;
    
    final String todayStr = _getTodayString();

    try {
      // 1. Dapatkan semua makanan hari ini untuk kira total terkini
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_calories')
          .where('date', isEqualTo: todayStr)
          .get();

      int totalKcal = 0;
      for (var doc in snapshot.docs) {
        totalKcal += (doc.data()['calories'] as int? ?? 0);
      }

      // 2. Simpan total ini ke dalam collection 'history' supaya Dashboard boleh baca
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('history')
          .doc(todayStr)
          .set({
            'total_calories': totalKcal,
            'date': todayStr,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          
      debugPrint("✅ Berjaya sync total kalori ($totalKcal kcal) ke Dashboard!");
    } catch (e) {
      debugPrint("❌ Ralat sync ke history: $e");
    }
  }
  // -----------------------------------------------------------------

  void _openMealBottomSheet({DocumentSnapshot? doc}) {
    if (doc != null) {
      _foodNameController.text = doc['foodName'];
      _caloriesController.text = doc['calories'].toString();
      _selectedMealType = doc['mealType'];
    } else {
      _foodNameController.clear();
      _caloriesController.clear();
      _selectedMealType = 'Breakfast';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1527),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isFormValid = _foodNameController.text.trim().isNotEmpty && 
                               _caloriesController.text.trim().isNotEmpty;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  top: 24,
                  left: 24,
                  right: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Bottom Sheet
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            doc == null ? 'Log Your Meal' : 'Edit Meal Log',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.grey),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Input: Nama Makanan
                      TextFormField(
                        controller: _foodNameController,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        decoration: _buildInputDecoration('What did you eat?', Icons.restaurant_menu_rounded),
                        onChanged: (value) => setModalState(() {}),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Input: Bilangan Kalori
                      TextFormField(
                        controller: _caloriesController,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration('Calories (kcal)', Icons.local_fire_department_rounded),
                        onChanged: (value) => setModalState(() {}),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          if (int.tryParse(value) == null) return 'Must be numeric';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // SEKSYEN INTERAKTIF BARU: Kategori Chips (Ganti Dropdown)
                      const Text(
                        'Select Meal Type',
                        style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: _mealConfigs.keys.map((type) {
                            bool isSelected = _selectedMealType == type;
                            Color activeColor = _mealConfigs[type]!['color'];
                            IconData icon = _mealConfigs[type]!['icon'];

                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    _selectedMealType = type;
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? activeColor.withOpacity(0.15) : const Color(0xFF060A13),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? activeColor : Colors.white.withOpacity(0.05),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(icon, color: isSelected ? activeColor : Colors.grey, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        type,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.grey,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Butang Simpan Dinamik
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mealConfigs[_selectedMealType]!['color'], 
                            disabledBackgroundColor: Colors.white.withOpacity(0.05),
                            foregroundColor: const Color(0xFF060A13),
                            disabledForegroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: isFormValid ? 4 : 0,
                          ),
                          onPressed: isFormValid ? () => _saveMealEntry(doc) : null,
                          icon: Icon(doc == null ? Icons.add_task_rounded : Icons.save_rounded),
                          label: Text(
                            doc == null ? 'Log This Meal' : 'Update Log',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF00E5FF), size: 22),
      filled: true,
      fillColor: const Color(0xFF060A13),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
      ),
    );
  }

  Future<void> _saveMealEntry(DocumentSnapshot? doc) async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final String todayStr = _getTodayString();

    final Map<String, dynamic> mealData = {
      'foodName': _foodNameController.text.trim(),
      'calories': int.parse(_caloriesController.text.trim()),
      'mealType': _selectedMealType,
      'date': todayStr,
      'createdAt': doc == null ? FieldValue.serverTimestamp() : doc['createdAt'],
    };

    try {
      if (doc == null) {
        // Tambah rekod baru
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('daily_calories')
            .add(mealData);
      } else {
        // Kemas kini rekod sedia ada
        await doc.reference.update(mealData);
      }

      // --- PANGGIL FUNGSI SYNC SELEPAS BERJAYA SIMPAN/UPDATE ---
      await _syncDailyTotalToHistory();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _deleteMealEntry(DocumentSnapshot doc) async {
    try {
      // Padam rekod
      await doc.reference.delete();

      // --- PANGGIL FUNGSI SYNC SELEPAS BERJAYA PADAM ---
      await _syncDailyTotalToHistory();

    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final String todayStr = _getTodayString();

    return Scaffold(
      backgroundColor: const Color(0xFF060A13),
      appBar: AppBar(
        title: const Text('NutriTrack', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        centerTitle: true,
        backgroundColor: const Color(0xFF060A13),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00E5FF),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () {
          HapticFeedback.lightImpact();
          _openMealBottomSheet();
        },
        icon: const Icon(Icons.add_rounded, color: Color(0xFF060A13), size: 24),
        label: const Text("Log Meal", style: TextStyle(color: Color(0xFF060A13), fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('daily_calories')
            .where('date', isEqualTo: todayStr)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
          }

          final docs = snapshot.data?.docs ?? [];
          int totalBreakfast = 0, totalLunch = 0, totalDinner = 0, totalSnack = 0;
          List<DocumentSnapshot> bList = [], lList = [], dList = [], sList = [];

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final int cal = data['calories'] ?? 0;
            final String type = data['mealType'] ?? 'Breakfast';

            if (type == 'Breakfast') { totalBreakfast += cal; bList.add(doc); }
            else if (type == 'Lunch') { totalLunch += cal; lList.add(doc); }
            else if (type == 'Dinner') { totalDinner += cal; dList.add(doc); }
            else if (type == 'Snack') { totalSnack += cal; sList.add(doc); }
          }

          int totalConsumed = totalBreakfast + totalLunch + totalDinner + totalSnack;
          int remaining = _calorieGoal - totalConsumed;
          bool isExceeded = totalConsumed > _calorieGoal;
          double progressRatio = (totalConsumed / _calorieGoal).clamp(0.0, 1.0);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- GLOWING PREMIUM DASHBOARD CARD ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF16223F), Color(0xFF0D1527)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.03)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("TODAY'S TOTAL", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("$totalConsumed", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                                const SizedBox(width: 4),
                                const Padding(padding: EdgeInsets.only(bottom: 6), child: Text("kcal", style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold))),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                _buildMiniStat("Goal", "$_calorieGoal"),
                                const SizedBox(width: 32),
                                _buildMiniStat(
                                  isExceeded ? "Over" : "Left", 
                                  "${remaining.abs()}",
                                  vColor: isExceeded ? Colors.redAccent : const Color(0xFF00E5FF),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Progress Ring
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 95,
                            height: 95,
                            child: CircularProgressIndicator(
                              value: progressRatio,
                              strokeWidth: 9,
                              backgroundColor: Colors.white.withOpacity(0.03),
                              strokeCap: StrokeCap.round,
                              valueColor: AlwaysStoppedAnimation<Color>(isExceeded ? Colors.redAccent : const Color(0xFF00E5FF)),
                            ),
                          ),
                          Column(
                            children: [
                              Text("${(progressRatio * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                              Text("filled", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (isExceeded) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                        SizedBox(width: 10),
                        Text("Calorie limit exceeded!", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                const Text('Summary Analytics', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                const SizedBox(height: 16),
                
                // Grid Kad Maklumat Statistik yang Cantik
                Row(
                  children: [
                    Expanded(child: _buildStatGridCard('Breakfast', totalBreakfast, _mealConfigs['Breakfast']!['color'], _mealConfigs['Breakfast']!['icon'])),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatGridCard('Lunch', totalLunch, _mealConfigs['Lunch']!['color'], _mealConfigs['Lunch']!['icon'])),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatGridCard('Dinner', totalDinner, _mealConfigs['Dinner']!['color'], _mealConfigs['Dinner']!['icon'])),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatGridCard('Snacks', totalSnack, _mealConfigs['Snack']!['color'], _mealConfigs['Snack']!['icon'])),
                  ],
                ),

                const SizedBox(height: 32),
                const Text('Logged Meals', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                const SizedBox(height: 16),

                docs.isEmpty 
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          _buildMealGroupList('Breakfast', bList, _mealConfigs['Breakfast']!['color']),
                          _buildMealGroupList('Lunch', lList, _mealConfigs['Lunch']!['color']),
                          _buildMealGroupList('Dinner', dList, _mealConfigs['Dinner']!['color']),
                          _buildMealGroupList('Snacks', sList, _mealConfigs['Snack']!['color']),
                        ],
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, {Color vColor = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: vColor, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatGridCard(String title, int kcal, Color themeColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1527),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.01)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w600)),
              Icon(icon, color: themeColor.withOpacity(0.7), size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text("$kcal kcal", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (kcal / 800).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.02),
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              minHeight: 4,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMealGroupList(String title, List<DocumentSnapshot> items, Color groupColor) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4),
          child: Row(
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                "${items.fold(0, (sum, doc) => sum + ((doc.data() as Map<String, dynamic>)['calories'] as int))} kcal",
                style: TextStyle(color: groupColor, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final doc = items[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                ),
                onDismissed: (direction) => _deleteMealEntry(doc),
                child: InkWell(
                  onTap: () => _openMealBottomSheet(doc: doc),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1527),
                      borderRadius: BorderRadius.circular(20),
                      border: Border(left: BorderSide(color: groupColor, width: 4)), 
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['foodName'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text("Tap to change entry", style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11)),
                            ],
                          ),
                        ),
                        Text("+${data['calories']} kcal", style: TextStyle(color: groupColor, fontSize: 15, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.blur_on_rounded, size: 48, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            const Text("Your plate is empty", style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("Log your food to gamify your health goals today!", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}  