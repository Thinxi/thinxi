import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thinxi/helpers/reward_helper.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int step = 0;

  @override
  void initState() {
    super.initState();
    RewardHelper.trigger("tutorial_started"); // ✅ ثبت شروع آموزش
  }

  void nextStep() {
    setState(() => step++);
  }

  Future<void> finishTutorial() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'first_time_user': false,
        'coins': FieldValue.increment(100),
      }, SetOptions(merge: true));

      RewardHelper.trigger("tutorial_completed"); // ✅ آموزش تمام شد
      debugPrint("✅ Tutorial completed. first_time_user set to false.");

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/wallet');
      }
    } catch (e) {
      debugPrint("❌ Error updating first_time_user: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _buildStep("Welcome to Thinxi!", "Let's take a quick tour."),
      _buildStep("This is your Home Screen", "Here you can start playing."),
      _buildStep(
          "Try your first Classic Game", "You will play against AI and win!"),
      _buildStep("Nice! You won!", "Let's go see your reward."),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              steps[step],
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (step == 2) {
                    RewardHelper.trigger(
                        "tutorial_classic_game"); // 🎯 شروع بازی آموزشی
                    Navigator.pushReplacementNamed(context, '/practice_ai');
                  } else if (step < steps.length - 1) {
                    nextStep();
                  } else {
                    finishTutorial();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
                child: Text(step < steps.length - 1 ? "Next" : "Finish"),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/explore');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/wallet');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.auto_graph), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ""),
        ],
      ),
    );
  }

  Widget _buildStep(String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
