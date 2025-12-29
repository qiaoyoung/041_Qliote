import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'text_to_video_page.dart';
import 'Video_qliote_page.dart';
import 'report_page.dart';
import 'qliote_figure_detail_page.dart';

class QlioteInspirationPage extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const QlioteInspirationPage({super.key, this.onDataChanged});

  @override
  State<QlioteInspirationPage> createState() => _QlioteInspirationPageState();
}

class _QlioteInspirationPageState extends State<QlioteInspirationPage> with WidgetsBindingObserver {
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
      final String jsonString = await rootBundle.loadString('assets/qliote_figure.json');
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
      final nickname = character['QlioteNickName'] as String? ?? '';
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
    final nickname = character['QlioteNickName'] ?? 'Unknown';
    
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
            top: 115 + _imageHeight + 20,
            left: 0,
            right: 0,
            bottom: 120,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: _buildCharacterList(screenWidth),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterList(double screenWidth) {
    final itemWidth = (screenWidth - 60) / 2.0;
    final spacing = 20.0;
    final runSpacing = 20.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: List.generate(_filteredCharacters.length, (index) {
          final character = _filteredCharacters[index];
          final thumbnailArray = character['QlioteShowThumbnailArray'] as List<dynamic>?;
          final thumbnailPath = thumbnailArray != null && thumbnailArray.isNotEmpty
              ? thumbnailArray[0] as String
              : null;

          final videoArray = character['QlioteShowVideoArray'] as List<dynamic>?;
          final videoPath = videoArray != null && videoArray.isNotEmpty
              ? videoArray[0] as String
              : null;

          final nickname = character['QlioteNickName'] as String? ?? '';
          final avatarPath = character['QlioteUserIcon'] as String? ?? '';

          return GestureDetector(
            onTap: () {
              if (videoPath != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoQliotePage(
                      videoPath: videoPath,
                      character: character,
                    ),
                  ),
                );
              }
            },
            child: SizedBox(
              width: itemWidth,
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/inspiration_video_cell_bg.png'),
                    fit: BoxFit.fill,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 缩略图 - 带圆角
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: thumbnailPath != null
                            ? Image.asset(
                                thumbnailPath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.error, color: Colors.grey),
                                  );
                                },
                              )
                            : const Center(
                                child: Icon(Icons.image, color: Colors.grey),
                              ),
                      ),
                      // 黑色半透明蒙版 - 只覆盖缩略图部分，带圆角
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          color: Colors.black.withOpacity(0.5),
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_filled,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                      // 举报按钮 - 右上角
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            _showActionSheet(context, character);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.report,
                              color: Colors.black,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      // 角色信息 - 底部（头像和昵称）
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                            ),
                          ),
                          child: Row(
                            children: [
                              // 头像 - 可点击跳转到详情页
                              GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => QlioteFigureDetailPage(
                                        character: character,
                                        onDataChanged: () {
                                          // Refresh data when returning from detail page
                                          _refreshData();
                                        },
                                      ),
                                    ),
                                  );
                                  // Refresh data if needed
                                  if (result == true) {
                                    _refreshData();
                                  }
                                },
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1),
                                  ),
                                  child: ClipOval(
                                    child: avatarPath.isNotEmpty
                                        ? Image.asset(
                                            avatarPath,
                                            width: 24,
                                            height: 24,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/user_qliote_icon.png',
                                                width: 24,
                                                height: 24,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          )
                                        : Image.asset(
                                            'assets/user_qliote_icon.png',
                                            width: 24,
                                            height: 24,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // 昵称 - 可点击跳转到详情页
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QlioteFigureDetailPage(
                                          character: character,
                                          onDataChanged: () {
                                            // Refresh data when returning from detail page
                                            _refreshData();
                                          },
                                        ),
                                      ),
                                    );
                                    // Refresh data if needed
                                    if (result == true) {
                                      _refreshData();
                                    }
                                  },
                                  child: Text(
                                    nickname,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}


