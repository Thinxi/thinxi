import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  double progressValue = 0.0;
  bool firebaseInitialized = false;

  @override
  void initState() {
    super.initState();
    initializeFirebase();
  }

  Future<void> initializeFirebase() async {
    try {
      print("🚀 Initializing Firebase...");
      await Firebase.initializeApp();
      print("✅ Firebase initialized!");
      setState(() {
        firebaseInitialized = true;
      });
      checkSavedLogin();
    } catch (e) {
      print("❌ Firebase initialization error: $e");
    }
  }

  Future<void> checkSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    final savedPassword = prefs.getString('password');

    if (savedEmail != null && savedPassword != null) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: savedEmail,
          password: savedPassword,
        );
        print("🔐 Auto login successful");
        Navigator.pushReplacementNamed(context, "/home");
        return;
      } catch (e) {
        print("⚠️ Auto login failed: $e");
      }
    }

    startLoadingAnimation();
  }

  void startLoadingAnimation() {
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (progressValue >= 1.0) {
        timer.cancel();
        Navigator.pushReplacementNamed(context, "/login");
      } else {
        setState(() {
          progressValue += 0.1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Center(
            child: Image.asset("assets/images/logo.png", width: 200),
          ),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 10,
                backgroundColor: Colors.pink.shade100,
                valueColor: AlwaysStoppedAnimation(Colors.blue.shade400),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              width: 80,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
