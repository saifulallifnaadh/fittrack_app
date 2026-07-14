import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 

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

  // Variabel untuk animasi butang "Calculate"
  bool _isCalcPressed = false;

  // --- FUNGSI KIRA BMI ---
  void _calculateBMI() {
    HapticFeedback.mediumImpact(); // Gegaran bila tekan calculate
    
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

    _showResultBottomSheet();
  }

  void _determineBMICategory(double bmi) {
    if (bmi < 18.5) {
      _bmiCategory = 'Underweight';
      _bmiColor = const Color(0xFF5C6BC0); // Indigo
      _bmiMessage = 'You are underweight. Consider eating more nutrient-dense foods to reach a healthy weight.';
      _bmiInsights = [
        'Potential Risks: Nutritional deficiencies, weakened immune system, and chronic fatigue.',
        'Recommendation: Focus on a calorie surplus with a balance of lean proteins, healthy fats, and complex carbohydrates.',
        'Fitness Tip: Combine your diet with strength training to build healthy muscle mass rather than just gaining fat.'
      ];
    } else if (bmi >= 18.5 && bmi <= 24.9) {
      _bmiCategory = 'Normal Weight';
      _bmiColor = const Color(0xFF00E676); // Green
      _bmiMessage = 'Great job! You have a normal body weight. Keep maintaining a healthy lifestyle.';
      _bmiInsights = [
        'Health Status: Lower risk of serious health conditions like heart disease and type 2 diabetes.',
        'Recommendation: Continue your current balanced diet and maintain an active lifestyle to preserve this healthy state.',
        'Fitness Tip: Aim for at least 150 minutes of moderate aerobic activity or 75 minutes of vigorous activity weekly.'
      ];
    } else if (bmi >= 25 && bmi <= 29.9) {
      _bmiCategory = 'Overweight';
      _bmiColor = const Color(0xFFFFA000); // Amber
      _bmiMessage = 'You are slightly overweight. Regular exercise and a balanced diet can help you reach your goals.';
      _bmiInsights = [
        'Potential Risks: Increased strain on the cardiovascular system, joints, and higher risk of metabolic issues.',
        'Recommendation: Implement a modest calorie deficit by reducing portion sizes and cutting down on sugary food or drinks.',
        'Fitness Tip: Incorporate a mix of cardiovascular exercises (like running or cycling) and weight training to maximize fat loss.'
      ];
    } else {
      _bmiCategory = 'Obese';
      _bmiColor = const Color(0xFFE53935); // Red
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
      backgroundColor: Colors.transparent, 
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF090E17), 
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              border: Border.all(color: _bmiColor.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(color: _bmiColor.withValues(alpha: 0.1), blurRadius: 40, spreadRadius: 5)
              ],
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 25),
                      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                    ),
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
    HapticFeedback.selectionClick();
    TextEditingController ctrl1 = TextEditingController();
    TextEditingController ctrl2 = TextEditingController(); 

    if (isHeight) {
       if (_isMetric) {
         ctrl1.text = _heightCm.toInt().toString();
       } else {
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
            // FIX BORDER ERROR: Guna 'side' untuk RoundedRectangleBorder
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24), 
              side: BorderSide(color: const Color(0xFF00E5FF).withValues(alpha: 0.3))
            ),
            title: Text('Enter $title', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: _isMetric || !isHeight 
                ? TextField(
                    controller: ctrl1,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                       suffixText: isHeight ? 'cm' : (_isMetric ? 'kg' : 'lbs'), 
                       suffixStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                       enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                       focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF), width: 2)),
                    ),
                    autofocus: true,
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ctrl1, 
                          keyboardType: TextInputType.number, 
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), 
                          decoration: const InputDecoration(
                            suffixText: 'ft',
                            suffixStyle: TextStyle(color: Colors.grey, fontSize: 16),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF), width: 2)),
                          ),
                          autofocus: true,
                        )
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          controller: ctrl2, 
                          keyboardType: TextInputType.number, 
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), 
                          decoration: const InputDecoration(
                            suffixText: 'in',
                            suffixStyle: TextStyle(color: Colors.grey, fontSize: 16),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF), width: 2)),
                          )
                        )
                      ),
                    ]
                  ),
            actions: [
               TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
               ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: () {
                     HapticFeedback.lightImpact();
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24.0, right: 24.0, top: 24.0,
            bottom: MediaQuery.of(context).padding.bottom + 24.0, 
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 25),
              const Row(
                children: [
                  Icon(Icons.info, color: Color(0xFF00E5FF), size: 28),
                  SizedBox(width: 10),
                  Text('About BMI', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                'BMI is a statistical measurement of body fat based on an individual\'s weight and height. Although it does not measure body fat directly, it is a widely accepted screening tool to categorize health risks associated with weight.',
                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 30),
              const Text('Standard Categories', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF090E17), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                child: Column(
                  children: [
                    _buildCategoryInfoRow('Underweight', '< 18.5', const Color(0xFF5C6BC0)),
                    const Divider(color: Colors.white10, height: 20),
                    _buildCategoryInfoRow('Normal Weight', '18.5 – 24.9', const Color(0xFF00E676)),
                    const Divider(color: Colors.white10, height: 20),
                    _buildCategoryInfoRow('Overweight', '25.0 – 29.9', const Color(0xFFFFA000)),
                    const Divider(color: Colors.white10, height: 20),
                    _buildCategoryInfoRow('Obese', '≥ 30.0', const Color(0xFFE53935)),
                  ],
                ),
              ),
              const SizedBox(height: 15), 
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryInfoRow(String title, String range, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)])),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        Text(range, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
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
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 10.0, bottom: 40.0),
          child: Column(
            children: [
              // --- SUIS TOGGLE UNIT (ANIMATED) ---
              Container(
                height: 55,
                decoration: BoxDecoration(
                  color: const Color(0xFF131A26),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() { _isMetric = true; _bmiValue = null; });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _isMetric ? const Color(0xFF00E5FF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isMetric ? [BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.3), blurRadius: 10)] : [],
                          ),
                          child: Center(
                            child: Text('Metric', style: TextStyle(color: _isMetric ? Colors.black : Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() { _isMetric = false; _bmiValue = null; });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: !_isMetric ? const Color(0xFF00E5FF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: !_isMetric ? [BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.3), blurRadius: 10)] : [],
                          ),
                          child: Center(
                            child: Text('Imperial', style: TextStyle(color: !_isMetric ? Colors.black : Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),

              // --- WIDGET INTERAKTIF TINGGI ---
              _buildInteractiveHeight(),
              const SizedBox(height: 25),

              // --- WIDGET INTERAKTIF BERAT ---
              _buildInteractiveWeight(),
              const SizedBox(height: 40),

              // --- BUTANG KIRA (ANIMATED & GLOWING) ---
              GestureDetector(
                onTapDown: (_) => setState(() => _isCalcPressed = true),
                onTapUp: (_) {
                  setState(() => _isCalcPressed = false);
                  _calculateBMI();
                },
                onTapCancel: () => setState(() => _isCalcPressed = false),
                child: AnimatedScale(
                  scale: _isCalcPressed ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    width: double.infinity,
                    height: 65,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF00B4D8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: _isCalcPressed 
                        ? [] 
                        : [BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: const Center(
                      child: Text('Calculate BMI', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    ),
                  ),
                ),
              ),
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
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Text('HEIGHT', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: () => _showInputDialog('Height', true),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _isMetric ? _heightCm.toInt().toString() : displayHeight,
                  style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.w900),
                ),
                if (_isMetric) const Text(' cm', style: TextStyle(color: Colors.grey, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _BouncyButton(
                icon: Icons.remove, 
                onPressed: () {
                  HapticFeedback.lightImpact();
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
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                    thumbColor: const Color(0xFF00E5FF),
                    overlayColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                  ),
                  child: Slider(
                    value: _isMetric ? _heightCm : _heightInches,
                    min: _isMetric ? 100.0 : 40.0,
                    max: _isMetric ? 250.0 : 98.0,
                    onChanged: (newValue) {
                      setState(() {
                        _bmiValue = null; 
                        if (_isMetric) {
                          _heightCm = newValue;
                        } else {
                          _heightInches = newValue;
                        }
                      });
                    },
                  ),
                ),
              ),
              _BouncyButton(
                icon: Icons.add, 
                onPressed: () {
                  HapticFeedback.lightImpact();
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
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Text('WEIGHT', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: () => _showInputDialog('Weight', false),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _isMetric ? _weightKg.toInt().toString() : _weightLbs.toInt().toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.w900),
                ),
                Text(_isMetric ? ' kg' : ' lbs', style: const TextStyle(color: Colors.grey, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _BouncyButton(
                icon: Icons.remove, 
                onPressed: () {
                  HapticFeedback.lightImpact();
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
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                    thumbColor: const Color(0xFF00E5FF),
                    overlayColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                  ),
                  child: Slider(
                    value: _isMetric ? _weightKg : _weightLbs,
                    min: _isMetric ? 30.0 : 66.0,
                    max: _isMetric ? 200.0 : 440.0,
                    onChanged: (newValue) {
                      setState(() {
                        _bmiValue = null; 
                        if (_isMetric) {
                          _weightKg = newValue;
                        } else {
                          _weightLbs = newValue;
                        }
                      });
                    },
                  ),
                ),
              ),
              _BouncyButton(
                icon: Icons.add, 
                onPressed: () {
                  HapticFeedback.lightImpact();
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

  // --- KAD KEPUTUSAN BMI (PREMIUM POPUP UI) ---
  Widget _buildResultCard() {
    return Column(
      children: [
        // Indikator Keputusan Atas
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _bmiColor.withValues(alpha: 0.15), 
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _bmiColor.withValues(alpha: 0.5))
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: _bmiColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _bmiColor.withValues(alpha: 0.6), blurRadius: 8)])),
              const SizedBox(width: 8),
              Text(
                _bmiCategory.toUpperCase(), 
                style: TextStyle(color: _bmiColor, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Nombor BMI Besar & Bercahaya
        Text(
          _bmiValue!.toStringAsFixed(1),
          style: TextStyle(
            color: Colors.white, 
            fontSize: 80, 
            fontWeight: FontWeight.w900,
            shadows: [BoxShadow(color: _bmiColor.withValues(alpha: 0.5), blurRadius: 30)]
          ),
        ),
        const Text('Your Body Mass Index', style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 35),

        // Garisan Indikator Warna
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF131A26), borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Container(height: 6, decoration: const BoxDecoration(color: Color(0xFF5C6BC0), borderRadius: BorderRadius.horizontal(left: Radius.circular(10))))),
                  const SizedBox(width: 3),
                  Expanded(child: Container(height: 6, decoration: const BoxDecoration(color: Color(0xFF00E676)))),
                  const SizedBox(width: 3),
                  Expanded(child: Container(height: 6, decoration: const BoxDecoration(color: Color(0xFFFFA000)))),
                  const SizedBox(width: 3),
                  Expanded(child: Container(height: 6, decoration: const BoxDecoration(color: Color(0xFFE53935), borderRadius: BorderRadius.horizontal(right: Radius.circular(10))))),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('18.5', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('24.9', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('29.9', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Mesej Utama
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _bmiColor.withValues(alpha: 0.05), 
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _bmiColor.withValues(alpha: 0.2))
          ),
          child: Row(
            children: [
              Icon(_bmiCategory == 'Normal Weight' ? Icons.check_circle : Icons.warning_amber_rounded, color: _bmiColor, size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Text(_bmiMessage, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // Senarai Insights Kesihatan
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Health Insights', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 15),
        Column(
          children: _bmiInsights.map((insight) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFF00E5FF).withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.star, color: const Color(0xFF00E5FF), size: 12),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      insight,
                      style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        
        // Butang Tutup Pop-Up
        SizedBox(
          width: double.infinity,
          height: 55,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF131A26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Close Report', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }
}

// ==========================================================
// KELAS KHAS: BUTANG BOUNCY (UNTUK +/-)
// ==========================================================
class _BouncyButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _BouncyButton({required this.icon, required this.onPressed});

  @override
  State<_BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<_BouncyButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF1D2633),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: _isPressed ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 5, offset: const Offset(0, 3))],
          ),
          child: Icon(widget.icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}