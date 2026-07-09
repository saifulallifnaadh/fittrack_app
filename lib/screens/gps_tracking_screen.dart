import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class GpsTrackingScreen extends StatefulWidget {
  const GpsTrackingScreen({super.key});

  @override
  State<GpsTrackingScreen> createState() => _GpsTrackingScreenState();
}

// Tambah TickerProviderStateMixin untuk membolehkan Animasi Peta & Marker berfungsi
class _GpsTrackingScreenState extends State<GpsTrackingScreen> with TickerProviderStateMixin {
  // --- STATE VARIABLES ---
  bool _isRunning = false;
  int _seconds = 0;
  Timer? _timer;
  // --- TAMBAH BARIS INI UNTUK ANIMASI BUTANG ---
  bool _isStartPressed = false;

  // Variabel GPS & Peta
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(4.1950, 101.2600); // Default ke Tapah
  bool _hasLocation = false;
  
  // Jejak laluan dan jarak
  final List<LatLng> _routePoints = []; 
  StreamSubscription<Position>? _positionStream;
  double _totalDistanceKm = 0.0;
  int _totalCalories = 0;
  String _currentPace = "0'00\"";

  // Animasi Marker Berdegup (Pulsing)
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup Animasi Marker Berdegup
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);
    
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _initLocation();
  }

  // --- 1. MINTA KEBENARAN & DAPATKAN LOKASI AWAL ---
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
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8), 
      );
      
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

  // --- FUNGSI ANIMASI PERGERAKAN PETA (SMOOTH PANNING) ---
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Kalau tak ada lokasi, jangan gerak
    if (!_hasLocation) return;
    
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    var animationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    Animation<double> animation = CurvedAnimation(parent: animationController, curve: Curves.fastOutSlowIn);

    animationController.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        animationController.dispose();
      }
    });
    animationController.forward();
  }

  // --- 2. FUNGSI START TRACKING (LIVE GPS) ---
  void _startWorkout() {
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        _calculateStats();
      });
    });

    const locationSettings = LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 2);
    
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        if (_isRunning) {
          LatLng newPos = LatLng(position.latitude, position.longitude);

          setState(() {
            if (_routePoints.isNotEmpty) {
              const Distance distance = Distance();
              final double meters = distance.as(LengthUnit.Meter, _routePoints.last, newPos);
              _totalDistanceKm += (meters / 1000.0);
            }
            
            _routePoints.add(newPos);
            _currentPosition = newPos;
          });

          // Kamera sentiasa ikut pelari dengan smooth
          _animatedMapMove(_currentPosition, 17.0);
        }
      }
    );
  }

  void _pauseWorkout() {
    setState(() => _isRunning = false);
    _timer?.cancel();
    _positionStream?.cancel();
  }

  void _calculateStats() {
    _totalCalories = (_totalDistanceKm * 60).toInt();

    if (_totalDistanceKm > 0.05) { 
      double minutes = _seconds / 60.0;
      double paceDecimal = minutes / _totalDistanceKm;
      
      int paceMinutes = paceDecimal.toInt();
      int paceSeconds = ((paceDecimal - paceMinutes) * 60).toInt();
      
      _currentPace = "$paceMinutes'${paceSeconds.toString().padLeft(2, '0')}\"";
    }
  }

  void _stopWorkout() {
    _pauseWorkout();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131A26),
        title: const Text('Workout Finished!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('You ran ${_totalDistanceKm.toStringAsFixed(2)} km in ${_formatTime(_seconds)}.\n\nSave this session?', style: const TextStyle(color: Colors.grey, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              setState(() {
                _seconds = 0;
                _totalDistanceKm = 0;
                _routePoints.clear();
              }); 
            },
            child: const Text('Discard', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pop(context); 
            },
            child: const Text('Save Workout', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
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
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
        title: const Text('Outdoor Run', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- PETA OPENSTREETMAP DENGAN UI OVERLAYS ---
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.05), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentPosition,
                        initialZoom: 16.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // Kunci rotation supaya tak pening
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.fittrack.app',
                        ),
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                color: const Color(0xFF00E5FF),
                                strokeWidth: 5.0,
                                
                              ),
                            ],
                          ),
                        if (_hasLocation)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _currentPosition,
                                width: 60,
                                height: 60,
                                child: AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Efek Radar (Pulsing)
                                        Container(
                                          width: 30 * _pulseAnimation.value,
                                          height: 30 * _pulseAnimation.value,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF00E5FF).withOpacity(1.0 - (_pulseAnimation.value - 0.5)),
                                          ),
                                        ),
                                        // Dot Tengah Solid
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00E5FF),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 3),
                                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)],
                                          ),
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

                    // OVERLAY: Paparan Loading jika GPS belum ditemui
                    if (!_hasLocation)
                      Container(
                        color: const Color(0xFF131A26).withOpacity(0.8),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Color(0xFF00E5FF)),
                              SizedBox(height: 15),
                              Text('Acquiring GPS Signal...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),

                    // OVERLAY: Butang Kawalan Peta (Kanan Bawah)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Butang Zoom In
                          FloatingActionButton.small(
                            heroTag: 'zoomIn',
                            backgroundColor: const Color(0xFF1D2633).withOpacity(0.9),
                            onPressed: () {
                              _animatedMapMove(_mapController.camera.center, _mapController.camera.zoom + 1);
                            },
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                          const SizedBox(height: 5),
                          // Butang Zoom Out
                          FloatingActionButton.small(
                            heroTag: 'zoomOut',
                            backgroundColor: const Color(0xFF1D2633).withOpacity(0.9),
                            onPressed: () {
                              _animatedMapMove(_mapController.camera.center, _mapController.camera.zoom - 1);
                            },
                            child: const Icon(Icons.remove, color: Colors.white),
                          ),
                          const SizedBox(height: 15),
                          // Butang My Location (Recenter)
                          FloatingActionButton(
                            heroTag: 'recenter',
                            backgroundColor: const Color(0xFF00E5FF),
                            onPressed: () {
                              _animatedMapMove(_currentPosition, 16.5);
                            },
                            child: const Icon(Icons.my_location, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- BAHAGIAN STATISTIK & KAWALAN (DENGAN SAFE AREA FIX) ---
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                left: 30, 
                right: 30, 
                top: 25, 
                // PENYELESAIAN OVERLAP: Guna padding bawah peranti + 20px
                bottom: MediaQuery.of(context).padding.bottom + 20, 
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF131A26),
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  const Text('TIME', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 5),
                  Text(
                    _formatTime(_seconds),
                    style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem('DISTANCE', '${_totalDistanceKm.toStringAsFixed(2)} km', Icons.route),
                      _buildStatItem('PACE', _currentPace, Icons.speed),
                      _buildStatItem('CALORIES', '$_totalCalories kcal', Icons.local_fire_department),
                    ],
                  ),
                  
                  const Spacer(), 

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isRunning || _seconds > 0) ...[
                        InkWell(
                          onTap: _isRunning ? _pauseWorkout : _startWorkout,
                          borderRadius: BorderRadius.circular(40),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D2633),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                            ),
                            child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 30),
                          ),
                        ),
                        const SizedBox(width: 30),
                        InkWell(
                          onTap: _stopWorkout,
                          borderRadius: BorderRadius.circular(40),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.redAccent),
                            ),
                            child: const Icon(Icons.stop, color: Colors.redAccent, size: 30),
                          ),
                        ),
                      ] else ...[
                        // Butang Start Besar dengan Animasi Bouncing
                        GestureDetector(
                          // Bila jari tekan ke bawah, butang mengecil
                          onTapDown: (_) => setState(() => _isStartPressed = true),
                          // Bila jari angkat (berjaya tekan), butang membesar & fungsi berjalan
                          onTapUp: (_) {
                            setState(() => _isStartPressed = false);
                            _startWorkout(); 
                          },
                          // Kalau jari tergelincir batal tekan, butang membesar balik
                          onTapCancel: () => setState(() => _isStartPressed = false),
                          
                          child: AnimatedScale(
                            scale: _isStartPressed ? 0.90 : 1.0, // Mengecil 10% bila ditekan
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 250,
                              height: 70,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF),
                                borderRadius: BorderRadius.circular(35),
                                // Bayang-bayang hilang bila ditekan (menjadikan efek ditekan ke dalam)
                                boxShadow: _isStartPressed
                                    ? [] 
                                    : [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 5))],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow, color: Colors.black, size: 30),
                                  SizedBox(width: 10),
                                  Text('START', style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      ],
                    
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00E5FF), size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1)),
      ],
    );
  }
}