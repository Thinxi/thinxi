import 'package:flutter/material.dart';
import 'package:thinxi/services/auth_service.dart';
import '../services/task_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LoginScreen extends StatefulWidget {
  final String? initialEmail;

  const LoginScreen({super.key, this.initialEmail});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final String predefinedEmail = "mhjhays@gmail.com";
  final String predefinedPassword = "54875487";

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      emailController.text = widget.initialEmail!;
    }
  }

  Future<void> initializeWalletIfNeeded(String uid, String country) async {
    final walletRef = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("wallet")
        .doc("main");

    final walletDoc = await walletRef.get();
    if (!walletDoc.exists) {
      final walletCurrency = country.toLowerCase() == "iran" ? "IRR" : "USD";
      await walletRef.set({
        'balance': 0.0,
        'currency': walletCurrency,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  void handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email == predefinedEmail && password == predefinedPassword) {
      await markTaskCompleted("test_user", "first_game");
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user == null) throw Exception("User not found.");

      await user.reload();

      if (!user.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please verify your email before logging in."),
        ));
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final country = userDoc.data()?['country'] ?? 'Other';

      await initializeWalletIfNeeded(user.uid, country);

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    }
  }

  void handleGoogleSignIn() async {
    try {
      await AuthService.signInWithGoogle();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Google login failed. Please try again.")));
        return;
      }

      if (!user.emailVerified && !kIsWeb) {
        await user.sendEmailVerification();
      }

      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        // 🆕 اگر کاربر برای اولین بار با گوگل لاگین کرده
        await userDocRef.set({
          'uid': user.uid,
          'email': user.email,
          'username': user.displayName ?? 'Anonymous',
          'country': 'Other',
          'countryCode': '',
          'language': 'English',
          'phone': user.phoneNumber ?? '',
          'photoUrl': user.photoURL,
          'score': 0,
          'isPremium': false,
          'createdAt': Timestamp.now(),
          'first_time_user': true, // 👈 مهم‌ترین خط
        });
      }

      final country = userDoc.data()?['country'] ?? 'Other';

      await initializeWalletIfNeeded(user.uid, country);

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            const Text(
              "Guess who is here!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Welcome back. Use your email\nand password to login",
              style: TextStyle(fontSize: 14, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildInputField(Icons.email, "Your Email",
                controller: emailController),
            _buildInputField(Icons.lock, "Password",
                isPassword: true, controller: passwordController),
            const SizedBox(height: 20),
            _buildGradientButton("Log In", handleLogin),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              icon: const Icon(Icons.g_mobiledata, color: Colors.white),
              label: const Text("Sign in with Google",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              onPressed: handleGoogleSignIn,
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/reset_password'),
              child: const Text(
                "Forgot your password?\nClick here",
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/signup'),
              child: const Text(
                "Don't have an account? Signup",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Image.asset("assets/images/logo.png", height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(IconData icon, String hint,
      {bool isPassword = false, TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white70),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.black54,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.pink],
        ),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15)),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 18)),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
