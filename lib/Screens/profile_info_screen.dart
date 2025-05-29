import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'wallet_screen.dart';
import 'settings_screen.dart';

class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({super.key});

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
  DocumentSnapshot<Map<String, dynamic>>? userData;
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        userData = doc;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    const List<Widget> screens = [
      HomeScreen(),
      ExploreScreen(),
      WalletScreen(),
      SettingsScreen(),
    ];
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screens[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = userData!.data()!;
    final name = data['username'] ?? 'No Name';
    final email = data['email'] ?? 'No Email';
    final country = data['country'] ?? 'Unknown';
    final language = data['language'] ?? 'English';
    final score = data['score'] ?? 0;
    final photoUrl = data['photoUrl'];
    final phone = data['phone'] ?? 'Not set';
    final countryCode = data['countryCode'] ?? _getCountryCode(country);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Profile Info')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (photoUrl != null)
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(photoUrl),
              ),
            const SizedBox(height: 16),
            Text(name,
                style: const TextStyle(fontSize: 22, color: Colors.white)),
            Text(email, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            infoTile("Country", country),
            infoTile("Language", language),
            infoTile("Score", score.toString()),
            infoTile("Phone",
                phone.startsWith('+') ? phone : '+$countryCode $phone'),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/icons/home.png')),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/icons/explore.png')),
            label: "Explore",
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/icons/wallet.png')),
            label: "Wallet",
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/icons/setting.png')),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  Widget infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  String _getCountryCode(String country) {
    Map<String, String> codes = {
      'United States': '1',
      'United Kingdom': '44',
      'Germany': '49',
      'France': '33',
      'Canada': '1',
      'Australia': '61',
      'China': '86',
      'Japan': '81',
      'India': '91',
      'Brazil': '55',
      'Oman': '968',
      'UAE': '971',
      'Iran': '98',
    };
    return codes[country] ?? '000';
  }
}
