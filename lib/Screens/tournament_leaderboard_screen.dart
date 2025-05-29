import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';

class TournamentLeaderboardScreen extends StatefulWidget {
  const TournamentLeaderboardScreen({super.key});

  @override
  State<TournamentLeaderboardScreen> createState() =>
      _TournamentLeaderboardScreenState();
}

class _TournamentLeaderboardScreenState
    extends State<TournamentLeaderboardScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  double calculatePrize(int rank) {
    if (rank == 1) return 12.0;
    if (rank == 2) return 8.0;
    if (rank == 3) return 6.0;
    if (rank >= 4 && rank <= 50) {
      const double a = 1.29787;
      const double d = 0.00647;
      return a - ((rank - 4) * d);
    }
    return 0.0;
  }

  Future<List<Map<String, dynamic>>> fetchResultsWithUsernames() async {
    final resultsSnapshot =
        await FirebaseFirestore.instance.collection('tournament_results').get();

    final usersCollection = FirebaseFirestore.instance.collection('users');

    List<Map<String, dynamic>> results = [];

    for (var doc in resultsSnapshot.docs) {
      final data = doc.data();
      final playerId = doc.id;

      final userDoc = await usersCollection.doc(playerId).get();
      final userData = userDoc.data();

      String displayName = playerId;

      if (userData != null) {
        final username = userData['username'];
        final email = userData['email'];

        if (username != null && username.toString().trim().isNotEmpty) {
          displayName = username;
        } else if (email != null && email.toString().contains('@')) {
          displayName = email.split('@')[0];
        }
      }

      results.add({
        ...data,
        'playerId': playerId,
        'displayName': displayName,
      });
    }

    results.sort((a, b) {
      int correctA = a['correct_answers'] ?? 0;
      int correctB = b['correct_answers'] ?? 0;
      if (correctA != correctB) {
        return correctB.compareTo(correctA);
      }
      int timeA = a['total_time'] ?? 999999;
      int timeB = b['total_time'] ?? 999999;
      return timeA.compareTo(timeB);
    });

    bool isWinner = false;
    for (int i = 0; i < results.length && i < 50; i++) {
      if (results[i]['playerId'] == currentUserId) {
        isWinner = true;
        break;
      }
    }

    if (isWinner) {
      _audioPlayer.play(AssetSource('audio/reward.mp3'));
    } else {
      _audioPlayer.play(AssetSource('audio/no prize tournament.mp3'));
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchResultsWithUsernames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No results available.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          List<Map<String, dynamic>> results = snapshot.data!;

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.blueAccent),
              columns: const [
                DataColumn(
                    label: Text('Rank', style: TextStyle(color: Colors.white))),
                DataColumn(
                    label: Text('Username',
                        style: TextStyle(color: Colors.white))),
                DataColumn(
                    label:
                        Text('Correct', style: TextStyle(color: Colors.white))),
                DataColumn(
                    label:
                        Text('Time(s)', style: TextStyle(color: Colors.white))),
                DataColumn(
                    label:
                        Text('Prize', style: TextStyle(color: Colors.white))),
              ],
              rows: List.generate(results.length, (index) {
                int rank = index + 1;
                double prize = 0.0;
                if (rank <= 50) {
                  prize = calculatePrize(rank);
                }
                return DataRow(
                  cells: [
                    DataCell(Text(rank.toString(),
                        style: const TextStyle(color: Colors.white))),
                    DataCell(Text(results[index]['displayName'] ?? '',
                        style: const TextStyle(color: Colors.white))),
                    DataCell(Text(results[index]['correct_answers'].toString(),
                        style: const TextStyle(color: Colors.white))),
                    DataCell(Text(results[index]['total_time'].toString(),
                        style: const TextStyle(color: Colors.white))),
                    DataCell(Text(prize.toStringAsFixed(2),
                        style: const TextStyle(color: Colors.white))),
                  ],
                );
              }),
            ),
          );
        },
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
