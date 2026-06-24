import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Ini akan panggil fail dalam folder screens
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const FitTrackApp());
}

class FitTrackApp extends StatelessWidget {
  const FitTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false, // Buang ribbon 'DEBUG' kat bucu skrin
      
      // Tetapan tema UI untuk aplikasi FitTrack
      theme: ThemeData(
        primaryColor: const Color(0xFF00E5FF), // Warna cyan utama
        scaffoldBackgroundColor: const Color(0xFF090E17), // Warna background gelap
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E5FF),
          brightness: Brightness.dark, // Wajibkan tema gelap (Dark Mode)
        ),
        useMaterial3: true, // Guna design Material yang paling latest
      ),
      
      // Set muka surat pertama yang akan keluar bila app dibuka
      home: const LoginScreen(), 
    );
  }
}