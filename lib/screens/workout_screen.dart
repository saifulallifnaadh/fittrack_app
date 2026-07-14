import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  int _selectedDayIndex = 0; 

  // --- DAPATKAN TARIKH BERDASARKAN HARI YANG DIPILIH PADA KALENDAR ---
  String get _selectedDateStr {
    final now = DateTime.now();
    // Tambah hari berdasarkan index kalendar (0 = Hari ini, 1 = Esok, dll)
    final targetDate = now.add(Duration(days: _selectedDayIndex));
    return "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
  }

  DateTime get _selectedDateTime {
    return DateTime.now().add(Duration(days: _selectedDayIndex));
  }

  // Senarai lalai (Default) jika pengguna buka hari baru
  final List<Map<String, dynamic>> defaultExercises = [
    {'title': 'Push-ups', 'detail1': '3 sets', 'detail2': '15 reps', 'icon': 'fitness_center', 'isCompleted': false},
    {'title': 'Squats', 'detail1': '3 sets', 'detail2': '20 reps', 'icon': 'accessibility_new', 'isCompleted': false},
    {'title': 'Plank', 'detail1': '3 sets', 'detail2': '60 sec', 'icon': 'self_improvement', 'isCompleted': false},
  ];

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'accessibility_new': return Icons.accessibility_new;
      case 'self_improvement': return Icons.self_improvement;
      default: return Icons.fitness_center;
    }
  }

  // --- FUNGSI UPDATE KE FIRESTORE MENGIKUT TARIKH DIPILIH ---
  Future<void> _toggleExercise(int index, List<dynamic> currentList) async {
    // Buat salinan (deep copy) supaya state betul-betul dikemaskini
    List<dynamic> updatedList = List.from(currentList);
    updatedList[index] = Map<String, dynamic>.from(updatedList[index]);
    updatedList[index]['isCompleted'] = !updatedList[index]['isCompleted'];
    
    // Simpan ke dalam subcollection history mengikut TARIKH YANG DIPILIH
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('history') 
        .doc(_selectedDateStr)         
        .set({
      'date': Timestamp.fromDate(_selectedDateTime), // Supaya Progress Screen susun betul
      'exercises': updatedList, 
    }, SetOptions(merge: true));
  }

  void _showReminderBottomSheet() {
    String selectedWorkout = 'Full Body';
    TimeOfDay selectedTime = TimeOfDay.now();
    DateTime selectedDate = DateTime.now(); 

    List<String> workoutTypes = ['Full Body', 'Upper Body', 'Leg Day', 'Cardio', 'Core'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF131A26),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 24.0, right: 24.0, top: 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 25),
                  const Text('Set Workout Reminder', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text('What are you planning to crush?', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: workoutTypes.map((type) {
                      bool isSelected = selectedWorkout == type;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() => selectedWorkout = type);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF9D50BB) : const Color(0xFF1D2633),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? const Color(0xFF9D50BB) : Colors.transparent),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),

                  const Text('When?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(), 
                              lastDate: DateTime.now().add(const Duration(days: 365)), 
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: Color(0xFF9D50BB),
                                      onPrimary: Colors.white,
                                      surface: Color(0xFF131A26),
                                      onSurface: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              setModalState(() => selectedDate = pickedDate);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D2633),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_month, color: Color(0xFF9D50BB), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: Color(0xFF9D50BB),
                                      onPrimary: Colors.white,
                                      surface: Color(0xFF131A26),
                                      onSurface: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedTime != null) {
                              setModalState(() => selectedTime = pickedTime);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D2633),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.access_time, color: Color(0xFF9D50BB), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  selectedTime.format(context), 
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () {
                        Navigator.pop(context); 
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF131A26),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: const BorderSide(color: Color(0xFF9D50BB), width: 1),
                            ),
                            content: Row(
                              children: [
                                const Icon(Icons.notifications_active, color: Color(0xFF9D50BB)),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    'Reminder: $selectedWorkout on ${selectedDate.day}/${selectedDate.month}/${selectedDate.year} at ${selectedTime.format(context)}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                      child: const Text('Set Reminder', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddGymExerciseForm(List<dynamic> currentList) {
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController setsCtrl = TextEditingController();
    TextEditingController repsCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: const Color(0xFF131A26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, 
            left: 24.0, right: 24.0, top: 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text('Add Gym Exercise', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
              
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Exercise Name (e.g. Bench Press)',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF9D50BB))),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: setsCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Sets',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF9D50BB))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: TextField(
                      controller: repsCtrl,
                      keyboardType: TextInputType.text, 
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Reps / Duration',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF9D50BB))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9D50BB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.isNotEmpty && setsCtrl.text.isNotEmpty && repsCtrl.text.isNotEmpty) {
                      
                      List<dynamic> updatedList = List.from(currentList);
                      
                      updatedList.add({
                        'title': nameCtrl.text,
                        'detail1': '${setsCtrl.text} sets',
                        'detail2': '${repsCtrl.text} reps',
                        'icon': 'fitness_center',
                        'isCompleted': false,
                      });
                      
                      // Simpan ke tarikh yang dipilih
                      await FirebaseFirestore.instance.collection('users').doc(userId).collection('history').doc(_selectedDateStr).set({
                        'date': Timestamp.fromDate(_selectedDateTime),
                        'exercises': updatedList,
                      }, SetOptions(merge: true));

                      if (context.mounted) Navigator.pop(context); 
                    }
                  },
                  child: const Text('Add to Workout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Color(0xFF9D50BB)),
            onPressed: _showReminderBottomSheet,
          ),
        ],
      ),
      // --- TARIK DATA BERDASARKAN TARIKH YANG DIPILIH (_selectedDateStr) ---
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('history').doc(_selectedDateStr).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF9D50BB)));
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          
          // Jika data tak wujud untuk hari tersebut, guna senarai default (yang belum tick)
          List<dynamic> exercises = (data != null && data.containsKey('exercises') && data['exercises'] != null) 
              ? data['exercises'] 
              : defaultExercises;

          int completedCount = exercises.where((e) => e['isCompleted'] == true).length;
          double progressVal = exercises.isEmpty ? 0.0 : (completedCount / exercises.length);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Workout Tracker', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text('Consistency today, strength tomorrow.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 25),

                  _buildCalendarStrip(),
                  const SizedBox(height: 30),

                  _buildProgressCard(completedCount, exercises.length, progressVal),
                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDayIndex == 0 ? "Today's Workout" : "Workout Plan", 
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                      Text("${exercises.length} Exercises", style: const TextStyle(color: Color(0xFF9D50BB), fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 15),

                  ...List.generate(exercises.length, (index) => _buildExerciseTile(index, exercises)),
                  
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B2CBF), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () => _showAddGymExerciseForm(exercises),
                      
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Add Exercise', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40), 
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildCalendarStrip() {
    DateTime today = DateTime.now(); 
    List<String> dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 85, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal, 
        physics: const BouncingScrollPhysics(), 
        itemCount: 30, 
        itemBuilder: (context, index) {
          DateTime date = today.add(Duration(days: index));
          
          String dayString = dayNames[date.weekday - 1]; 
          String dateString = date.day.toString();

          bool isSelected = _selectedDayIndex == index;
          
          return GestureDetector(
            onTap: () {
              setState(() { _selectedDayIndex = index; });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300), 
              margin: const EdgeInsets.only(right: 12), 
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18), 
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF7B2CBF) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.withValues(alpha: 0.2)),
                boxShadow: isSelected 
                    ? [BoxShadow(color: const Color(0xFF7B2CBF).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))] 
                    : [], 
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dayString, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(dateString, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressCard(int completed, int total, double progressVal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161626), 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF9D50BB).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF7B2CBF).withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progressVal,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9D50BB)),
                ),
                Center(
                  child: Text('${(progressVal * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Progress', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text('$completed of $total workouts completed', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.fitness_center, color: Color(0xFF9D50BB), size: 40),
        ],
      ),
    );
  }

  Widget _buildExerciseTile(int index, List<dynamic> currentList) {
    final exercise = currentList[index];
    bool isDone = exercise['isCompleted'] ?? false;
    IconData actualIcon = _getIconData(exercise['icon'] ?? 'fitness_center');

    return GestureDetector(
      onTap: () => _toggleExercise(index, currentList), 
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), 
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF131A26),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isDone ? const Color(0xFF9D50BB).withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.1)),
          boxShadow: isDone ? [BoxShadow(color: const Color(0xFF9D50BB).withValues(alpha: 0.1), blurRadius: 10)] : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFF9D50BB) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isDone ? const Color(0xFF9D50BB) : Colors.grey),
              ),
              child: isDone ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: isDone ? Colors.grey : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                    child: Text(exercise['title'] ?? ''),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.grey, size: 12),
                      const SizedBox(width: 4),
                      Text(exercise['detail1'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 10),
                      const Text('|', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 10),
                      const Icon(Icons.repeat, color: Colors.grey, size: 12),
                      const SizedBox(width: 4),
                      Text(exercise['detail2'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(actualIcon, color: isDone ? Colors.grey : const Color(0xFF9D50BB), size: 28),
          ],
        ),
      ),
    );
  }
}