import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thinxi/helpers/reward_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  String username = 'User';
  DateTime? lastUsernameChange;
  String selectedLanguage = 'en';
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    RewardHelper.trigger("settings_opened");
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final uid = user?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        username = doc.data()?['username'] ?? 'User';
        selectedLanguage = doc.data()?['language'] ?? 'en';
        notificationsEnabled = doc.data()?['notificationsEnabled'] ?? true;
        final ts = doc.data()?['lastUsernameChange'];
        if (ts != null) {
          lastUsernameChange = (ts as Timestamp).toDate();
        }
      });
    }
  }

  void _showPopup(Widget child) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "",
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white24),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon:
                                const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _popupFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text("Back"),
      ),
    );
  }

  Future<void> _changeUsername(String newUsername) async {
    final uid = user?.uid;
    if (uid == null) return;
    if (lastUsernameChange != null) {
      final diff = DateTime.now().difference(lastUsernameChange!);
      if (diff.inDays < 90) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "You can change your username in ${90 - diff.inDays} day(s)."),
          ),
        );
        return;
      }
    }
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'username': newUsername,
      'lastUsernameChange': Timestamp.fromDate(DateTime.now()),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Username updated successfully")),
    );
    Navigator.pop(context);
    setState(() {
      username = newUsername;
      lastUsernameChange = DateTime.now();
    });
  }

  Future<void> _changeEmail(String newEmail) async {
    try {
      await user?.verifyBeforeUpdateEmail(newEmail);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification link sent to new email.")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Future<void> _changePassword(
      String currentPassword, String newPassword) async {
    try {
      final cred = EmailAuthProvider.credential(
          email: user!.email!, password: currentPassword);
      await user!.reauthenticateWithCredential(cred);
      await user!.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Future<void> _changePhone(String fullPhoneNumber) async {
    final uid = user?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'phone': fullPhoneNumber,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Phone number saved successfully")),
    );
    Navigator.pop(context);
  }

  Future<void> _updateNotificationStatus(bool status) async {
    final uid = user?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'notificationsEnabled': status,
    });
    setState(() {
      notificationsEnabled = status;
    });
  }

  Future<void> _sendReport(String reportText) async {
    // Implement sending report via Cloud Function or REST API to report@thinxi.com
    await Future.delayed(const Duration(seconds: 1));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text("Your report has been sent. Thank you for your feedback.")),
    );
    Navigator.pop(context);
  }

  Future<void> _submitFeedback(int rating, String comment) async {
    final uid = user?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('feedbacks').add({
      'uid': uid,
      'rating': rating,
      'comment': comment,
      'timestamp': Timestamp.now(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Your feedback has been submitted")),
    );
    Navigator.pop(context);
  }

  Future<void> _deleteAccount() async {
    try {
      final uid = user?.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      // Delete other user-related collections if necessary.
      await user!.delete();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting account: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isRTL = Localizations.localeOf(context).languageCode == 'fa' ||
        Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              CircleAvatar(
                radius: 40,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                backgroundColor: Colors.white24,
                child: user?.photoURL == null
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                username,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                user?.email ?? "email@thinxi.com",
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildSettingsOption(Icons.edit, "Change Username",
                        () => _showPopup(_changeUsernamePopup())),
                    _buildSettingsOption(Icons.language, "Language Selection",
                        () => _showPopup(_languagePopup())),
                    _buildSettingsOption(Icons.email, "Change Email",
                        () => _showPopup(_changeEmailPopup())),
                    _buildSettingsOption(Icons.phone, "Change Phone Number",
                        () => _showPopup(_changePhonePopup())),
                    _buildSettingsOption(Icons.lock, "Change Password",
                        () => _showPopup(_changePasswordPopup())),
                    _buildSettingsOption(
                        Icons.account_circle,
                        "Account Status",
                        () => _showPopup(const Center(
                            child: Text("Your account is linked with Google ✅",
                                style: TextStyle(color: Colors.white))))),
                    _buildSettingsOption(Icons.notifications, "Notifications",
                        () => _showPopup(_notificationPopup())),
                    _buildSettingsOption(
                        Icons.share,
                        "Invite Friends & Share Referral Code",
                        () => _showPopup(_inviteFriendsPopup())),
                    _buildSettingsOption(Icons.wallet, "Payment & Wallet",
                        () => Navigator.pushNamed(context, '/wallet')),
                    _buildSettingsOption(
                        Icons.rule,
                        "Community Guidelines & Terms of Use",
                        () => _showPopup(_communityGuidelinesPopup())),
                    _buildSettingsOption(Icons.help, "FAQs & How to Play Guide",
                        () => _showPopup(_faqPopup())),
                    _buildSettingsOption(
                        Icons.feedback,
                        "Submit Rating & Feedback",
                        () => _showPopup(_feedbackPopup())),
                    _buildSettingsOption(
                        Icons.report,
                        "Report a Problem / Contact Support",
                        () => _showPopup(_reportProblemPopup())),
                    _buildSettingsOption(
                        Icons.policy,
                        "Legal & Compliance Policies",
                        () => _showPopup(_legalPoliciesPopup())),
                    _buildSettingsOption(Icons.delete, "Delete Account",
                        () => _showPopup(_deleteAccountPopup())),
                    _buildLogoutOption(context),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Rate Thinxi and claim your prize.",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => const Icon(Icons.star_border,
                      color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Write a comment and claim another prize...",
                style: TextStyle(fontSize: 14, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing:
          const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildLogoutOption(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.pinkAccent),
      title: const Text(
        "Log Out",
        style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
      ),
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
      },
    );
  }

  Widget _changeUsernamePopup() {
    final controller = TextEditingController();
    bool canChange = lastUsernameChange == null ||
        DateTime.now().difference(lastUsernameChange!).inDays >= 90;
    String infoText = "Username can be changed every 90 days.";
    if (!canChange) {
      final diff = DateTime.now().difference(lastUsernameChange!);
      infoText = "You can change your username in ${90 - diff.inDays} day(s).";
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Change Username",
            style: TextStyle(fontSize: 18, color: Colors.white)),
        const SizedBox(height: 10),
        Text("Current username: $username",
            style: const TextStyle(fontSize: 16, color: Colors.white70)),
        const SizedBox(height: 5),
        Text(infoText,
            style: const TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Username'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed:
              canChange ? () => _changeUsername(controller.text.trim()) : null,
          child: const Text("Save"),
        ),
        _popupFooter(),
      ],
    );
  }

  Widget _languagePopup() {
    String tempLanguage = selectedLanguage;
    return StatefulBuilder(
      builder: (context, setStateSB) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Language Selection",
                style: TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 10),
            DropdownButton<String>(
              dropdownColor: Colors.black,
              value: tempLanguage,
              onChanged: (val) async {
                if (val != null) {
                  setStateSB(() {
                    tempLanguage = val;
                  });
                  final uid = user?.uid;
                  if (uid != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({
                      'language': val,
                    });
                  }
                  setState(() {
                    selectedLanguage = val;
                  });
                }
              },
              items: const [
                DropdownMenuItem(value: 'en', child: Text("English")),
                DropdownMenuItem(value: 'fa', child: Text("Persian")),
                DropdownMenuItem(value: 'ar', child: Text("Arabic")),
              ],
            ),
            _popupFooter(),
          ],
        );
      },
    );
  }

  Widget _changeEmailPopup() {
    final emailController = TextEditingController();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Change Email",
            style: TextStyle(fontSize: 18, color: Colors.white)),
        const SizedBox(height: 10),
        TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'New Email'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _changeEmail(emailController.text.trim()),
          child: const Text("Send Verification Link"),
        ),
        _popupFooter(),
      ],
    );
  }

  Widget _changePhonePopup() {
    final phoneController = TextEditingController();
    String selectedCountryCode = '+98';
    final List<Map<String, String>> countries = [
      {'code': '+98', 'flag': '🇮🇷'},
      {'code': '+968', 'flag': '🇴🇲'},
      {'code': '+966', 'flag': '🇸🇦'},
    ];
    return StatefulBuilder(
      builder: (context, setStateSB) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Change Phone Number",
                style: TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 10),
            Row(
              children: [
                DropdownButton<String>(
                  value: selectedCountryCode,
                  dropdownColor: Colors.black,
                  onChanged: (val) {
                    if (val != null) {
                      setStateSB(() {
                        selectedCountryCode = val;
                      });
                    }
                  },
                  items: countries.map((country) {
                    return DropdownMenuItem(
                      value: country['code'],
                      child: Text("${country['flag']} ${country['code']}",
                          style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration:
                        const InputDecoration(labelText: 'Phone Number'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                final fullNumber =
                    "$selectedCountryCode${phoneController.text.trim()}";
                _changePhone(fullNumber);
              },
              child: const Text("Submit"),
            ),
            _popupFooter(),
          ],
        );
      },
    );
  }

  Widget _changePasswordPopup() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Change Password",
            style: TextStyle(fontSize: 18, color: Colors.white)),
        const SizedBox(height: 10),
        TextField(
          controller: currentPassController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Current Password'),
        ),
        TextField(
          controller: newPassController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New Password'),
        ),
        TextField(
          controller: confirmPassController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Repeat New Password'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            if (newPassController.text.trim() !=
                confirmPassController.text.trim()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Passwords do not match")),
              );
              return;
            }
            _changePassword(currentPassController.text.trim(),
                newPassController.text.trim());
          },
          child: const Text("Update Password"),
        ),
        _popupFooter(),
      ],
    );
  }

  Widget _notificationPopup() {
    bool tempStatus = notificationsEnabled;
    return StatefulBuilder(
      builder: (context, setStateSB) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Notifications",
                style: TextStyle(fontSize: 18, color: Colors.white)),
            SwitchListTile(
              value: tempStatus,
              onChanged: (val) async {
                setStateSB(() {
                  tempStatus = val;
                });
                await _updateNotificationStatus(val);
              },
              title: const Text("Enable/Disable Notifications",
                  style: TextStyle(color: Colors.white)),
            ),
            _popupFooter(),
          ],
        );
      },
    );
  }

  Widget _inviteFriendsPopup() {
    final referralLink = "https://thinxi.app/referral?code=$username";
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Invite Friends",
            style: TextStyle(fontSize: 18, color: Colors.white)),
        const SizedBox(height: 10),
        Text("Your referral code: $username",
            style: const TextStyle(fontSize: 16, color: Colors.white70)),
        const SizedBox(height: 5),
        SelectableText(referralLink,
            style: const TextStyle(color: Colors.lightBlueAccent)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                // Implement message sending functionality
              },
              child: const Text("Message"),
            ),
            ElevatedButton(
              onPressed: () {
                // Implement WhatsApp integration
              },
              child: const Text("WhatsApp"),
            ),
            ElevatedButton(
              onPressed: () {
                // Implement Instagram Story sharing
              },
              child: const Text("Insta Story"),
            ),
          ],
        ),
        _popupFooter(),
      ],
    );
  }

  Widget _reportProblemPopup() {
    final reportController = TextEditingController();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Report a Problem",
            style: TextStyle(fontSize: 18, color: Colors.white)),
        const SizedBox(height: 10),
        TextField(
          controller: reportController,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Describe the issue'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            // Implement screenshot upload functionality
          },
          child: const Text("Upload Screenshot"),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _sendReport(reportController.text.trim()),
          child: const Text("Send Report"),
        ),
        _popupFooter(),
      ],
    );
  }

  Widget _feedbackPopup() {
    int rating = 0;
    final commentController = TextEditingController();
    return StatefulBuilder(
      builder: (context, setStateSB) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Submit Rating & Feedback",
                style: TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 30,
                  ),
                  onPressed: () {
                    setStateSB(() {
                      rating = index + 1;
                    });
                  },
                );
              }),
            ),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(labelText: 'Your feedback'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _submitFeedback(rating, commentController.text.trim());
              },
              child: const Text("Submit"),
            ),
            _popupFooter(),
          ],
        );
      },
    );
  }

  Widget _communityGuidelinesPopup() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Community Guidelines & Terms of Use",
            style: TextStyle(fontSize: 18, color: Colors.white)),
        const SizedBox(height: 10),
        const Text(
          "Absolute Value Trading is committed to providing a safe and transparent service. Please read our community guidelines and terms of use carefully before using the app. By using this service, you agree to all terms and conditions.",
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.justify,
        ),
        _popupFooter(),
      ],
    );
  }

  Widget _faqPopup() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("FAQs & How to Play Guide",
            style: TextStyle(fontSize: 18, color: Colors.white)),
        const SizedBox(height: 10),
        const Text(
          "Absolute Value Trading provides a comprehensive guide on how to play the game along with answers to frequently asked questions. Learn the tips and strategies necessary for success.",
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.justify,
        ),
        _popupFooter(),
      ],
    );
  }

  Widget _legalPoliciesPopup() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Legal & Compliance Policies",
            style: TextStyle(fontSize: 18, color: Colors.white)),
        const SizedBox(height: 10),
        const Text(
          "Absolute Value Trading is committed to adhering to laws and regulations. This section details our legal policies, including data collection, usage, and protection of your personal information.",
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.justify,
        ),
        _popupFooter(),
      ],
    );
  }

  Widget _deleteAccountPopup() {
    final passwordController = TextEditingController();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Delete Account",
            style: TextStyle(fontSize: 18, color: Colors.redAccent)),
        const SizedBox(height: 10),
        const Text(
          "Deleting your account will permanently remove all your data including game history. For security reasons, please enter your current password.",
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            try {
              final cred = EmailAuthProvider.credential(
                  email: user!.email!,
                  password: passwordController.text.trim());
              await user!.reauthenticateWithCredential(cred);
              bool? confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Warning"),
                  content: const Text(
                      "Are you sure you want to delete your account? This action cannot be undone."),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel")),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Confirm")),
                  ],
                ),
              );
              if (confirmed == true) {
                _deleteAccount();
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error: ${e.toString()}")),
              );
            }
          },
          child: const Text("Delete Account"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
        ),
        _popupFooter(),
      ],
    );
  }
}
