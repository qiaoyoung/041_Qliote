import 'package:flutter/material.dart';
import 'qliote_speech_page.dart';
import 'qliote_Inspiration_page.dart';
import 'qliote_profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: screenWidth,
            alignment: Alignment.topCenter,
            child: Image.asset(
              'assets/home_content_bg.png',
              width: screenWidth,
              fit: BoxFit.fitWidth,
            ),
          ),
          Positioned(
            left: 30,
            right: 30,
            bottom: bottomPadding + 48 + 110,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/home_Introduce.png',
                  width: screenWidth - 60,
                  fit: BoxFit.fitWidth,
                ),
                const SizedBox(height: 20),
                _buildGoButton(context),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    String imagePath,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        imagePath,
        width: 73,
        height: 74,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildGoButton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth - 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: const Color(0xFFFE69A8),
        border: Border.all(color: Colors.black, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QlioteSpeechPage(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(25),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            child: Center(
              child: Text(
                'Go',
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
    );
  }
}

