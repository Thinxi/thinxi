import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pal_mode_result_screen.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'wallet_screen.dart';
import 'settings_screen.dart';

class PalModeQuestionsScreen extends StatefulWidget {
  final String userId;
  final String gameId;

  const PalModeQuestionsScreen({
    super.key,
    required this.userId,
    required this.gameId,
  });

  @override
  State<PalModeQuestionsScreen> createState() => _PalModeQuestionsScreenState();
}

class _PalModeQuestionsScreenState extends State<PalModeQuestionsScreen> {
  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  bool answered = false;
  Timer? gameTimer;
  int remainingSeconds = 1500;
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    WalletScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => _screens[index]),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchQuestions();
    startTimer();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void startTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          timer.cancel();
          endGame();
        }
      });
    });
  }

  Future<void> fetchQuestions() async {
    List<Map<String, dynamic>> all = [];
    for (int level = 1; level <= 5; level++) {
      final snap = await FirebaseFirestore.instance
          .collection('questions')
          .where('difficulty', isEqualTo: level)
          .limit(10)
          .get();
      all.addAll(snap.docs.map((doc) => doc.data()));
    }
    setState(() {
      questions = all;
    });
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

  void answerQuestion(int index) {
    if (answered) return;
    setState(() {
      answered = true;
    });

    final correct = questions[currentQuestionIndex]['correct'];
    if (index == correct) {
      score++;
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          answered = false;
        });
      } else {
        endGame();
      }
    });
  }

  void endGame() async {
    gameTimer?.cancel();
    int secondsTaken = 1500 - remainingSeconds;

    await FirebaseFirestore.instance
        .collection('pal_mode_games')
        .doc(widget.gameId)
        .collection('players')
        .doc(widget.userId)
        .set({
      'score': score,
      'finished': true,
      'time_taken': secondsTaken,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _checkAndCompleteTask("game_played");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PalModeResultScreen(
          score: score,
          totalQuestions: questions.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    final question = questions[currentQuestionIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '⏱ ${(remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(remainingSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Question ${currentQuestionIndex + 1}/${questions.length}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  question['question'],
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              ...List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => answerQuestion(index),
                    child: Text(
                      question['options'][index],
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/icons/home.png')),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/icons/explore.png')),
            label: "Explore",
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/icons/wallet.png')),
            label: "Wallet",
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/icons/setting.png')),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
