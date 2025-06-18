import 'package:flutter/material.dart';

class Slide3 extends StatelessWidget {
  final VoidCallback onGetStarted;

  const Slide3({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.lightBlue[100],
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Image.asset('assets/icons/onboarding3.jpg', height: 250),
          const SizedBox(height: 32),
          const Text(
            'Stay Aware, Stay Connected',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Real-time tracking,\nweather updates and full control.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onGetStarted,
              child: const Text("Get Started"),
            ),
          ),
        ],
      ),
    );
  }
}
