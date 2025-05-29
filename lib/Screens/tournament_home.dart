import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thinxi/screens/intro_screen.dart';
import 'package:thinxi/screens/tournament_questions_ui.dart';

class TournamentHome extends StatelessWidget {
  const TournamentHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Tournament',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: false,
      ),
      backgroundColor: Colors.black,
      body: const TournamentBody(),
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
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/icons/home.png')),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/icons/explore.png')),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/icons/wallet.png')),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/icons/setting.png')),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class TournamentBody extends StatelessWidget {
  const TournamentBody({super.key});

  Future<void> _joinTournament(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final sessionId = 'T-${DateTime.now().millisecondsSinceEpoch}';

    try {
      final walletDoc = await userRef.collection('wallet').doc('main').get();
      final balance = walletDoc.data()?['balance'] ?? 0.0;

      if (balance < 1.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Not enough balance to join tournament.")),
        );
        return;
      }

      await FirebaseFirestore.instance.runTransaction((txn) async {
        txn.update(userRef.collection('wallet').doc('main'), {
          'balance': FieldValue.increment(-1.0),
        });

        txn.set(
          FirebaseFirestore.instance
              .collection('tournament_sessions')
              .doc(sessionId),
          {
            'userId': user.uid,
            'status': 'active',
            'score': 0,
            'joinedAt': Timestamp.now(),
            'seed': DateTime.now().millisecondsSinceEpoch % 1000,
            'paused': false,
            'refundable': true,
          },
        );
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IntroScreen(
            title: 'Tournament Mode',
            description: 'Compete with 99 other players and win big rewards!',
            onStart: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TournamentQuestionsScreen(),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tournament entry failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/images/icons/tournament_intro.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Compete with 99 players from around the world. Score the most correct answers fastest to claim your share of the prize! The top 50 finishers earn rewards from 12× their entry fee down to 1/10 of it. Your prize is automatically added to your wallet in the currency you prefer.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF3B41C5),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _joinTournament(context),
            child: const Text(
              'Start (one ticket)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/wallet');
            },
            child: const Text(
              'Need charge? Top up now',
              style: TextStyle(
                color: Colors.purpleAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
