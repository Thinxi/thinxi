import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await setupTestUserTasks();
  print("✅ Test tasks created successfully!");
}

Future<void> setupTestUserTasks() async {
  const String userId = 'test_user';

  final tasksToSet = [
    'first_game',
    'first_win',
    'invite_friend_1',
  ];

  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  for (var taskId in tasksToSet) {
    final taskRef = firestore
        .collection('user_tasks')
        .doc(userId)
        .collection('tasks')
        .doc(taskId);

    batch.set(taskRef, {
      'completed': true,
      'claimed': false,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
}
