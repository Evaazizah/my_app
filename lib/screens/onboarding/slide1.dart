import 'package:flutter/material.dart';

class Slide1 extends StatelessWidget {
  final VoidCallback onNext;

  const Slide1({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 241, 240, 240),

      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),

              Text(
                'Organize Your Day',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              Text(
                'Keep track of your tasks,\nwith smart reminders and scheduling.',
                style: TextStyle(fontSize: 25),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 250),

              Image.asset(
                'assets/icons/onboarding1.jpg',
                height: 250,
                fit: BoxFit.contain,
              ),
              const Spacer(),

              Align(
                alignment: Alignment.bottomRight,
                child: SizedBox(
                  width: 100,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(7.0),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
