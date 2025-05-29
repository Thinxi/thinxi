import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RewardHelper {
  static Future<void> trigger(String key) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('reward_triggers')
        .doc(key)
        .set({
      'triggered': true,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> checkAndCompleteTask(String taskId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final taskRef =
        FirebaseFirestore.instance.collection('user_tasks').doc(user.uid);

    final taskDoc = await taskRef.get();
    final currentData = taskDoc.data() ?? {};

    final alreadyCompleted = currentData[taskId]?['completed'] ?? false;

    if (!alreadyCompleted) {
      await taskRef.set({
        taskId: {'completed': true, 'claimed': false}
      }, SetOptions(merge: true));
    }
  }
}
