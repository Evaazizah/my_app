import 'package:flutter/material.dart';

class Slide2 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Slide2({super.key, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.lightBlue[100],
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Image.asset('assets/icons/onboarding2.jpg', height: 250),
          const SizedBox(height: 32),
          const Text(
            'Smart Tools, One App',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'From notes to finances,\neverything you need in one place.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(onPressed: onBack, child: const Text("Back")),
              ElevatedButton(onPressed: onNext, child: const Text("Next")),
            ],
          ),
        ],
      ),
    );
  }
}
