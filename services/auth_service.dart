import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static Future<void> signInWithGoogle() async {
    try {
      // Sign out from any previous Google account to force account picker
      await GoogleSignIn().signOut();

      // Start Google Sign-In flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        print('⚠️ Google Sign-In was cancelled by the user.');
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        print('❌ No user returned after sign-in.');
        return;
      }

      // Check and store user info in Firestore
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
          'createdAt': Timestamp.now(),
        });
        print('✅ New user saved to Firestore.');
      } else {
        print('ℹ️ Existing user. No need to create document.');
      }

      print('🎉 Google Sign-In successful: ${user.email}');
    } catch (e) {
      print('❌ Error during Google Sign-In: $e');
    }
  }
}
