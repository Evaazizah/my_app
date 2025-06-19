import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _currentPage++;
        if (_currentPage >= 4) {
          _timer?.cancel();
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 300),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/icons/Logo.json',
                    height: 150,
                    width: 150,
                  ),
                  const SizedBox(height: 30),

                  const Text(
                    'TRENIX',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text(
                    'One App. Smarter Life',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              const Spacer(),
              Lottie.asset('assets/icons/Loading.json', height: 50),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
