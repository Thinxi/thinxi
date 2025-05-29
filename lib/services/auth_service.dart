import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  static Future<void> signInWithGoogle() async {
    try {
      // Step 1: Google sign-in
      GoogleSignInAccount? googleUser;

      if (kIsWeb) {
        googleUser = await GoogleSignIn(
          clientId:
              '931641118924-6gef74vvccg2h51ql9n05kjdp10j2of3.apps.googleusercontent.com',
        ).signIn();
      } else {
        googleUser = await GoogleSignIn().signIn();
      }

      if (googleUser == null) {
        print('❌ Sign-in canceled by user.');
        return;
      }

      // Step 2: Get credentials
      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 3: Sign in to Firebase Auth
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        print("❌ Firebase user is null after sign-in.");
        return;
      }

      print("✅ Logged in as ${user.email}");

      // Step 4: Save to Firestore if new user
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? '',
          'photoUrl': user.photoURL ?? '',
          'score': 0,
          'language': 'English',
          'country': 'Unknown',
          'phone': '',
          'isPremium': false,
          'createdAt': Timestamp.now(),
        });
        print("🔥 New user saved to Firestore: ${user.email}");
      } else {
        print("🔁 User already exists: ${user.email}");
      }
    } catch (e) {
      print("❌ Error during Google Sign-In: $e");
    }
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    print("🚪 User signed out.");
  }

  static User? get currentUser => FirebaseAuth.instance.currentUser;
}
