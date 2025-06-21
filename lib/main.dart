import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/LoginScreen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/forgot_password.dart';
import 'screens/todo_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/track_screen.dart';
import 'screens/weather_screen.dart';
import 'screens/signup_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; // Default light mode
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode(); // Load tema saat provider dibuat
  }

  void toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Beri tahu listener bahwa tema berubah
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(
      'isDarkMode',
      _themeMode == ThemeMode.dark,
    ); // Simpan preferensi
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false; // Default false
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase init failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TRENIX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue, // Warna primer aplikasi
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(
          0xFFE0F2F7,
        ), // Background biru muda
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE0F2F7),
          elevation: 0,
          foregroundColor: Colors.black, // Warna ikon/teks di AppBar
        ),
        cardColor: Colors.white, // Warna Card untuk Light Mode
        textTheme: GoogleFonts.poppinsTextTheme(
          // Menggunakan font Poppins
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.black), // Warna teks default
        // Pastikan useMaterial3 tetap true jika kamu ingin Material 3 design
        useMaterial3: true,
      ),

      // Definisi Tema Gelap
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900], // Background gelap
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        cardColor: Colors.grey[800], // Warna Card untuk Dark Mode
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white),
        // Pastikan useMaterial3 tetap true jika kamu ingin Material 3 design
        useMaterial3: true,
      ),

      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/forgot': (context) => const ForgotPasswordScreen(),
        '/todo': (context) => const TodoScreen(),
        '/finance': (context) => const FinanceScreen(),
        '/track': (context) => const TrackScreen(),
        '/weather': (context) => const WeatherScreen(),
        '/signup': (context) => const SignupScreen(),
      },
    );
  }
}
