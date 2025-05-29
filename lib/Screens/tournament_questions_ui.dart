import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thinxi/screens/tournament_leaderboard_screen.dart';

class TournamentQuestionsScreen extends StatefulWidget {
  const TournamentQuestionsScreen({super.key});

  @override
  _TournamentQuestionsScreenState createState() =>
      _TournamentQuestionsScreenState();
}

class _TournamentQuestionsScreenState extends State<TournamentQuestionsScreen> {
  static const maxDuration = Duration(minutes: 50);
  Duration duration = maxDuration;
  Timer? timer;
  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  DateTime startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchQuestions();
    startTimer();
  }

  void fetchQuestions() async {
    FirebaseFirestore.instance.collection('questions').get().then((snapshot) {
      List<Map<String, dynamic>> allQuestions =
          snapshot.docs.map((doc) => doc.data()).toList();
      allQuestions.shuffle(Random());
      setState(() {
        questions = allQuestions.length > 100
            ? allQuestions.sublist(0, 100)
            : allQuestions;
      });
    });
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      setState(() {
        final millis = duration.inMilliseconds - 10;
        if (millis <= 0) {
          timer?.cancel();
          endGame();
        } else {
          duration = Duration(milliseconds: millis);
        }
      });
    });
  }

  void answerQuestion(int selectedIndex) {
    if (questions.isEmpty) return;
    final correct = questions[currentQuestionIndex]['correct'];
    if (selectedIndex == correct) {
      correctAnswers++;
    }
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      endGame();
    }
  }

  Future<void> _checkAndCompleteTask(String trigger) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = FirebaseFirestore.instance;
    final tasksSnapshot = await db
        .collection('reward_tasks')
        .where('trigger', isEqualTo: trigger)
        .get();

    if (tasksSnapshot.docs.isEmpty) return;

    final userTaskDoc = await db.collection('user_tasks').doc(user.uid).get();
    final userTaskData = userTaskDoc.data() ?? {};

    for (var task in tasksSnapshot.docs) {
      final taskId = task['id'];
      if (userTaskData[taskId]?['completed'] == true) continue;
      await db.collection('user_tasks').doc(user.uid).set({
        taskId: {
          'completed': true,
          'claimed': false,
          'timestamp': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    }
  }

  void endGame() async {
    timer?.cancel();
    Duration totalTime = DateTime.now().difference(startTime);

    await FirebaseFirestore.instance.collection('tournament_results').add({
      "correct_answers": correctAnswers,
      "total_time": totalTime.inSeconds,
      "timestamp": FieldValue.serverTimestamp(),
    });

    await _checkAndCompleteTask("tournament_played");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentResultScreen(
          correctAnswers: correctAnswers,
          totalTime: totalTime.inSeconds,
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final milliseconds = (duration.inMilliseconds.remainder(1000) ~/ 10)
        .toString()
        .padLeft(2, '0');

    if (questions.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body:
            Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    Map<String, dynamic> question = questions[currentQuestionIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  const Text(
                    'TOURNAMENT MODE',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      question['question'],
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              Column(
                children: List.generate(
                  4,
                  (index) => optionButton(index, question['options'][index]),
                ),
              ),
              Column(
                children: [
                  const Text(
                    'Till the end of this game',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$minutes:$seconds:$milliseconds',
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent),
                    onPressed: () {
                      endGame();
                    },
                    child: const Text('Exit to lobby'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget optionButton(int index, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white24,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onPressed: () {
          answerQuestion(index);
        },
        child: Row(
          children: [
            Text(
              "${index + 1}",
              style: const TextStyle(fontSize: 22, color: Colors.blueAccent),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TournamentResultScreen extends StatelessWidget {
  final int correctAnswers;
  final int totalTime;

  const TournamentResultScreen(
      {super.key, required this.correctAnswers, required this.totalTime});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'TOURNAMENT COMPLETED!',
              style: TextStyle(fontSize: 28, color: Colors.greenAccent),
            ),
            const SizedBox(height: 10),
            const Text(
              'منتظر نتایج باشید',
              style: TextStyle(fontSize: 20, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Text(
              'Correct Answers: $correctAnswers',
              style: const TextStyle(fontSize: 22, color: Colors.white),
            ),
            Text(
              'Total Time: ${totalTime}s',
              style: const TextStyle(fontSize: 22, color: Colors.white),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TournamentLeaderboardScreen(),
                  ),
                );
              },
              child: const Text('View Leaderboard'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
        currentIndex: 1,
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
}
