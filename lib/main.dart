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

void main() {
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
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
        fontFamily: 'Roboto',
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
