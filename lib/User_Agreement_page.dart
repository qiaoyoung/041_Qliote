import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class UserAgreementPage extends StatefulWidget {
  const UserAgreementPage({super.key});

  @override
  State<UserAgreementPage> createState() => _UserAgreementPageState();
}

class _UserAgreementPageState extends State<UserAgreementPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://www.privacypolicies.com/live/74492480-1b09-4774-a695-fe5cb598d2c0'));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final webViewHeight = screenHeight - statusBarHeight - 78;
    final webViewTop = statusBarHeight + 78;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/base_Content_bg.png',
              width: screenWidth,
              fit: BoxFit.fitWidth,
            ),
          ),
          Positioned(
            top: statusBarHeight + 10 ,
            left: 20,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
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
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: webViewTop,
            left: 0,
            right: 0,
            height: webViewHeight,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: WebViewWidget(controller: _controller),
            ),
          ),
        ],
      ),
    );
  }
}

