import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'text_to_video_page.dart';
import 'Video_qyiaar_page.dart';
import 'report_page.dart';
import 'qyiaar_figure_detail_page.dart';
import 'qyiaar_Inspiration_list_page.dart';
import 'qyiaar_Inspiration_list_full_page.dart';
import 'qyiaar_voice_course_list_page.dart';

class QyiaarInspirationPage extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const QyiaarInspirationPage({super.key, this.onDataChanged});

  @override
  State<QyiaarInspirationPage> createState() => _QyiaarInspirationPageState();
}

class _QyiaarInspirationPageState extends State<QyiaarInspirationPage> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _characters = [];
  List<Map<String, dynamic>> _filteredCharacters = [];
  bool _isLoading = true;
  double _imageHeight = 140; // Default height, will be updated when image loads

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCharacters();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  // 当页面重新显示时刷新数据
  void refreshOnResume() {
    _refreshData();
  }

  Future<void> _loadCharacters() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/qyiaar_figure.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      final allCharacters = jsonData.cast<Map<String, dynamic>>();
      final filtered = await _filterBlockedCharacters(allCharacters);
      
      setState(() {
        _characters = allCharacters;
        _filteredCharacters = filtered;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading characters: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _filterBlockedCharacters(
    List<Map<String, dynamic>> characters,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final blockedList = prefs.getStringList('blocked_characters') ?? [];
    final mutedList = prefs.getStringList('muted_characters') ?? [];
    final allBlocked = {...blockedList, ...mutedList};

    return characters.where((character) {
      final nickname = character['QyiaarNickName'] as String? ?? '';
      return !allBlocked.contains(nickname);
    }).toList();
  }

  Future<void> _blockCharacter(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    final blockedList = prefs.getStringList('blocked_characters') ?? [];
    if (!blockedList.contains(nickname)) {
      blockedList.add(nickname);
      await prefs.setStringList('blocked_characters', blockedList);
    }
    await _refreshData();
  }

  Future<void> _muteCharacter(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    final mutedList = prefs.getStringList('muted_characters') ?? [];
    if (!mutedList.contains(nickname)) {
      mutedList.add(nickname);
      await prefs.setStringList('muted_characters', mutedList);
    }
    await _refreshData();
  }

  Future<void> _refreshData() async {
    final filtered = await _filterBlockedCharacters(_characters);
    setState(() {
      _filteredCharacters = filtered;
    });
    
    // Notify parent component that data has changed
    if (widget.onDataChanged != null) {
      widget.onDataChanged!();
    }
  }

  void _showActionSheet(BuildContext context, Map<String, dynamic> character) {
    final nickname = character['QyiaarNickName'] ?? 'Unknown';
    
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
                  builder: (context) => ReportPage(character: character),
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
              // Return to root view
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
              // Return to root view
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/Inspiration_content_bg.png',
              width: screenWidth,
              fit: BoxFit.fitWidth,
            ),
          ),
          Positioned(
            top: 115,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QyiaarInspirationListFullPage(),
                  ),
                );
              },
              child: Container(
                width: screenWidth - 40,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      offset: Offset(4, 4),
                      blurRadius: 0,
                      color: Color(0xFF000000),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Appreciate Voice Acting',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 115 + 56 + 20,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TextToVideoPage(),
                  ),
                );
              },
              child: Image.asset(
                'assets/inspiration_video_review.png',
                width: screenWidth - 40,
                fit: BoxFit.fitWidth,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (frame != null && _imageHeight == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                      if (renderBox != null && mounted) {
                        setState(() {
                          _imageHeight = renderBox.size.height;
                        });
                      }
                    });
                  }
                  return child;
                },
              ),
            ),
          ),
          Positioned(
            top: 115 + 56 + 20 + _imageHeight + 20,
            left: 0,
            right: 0,
            bottom: 120,
            child: SingleChildScrollView(
              child: const QyiaarVoiceCourseListPage(),
            ),
          ),
        ],
      ),
    );
  }

}


