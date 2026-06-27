import 'package:flutter/material.dart';

class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key});

  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  double? _bmiValue;
  String _bmiCategory = '';
  Color _bmiColor = Colors.white;
  String _bmiMessage = '';
  List<String> _bmiInsights = []; // Untuk simpan maklumat tambahan tentang keputusan

  // Fungsi untuk mengira BMI
  void _calculateBMI() {
    double heightCm = double.tryParse(_heightController.text) ?? 0;
    double weightKg = double.tryParse(_weightController.text) ?? 0;

    if (heightCm > 0 && weightKg > 0) {
      double heightM = heightCm / 100;
      double bmi = weightKg / (heightM * heightM);

      setState(() {
        _bmiValue = bmi;
        _determineBMICategory(bmi);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid height and weight.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fungsi untuk tentukan kategori, mesej, dan maklumat tambahan (insights)
  void _determineBMICategory(double bmi) {
    if (bmi < 18.5) {
      _bmiCategory = 'Underweight';
      _bmiColor = const Color(0xFF5C6BC0); 
      _bmiMessage = 'You are underweight. Consider eating more nutrient-dense foods to reach a healthy weight.';
      _bmiInsights = [
        'Potential Risks: Nutritional deficiencies, weakened immune system, and chronic fatigue.',
        'Recommendation: Focus on a calorie surplus with a balance of lean proteins, healthy fats, and complex carbohydrates.',
        'Fitness Tip: Combine your diet with strength training to build healthy muscle mass rather than just gaining fat.'
      ];
    } else if (bmi >= 18.5 && bmi <= 24.9) {
      _bmiCategory = 'Normal Weight';
      _bmiColor = const Color(0xFF00E676); 
      _bmiMessage = 'Great job! You have a normal body weight. Keep maintaining a healthy lifestyle.';
      _bmiInsights = [
        'Health Status: Lower risk of serious health conditions like heart disease and type 2 diabetes.',
        'Recommendation: Continue your current balanced diet and maintain an active lifestyle to preserve this healthy state.',
        'Fitness Tip: Aim for at least 150 minutes of moderate aerobic activity or 75 minutes of vigorous activity weekly.'
      ];
    } else if (bmi >= 25 && bmi <= 29.9) {
      _bmiCategory = 'Overweight';
      _bmiColor = const Color(0xFFFFA000); 
      _bmiMessage = 'You are slightly overweight. Regular exercise and a balanced diet can help you reach your goals.';
      _bmiInsights = [
        'Potential Risks: Increased strain on the cardiovascular system, joints, and higher risk of metabolic issues.',
        'Recommendation: Implement a modest calorie deficit by reducing portion sizes and cutting down on sugary food or drinks.',
        'Fitness Tip: Incorporate a mix of cardiovascular exercises (like running or cycling) and weight training to maximize fat loss.'
      ];
    } else {
      _bmiCategory = 'Obese';
      _bmiColor = const Color(0xFFE53935); 
      _bmiMessage = 'Your BMI indicates obesity. Consider consulting a healthcare provider for personalized advice.';
      _bmiInsights = [
        'Potential Risks: Elevated risk of high blood pressure, type 2 diabetes, stroke, and cardiovascular diseases.',
        'Recommendation: Focus on sustainable lifestyle changes. It is highly recommended to seek professional guidance from a nutritionist.',
        'Fitness Tip: Start with low-impact exercises such as brisk walking, swimming, or stationary cycling to protect your joints from injury.'
      ];
    }
  }

  // FUNGSI UNTUK TUNJUK MAKLUMAT TAMBAHAN AM TENTANG BMI (BOTTOM SHEET)
  void _showBmiInfoBottomSheet() {
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
            left: 24.0,
            right: 24.0,
            top: 24.0,
            bottom: MediaQuery.of(context).padding.bottom + 24.0, 
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // <-- Pastikan saiz ikut isi kandungan
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('About Body Mass Index (BMI)', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text(
                'BMI is a statistical measurement of body fat based on an individual\'s weight and height. Although it does not measure body fat directly, it is a widely accepted screening tool to categorize health risks associated with weight.',
                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 25),
              const Text('Standard BMI Categories', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildCategoryInfoRow('Underweight', '< 18.5', const Color(0xFF5C6BC0)),
              _buildCategoryInfoRow('Normal Weight', '18.5 – 24.9', const Color(0xFF00E676)),
              _buildCategoryInfoRow('Overweight', '25.0 – 29.9', const Color(0xFFFFA000)),
              _buildCategoryInfoRow('Obese', '≥ 30.0', const Color(0xFFE53935)),
              const SizedBox(height: 15), // Tambah sikit ruang pernafasan kat bawah
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryInfoRow(String title, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          Text(range, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('BMI Calculator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF00E5FF)),
            onPressed: _showBmiInfoBottomSheet, // LINK-KAN BUTANG INFO KE PANEL DI SINI
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF131A26),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.1), blurRadius: 20, spreadRadius: 2),
                ],
              ),
              child: const Icon(Icons.monitor_weight_outlined, color: Color(0xFF00E5FF), size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enter your details to calculate\nyour Body Mass Index',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 40),

            _buildInputField(label: 'Height (cm)', controller: _heightController, icon: Icons.height, suffixText: 'cm'),
            const SizedBox(height: 20),
            _buildInputField(label: 'Weight (kg)', controller: _weightController, icon: Icons.fitness_center, suffixText: 'kg'),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _calculateBMI,
                child: const Text('Calculate', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),

            if (_bmiValue != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({required String label, required TextEditingController controller, required IconData icon, required String suffixText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF131A26),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Icon(icon, color: const Color(0xFF00E5FF), size: 24),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(border: InputBorder.none, hintText: '0', hintStyle: TextStyle(color: Colors.grey)),
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.3)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Text(suffixText, style: const TextStyle(color: Colors.grey, fontSize: 16)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // WIDGET KEPUTUSAN YANG TELAH DITAMBAH MAKLUMAT DETAIL (INSIGHTS)
  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Your BMI', style: TextStyle(color: Colors.grey, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _bmiColor.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: _bmiColor, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(_bmiCategory == 'Normal Weight' ? 'Healthy' : _bmiCategory, style: TextStyle(color: _bmiColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            _bmiValue!.toStringAsFixed(1),
            style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 65, fontWeight: FontWeight.bold),
          ),
          Text(_bmiCategory, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 30),

          Row(
            children: [
              Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF5C6BC0), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(width: 4),
              Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF00E676), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(width: 4),
              Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFFFFA000), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(width: 4),
              Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(2)))),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('18.5', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text('24.9', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text('29.9', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 25),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: const Color(0xFF1D2633), borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _bmiColor, width: 2)),
                  child: Icon(Icons.favorite_border, color: _bmiColor, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _bmiCategory == 'Normal Weight' ? 'Great job!' : 'Take note!',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 5),
                      Text(_bmiMessage, style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // --- BAHAGIAN SEKSYEN BARU: MAKLUMAT TAMBAHAN UNTUK KEPUTUSAN ---
          const SizedBox(height: 30),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Health Insights & Recommendations', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Column(
            children: _bmiInsights.map((insight) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 16, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}