import 'package:flutter/material.dart';

class IntroScreen extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onStart;

  const IntroScreen({
    super.key,
    required this.title,
    required this.description,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                "Start Game",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
