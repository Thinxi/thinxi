import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await uploadInitialTasks();
  print("✅ Tasks uploaded successfully!");
}

Future<void> uploadInitialTasks() async {
  final tasks = [
    {
      "id": "signup",
      "title": "Sign Up",
      "description": "Register your account",
      "reward": 5,
      "type": "once",
      "trigger": "user_signup",
      "active": true,
    },
    {
      "id": "first_game",
      "title": "First Game",
      "description": "Play your first game",
      "reward": 5,
      "type": "once",
      "trigger": "game_played",
      "active": true,
    },
    {
      "id": "first_win",
      "title": "First Win",
      "description": "Win your first game",
      "reward": 10,
      "type": "once",
      "trigger": "game_won",
      "active": true,
    },
    {
      "id": "complete_profile",
      "title": "Profile Setup",
      "description": "Complete your profile",
      "reward": 5,
      "type": "once",
      "trigger": "profile_completed",
      "active": true,
    },
    {
      "id": "first_tournament",
      "title": "First Tournament",
      "description": "Join your first tournament",
      "reward": 10,
      "type": "once",
      "trigger": "tournament_joined",
      "active": true,
    },
    {
      "id": "invite_friend_1",
      "title": "Invite a Friend",
      "description": "Invite and verify one friend",
      "reward": 10,
      "type": "repeatable",
      "trigger": "friend_invited",
      "active": true,
    },
    {
      "id": "game_3_today",
      "title": "Triple Play",
      "description": "Play 3 games in a day",
      "reward": 5,
      "type": "daily",
      "trigger": "game_played_daily_3",
      "active": true,
    },
    {
      "id": "daily_ad_watch",
      "title": "Ad Bonus",
      "description": "Watch 1 ad today",
      "reward": 3,
      "type": "daily",
      "trigger": "ad_watched",
      "active": true,
    },
    {
      "id": "win_3_streak",
      "title": "Winning Streak",
      "description": "Win 3 games in a row",
      "reward": 10,
      "type": "repeatable",
      "trigger": "win_streak_3",
      "active": true,
    },
    {
      "id": "answer_50_day",
      "title": "Fast Learner",
      "description": "Answer 50 questions in a day",
      "reward": 7,
      "type": "daily",
      "trigger": "questions_answered_50",
      "active": true,
    },
    {
      "id": "game_5_total",
      "title": "Rookie Player",
      "description": "Play 5 games in total",
      "reward": 7,
      "type": "once",
      "trigger": "games_played_5_total",
      "active": true,
    },
    {
      "id": "game_10_total",
      "title": "Amateur Gamer",
      "description": "Play 10 games in total",
      "reward": 10,
      "type": "once",
      "trigger": "games_played_10_total",
      "active": true,
    },
    {
      "id": "win_5_total",
      "title": "Getting Good",
      "description": "Win 5 games",
      "reward": 15,
      "type": "once",
      "trigger": "games_won_5_total",
      "active": true,
    },
    {
      "id": "tournament_3",
      "title": "Tournament Tryout",
      "description": "Join 3 tournaments",
      "reward": 10,
      "type": "once",
      "trigger": "tournaments_joined_3",
      "active": true,
    },
    {
      "id": "invite_3_friends",
      "title": "Trio Recruiter",
      "description": "Invite and verify 3 friends",
      "reward": 20,
      "type": "once",
      "trigger": "friends_invited_3",
      "active": true,
    },
    {
      "id": "streak_5",
      "title": "Super Streak",
      "description": "Win 5 games in a row",
      "reward": 15,
      "type": "repeatable",
      "trigger": "win_streak_5",
      "active": true,
    },
    {
      "id": "questions_200_total",
      "title": "Quiz Fanatic",
      "description": "Answer 200 questions",
      "reward": 10,
      "type": "once",
      "trigger": "questions_answered_200_total",
      "active": true,
    },
    {
      "id": "watch_5_ads",
      "title": "Ad Watcher",
      "description": "Watch 5 rewarded ads",
      "reward": 5,
      "type": "once",
      "trigger": "ads_watched_5_total",
      "active": true,
    },
    {
      "id": "coin_100_earned",
      "title": "Mini Banker",
      "description": "Earn 100 coins total",
      "reward": 10,
      "type": "once",
      "trigger": "coins_earned_100",
      "active": true,
    },
    {
      "id": "profile_picture",
      "title": "Say Cheese!",
      "description": "Upload a profile picture",
      "reward": 5,
      "type": "once",
      "trigger": "profile_picture_uploaded",
      "active": true,
    },
  ];

  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  for (var task in tasks) {
    final docRef =
        firestore.collection('reward_tasks').doc(task['id'] as String?);
    batch.set(docRef, task);
  }

  await batch.commit();
}
