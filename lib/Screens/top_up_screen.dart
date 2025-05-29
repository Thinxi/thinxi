import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final TextEditingController amountController = TextEditingController();
  double balance = 0.0;
  final double minTopUp = 5.0;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wallet')
        .doc('main')
        .get();

    if (doc.exists) {
      setState(() {
        balance = doc['balance'] ?? 0.0;
      });
    }
  }

  Future<void> _submitTopUp() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    double? enteredAmount = double.tryParse(amountController.text);
    if (enteredAmount == null || enteredAmount < minTopUp) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Minimum top-up is $minTopUp USD."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ثبت تراکنش به عنوان pending
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .add({
      'type': 'topup',
      'amount': enteredAmount,
      'currency': 'USD',
      'status': 'pending',
      'method': 'manual',
      'createdAt': Timestamp.now(),
      'note': 'User requested manual top-up'
    });

    amountController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Top-up request submitted. Awaiting confirmation."),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            const Icon(Icons.upload, size: 60, color: Colors.white),
            const SizedBox(height: 10),
            const Text("Top Up",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 20),
            const Text("Your Balance:",
                style: TextStyle(fontSize: 20, color: Colors.white)),
            Text("\$${balance.toStringAsFixed(2)} USD",
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white70),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Enter amount to top up"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitTopUp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Request Top Up",
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "The minimum top-up is 5 USD. Once approved, your wallet will be updated.",
              style: TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
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
        },
        backgroundColor: Colors.black,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.white70,
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.black54,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
