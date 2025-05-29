import 'package:flutter/material.dart';

class WinnersScreen extends StatelessWidget {
  const WinnersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // **لیست تستی برندگان (بعداً از سرور لود می‌شود)**
    List<Map<String, dynamic>> winners = [
      {"name": "Ali", "prize": "50\$"},
      {"name": "Sara", "prize": "30\$"},
      {"name": "Reza", "prize": "20\$"},
      {"name": "Mina", "prize": "10\$"},
      {"name": "Hassan", "prize": "5\$"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("🏆 Winners"),
        backgroundColor: Colors.pink,
      ),
      backgroundColor: Colors.blueGrey[900],
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "🎉 Congratulations!",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Top 5 winners of the game",
            style: TextStyle(
              fontSize: 18,
              color: Colors.tealAccent,
            ),
          ),
          const SizedBox(height: 20),

          // **لیست برندگان**
          Expanded(
            child: ListView.builder(
              itemCount: winners.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Text(
                    "#${index + 1}",
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  title: Text(
                    winners[index]["name"],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  trailing: Text(
                    winners[index]["prize"],
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.greenAccent,
                    ),
                  ),
                );
              },
            ),
          ),

          // **دکمه بازگشت**
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text("Back", style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
