import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

// Services
import 'services/language_manager.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/swap_screen.dart';
import 'screens/withdraw_screen.dart';
import 'screens/classic_questions_ui.dart';
import 'screens/tournament_questions_ui.dart';
import 'screens/invite_rewards_screen.dart';
import 'screens/rankings_leaderboards_screen.dart';
import 'screens/live_scoreboard.dart';
import 'screens/winners_screen.dart';
import 'screens/transaction_list_screen.dart';
import 'screens/tutorial_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/practice_ai_game.dart';
import 'screens/millionaire_screen.dart';
import 'screens/millionaire_questions_ui.dart';
import 'screens/millionaire_reward_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageManager(),
      child: const ThinxiApp(),
    ),
  );
}

class ThinxiApp extends StatelessWidget {
  const ThinxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thinxi',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const RootRouter(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/reset_password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/swap': (context) => const SwapScreen(),
        '/withdraw': (context) => const WithdrawScreen(),
        '/classic_questions': (context) => const ClassicQuestionsScreen(),
        '/tournament': (context) => const TournamentQuestionsScreen(),
        '/invite': (context) => const InviteRewardsScreen(),
        '/rankings': (context) => const RankingsLeaderboardsScreen(),
        '/live_scoreboard': (context) => const LiveScoreboardScreen(),
        '/winners': (context) => const WinnersScreen(),
        '/transactions': (context) => const TransactionListScreen(),
        '/tutorial': (context) => const TutorialScreen(),
        '/practice_ai': (context) => const PracticeAIGame(),
        '/millionaire': (context) => const MillionaireScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/millionaire_questions_ui') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null && args.containsKey('questionNumber')) {
            return MaterialPageRoute(
              builder: (context) => MillionaireQuestionsUI(
                questionNumber: args['questionNumber'],
              ),
            );
          }
        }

        if (settings.name == '/millionaire_reward_screen') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null &&
              args.containsKey('questionNumber') &&
              args.containsKey('isCorrect')) {
            return MaterialPageRoute(
              builder: (context) => MillionaireRewardScreen(
                questionNumber: args['questionNumber'],
                isCorrect: args['isCorrect'],
              ),
            );
          }
        }

        return null;
      },
    );
  }
}

class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  Future<Widget> _getStartScreen() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final data = doc.data();
        final isFirstTime = data != null && data['first_time_user'] == true;

        return isFirstTime ? const TutorialScreen() : const HomeScreen();
      } catch (e) {
        print("❌ Error loading user data: $e");
        return const HomeScreen();
      }
    }

    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getStartScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return snapshot.data!;
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
