import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  int touchedIndex = -1;
  int _touchedBarIndex = -1; 
  bool _showRawValues = false;
  
  Stream<QuerySnapshot>? _weeklySummaryStream;

  final List<String> _weekDaysFull = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  String get _todayStr {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    
    // Tarikh hari Isnin untuk minggu ini (supaya kita ambil data seminggu sahaja)
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final String startStr = "${startOfWeek.year}-${startOfWeek.month.toString().padLeft(2, '0')}-${startOfWeek.day.toString().padLeft(2, '0')}";

    // BACA KESELURUHAN DATA MINGGU INI SAHAJA
    _weeklySummaryStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('history')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startStr)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Today\'s Summary', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 24)
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, 
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _weeklySummaryStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
          }

          // Variabel untuk Daily Goals (Hari Ini Sahaja)
          double workoutPerc = 0.0;
          double caloriesPerc = 0.0;
          double waterPerc = 0.0;
          int completedWorkouts = 0;
          int totalWorkouts = 3;
          int caloriesBurned = 0;
          int waterIntake = 0;
          int totalSteps = 0;

          // Variabel untuk Graf Mingguan
          List<double> weeklyActiveMinutes = List.filled(7, 0.0);

          if (snapshot.hasData && snapshot.data != null) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              
              // --- 1. PROSES DATA GRAF MINGGUAN ---
              try {
                DateTime docDate = DateTime.parse(doc.id);
                int dayIndex = docDate.weekday - 1; // 0 = Isnin, 6 = Ahad

                // Logik Pintar: Gabungkan masa Dashboard, GPS Larian, dan Senaman Gym
                double rawDashboardTicks = (data['active_minutes'] ?? 0).toDouble();
                double dashboardMins = rawDashboardTicks / 6.0; // 1 tick = 10 saat
                double runMins = (data['run_distance'] ?? 0).toDouble() * 10.0; // Anggar 10 minit per km
                
                List<dynamic> exercises = data.containsKey('exercises') ? data['exercises'] : [];
                double gymMins = exercises.where((e) => e['isCompleted'] == true).length * 15.0; // Anggar 15 minit per senaman

                weeklyActiveMinutes[dayIndex] = dashboardMins + runMins + gymMins;
              } catch (e) {
                // Abaikan ralat parsing format tarikh
              }

              // --- 2. PROSES DATA HARIAN (KAD ATAS) ---
              if (doc.id == _todayStr) {
                waterIntake = data.containsKey('water_intake') ? data['water_intake'] : 0;
                waterPerc = (waterIntake / 2500).clamp(0.0, 1.0); 

                List<dynamic> exercises = data.containsKey('exercises') ? data['exercises'] : [];
                completedWorkouts = exercises.where((e) => e['isCompleted'] == true).length;
                totalWorkouts = exercises.isEmpty ? 3 : exercises.length;
                workoutPerc = totalWorkouts == 0 ? 0.0 : (completedWorkouts / totalWorkouts).clamp(0.0, 1.0);

                if (data.containsKey('total_calories')) {
                  caloriesBurned = (data['total_calories'] as num).toInt();
                } else if (data.containsKey('calories_burned')) {
                  caloriesBurned = (data['calories_burned'] as num).toInt();
                }
                caloriesPerc = (caloriesBurned / 2000).clamp(0.0, 1.0); 

                totalSteps = data.containsKey('steps') ? data['steps'] : 0;
              }
            }
          }

          String formattedSteps = NumberFormat.decimalPattern().format(totalSteps);
          String todayDisplay = DateFormat('EEEE, dd MMM yyyy').format(DateTime.now());

          // Logik Carta Bar Mingguan Terkini
          double maxMins = weeklyActiveMinutes.reduce((a, b) => a > b ? a : b);
          double chartMaxY = maxMins > 100 ? maxMins + 20 : 100; // Auto-scale graf kalau lebih 100 minit

          double weeklyTotal = weeklyActiveMinutes.fold(0.0, (a, b) => a + b);
          String readoutValue = _touchedBarIndex == -1 
              ? (weeklyTotal / 7).toStringAsFixed(0) 
              : weeklyActiveMinutes[_touchedBarIndex].toInt().toString();

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER TARIKH ---
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A26),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.05), blurRadius: 15, spreadRadius: 1)
                        ]
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: Color(0xFF00E5FF), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            todayDisplay,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),

                  // --- KAD MOTIVASI ---
                  _BouncingCard(
                    child: _buildMotivationalBanner(workoutPerc, caloriesPerc, waterPerc)
                  ),
                  const SizedBox(height: 40),

                  // --- KAD 1: ACTIVITY RINGS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('DAILY GOALS', Icons.track_changes_rounded, const Color(0xFF00E5FF)),
                      Text(
                        'Tap card to toggle', 
                        style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 11, fontStyle: FontStyle.italic)
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _BouncingCard(
                    onTap: () {
                      setState(() {
                        _showRawValues = !_showRawValues;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 26),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A26),
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(color: Colors.white.withOpacity(0.04)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 170, 
                            width: 170,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                                      child: Icon(
                                        _showRawValues ? Icons.numbers_rounded : Icons.percent_rounded,
                                        key: ValueKey<bool>(_showRawValues),
                                        color: Colors.grey.withOpacity(0.3),
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      child: Text(
                                        _showRawValues ? 'VALUES' : 'PERCENT',
                                        key: ValueKey<bool>(_showRawValues),
                                        style: TextStyle(color: Colors.grey.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 170, width: 170,
                                  child: CircularProgressIndicator(value: workoutPerc, strokeWidth: 14, backgroundColor: const Color(0xFF00E5FF).withOpacity(0.12), color: const Color(0xFF00E5FF), strokeCap: StrokeCap.round),
                                ),
                                SizedBox(
                                  height: 130, width: 130,
                                  child: CircularProgressIndicator(value: caloriesPerc, strokeWidth: 14, backgroundColor: const Color(0xFFFF9800).withOpacity(0.12), color: const Color(0xFFFF9800), strokeCap: StrokeCap.round),
                                ),
                                SizedBox(
                                  height: 90, width: 90,
                                  child: CircularProgressIndicator(value: waterPerc, strokeWidth: 14, backgroundColor: const Color(0xFF9D50BB).withOpacity(0.12), color: const Color(0xFF9D50BB), strokeCap: StrokeCap.round),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          _buildLegendRow(
                            icon: Icons.fitness_center_rounded,
                            color: const Color(0xFF00E5FF),
                            title: 'Workout',
                            val: _showRawValues ? '$completedWorkouts / $totalWorkouts' : '${(workoutPerc * 100).toInt()}%',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14), 
                            child: Divider(color: Colors.white10, height: 1)
                          ),
                          _buildLegendRow(
                            icon: Icons.local_fire_department_rounded,
                            color: const Color(0xFFFF9800),
                            title: 'Calories',
                            val: _showRawValues ? '$caloriesBurned / 2000' : '${(caloriesPerc * 100).toInt()}%',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14), 
                            child: Divider(color: Colors.white10, height: 1)
                          ),
                          _buildLegendRow(
                            icon: Icons.water_drop_rounded,
                            color: const Color(0xFF9D50BB),
                            title: 'Water',
                            val: _showRawValues ? '$waterIntake / 2500' : '${(waterPerc * 100).toInt()}%',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 45),

                  // --- KAD 2: GRAF BAR MINGGUAN LIVE SYNC ---
                  _buildSectionTitle('WEEKLY ACTIVITY', Icons.bar_chart_rounded, const Color(0xFF9D50BB)),
                  const SizedBox(height: 15),
                  _BouncingCard(
                    child: Container(
                      padding: const EdgeInsets.only(top: 30, bottom: 20, left: 15, right: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A26),
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: Column(
                        children: [
                          // PAPARAN DIGITAL BERANIMASI (READOUT)
                          SizedBox(
                            height: 85, 
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                              child: Column(
                                key: ValueKey<int>(_touchedBarIndex),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _touchedBarIndex == -1 ? 'WEEKLY AVERAGE' : _weekDaysFull[_touchedBarIndex].toUpperCase(),
                                    style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            readoutValue,
                                            style: TextStyle(
                                              color: _touchedBarIndex == -1 ? Colors.white : const Color(0xFF00E5FF),
                                              fontSize: 38,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -1,
                                              shadows: _touchedBarIndex != -1 ? [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.5), blurRadius: 15)] : [],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text('min', style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          
                          // GRAF BAR MINIMALIS INTERAKTIF
                          SizedBox(
                            height: 180,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: chartMaxY,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  handleBuiltInTouches: false, 
                                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions || barTouchResponse == null || barTouchResponse.spot == null) {
                                        _touchedBarIndex = -1;
                                        return;
                                      }
                                      if (_touchedBarIndex != barTouchResponse.spot!.touchedBarGroupIndex) {
                                        HapticFeedback.selectionClick();
                                      }
                                      _touchedBarIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                                    });
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget: getBottomTitles,
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                gridData: FlGridData(
                                  show: true, 
                                  drawVerticalLine: false,
                                  horizontalInterval: chartMaxY / 4,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(color: Colors.white.withOpacity(0.04), strokeWidth: 1, dashArray: [6, 6]);
                                  }
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: List.generate(7, (i) => _makeInteractiveBarData(i, weeklyActiveMinutes[i], i == _touchedBarIndex, chartMaxY)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 45),

                  // --- KAD 3: STATISTIK RINGKAS ---
                  _buildSectionTitle('KEY METRICS', Icons.insights_rounded, const Color(0xFFFF9800)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard(Icons.local_fire_department_rounded, const Color(0xFFFF9800), 'Calories', '$caloriesBurned', 'kcal')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildMetricCard(Icons.directions_walk_rounded, const Color(0xFF00E5FF), 'Steps', formattedSteps, 'steps')),
                    ],
                  ),
                  const SizedBox(height: 50), 
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(
          title, 
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)
        ),
      ],
    );
  }

  Widget _buildMotivationalBanner(double workout, double calories, double water) {
    String title;
    String message;
    IconData icon;
    Color themeColor;
    List<Color> gradientColors;

    double avg = (workout + calories + water) / 3;

    if (avg == 0) {
      title = "READY TO START?";
      message = "Setiap langkah besar bermula dari satu langkah kecil. Jom mulakan aktiviti pertama hari ini! 🚀";
      icon = Icons.directions_run_rounded;
      themeColor = const Color(0xFF00E5FF);
      gradientColors = [const Color(0xFF00E5FF).withOpacity(0.15), const Color(0xFF0088FF).withOpacity(0.02)];
    } else if (avg < 0.4) {
      title = "GOOD START!";
      message = "You've got a great start! A little progress is still progress. Consistency is the key! 🔥";
      icon = Icons.local_fire_department_rounded;
      themeColor = const Color(0xFFFF9800);
      gradientColors = [const Color(0xFFFF9800).withOpacity(0.15), const Color(0xFFFF5722).withOpacity(0.02)];
    } else if (avg < 0.8) {
      title = "IN THE ZONE!";
      message = "You're crushing it! You're already more than halfway through today's goals. Keep going! 💪";
      icon = Icons.bolt_rounded;
      themeColor = const Color(0xFF9D50BB);
      gradientColors = [const Color(0xFF9D50BB).withOpacity(0.15), const Color(0xFF6E00FF).withOpacity(0.02)];
    } else {
      title = "GOAL CRUSHER!";
      message = "Outstanding! You've successfully completed today's mission. Salute to you! 🏆";
      icon = Icons.emoji_events_rounded;
      themeColor = Colors.amber;
      gradientColors = [Colors.amber.withOpacity(0.15), Colors.orange.withOpacity(0.02)];
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: themeColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: themeColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))
        ]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: themeColor, size: 32),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: themeColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeInteractiveBarData(int x, double y, bool isTouched, double maxY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: isTouched
              ? const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF00E5FF)], begin: Alignment.bottomCenter, end: Alignment.topCenter) 
              : const LinearGradient(colors: [Color(0xFF00B4D8), Color(0xFF00E5FF)], begin: Alignment.bottomCenter, end: Alignment.topCenter), 
          width: isTouched ? 26 : 18, 
          borderRadius: BorderRadius.circular(8),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY, 
            color: isTouched ? const Color(0xFF00E5FF).withOpacity(0.15) : Colors.white.withOpacity(0.03), 
          ),
        ),
      ],
    );
  }

  Widget getBottomTitles(double value, TitleMeta meta) {
    bool isTouched = value.toInt() == _touchedBarIndex;
    final style = TextStyle(
      color: isTouched ? const Color(0xFF00E5FF) : Colors.grey.withOpacity(0.5), 
      fontWeight: isTouched ? FontWeight.w900 : FontWeight.bold, 
      fontSize: isTouched ? 15 : 12,
    );
    
    Widget text;
    switch (value.toInt()) {
      case 0: text = Text('M', style: style); break;
      case 1: text = Text('T', style: style); break;
      case 2: text = Text('W', style: style); break;
      case 3: text = Text('T', style: style); break;
      case 4: text = Text('F', style: style); break;
      case 5: text = Text('S', style: style); break;
      case 6: text = Text('S', style: style); break;
      default: text = Text('', style: style); break;
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 10.0), 
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: text,
      )
    );
  }

  Widget _buildLegendRow({required IconData icon, required Color color, required String title, required String val}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            val, 
            key: ValueKey<String>(val), 
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(IconData icon, Color color, String title, String value, String unit) {
    return _BouncingCard(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        decoration: BoxDecoration(
          color: const Color(0xFF131A26), 
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value, 
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(unit, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BouncingCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  
  const _BouncingCard({required this.child, this.onTap});

  @override
  State<_BouncingCard> createState() => _BouncingCardState();
}

class _BouncingCardState extends State<_BouncingCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = false);
        if (widget.onTap != null) widget.onTap!();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}