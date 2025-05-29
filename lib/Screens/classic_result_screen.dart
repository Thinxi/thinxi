import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

class ClassicResultScreen extends StatefulWidget {
  final int correctAnswers;
  final int wrongAnswers;
  final int totalTime;

  const ClassicResultScreen({
    super.key,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.totalTime,
  });

  @override
  State<ClassicResultScreen> createState() => _ClassicResultScreenState();
}

class _ClassicResultScreenState extends State<ClassicResultScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    playResultSound();
    saveGameResult();
  }

  void playResultSound() {
    if (widget.correctAnswers > widget.wrongAnswers) {
      _audioPlayer.play(AssetSource('audio/reward.mp3'));
    } else {
      _audioPlayer.play(AssetSource('audio/no prize tournament.mp3'));
    }
  }

  Future<void> saveGameResult() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('game_history')
        .add({
      'mode': 'classic',
      'correct': widget.correctAnswers,
      'wrong': widget.wrongAnswers,
      'time': widget.totalTime,
      'timestamp': Timestamp.now(),
    });
  }

  void shareResult() {
    final text = '''
🎮 I just completed a Classic Game on Thinxi!

✅ Correct: ${widget.correctAnswers}
❌ Wrong: ${widget.wrongAnswers}
⏱ Time: ${widget.totalTime} seconds

Can you beat my score? Join Thinxi and play now!
''';

    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🎉 Game Over!',
                style: TextStyle(fontSize: 28, color: Colors.white),
              ),
              const SizedBox(height: 30),
              Text(
                '✅ Correct: ${widget.correctAnswers}',
                style: const TextStyle(fontSize: 20, color: Colors.greenAccent),
              ),
              Text(
                '❌ Wrong: ${widget.wrongAnswers}',
                style: const TextStyle(fontSize: 20, color: Colors.redAccent),
              ),
              const SizedBox(height: 10),
              Text(
                '⏱ Time: ${widget.totalTime} sec',
                style: const TextStyle(fontSize: 18, color: Colors.white54),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: shareResult,
                icon: const Icon(Icons.share),
                label: const Text(
                  'Share Result',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home',
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text(
                  'Back to Home',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
