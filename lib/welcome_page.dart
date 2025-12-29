import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'User_Agreement_page.dart';
import 'Privacy_Policy_page.dart';
import 'main.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _enterApp() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms of Service and Privacy Policy'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_agreed_to_terms', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainTabBarPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/welcome_content_bg.png',
              width: screenWidth,
              fit: BoxFit.fitWidth,
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomPadding + 48,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enter App button
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: const Color(0xFFFE69A8),
                    borderRadius: BorderRadius.circular(25),
                    child: InkWell(
                      onTap: _enterApp,
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.black, width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(4, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Enter App',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Agreement text
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _agreedToTerms = !_agreedToTerms;
                        });
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: _agreedToTerms ? const Color(0xFFFE69A8) : Colors.white,
                          border: Border.all(color: Colors.black, width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: _agreedToTerms
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          children: [
                            const TextSpan(text: 'I have read and agree '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFFE69A8),
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const UserAgreementPage(),
                                    ),
                                  );
                                },
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFFE69A8),
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PrivacyPolicyPage(),
                                    ),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

