import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; 
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitTrack',
      // Kita kekalkan satu tema gelap rasmi untuk app kau
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090E17),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF00E5FF)),
      ),
      home: const AuthGate(), 
    );
  }
}

// --- SISTEM PENJAGA PINTU (AUTH GATE FIREBASE) ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF090E17),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return DashboardScreen(userId: snapshot.data!.uid);
        }

        return const LoginScreen();
      },
    );
  }
}