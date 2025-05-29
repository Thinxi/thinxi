import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';
import 'explore_screen.dart';
import 'wallet_screen.dart';
import 'settings_screen.dart';

class MillionaireQuestionsUI extends StatefulWidget {
  final int questionNumber;

  const MillionaireQuestionsUI({super.key, required this.questionNumber});

  @override
  State<MillionaireQuestionsUI> createState() => _MillionaireQuestionsUIState();
}

class _MillionaireQuestionsUIState extends State<MillionaireQuestionsUI> {
  Map<String, dynamic>? currentQuestion;
  bool isAnswered = false;
  bool isCorrect = false;
  String? selectedAnswer;
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    WalletScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
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
    _loadNextQuestion();
  }

  Future<void> _loadNextQuestion() async {
    int difficulty = ((widget.questionNumber - 1) ~/ 5 + 1).clamp(1, 5);
    QuerySnapshot<Map<String, dynamic>> questionSnap;

    for (int attempt = 0; attempt < 5; attempt++) {
      questionSnap = await FirebaseFirestore.instance
          .collection('questions')
          .where('difficulty', isEqualTo: difficulty)
          .limit(10)
          .get();

      if (questionSnap.docs.isNotEmpty) {
        final index = (widget.questionNumber - 1) % questionSnap.docs.length;
        final question = questionSnap.docs[index].data();

        setState(() {
          currentQuestion = question;
          isAnswered = false;
          selectedAnswer = null;
        });
        return;
      }

      difficulty = (difficulty % 5) + 1;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("❌ No questions found at any difficulty.")),
    );
    Navigator.pop(context);
  }

  void _submitAnswer(String answer) async {
    if (isAnswered) return;

    final correctIndex = currentQuestion?['correct'];
    final correctAnswer = currentQuestion?['options']?[correctIndex];
    final correct = answer == correctAnswer;

    setState(() {
      selectedAnswer = answer;
      isAnswered = true;
      isCorrect = correct;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && currentQuestion != null) {
      await FirebaseFirestore.instance.collection('millionaire_answers').add({
        'userId': uid,
        'questionNumber': widget.questionNumber,
        'questionId': currentQuestion!['id'] ?? '',
        'selectedAnswer': answer,
        'correctAnswer': correctAnswer,
        'isCorrect': correct,
        'timestamp': Timestamp.now(),
      });
    }

    await Future.delayed(const Duration(seconds: 2));
    Navigator.pushReplacementNamed(
      context,
      '/millionaire_reward_screen',
      arguments: {
        'questionNumber': widget.questionNumber,
        'isCorrect': correct,
      },
    );
  }

  BottomNavigationBarItem buildCustomIcon(String assetName, String label) {
    return BottomNavigationBarItem(
      icon: Image.asset(
        'assets/images/icons/$assetName',
        width: 26,
        height: 26,
        color: Colors.white54,
      ),
      activeIcon: Image.asset(
        'assets/images/icons/$assetName',
        width: 26,
        height: 26,
        color: Colors.purpleAccent,
      ),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentQuestion == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final options = currentQuestion!['options'] as List<dynamic>;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Question ${widget.questionNumber}'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentQuestion!['question'],
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 24),
            ...List.generate(options.length, (i) {
              final option = options[i];
              final correctIndex = currentQuestion!['correct'];
              final correctAnswer = options[correctIndex];
              final isSelected = option == selectedAnswer;
              final isCorrectAnswer = option == correctAnswer;
              final color = !isAnswered
                  ? Colors.blue
                  : isSelected
                      ? (isCorrectAnswer ? Colors.green : Colors.red)
                      : Colors.grey[800];

              return GestureDetector(
                onTap: () => _submitAnswer(option),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    option,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: [
          buildCustomIcon('home.png', 'Home'),
          buildCustomIcon('explore.png', 'Explore'),
          buildCustomIcon('wallet.png', 'Wallet'),
          buildCustomIcon('setting.png', 'Settings'),
        ],
      ),
    );
  }
}
