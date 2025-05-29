import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/app_localization.dart';
import '../screens/reward_dialog.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> dailyTasks = [];
  List<Map<String, dynamic>> weeklyTasks = [];
  List<Map<String, dynamic>> monthlyTasks = [];
  List<bool> weeklyProgress = List.filled(7, false);
  int tasksCompleted = 0;
  int daysRemaining = 7;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadWeeklyProgress();
  }

  Future<void> _loadTasks() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore.collection('reward_tasks').get();
    final userTaskDoc =
        await _firestore.collection('user_tasks').doc(user.uid).get();
    final userData = userTaskDoc.data() ?? {};

    List<Map<String, dynamic>> daily = [];
    List<Map<String, dynamic>> weekly = [];
    List<Map<String, dynamic>> monthly = [];
    int completedCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final id = data['id'];
      bool completed = userData[id]?['completed'] ?? false;
      bool claimed = userData[id]?['claimed'] ?? false;
      if (completed && !claimed) completedCount++;

      final task = {
        ...data,
        'completed': completed,
        'claimed': claimed,
      };

      if (data['type'] == 'daily') {
        daily.add(task);
      } else if (data['type'] == 'weekly') {
        weekly.add(task);
      } else if (data['type'] == 'monthly') {
        monthly.add(task);
      }
    }

    setState(() {
      dailyTasks = daily;
      weeklyTasks = weekly;
      monthlyTasks = monthly;
      tasksCompleted = completedCount;
    });
  }

  Future<void> _loadWeeklyProgress() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      final List<dynamic> days =
          data['weekly_task']?['days'] ?? List.filled(7, false);
      final timestamp = data['weekly_task']?['lastUpdated'];

      if (timestamp != null) {
        final lastDate = (timestamp as Timestamp).toDate();
        final now = DateTime.now();
        final difference = now.difference(lastDate).inDays;
        daysRemaining = 7 - difference.clamp(0, 7);

        if (difference > 7) {
          await _firestore.collection('users').doc(user.uid).update({
            'weekly_task.days': List.filled(7, false),
            'weekly_task.lastUpdated': DateTime.now(),
          });
          setState(() {
            weeklyProgress = List.filled(7, false);
            daysRemaining = 7;
          });
        } else {
          setState(() {
            weeklyProgress = List<bool>.from(days);
          });
        }
      }
    }
  }

  Future<void> _claimReward(String taskId, int reward) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('user_tasks').doc(user.uid).set({
      taskId: {'claimed': true},
    }, SetOptions(merge: true));

    await _firestore.collection('wallet_transactions').add({
      'user_id': user.uid,
      'type': 'reward',
      'amount': reward,
      'timestamp': FieldValue.serverTimestamp(),
      'source': taskId,
    });

    showDialog(
      context: context,
      builder: (context) => RewardDialog(onFinished: () {
        Navigator.pop(context);
        _loadTasks();
      }),
    );
  }

  Widget _buildTaskSection(String title, List<Map<String, dynamic>> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: T(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ),
        ...tasks.map((task) => _buildTaskRow(task)).toList(),
      ],
    );
  }

  Widget _buildTaskRow(Map<String, dynamic> task) {
    final bool completed = task['completed'] ?? false;
    final bool claimed = task['claimed'] ?? false;
    final bool claimable = completed && !claimed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.yellow, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: T(task['title'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
          GestureDetector(
            onTap: claimable
                ? () => _claimReward(task['id'], task['reward'])
                : null,
            child: Container(
              decoration: BoxDecoration(
                gradient: claimable
                    ? const LinearGradient(
                        colors: [Color(0xFF3B41C5), Color(0xFFED1E79)])
                    : null,
                color: claimed ? Colors.grey : null,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: T(
                claimed ? "Claimed" : "Claim",
                style: TextStyle(
                  color: claimed
                      ? Colors.white60
                      : (claimable ? Colors.white : Colors.white70),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DirectionalWrapper(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const T('Explore', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/rankings'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B41C5), Color(0xFFED1E79)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const T(
                    "RANKINGS & LEADERBOARDS",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        7,
                        (index) => Container(
                          width: 30,
                          height: 30,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: weeklyProgress[index]
                                ? Colors.purple
                                : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    T("$tasksCompleted/7 Tasks completed",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("$daysRemaining ",
                            style: const TextStyle(
                                color: Colors.pink,
                                fontSize: 28,
                                fontWeight: FontWeight.bold)),
                        const T("DAYS TO GO",
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const T(
                      "Complete the tasks and get your 1 free Tournament ticket and win up to 12X",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildTaskSection("Daily Tasks", dailyTasks),
              _buildTaskSection("Weekly Tasks", weeklyTasks),
              _buildTaskSection("Monthly Tasks", monthlyTasks),
            ],
          ),
        ),
      ),
    );
  }
}
