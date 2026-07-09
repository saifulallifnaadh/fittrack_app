import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Today\'s Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false, 
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- KAD 1: CARTA PAI (RUMUSAN HARI INI) ---
              const Text('Daily Goals', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A26),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 4,
                          centerSpaceRadius: 35,
                          sections: _showingSections(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 30),
                    // Legend
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegend(color: const Color(0xFF00E5FF), text: 'Workout (45%)'),
                          const SizedBox(height: 8),
                          _buildLegend(color: const Color(0xFFFF9800), text: 'Calories (35%)'),
                          const SizedBox(height: 8),
                          _buildLegend(color: const Color(0xFF9D50BB), text: 'Water (20%)'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // --- KAD 2: GRAF BAR (AKTIVITI MINGGUAN) ---
              const Text('Weekly Activity (Minutes)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Container(
                height: 250,
                padding: const EdgeInsets.only(top: 30, bottom: 15, left: 15, right: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A26),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Colors.black87,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.round()} mins',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
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
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      _makeBarData(0, 45), // Mon
                      _makeBarData(1, 60), // Tue
                      _makeBarData(2, 30), // Wed
                      _makeBarData(3, 80), // Thu
                      _makeBarData(4, 50), // Fri
                      _makeBarData(5, 90), // Sat
                      _makeBarData(6, 20), // Sun
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // --- KAD 3: STATISTIK RINGKAS ---
              const Text('Key Metrics', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildMetricCard(Icons.local_fire_department, const Color(0xFFFF9800), 'Burned', '450', 'kcal')),
                  const SizedBox(width: 15),
                  Expanded(child: _buildMetricCard(Icons.directions_walk, const Color(0xFF00E5FF), 'Steps', '8,432', 'steps')),
                ],
              ),
              const SizedBox(height: 30), // Padding bawah
            ],
          ),
        ),
      ),
    );
  }

  // --- FUNGSI BANTUAN UNTUK GRAF PAI ---
  List<PieChartSectionData> _showingSections() {
    return List.generate(3, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 16.0 : 0.0;
      final radius = isTouched ? 35.0 : 25.0;

      switch (i) {
        case 0:
          return PieChartSectionData(color: const Color(0xFF00E5FF), value: 45, title: '45%', radius: radius, titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.black));
        case 1:
          return PieChartSectionData(color: const Color(0xFFFF9800), value: 35, title: '35%', radius: radius, titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.black));
        case 2:
          return PieChartSectionData(color: const Color(0xFF9D50BB), value: 20, title: '20%', radius: radius, titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white));
        default:
          throw Error();
      }
    });
  }

  // --- FUNGSI BANTUAN UNTUK GRAF BAR ---
  BarChartGroupData _makeBarData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFF00E5FF),
          width: 16,
          borderRadius: BorderRadius.circular(6),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100, // Nilai maksimum graf latar belakang
            color: const Color(0xFF131A26).withOpacity(0.5),
          ),
        ),
      ],
    );
  }

 Widget getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12);
    Widget text;
    switch (value.toInt()) {
      case 0: text = const Text('M', style: style); break;
      case 1: text = const Text('T', style: style); break;
      case 2: text = const Text('W', style: style); break;
      case 3: text = const Text('T', style: style); break;
      case 4: text = const Text('F', style: style); break;
      case 5: text = const Text('S', style: style); break;
      case 6: text = const Text('S', style: style); break;
      default: text = const Text('', style: style); break;
    }
    
    // Ganti SideTitleWidget dengan Padding biasa
    return Padding(
      padding: const EdgeInsets.only(top: 10.0), // Jarak teks dari graf
      child: text,
    );
  }

  // --- WIDGET LAIN ---
  Widget _buildLegend({required Color color, required String text}) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildMetricCard(IconData icon, Color color, String title, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF131A26), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}