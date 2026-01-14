import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Video_qyiaar_page.dart';
import 'report_page.dart';
import 'qyiaar_character_chat_page.dart';

class QyiaarFigureDetailPage extends StatefulWidget {
  final Map<String, dynamic> character;
  final VoidCallback? onDataChanged;

  const QyiaarFigureDetailPage({
    super.key,
    required this.character,
    this.onDataChanged,
  });

  @override
  State<QyiaarFigureDetailPage> createState() => _QyiaarFigureDetailPageState();
}

class _QyiaarFigureDetailPageState extends State<QyiaarFigureDetailPage> {
  int _selectedImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final nickname = widget.character['QyiaarNickName'] as String? ?? '';
    final avatarPath = widget.character['QyiaarUserIcon'] as String? ?? '';
    final motto = widget.character['QyiaarShowMotto'] as String? ?? '';
    final photoArray = widget.character['QyiaarShowPhotoArray'] as List<dynamic>? ?? [];
    final videoArray = widget.character['QyiaarShowVideoArray'] as List<dynamic>? ?? [];
    final thumbnailArray = widget.character['QyiaarShowThumbnailArray'] as List<dynamic>? ?? [];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/base_Content_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: statusBarHeight + 20,
            left: 20,
            child: _buildBackButton(context),
          ),
          Positioned(
            top: statusBarHeight + 20,
            right: 20,
            child: _buildReportButton(context),
          ),
          Positioned(
            top: statusBarHeight + 80,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 头像和昵称
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(4, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: avatarPath.isNotEmpty
                              ? Image.asset(
                                  avatarPath,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/user_qyiaar_icon.png',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
                                  'assets/user_qyiaar_icon.png',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          nickname,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 开始聊天按钮
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
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
                              builder: (context) => QyiaarCharacterChatPage(
                                character: widget.character,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'Start Chat',
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
                  const SizedBox(height: 20),
                  // 座右铭
                  if (motto.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        motto,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          height: 1.5,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  // 照片列表
                  if (photoArray.isNotEmpty) ...[
                    const Text(
                      'Photos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: photoArray.length,
                        itemBuilder: (context, index) {
                          final photoPath = photoArray[index] as String;
                          return GestureDetector(
                            onTap: () {
                              _showImageFullScreen(context, photoPath, photoArray, index);
                            },
                            child: Container(
                              width: 120,
                              height: 120,
                              margin: EdgeInsets.only(
                                right: index < photoArray.length - 1 ? 12 : 0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black, width: 1),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black,
                                    offset: Offset(2, 2),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  photoPath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.error, color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // 视频列表
                  if (videoArray.isNotEmpty) ...[
                    const Text(
                      'Videos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(videoArray.length, (index) {
                        final videoPath = videoArray[index] as String;
                        final thumbnailPath = thumbnailArray != null &&
                                index < thumbnailArray.length
                            ? thumbnailArray[index] as String
                            : null;
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoQyiaarPage(
                                  videoPath: videoPath,
                                  character: widget.character,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: (screenWidth - 64) / 2,
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black, width: 1),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: thumbnailPath != null
                                      ? Image.asset(
                                          thumbnailPath,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: Icon(
                                                  Icons.video_library,
                                                  color: Colors.grey,
                                                  size: 40,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(
                                              Icons.video_library,
                                              color: Colors.grey,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.play_circle_filled,
                                      color: Colors.white,
                                      size: 50,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageFullScreen(
    BuildContext context,
    String imagePath,
    List<dynamic> photoArray,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return _ImageFullScreenViewer(
          imagePath: imagePath,
          photoArray: photoArray,
          initialIndex: initialIndex,
        );
      },
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
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
    );
  }

  Widget _buildReportButton(BuildContext context) {
    return Container(
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
            _showActionSheet(context);
          },
          borderRadius: BorderRadius.circular(20),
          child: const Center(
            child: Icon(
              Icons.report,
              color: Colors.black,
              size: 20,
            ),
          ),
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
    final nickname = widget.character['QyiaarNickName'] ?? 'Unknown';
    
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
                  builder: (context) => ReportPage(character: widget.character),
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
              // Notify parent page to refresh data
              if (widget.onDataChanged != null) {
                widget.onDataChanged!();
              }
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
              // Notify parent page to refresh data
              if (widget.onDataChanged != null) {
                widget.onDataChanged!();
              }
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
}

class _ImageFullScreenViewer extends StatefulWidget {
  final String imagePath;
  final List<dynamic> photoArray;
  final int initialIndex;

  const _ImageFullScreenViewer({
    required this.imagePath,
    required this.photoArray,
    required this.initialIndex,
  });

  @override
  State<_ImageFullScreenViewer> createState() => _ImageFullScreenViewerState();
}

class _ImageFullScreenViewerState extends State<_ImageFullScreenViewer> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photoArray.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final photoPath = widget.photoArray[index] as String;
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
          // 关闭按钮
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.5),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          // 图片指示器
          if (widget.photoArray.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.photoArray.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

