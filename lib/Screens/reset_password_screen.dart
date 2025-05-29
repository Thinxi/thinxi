import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0;

  void _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage("Please enter your email.");
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showMessage("Reset link sent! Check your email.");
    } catch (e) {
      _showMessage("Error: ${e.toString()}");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.blueAccent,
    ));
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Ooops!!!",
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Forgot Password?\nYou need a better memory to win in Thinxi",
              style: TextStyle(fontSize: 14, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildInputField("Enter your email"),
            const SizedBox(height: 20),
            _buildGradientButton("Send Reset Link", _resetPassword),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                // Navigate to support screen
              },
              child: const Text(
                "Need help? Go to Support",
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Image.asset("assets/images/thinxi_logo.png", height: 60),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFFFF007F),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/icons/home.png',
                width: 24, height: 24),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/icons/explore.png',
                width: 24, height: 24),
            label: "Explore",
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/icons/wallet.png',
                width: 24, height: 24),
            label: "Wallet",
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/icons/setting.png',
                width: 24, height: 24),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
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
        gradient: const LinearGradient(colors: [Colors.blue, Colors.pink]),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
        ),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 18)),
      ),
    );
  }
}
