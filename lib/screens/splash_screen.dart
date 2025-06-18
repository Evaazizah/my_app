import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/icons/TRENIX.jpg', height: 120),
              const SizedBox(height: 30),

              const Text(
                'TRENIX',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                'One App. Smarter Life',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 100),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == 0 ? Colors.black : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
