// lib/services/task_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> markTaskCompleted(String userId, String taskId) async {
  final taskRef = FirebaseFirestore.instance
      .collection('user_tasks')
      .doc(userId)
      .collection('tasks')
      .doc(taskId);

  await taskRef.set({
    'completed': true,
    'claimed': false,
    'completedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
