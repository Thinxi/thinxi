// 🔐 SIGNUP SCREEN (OPTIMIZED WITH TRANSLATION + EXTERNAL DATA + WALLET INIT)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_localization.dart';
import '../services/language_manager.dart';
import '../data/country_data.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController languageController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  void showPicker(BuildContext context, TextEditingController controller,
      List<String> items) {
    List<String> filteredItems = List.from(items);
    showCupertinoModalPopup(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: 350,
            color: Colors.black,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CupertinoSearchTextField(
                    backgroundColor: Colors.white24,
                    onChanged: (query) {
                      setState(() {
                        filteredItems = items
                            .where((item) => item
                                .toLowerCase()
                                .startsWith(query.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 40,
                    onSelectedItemChanged: (_) {},
                    children: filteredItems
                        .map((e) => GestureDetector(
                              onTap: () {
                                controller.text = e;
                                if (controller == countryController) {
                                  phoneController.text =
                                      '+${countryCodes[e] ?? ''}';
                                }
                                Navigator.pop(context);
                              },
                              child: Text(e,
                                  style: const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> handleSignUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final phone = phoneController.text.trim();
    final country = countryController.text.trim();
    final countryCode = countryCodes[country] ?? '';
    final language = languageController.text.trim();
    final username = usernameController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match.")),
      );
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'username': username,
        'country': country,
        'countryCode': countryCode,
        'language': language,
        'phone': phone,
        'photoUrl': null,
        'score': 0,
        'isPremium': false,
        'createdAt': Timestamp.now(),
        'first_time_user': true,
      });

      // ساخت کیف پول در users/{uid}/wallet/main
      final walletCurrency = country.toLowerCase() == "iran" ? "IRR" : "USD";

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('wallet')
          .doc('main')
          .set({
        'balance': 0.0,
        'currency': walletCurrency,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await userCredential.user!.sendEmailVerification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Verification email sent! Please check your inbox.")),
      );

      Navigator.pushReplacementNamed(context, '/login', arguments: email);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DirectionalWrapper(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              const T("We Say Hello!",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              _buildInputField(Icons.person, "Username",
                  controller: usernameController),
              _buildInputField(Icons.email, "Your Email",
                  controller: emailController),
              _buildInputField(Icons.lock, "Create a Password",
                  isPassword: true, controller: passwordController),
              _buildInputField(Icons.lock, "Retype Password",
                  isPassword: true, controller: confirmPasswordController),
              GestureDetector(
                onTap: () => showPicker(context, countryController, countries),
                child: AbsorbPointer(
                    child: _buildInputField(Icons.public, "Country",
                        controller: countryController)),
              ),
              _buildInputField(Icons.phone, "Phone (with country code)",
                  controller: phoneController),
              GestureDetector(
                onTap: () => showPicker(context, languageController, languages),
                child: AbsorbPointer(
                    child: _buildInputField(Icons.language, "Language",
                        controller: languageController)),
              ),
              const SizedBox(height: 20),
              _buildGradientButton("Sign Up", handleSignUp),
              const SizedBox(height: 20),
              Image.asset("assets/images/logo.png", height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(IconData icon, String hint,
      {bool isPassword = false, TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: FutureBuilder<String>(
        future: AppLocalization.translate(
            hint, Provider.of<LanguageManager>(context).currentLang),
        builder: (context, snapshot) {
          final translatedHint = snapshot.data ?? hint;
          return TextField(
            controller: controller,
            obscureText: isPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white70),
              hintText: translatedHint,
              hintStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.black54,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed) {
    return FutureBuilder<String>(
      future: AppLocalization.translate(
          text, Provider.of<LanguageManager>(context).currentLang),
      builder: (context, snapshot) {
        final label = snapshot.data ?? text;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: [Colors.blue, Colors.pink]),
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
            ),
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 18)),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    countryController.dispose();
    languageController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
