import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'report_page.dart';
import 'main.dart';

class ImageQyiaarPage extends StatefulWidget {
  final String imagePath;
  final List<String> imageArray;
  final int initialIndex;
  final Map<String, dynamic>? character;

  const ImageQyiaarPage({
    super.key,
    required this.imagePath,
    required this.imageArray,
    this.initialIndex = 0,
    this.character,
  });

  @override
  State<ImageQyiaarPage> createState() => _ImageQyiaarPageState();
}

class _ImageQyiaarPageState extends State<ImageQyiaarPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildReportButton(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
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
      child: const Center(
        child: Icon(
          Icons.report_problem,
          color: Colors.black,
          size: 20,
        ),
      ),
    );
  }

  Future<void> _blockCharacter(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    final blockedList = prefs.getStringList('blocked_characters') ?? [];
    if (!blockedList.contains(nickname)) {
      blockedList.add(nickname);
      await prefs.setStringList('blocked_characters', blockedList);
    }
  }

  Future<void> _muteCharacter(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    final mutedList = prefs.getStringList('muted_characters') ?? [];
    if (!mutedList.contains(nickname)) {
      mutedList.add(nickname);
      await prefs.setStringList('muted_characters', mutedList);
    }
  }

  void _showActionSheet(BuildContext context) {
    if (widget.character == null) return;
    
    final nickname = widget.character!['QyiaarNickName'] ?? 'Unknown';
    
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportPage(character: widget.character!),
                ),
              );
            },
            child: const Text(
              'Report',
              style: TextStyle(color: Colors.red),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              await _blockCharacter(nickname);
              PageRefreshNotifier().notifyRefresh();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text(
              'Block',
              style: TextStyle(color: Colors.red),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              await _muteCharacter(nickname);
              PageRefreshNotifier().notifyRefresh();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text(
              'Mute',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageArray.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final photoPath = widget.imageArray[index];
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Image.asset(
                    photoPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.error, color: Colors.white, size: 50),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: statusBarHeight + 20,
            left: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 44,
                height: 44,
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
                child: const Center(
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: statusBarHeight + 20,
            right: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.imageArray.length > 1)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.imageArray.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (widget.character != null)
                  GestureDetector(
                    onTap: () {
                      _showActionSheet(context);
                    },
                    child: _buildReportButton(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
