import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thinxi/Screens/classic_result_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClassicQuestionsScreen extends StatefulWidget {
  const ClassicQuestionsScreen({super.key});

  @override
  State<ClassicQuestionsScreen> createState() => _ClassicQuestionsScreenState();
}

class _ClassicQuestionsScreenState extends State<ClassicQuestionsScreen> {
  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  int? selectedOptionIndex;
  bool answered = false;

  int correctAnswers = 0;
  int wrongAnswers = 0;
  late DateTime startTime;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    fetchQuestions();
    startTime = DateTime.now();
  }

  void fetchQuestions() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('questions').get();

    setState(() {
      questions = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  void goToResults() async {
    final endTime = DateTime.now();
    final totalTime = endTime.difference(startTime).inSeconds;

    await _checkAndCompleteTask("game_played");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ClassicResultScreen(
          correctAnswers: correctAnswers,
          wrongAnswers: wrongAnswers,
          totalTime: totalTime,
        ),
      ),
    );
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

  void nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        answered = false;
        selectedOptionIndex = null;
      });
    } else {
      goToResults();
    }
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: _buildQuestionContent(
            key: ValueKey<int>(currentQuestionIndex),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionContent({Key? key}) {
    final question = questions[currentQuestionIndex];
    final correctAnswer = question['correct'];

    return Container(
      key: key,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          LinearProgressIndicator(
            value: (currentQuestionIndex + 1) / questions.length,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          ),
          const Text(
            'CLASSIC MODE',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
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
          Column(
            children: List.generate(
              4,
              (index) => buildOptionButton(
                index,
                question['options'][index],
                correctAnswer,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Exit to lobby'),
          ),
        ],
      ),
    );
  }

  Widget buildOptionButton(int index, String text, int correctAnswer) {
    Color bgColor = Colors.white24;

    if (answered) {
      if (index == correctAnswer) {
        bgColor = Colors.green;
      } else if (index == selectedOptionIndex) {
        bgColor = Colors.red;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onPressed: answered
            ? null
            : () async {
                setState(() {
                  selectedOptionIndex = index;
                  answered = true;

                  if (index == correctAnswer) {
                    correctAnswers++;
                    _audioPlayer.play(AssetSource('audio/correct.mp3'));
                  } else {
                    wrongAnswers++;
                    _audioPlayer.play(AssetSource('audio/wrong.mp3'));
                  }
                });

                if (currentQuestionIndex == questions.length - 1) {
                  await Future.delayed(const Duration(milliseconds: 1500));
                  _audioPlayer.play(AssetSource('audio/finished.mp3'));
                }

                Future.delayed(const Duration(seconds: 2), nextQuestion);
              },
        child: Row(
          children: [
            Text(
              '${index + 1}',
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
