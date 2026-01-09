import 'package:flutter/material.dart';

class ProfilePostSubmitPage extends StatefulWidget {
  const ProfilePostSubmitPage({super.key});

  @override
  State<ProfilePostSubmitPage> createState() => _ProfilePostSubmitPageState();
}

class _ProfilePostSubmitPageState extends State<ProfilePostSubmitPage> {
  @override
  void initState() {
    super.initState();
    _autoReturn();
  }

  void _autoReturn() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submit Successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/base_Content_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text(
                  'Submitting...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

