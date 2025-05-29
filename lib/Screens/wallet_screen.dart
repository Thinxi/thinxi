import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thinxi/helpers/reward_helper.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final int _selectedIndex = 2;
  double? balance;
  String currency = "USD";
  String? username = "";
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    fetchWallet();
    fetchUsername();
    fetchTransactions();
    RewardHelper.checkAndCompleteTask("wallet_opened");
  }

  Future<void> fetchWallet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final walletDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wallet')
        .doc('main')
        .get();

    if (walletDoc.exists) {
      final data = walletDoc.data();
      if (data != null) {
        setState(() {
          balance = data['balance']?.toDouble() ?? 0.0;
          currency = data['currency'] ?? 'USD';
        });
      }
    }
  }

  Future<void> fetchUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null) {
        setState(() {
          username = data['username'] ?? data['name'] ?? '';
        });
      }
    }
  }

  Future<void> fetchTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wallet')
        .doc('main')
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();

    setState(() {
      transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  void _showTopUpDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Top Up"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Enter amount (USD)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null && controller.text.isNotEmpty) {
                final amount = double.tryParse(controller.text);
                if (amount != null && amount > 0) {
                  final tx = {
                    'type': 'TopUp',
                    'amount': amount,
                    'currency': currency,
                    'timestamp': Timestamp.now(),
                    'status': 'completed',
                    'dispute': false,
                  };

                  final walletRef = FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('wallet')
                      .doc('main');

                  final txRef = walletRef.collection('transactions').doc();

                  await FirebaseFirestore.instance.runTransaction((txn) async {
                    final walletSnap = await txn.get(walletRef);
                    final currentBalance =
                        walletSnap.data()?['balance']?.toDouble() ?? 0.0;

                    txn.update(walletRef, {'balance': currentBalance + amount});
                    txn.set(txRef, tx);
                  });

                  await fetchWallet();
                  await fetchTransactions();
                  Navigator.pop(context);
                }
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  void _markDispute(String txId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wallet')
        .doc('main')
        .collection('transactions')
        .doc(txId)
        .update({'dispute': true});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction marked for review.')),
    );
    await fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello ${username ?? ''}!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your available balance',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: () {
                    fetchWallet();
                    fetchTransactions();
                  },
                ),
              ],
            ),
            Text(
              balance != null
                  ? '\$${balance!.toStringAsFixed(2)} $currency'
                  : 'Loading...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B41C5), Color(0xFFED1E79)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _WalletActionButton(
                    icon: Icons.arrow_upward,
                    label: 'Top Up',
                    onTap: _showTopUpDialog,
                  ),
                  _WalletActionButton(
                    icon: Icons.swap_horiz,
                    label: 'Swap',
                    onTap: () => Navigator.pushNamed(context, '/swap'),
                  ),
                  _WalletActionButton(
                    icon: Icons.arrow_downward,
                    label: 'Withdrawal',
                    onTap: () {
                      if (balance != null && balance! >= 100) {
                        Navigator.pushNamed(context, '/withdraw');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Min withdrawal limit is \$100'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Transaction History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (transactions.isEmpty)
              const Text(
                "No recent transactions",
                style: TextStyle(color: Colors.white54),
              )
            else
              for (var tx in transactions)
                _TransactionItem(
                  id: tx['id'],
                  title: tx['type'],
                  date: (tx['timestamp'] as Timestamp)
                      .toDate()
                      .toString()
                      .split('.')
                      .first,
                  amount: tx['amount'] ?? 0,
                  type: tx['type'],
                  dispute: tx['dispute'] ?? false,
                  verification: (tx['amount'] ?? 0) >= 100,
                  onDispute: _markDispute,
                ),
          ],
        ),
      ),
    );
  }
}

class _WalletActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _WalletActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String id;
  final String title;
  final String date;
  final double amount;
  final String type;
  final bool dispute;
  final bool verification;
  final Function(String) onDispute;

  const _TransactionItem({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.type,
    required this.dispute,
    required this.verification,
    required this.onDispute,
  });

  @override
  Widget build(BuildContext context) {
    Color amountColor;
    if (type == 'TopUp' || type == 'Reward') {
      amountColor = Colors.green;
    } else if (type == 'Withdraw' || type == 'EntryFee') {
      amountColor = Colors.red;
    } else {
      amountColor = Colors.white;
    }

    final prefix = amountColor == Colors.red ? '-' : '+';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    if (verification)
                      const Text(
                        '🔒 Verification required',
                        style: TextStyle(color: Colors.amber, fontSize: 12),
                      ),
                    if (dispute)
                      const Text(
                        '🚨 Under Dispute',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Text(
                "$prefix\$${amount.toStringAsFixed(2)}",
                style: TextStyle(
                  color: amountColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!dispute)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => onDispute(id),
                child: const Text(
                  "Report Dispute",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
