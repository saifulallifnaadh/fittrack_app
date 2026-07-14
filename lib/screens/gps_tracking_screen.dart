import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GpsTrackingScreen extends StatefulWidget {
  const GpsTrackingScreen({super.key});

  @override
  State<GpsTrackingScreen> createState() => _GpsTrackingScreenState();
}

class _GpsTrackingScreenState extends State<GpsTrackingScreen> with TickerProviderStateMixin {
  // --- STATE VARIABLES ---
  bool _isRunning = false;
  bool _isPaused = false; 
  int _seconds = 0;
  Timer? _timer;

  // Variabel untuk Countdown 3 saat
  bool _isCountingDown = false;
  int _countdownValue = 3;

  // Variabel Tema Peta (Dark / Light Mode)
  bool _isDarkModeMap = true; 

  // Variabel GPS & Peta
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(4.1950, 101.2600); 
  bool _hasLocation = false;
  
  // Jejak laluan dan jarak
  final List<LatLng> _routePoints = []; 
  StreamSubscription<Position>? _positionStream;
  double _totalDistanceKm = 0.0;
  int _totalCalories = 0;
  String _currentPace = "0'00\"";

  // Animasi Marker Berdegup
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: false);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    _initLocation();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sila "ON" kan GPS.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 8));
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _hasLocation = true;
      });
      _animatedMapMove(_currentPosition, 16.5);
    } catch (e) {
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        setState(() {
          _currentPosition = LatLng(lastPosition.latitude, lastPosition.longitude);
          _hasLocation = true;
        });
        _animatedMapMove(_currentPosition, 16.5);
      }
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!_hasLocation) return;
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    var animationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    Animation<double> animation = CurvedAnimation(parent: animationController, curve: Curves.fastOutSlowIn);

    animationController.addListener(() {
      _mapController.move(LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)), zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) animationController.dispose();
    });
    animationController.forward();
  }

  // --- FUNGSI COUNTDOWN (3.. 2.. 1.. GO!) ---
  void _startCountdown() {
    if (!_hasLocation) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sila tunggu isyarat GPS stabil...')));
      return;
    }

    setState(() {
      _isCountingDown = true;
      _countdownValue = 3;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownValue == 1) {
        timer.cancel();
        setState(() => _isCountingDown = false);
        _startWorkout(); 
      } else {
        setState(() => _countdownValue--);
      }
    });
  }

  // --- FUNGSI LARIAN ---
  void _startWorkout() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        _calculateStats();
      });
    });

    if (_positionStream == null) {
      const locationSettings = LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 2);
      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
        LatLng newPos = LatLng(position.latitude, position.longitude);

        if (_isRunning && !_isPaused) {
          setState(() {
            if (_routePoints.isNotEmpty) {
              const Distance distance = Distance();
              final double meters = distance.as(LengthUnit.Meter, _routePoints.last, newPos);
              _totalDistanceKm += (meters / 1000.0);
            }
            _routePoints.add(newPos);
            _currentPosition = newPos;
          });
          _animatedMapMove(_currentPosition, 17.0);
        } else {
          setState(() => _currentPosition = newPos);
        }
      });
    }
  }

  void _pauseWorkout() {
    setState(() => _isPaused = true);
    _timer?.cancel();
  }

  void _resumeWorkout() {
    _startWorkout();
  }

  void _calculateStats() {
    _totalCalories = (_totalDistanceKm * 60).toInt();

    if (_totalDistanceKm > 0.01) { 
      double minutes = _seconds / 60.0;
      double paceDecimal = minutes / _totalDistanceKm;
      
      int paceMinutes = paceDecimal.toInt();
      int paceSeconds = ((paceDecimal - paceMinutes) * 60).toInt();
      _currentPace = "$paceMinutes'${paceSeconds.toString().padLeft(2, '0')}\"";
    }
  }

  // ==========================================================
  // POPUP WORKOUT FINISHED (REKAAN PREMIUM BARU)
  // ==========================================================
  void _stopWorkout() {
    _pauseWorkout();
    int estimatedSteps = (_totalDistanceKm * 1312).toInt();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF131A26),
            borderRadius: BorderRadius.circular(30), // Bucu lebih membulat
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, spreadRadius: 5)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- HEADER PIALA EMAS ---
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF9800)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)
                  ],
                ),
                child: const Icon(Icons.emoji_events, color: Colors.white, size: 45),
              ),
              const SizedBox(height: 20),
              
              const Text('Workout Finished!', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Great job! Here is your session summary.', style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 25),

              // --- GRID STATISTIK KAD PREMIUM ---
              Row(
                children: [
                  Expanded(child: _buildPremiumStatCard(Icons.route, 'Distance', '${_totalDistanceKm.toStringAsFixed(2)} km', const Color(0xFF00E5FF))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildPremiumStatCard(Icons.timer, 'Time', _formatTime(_seconds), Colors.white)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildPremiumStatCard(Icons.speed, 'Avg Pace', _currentPace, Colors.amber)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildPremiumStatCard(Icons.local_fire_department, 'Calories', '$_totalCalories kcal', Colors.deepOrangeAccent)),
                ],
              ),
              const SizedBox(height: 12),
              // Kad Panjang untuk Steps
              _buildPremiumStatCard(Icons.directions_walk, 'Estimated Steps', '$estimatedSteps steps', Colors.greenAccent, isWide: true),

              const SizedBox(height: 30),

              // --- BUTANG KAWALAN ---
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16), 
                        side: BorderSide(color: Colors.redAccent.withOpacity(0.5)), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      onPressed: () {
                        Navigator.pop(context); 
                        setState(() {
                          _seconds = 0; _totalDistanceKm = 0; _totalCalories = 0; _currentPace = "0'00\""; _routePoints.clear(); _isRunning = false; _isPaused = false;
                        }); 
                      },
                      child: const Text('Discard', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF), 
                        padding: const EdgeInsets.symmetric(vertical: 16), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                        elevation: 5, 
                        shadowColor: const Color(0xFF00E5FF).withOpacity(0.4)
                      ),
                      onPressed: () async {
                        final String? userId = FirebaseAuth.instance.currentUser?.uid;
                        if (userId != null) {
                          final now = DateTime.now();
                          final String todayDateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                          List<GeoPoint> savedRoute = _routePoints.map((point) => GeoPoint(point.latitude, point.longitude)).toList();

                          await FirebaseFirestore.instance.collection('users').doc(userId).collection('history').doc(todayDateStr).set({
                            'date': Timestamp.fromDate(now), 
                            'run_distance': FieldValue.increment(_totalDistanceKm),
                            'calories_burned': FieldValue.increment(_totalCalories),
                            'steps': FieldValue.increment(estimatedSteps),
                          }, SetOptions(merge: true)); 

                          final String sessionId = now.millisecondsSinceEpoch.toString();
                          await FirebaseFirestore.instance.collection('users').doc(userId).collection('run_sessions').doc(sessionId).set({
                            'date': Timestamp.fromDate(now), 'distance': _totalDistanceKm, 'calories': _totalCalories, 'steps': estimatedSteps, 'duration_seconds': _seconds, 'pace': _currentPace, 'route_points': savedRoute,
                          });
                        }
                        if (mounted) {
                          Navigator.pop(context); Navigator.pop(context); 
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Run Saved! Awesome work! 🏃‍♂️'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
                        }
                      },
                      child: const Text('Save Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET KAD GRID UNTUK POPUP
  Widget _buildPremiumStatCard(IconData icon, String label, String value, Color iconColor, {bool isWide = false}) {
    return Container(
      width: isWide ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2633),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    _positionStream?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    if (hours > 0) return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      body: Stack(
        children: [
          // --- LAYER 1: PETA FULL SCREEN ---
          Positioned(
            top: -250, 
            bottom: 0,
            left: 0,
            right: 0,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition,
                initialZoom: 16.0,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              ),
              children: [
                TileLayer(
                  urlTemplate: _isDarkModeMap
                      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                      : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.fittrack.app',
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints, 
                        color: _isDarkModeMap ? const Color(0xFF00E5FF) : const Color(0xFF9D50BB), 
                        strokeWidth: 6.0, 
                        borderStrokeWidth: 2.0, 
                        borderColor: Colors.black.withOpacity(0.3)
                      ),
                    ],
                  ),
                if (_hasLocation)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentPosition,
                        width: 60, height: 60,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            Color markerColor = _isDarkModeMap ? const Color(0xFF00E5FF) : const Color(0xFF9D50BB);
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 30 * _pulseAnimation.value, height: 30 * _pulseAnimation.value,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: markerColor.withOpacity(1.0 - (_pulseAnimation.value - 0.5))),
                                ),
                                Container(
                                  width: 18, height: 18,
                                  decoration: BoxDecoration(color: markerColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)]),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // --- LAYER 2: OVERLAY UI BAWAHAN & ATASAN ---
          SafeArea(
            child: Column(
              children: [
                // Header (Back Button & GPS Status)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMapCircleButton(Icons.arrow_back_ios_new, const Color(0xFF131A26).withOpacity(0.9), () => Navigator.pop(context), iconColor: Colors.white),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFF131A26).withOpacity(0.85), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _hasLocation ? Colors.greenAccent : Colors.orangeAccent)),
                            const SizedBox(width: 8),
                            Text(_hasLocation ? 'GPS Ready' : 'Acquiring...', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                
                const Spacer(),

                // Map Controls
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 15, bottom: 20),
                    child: Column(
                      children: [
                        _buildMapCircleButton(
                          _isDarkModeMap ? Icons.light_mode : Icons.dark_mode, 
                          const Color(0xFF131A26).withOpacity(0.9), 
                          () {
                            setState(() {
                              _isDarkModeMap = !_isDarkModeMap;
                            });
                          }, 
                          iconColor: _isDarkModeMap ? Colors.amber : Colors.white
                        ),
                        const SizedBox(height: 15),
                        _buildMapCircleButton(Icons.add, const Color(0xFF131A26).withOpacity(0.9), () => _animatedMapMove(_mapController.camera.center, _mapController.camera.zoom + 1), iconColor: Colors.white),
                        const SizedBox(height: 10),
                        _buildMapCircleButton(Icons.remove, const Color(0xFF131A26).withOpacity(0.9), () => _animatedMapMove(_mapController.camera.center, _mapController.camera.zoom - 1), iconColor: Colors.white),
                        const SizedBox(height: 20),
                        _buildMapCircleButton(Icons.my_location, _isDarkModeMap ? const Color(0xFF00E5FF) : const Color(0xFF9D50BB), () => _animatedMapMove(_currentPosition, 16.5), iconColor: _isDarkModeMap ? Colors.black : Colors.white),
                      ],
                    ),
                  ),
                ),

                // --- BOTTOM STATS PANEL (GLASSMORPHISM) ---
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(left: 30, right: 30, top: 35, bottom: MediaQuery.of(context).padding.bottom + 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [const Color(0xFF131A26).withOpacity(0.85), const Color(0xFF090E17).withOpacity(0.95)],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('TIME', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                          const SizedBox(height: 5),
                          Text(_formatTime(_seconds), style: const TextStyle(color: Colors.white, fontSize: 65, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                          const SizedBox(height: 30),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatItem('DISTANCE', '${_totalDistanceKm.toStringAsFixed(2)} km', Icons.route),
                              _buildStatItem('PACE', _currentPace, Icons.speed),
                              _buildStatItem('CALORIES', '$_totalCalories kcal', Icons.local_fire_department),
                            ],
                          ),
                          const SizedBox(height: 40),

                          // KAWALAN BUTANG
                          if (!_isRunning && !_isPaused) 
                            _buildBigButton(text: 'START RUN', color: const Color(0xFF00E5FF), textColor: Colors.black, icon: Icons.play_arrow, onTap: _startCountdown)
                          else if (_isRunning && !_isPaused) 
                            _buildBigButton(text: 'PAUSE', color: Colors.amberAccent, textColor: Colors.black, icon: Icons.pause, onTap: _pauseWorkout)
                          else if (_isPaused)
                            Row(
                              children: [
                                Expanded(child: _buildBigButton(text: 'RESUME', color: const Color(0xFF00E5FF), textColor: Colors.black, icon: Icons.play_arrow, onTap: _resumeWorkout)),
                                const SizedBox(width: 15),
                                Expanded(child: _buildBigButton(text: 'FINISH', color: Colors.redAccent, textColor: Colors.white, icon: Icons.stop, onTap: _stopWorkout)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- LAYER 3: COUNTDOWN OVERLAY ---
          if (_isCountingDown)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: const Color(0xFF090E17).withOpacity(0.7),
                  child: Center(
                    child: Text(
                      '$_countdownValue',
                      style: const TextStyle(
                        color: Color(0xFF00E5FF), 
                        fontSize: 150, 
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGET BANTUAN UI ---
  Widget _buildMapCircleButton(IconData icon, Color bgColor, VoidCallback onTap, {Color iconColor = Colors.black}) {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)]),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: bgColor,
        child: IconButton(icon: Icon(icon, color: iconColor, size: 22), onPressed: onTap),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: _isDarkModeMap ? const Color(0xFF00E5FF) : const Color(0xFF9D50BB), size: 26),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildBigButton({required String text, required Color color, required Color textColor, required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      height: 65,
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: color.withOpacity(0.4),
        ),
        onPressed: onTap,
        icon: Icon(icon, color: textColor, size: 28),
        label: Text(text, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ),
    );
  }
}