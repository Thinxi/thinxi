import 'package:flutter/material.dart';
import 'dart:async';

class LiveScoreboardScreen extends StatefulWidget {
  const LiveScoreboardScreen({super.key});

  @override
  State<LiveScoreboardScreen> createState() => _LiveScoreboardScreenState();
}

class _LiveScoreboardScreenState extends State<LiveScoreboardScreen> {
  List<Map<String, dynamic>> players = [
    {"name": "Ali", "score": 15},
    {"name": "Sara", "score": 12},
    {"name": "Reza", "score": 10},
    {"name": "Mina", "score": 8},
    {"name": "Hassan", "score": 6},
  ];

  @override
  void initState() {
    super.initState();
    _simulateLiveUpdates();
  }

  void _simulateLiveUpdates() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        players.shuffle();
        for (var player in players) {
          player["score"] += (1 + (player["score"] % 3));
        }
        players.sort((a, b) => b["score"].compareTo(a["score"]));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Scoreboard"),
        backgroundColor: Colors.blueGrey[900],
      ),
      backgroundColor: Colors.blueGrey[900],
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "Current Player Rankings",
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.tealAccent[700],
                    child: Text(
                      "#${index + 1}",
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  title: Text(
                    players[index]["name"],
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  trailing: Text(
                    "${players[index]["score"]} pts",
                    style: const TextStyle(
                        fontSize: 18, color: Colors.greenAccent),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child:
                    const Text("Back", style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/game");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent[700],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text("Continue",
                    style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
