import 'package:flutter/material.dart';
import 'slide1.dart';
import 'slide2.dart';
import 'slide3.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  void _nextPage() {
    if (_currentIndex < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login_register');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          Slide1(onNext: _nextPage),
          Slide2(
            onNext: _nextPage,
            onBack: () {
              _controller.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            },
          ),
          Slide3(onGetStarted: _nextPage),
        ],
      ),
    );
  }
}
