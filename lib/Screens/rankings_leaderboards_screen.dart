import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/reward_dialog.dart';

class RankingsLeaderboardsScreen extends StatefulWidget {
  const RankingsLeaderboardsScreen({super.key});

  @override
  State<RankingsLeaderboardsScreen> createState() =>
      _RankingsLeaderboardsScreenState();
}

class _RankingsLeaderboardsScreenState
    extends State<RankingsLeaderboardsScreen> {
  List<Map<String, dynamic>> leaderboardData = [];
  List<Map<String, dynamic>> taskRewards = [];
  List<Map<String, dynamic>> userGames = [];
  int completedTasks = 0;
  int totalTasks = 0;

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
    fetchTasks();
    fetchRecentGames();
  }

  Future<void> fetchLeaderboard() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('leaderboards')
        .orderBy('score', descending: true)
        .limit(10)
        .get();
    final data = snapshot.docs.map((doc) => doc.data()).toList();
    setState(() => leaderboardData = List<Map<String, dynamic>>.from(data));
  }

  Future<void> fetchTasks() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final allTasksSnap =
        await FirebaseFirestore.instance.collection('reward_tasks').get();
    final userTasksSnap = await FirebaseFirestore.instance
        .collection('user_tasks')
        .doc(uid)
        .get();
    final userData = userTasksSnap.data() ?? {};

    List<Map<String, dynamic>> tasks = [];
    int done = 0;

    for (var doc in allTasksSnap.docs) {
      final task = doc.data();
      final id = task['id'];
      final isCompleted = userData[id]?['completed'] ?? false;
      final isClaimed = userData[id]?['claimed'] ?? false;
      if (isCompleted) done++;
      tasks.add({
        'title': task['title'],
        'id': id,
        'reward': task['reward'],
        'completed': isCompleted,
        'claimed': isClaimed,
      });
    }

    setState(() {
      taskRewards = tasks;
      completedTasks = done;
      totalTasks = tasks.length;
    });
  }

  Future<void> claimTask(String taskId, int reward) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('user_tasks').doc(uid).set({
      taskId: {'claimed': true},
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance.collection('wallet_transactions').add({
      'user_id': uid,
      'type': 'reward',
      'amount': reward,
      'timestamp': FieldValue.serverTimestamp(),
      'source': taskId,
    });

    showDialog(
      context: context,
      builder: (context) => RewardDialog(onFinished: () {
        Navigator.pop(context);
        fetchTasks();
      }),
    );
  }

  Future<void> fetchRecentGames() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('game_results')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();

    setState(() {
      userGames = snapshot.docs.map((e) => e.data()).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              _buildGradientTitle("RANKINGS & LEADERBOARDS"),
              const SizedBox(height: 20),
              _buildTopPlayersSection(),
              const SizedBox(height: 30),
              _buildTaskProgressSection(),
              const SizedBox(height: 20),
              const Text("Task Rewards",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...taskRewards.map((task) => _buildTaskItem(task)).toList(),
              const SizedBox(height: 30),
              const Text("Your Last Games",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 10),
              ...userGames.map((g) => _buildLastGameCard(
                  g['rank']?.toString() ?? "-",
                  g['mode'] ?? "Classic",
                  g['score']?.toString() ?? "-")),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
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
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFFFF007F),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/icons/home.png',
                width: 24, height: 24),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/icons/explore.png',
                width: 24, height: 24),
            label: "Explore",
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/icons/wallet.png',
                width: 24, height: 24),
            label: "Wallet",
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/icons/setting.png',
                width: 24, height: 24),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  Widget _buildGradientTitle(String text) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Colors.pinkAccent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );

  Widget _buildTopPlayersSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Top Players",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 10),
          ...leaderboardData.map((player) => _buildLeaderboardItem(
              player["name"],
              player["score"],
              player["earning"],
              player["rank"])),
        ],
      );

  Widget _buildLeaderboardItem(
          String name, dynamic points, dynamic earning, dynamic rank) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text("Earning $earning",
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            Text("$points points",
                style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            Text(rank.toString(),
                style: TextStyle(
                    color: rank == "1st"
                        ? Colors.red
                        : rank == "2nd"
                            ? Colors.orange
                            : Colors.purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
      );

  Widget _buildTaskProgressSection() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.grey[900], borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            Text("$completedTasks/$totalTasks Tasks completed",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (totalTasks == 0) ? 0 : completedTasks / totalTasks,
                minHeight: 10,
                backgroundColor: Colors.pink.shade100,
                valueColor: const AlwaysStoppedAnimation(Colors.blueAccent),
              ),
            ),
          ],
        ),
      );

  Widget _buildTaskItem(Map<String, dynamic> task) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12), color: Colors.grey[900]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(task['title'],
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            ElevatedButton(
              onPressed: (task['completed'] && !task['claimed'])
                  ? () => claimTask(task['id'], task['reward'])
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: (task['completed'] && !task['claimed'])
                    ? Colors.pink
                    : Colors.grey,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                task['claimed'] ? "Claimed" : "Claim",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

  Widget _buildLastGameCard(String rank, String gameType, String score) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12), color: Colors.grey[900]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rank,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(gameType,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
                Text("Score: $score",
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("View Details",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
}
