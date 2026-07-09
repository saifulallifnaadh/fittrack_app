import 'package:flutter/material.dart';

class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key});

  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
  // --- STATE VARIABLES ---
  bool _isMetric = true; 

  double _heightCm = 170.0;
  double _weightKg = 65.0;

  double _heightInches = 67.0; 
  double _weightLbs = 143.0;

  double? _bmiValue;
  String _bmiCategory = '';
  Color _bmiColor = Colors.white;
  String _bmiMessage = '';
  List<String> _bmiInsights = [];

  // --- FUNGSI KIRA BMI ---
  void _calculateBMI() {
    double bmi = 0;

    if (_isMetric) {
      double heightM = _heightCm / 100;
      bmi = _weightKg / (heightM * heightM);
    } else {
      bmi = (_weightLbs / (_heightInches * _heightInches)) * 703;
    }

    setState(() {
      _bmiValue = bmi;
      _determineBMICategory(bmi);
    });

    // --- PANGGIL POPUP KEPUTUSAN SELEPAS KIRA ---
    _showResultBottomSheet();
  }

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

  // --- FUNGSI POPUP UNTUK TUNJUK KEPUTUSAN BMI ---
  void _showResultBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Buat transparent sebab kita nak design kotak sendiri
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF090E17), // Warna background utama aplikasi
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- GARISAN DRAG (HANDLE) ---
                    Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3), 
                        borderRadius: BorderRadius.circular(10)
                      ),
                    ),
                    // --- MASUKKAN KAD KEPUTUSAN ---
                    _buildResultCard(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- FUNGSI POPUP UNTUK TAIP NOMBOR ---
  void _showInputDialog(String title, bool isHeight) {
    TextEditingController ctrl1 = TextEditingController();
    TextEditingController ctrl2 = TextEditingController(); 

    if (isHeight) {
       if (_isMetric) ctrl1.text = _heightCm.toInt().toString();
       else {
          ctrl1.text = (_heightInches ~/ 12).toString();
          ctrl2.text = (_heightInches % 12).toInt().toString();
       }
    } else {
       ctrl1.text = _isMetric ? _weightKg.toInt().toString() : _weightLbs.toInt().toString();
    }

    showDialog(
      context: context,
      builder: (context) {
         return AlertDialog(
            backgroundColor: const Color(0xFF131A26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Enter $title', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: _isMetric || !isHeight 
               ? TextField(
                   controller: ctrl1,
                   keyboardType: TextInputType.number,
                   style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                   decoration: InputDecoration(
                      suffixText: isHeight ? 'cm' : (_isMetric ? 'kg' : 'lbs'), 
                      suffixStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF))),
                   ),
                   autofocus: true,
                 )
               : Row(
                   children: [
                     Expanded(
                       child: TextField(
                         controller: ctrl1, 
                         keyboardType: TextInputType.number, 
                         style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), 
                         decoration: const InputDecoration(
                           suffixText: 'ft',
                           suffixStyle: TextStyle(color: Colors.grey),
                           enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                           focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF))),
                         ),
                         autofocus: true,
                       )
                     ),
                     const SizedBox(width: 15),
                     Expanded(
                       child: TextField(
                         controller: ctrl2, 
                         keyboardType: TextInputType.number, 
                         style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), 
                         decoration: const InputDecoration(
                           suffixText: 'in',
                           suffixStyle: TextStyle(color: Colors.grey),
                           enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                           focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF))),
                         )
                       )
                     ),
                   ]
                 ),
            actions: [
               TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
               ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                  onPressed: () {
                     setState((){
                        if (isHeight) {
                           if (_isMetric) {
                              _heightCm = double.tryParse(ctrl1.text) ?? _heightCm;
                              _heightCm = _heightCm.clamp(100.0, 250.0); 
                           } else {
                              _heightInches = (double.tryParse(ctrl1.text) ?? 0) * 12 + (double.tryParse(ctrl2.text) ?? 0);
                              _heightInches = _heightInches.clamp(40.0, 98.0);
                           }
                        } else {
                           if (_isMetric) {
                              _weightKg = double.tryParse(ctrl1.text) ?? _weightKg;
                              _weightKg = _weightKg.clamp(30.0, 200.0);
                           } else {
                              _weightLbs = double.tryParse(ctrl1.text) ?? _weightLbs;
                              _weightLbs = _weightLbs.clamp(66.0, 440.0);
                           }
                        }
                        _bmiValue = null; 
                     });
                     Navigator.pop(context);
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
               )
            ]
         );
      }
    );
  }

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
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 15), 
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
            onPressed: _showBmiInfoBottomSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 20.0, bottom: 40.0), // Dah tak perlukan padding bawah terlalu besar
          child: Column(
            children: [
              // --- SUIS TOGGLE UNIT ---
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF131A26),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isMetric = true;
                            _bmiValue = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isMetric ? const Color(0xFF00E5FF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Text('Metric', style: TextStyle(color: _isMetric ? Colors.black : Colors.grey, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isMetric = false;
                            _bmiValue = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isMetric ? const Color(0xFF00E5FF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Text('Imperial', style: TextStyle(color: !_isMetric ? Colors.black : Colors.grey, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- WIDGET INTERAKTIF TINGGI ---
              _buildInteractiveHeight(),
              const SizedBox(height: 20),

              // --- WIDGET INTERAKTIF BERAT ---
              _buildInteractiveWeight(),
              const SizedBox(height: 30),

              // --- BUTANG KIRA ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _calculateBMI,
                  child: const Text('Calculate BMI', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              
              // KITA DAH BUANG _buildResultCard() DARI SINI
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET TINGGI (HEIGHT) ---
  Widget _buildInteractiveHeight() {
    String displayHeight = _isMetric 
        ? '${_heightCm.toInt()} cm' 
        : '${(_heightInches ~/ 12)}\' ${(_heightInches % 12).toInt()}"';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text('Height', style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _showInputDialog('Height', true),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _isMetric ? _heightCm.toInt().toString() : displayHeight,
                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                ),
                if (_isMetric) const Text(' cm', style: TextStyle(color: Colors.grey, fontSize: 20)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _buildCircleButton(
                icon: Icons.remove, 
                onPressed: () {
                  setState(() {
                    _bmiValue = null;
                    if (_isMetric && _heightCm > 100) _heightCm--;
                    if (!_isMetric && _heightInches > 40) _heightInches--;
                  });
                }
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF00E5FF),
                    inactiveTrackColor: Colors.grey.withOpacity(0.3),
                    thumbColor: const Color(0xFF00E5FF),
                    overlayColor: const Color(0xFF00E5FF).withOpacity(0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _isMetric ? _heightCm : _heightInches,
                    min: _isMetric ? 100.0 : 40.0,
                    max: _isMetric ? 250.0 : 98.0,
                    onChanged: (newValue) {
                      setState(() {
                        _bmiValue = null; 
                        if (_isMetric) _heightCm = newValue;
                        else _heightInches = newValue;
                      });
                    },
                  ),
                ),
              ),
              _buildCircleButton(
                icon: Icons.add, 
                onPressed: () {
                  setState(() {
                    _bmiValue = null;
                    if (_isMetric && _heightCm < 250) _heightCm++;
                    if (!_isMetric && _heightInches < 98) _heightInches++;
                  });
                }
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET BERAT (WEIGHT) ---
  Widget _buildInteractiveWeight() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text('Weight', style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _showInputDialog('Weight', false),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _isMetric ? _weightKg.toInt().toString() : _weightLbs.toInt().toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                ),
                Text(_isMetric ? ' kg' : ' lbs', style: const TextStyle(color: Colors.grey, fontSize: 20)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _buildCircleButton(
                icon: Icons.remove, 
                onPressed: () {
                  setState(() {
                    _bmiValue = null;
                    if (_isMetric && _weightKg > 30) _weightKg--;
                    if (!_isMetric && _weightLbs > 66) _weightLbs--;
                  });
                }
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF00E5FF),
                    inactiveTrackColor: Colors.grey.withOpacity(0.3),
                    thumbColor: const Color(0xFF00E5FF),
                    overlayColor: const Color(0xFF00E5FF).withOpacity(0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _isMetric ? _weightKg : _weightLbs,
                    min: _isMetric ? 30.0 : 66.0,
                    max: _isMetric ? 200.0 : 440.0,
                    onChanged: (newValue) {
                      setState(() {
                        _bmiValue = null; 
                        if (_isMetric) _weightKg = newValue;
                        else _weightLbs = newValue;
                      });
                    },
                  ),
                ),
              ),
              _buildCircleButton(
                icon: Icons.add, 
                onPressed: () {
                  setState(() {
                    _bmiValue = null;
                    if (_isMetric && _weightKg < 200) _weightKg++;
                    if (!_isMetric && _weightLbs < 440) _weightLbs++;
                  });
                }
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 45,
        height: 45,
        decoration: const BoxDecoration(
          color: Color(0xFF1D2633),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  // --- KAD KEPUTUSAN BMI (SEKARANG MUNCUL DI POPUP) ---
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