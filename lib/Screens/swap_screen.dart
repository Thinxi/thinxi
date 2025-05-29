import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  String? fromCurrency;
  String? toCurrency;
  final TextEditingController amountController = TextEditingController();
  double? balance;
  String walletCurrency = "USD";
  double convertedAmount = 0.0;
  Map<String, double> exchangeRates = {};

  @override
  void initState() {
    super.initState();
    fetchWallet();
    fetchExchangeRates();
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
      setState(() {
        balance = data?['balance']?.toDouble() ?? 0.0;
        walletCurrency = data?['currency'] ?? 'USD';
        fromCurrency = walletCurrency;
      });
    }
  }

  Future<void> fetchExchangeRates() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('exchangeRates').get();
    Map<String, double> rates = {};
    for (var doc in snapshot.docs) {
      rates[doc.id] = doc.data()['rateToUSD']?.toDouble() ?? 1.0;
    }
    setState(() {
      exchangeRates = rates;
    });
  }

  void _convertCurrency() {
    final inputAmount = double.tryParse(amountController.text);
    if (inputAmount == null || fromCurrency == null || toCurrency == null) {
      return;
    }
    final fromRate = exchangeRates[fromCurrency] ?? 1.0;
    final toRate = exchangeRates[toCurrency] ?? 1.0;
    final usdAmount = inputAmount * fromRate;
    final converted = usdAmount / toRate;
    setState(() {
      convertedAmount = converted;
    });
  }

  Future<void> _swap() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final inputAmount = double.tryParse(amountController.text);
    if (inputAmount == null || inputAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please enter a valid amount."),
            backgroundColor: Colors.red),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .add({
      'type': 'swap',
      'from': fromCurrency,
      'to': toCurrency,
      'amount': inputAmount,
      'converted': convertedAmount,
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "Swap completed: $inputAmount $fromCurrency → ${convertedAmount.toStringAsFixed(2)} $toCurrency"),
        backgroundColor: Colors.green,
      ),
    );
    amountController.clear();
    setState(() {
      convertedAmount = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final availableCurrencies = exchangeRates.keys.toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            const Icon(Icons.swap_horiz, size: 60, color: Colors.white),
            const SizedBox(height: 10),
            const Text("Swap",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 20),
            const Text("Your Balance:",
                style: TextStyle(fontSize: 20, color: Colors.white)),
            Text(
              balance != null
                  ? "\$${balance!.toStringAsFixed(2)} $walletCurrency"
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
                    value: fromCurrency,
                    decoration: _inputDecoration("From Currency"),
                    dropdownColor: Colors.black,
                    items: availableCurrencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency,
                            style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => fromCurrency = value);
                      _convertCurrency();
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: toCurrency,
                    decoration: _inputDecoration("To Currency"),
                    dropdownColor: Colors.black,
                    items: availableCurrencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency,
                            style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => toCurrency = value);
                      _convertCurrency();
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Amount to convert"),
                    onChanged: (value) => _convertCurrency(),
                  ),
                  const SizedBox(height: 20),
                  const Text("Converted Amount:",
                      style: TextStyle(fontSize: 16, color: Colors.white70)),
                  Text(
                    "${convertedAmount.toStringAsFixed(2)} ${toCurrency ?? ''}",
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _swap,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Swap",
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Swapping shows the equivalent value in your preferred currency. Balance remains in your base currency.",
              style: TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            const Text(
              "Exchange rates are pulled from live Firestore data.",
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
