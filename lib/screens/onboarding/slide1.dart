import 'package:flutter/material.dart';

class Slide1 extends StatelessWidget {
  final VoidCallback onNext;

  const Slide1({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.lightBlue[100],
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Image.asset('assets/icons/onboarding1.jpg', height: 250),
          const SizedBox(height: 32),
          const Text(
            'Organize Your Day',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Keep track of your tasks,\nwith smart reminders and scheduling.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(onPressed: onNext, child: const Text("Next")),
          ),
        ],
      ),
    );
  }
}
