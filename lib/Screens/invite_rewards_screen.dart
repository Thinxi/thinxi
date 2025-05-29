import 'package:flutter/material.dart';
import 'package:thinxi/helpers/reward_helper.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'wallet_screen.dart';
import 'settings_screen.dart';

class InviteRewardsScreen extends StatefulWidget {
  const InviteRewardsScreen({super.key});

  @override
  _InviteRewardsScreenState createState() => _InviteRewardsScreenState();
}

class _InviteRewardsScreenState extends State<InviteRewardsScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ExploreScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WalletScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
    }
  }

  Future<void> _onInvitePressed() async {
    await RewardHelper.checkAndCompleteTask("invite_friend");
    await RewardHelper.checkAndCompleteTask("invite_3_week");
    await RewardHelper.checkAndCompleteTask("invite_10");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sharing feature coming soon!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title:
            const Text("Invite & Earn", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                text: "Invite your friends and\n",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                children: <TextSpan>[
                  TextSpan(text: "earn up to "),
                  TextSpan(
                    text: "1000 USD ",
                    style: TextStyle(
                        color: Colors.pinkAccent, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: "per month and lots of\nother prizes"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Thinxi link in app store and google play",
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  backgroundColor: Colors.pinkAccent,
                ),
                onPressed: _onInvitePressed,
                child: const Text("Share",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Rewards points",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent)),
            const SizedBox(height: 5),
            const Text("Current Income Plan: Base",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/images/icons/star.png',
                          width: 25, height: 25),
                      const SizedBox(width: 5),
                      const Text("150 / 500",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text("Get 500 stars to upgrade your income plan",
                            style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Get 10 stars per complete invitation with your link or referral code and get 1 dollar per 5 tournaments they play.",
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildRewardItem("Kind one", "Add one friend", true),
            _buildRewardItem("Partner up", "Play with your friend", false),
            _buildRewardItem("Leader", "Add 10 friends", false),
            _buildRewardItem("General", "Add 100 friends", false),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
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

  Widget _buildRewardItem(String title, String subtitle, bool isClaimed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/icons/coin.png', width: 30, height: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          _buildClaimButton(isClaimed),
        ],
      ),
    );
  }

  Widget _buildClaimButton(bool isClaimed) {
    return TextButton(
      onPressed: () {},
      child: Text(isClaimed ? "Claimed" : "Claim",
          style: const TextStyle(color: Colors.white)),
    );
  }
}
