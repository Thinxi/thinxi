import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child:
                Text("Not logged in", style: TextStyle(color: Colors.white))),
      );
    }

    final transactionsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Transactions"),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: transactionsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No transactions yet",
                  style: TextStyle(color: Colors.white70)),
            );
          }

          final transactions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final data = tx.data() as Map<String, dynamic>;
              final type = data['type'] ?? 'unknown';
              final amount = data['amount']?.toDouble() ?? 0.0;
              final currency = data['currency'] ?? 'USD';
              final status = data['status'] ?? 'n/a';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final formattedDate = createdAt != null
                  ? DateFormat('MMM d, yyyy – h:mm a').format(createdAt)
                  : 'No date';

              final icon = _getIcon(type);
              final color = _getColor(status);

              return ListTile(
                leading: Icon(icon, color: Colors.white),
                title: Text(
                  "${type.toUpperCase()} - \$${amount.toStringAsFixed(2)} $currency",
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(formattedDate,
                    style: const TextStyle(color: Colors.white54)),
                trailing: Text(status.toString().toUpperCase(),
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.bold)),
              );
            },
          );
        },
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
              Navigator.pushReplacementNamed(context, '/wallet');
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

  IconData _getIcon(String type) {
    switch (type) {
      case 'topup':
        return Icons.arrow_downward;
      case 'withdraw':
        return Icons.arrow_upward;
      case 'swap':
        return Icons.swap_horiz;
      default:
        return Icons.help_outline;
    }
  }

  Color _getColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orangeAccent;
      case 'success':
        return Colors.greenAccent;
      case 'failed':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}
