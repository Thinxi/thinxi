import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

class RewardDialog extends StatefulWidget {
  final VoidCallback onFinished;

  const RewardDialog({super.key, required this.onFinished});

  @override
  State<RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<RewardDialog> {
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
    _audioPlayer.play(AssetSource('sounds/reward.mp3'));
    Future.delayed(const Duration(seconds: 4), widget.onFinished);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            shouldLoop: false,
          ),
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 80),
                SizedBox(height: 20),
                Text("YOU WON!",
                    style: TextStyle(fontSize: 24, color: Colors.white)),
                SizedBox(height: 10),
                Text("100 coins added to your wallet!",
                    style: TextStyle(fontSize: 16, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
