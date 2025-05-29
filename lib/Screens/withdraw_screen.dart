import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  String? selectedCurrency;
  String? selectedCard;
  final TextEditingController amountController = TextEditingController();
  double? balance;
  String currency = "USD";
  final double minWithdraw = 10.0;

  @override
  void initState() {
    super.initState();
    fetchWallet();
  }

  Future<void> fetchWallet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wallet')
        .doc('main')
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        setState(() {
          balance = data['balance']?.toDouble() ?? 0.0;
          currency = data['currency'] ?? 'USD';
        });
      }
    }
  }

  Future<void> _withdraw() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    double? enteredAmount = double.tryParse(amountController.text);

    if (enteredAmount == null ||
        enteredAmount < minWithdraw ||
        enteredAmount > (balance ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Minimum withdrawal is $minWithdraw $currency. Ensure you have enough balance."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .add({
        'type': 'withdraw',
        'amount': enteredAmount,
        'currency': currency,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'destination': selectedCard ?? 'N/A',
        'note': 'User selected $selectedCurrency',
      });

      amountController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Withdrawal request submitted and pending approval."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error submitting withdrawal: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            const Icon(Icons.download, size: 60, color: Colors.white),
            const SizedBox(height: 10),
            const Text("Withdrawal",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 20),
            const Text("Your Balance:",
                style: TextStyle(fontSize: 20, color: Colors.white)),
            Text(
              balance != null
                  ? "\$${balance!.toStringAsFixed(2)} $currency"
                  : "Loading...",
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent),
            ),
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
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.black,
                    value: selectedCurrency,
                    decoration: _inputDecoration("Choose currency"),
                    items: ["USD", "EUR", "BTC", "OMR"].map((String currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency,
                            style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCurrency = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.black,
                    value: selectedCard,
                    decoration: _inputDecoration("Choose Card"),
                    items: [
                      "Visa **** 1234",
                      "Mastercard **** 5678",
                      "Crypto Wallet"
                    ].map((String card) {
                      return DropdownMenuItem(
                        value: card,
                        child: Text(card,
                            style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCard = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Amount"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _withdraw,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Withdraw",
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Depending on destination regulations and country, the withdrawal usually takes up to 2 hours.",
              style: TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            const Text(
              "Please read the rules by clicking on this link before completing the action.",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
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
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.auto_graph), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ""),
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
