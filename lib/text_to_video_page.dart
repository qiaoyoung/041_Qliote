import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'services/zhipu_video_service.dart';

const Color _primaryColor = Color(0xFFFE69A8);

class VideoMessage {
  final bool isUser;
  final String text;
  final String? videoPath;
  final VideoPlayerController? controller;

  VideoMessage({
    required this.isUser,
    required this.text,
    this.videoPath,
    this.controller,
  });

  void dispose() {
    controller?.dispose();
  }
}

class TextToVideoPage extends StatefulWidget {
  const TextToVideoPage({super.key});

  @override
  State<TextToVideoPage> createState() => _TextToVideoPageState();
}

class _TextToVideoPageState extends State<TextToVideoPage> {
  final TextEditingController _textController = TextEditingController();
  final ZhipuVideoService _videoService = ZhipuVideoService();
  final ScrollController _scrollController = ScrollController();
  final Random _random = Random();
  
  List<VideoMessage> _messages = [];
  bool _isGenerating = false;
  String _generationStatus = '';
  VideoPlayerController? _currentPlayingController;
  String? _avatarPath;

  // Movie quotes for AI button
  static const List<String> _movieQuotes = [
    "A beautiful sunset over the ocean",
    "A cat playing in a garden",
    "A city street at night with neon lights",
    "A peaceful forest with sunlight filtering through trees",
    "A train traveling through mountains",
    "A busy marketplace with people shopping",
    "A beach with waves crashing on the shore",
    "A snow-covered mountain peak",
    "A flower blooming in slow motion",
    "A bird flying across a blue sky",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserAvatar();
    _playIntroduction();
  }

  Future<void> _loadUserAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _avatarPath = prefs.getString('user_avatar_path');
    });
  }

  Future<String?> _getAvatarFilePath(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) {
      return null;
    }
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fullPath = path.join(appDir.path, relativePath);
      final file = File(fullPath);
      if (await file.exists()) {
        return fullPath;
      }
    } catch (e) {
      // 文件不存在或读取失败
    }
    return null;
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    for (var message in _messages) {
      message.dispose();
    }
    _currentPlayingController?.dispose();
    super.dispose();
  }

  Future<void> _playIntroduction() async {
    const introText = 'Hello! I am a text-to-video assistant. I can convert your text descriptions into videos using AI. Simply describe what you want to see, and I will generate a video for you.';
    
    if (mounted) {
      setState(() {
        _messages.add(VideoMessage(
          isUser: false,
          text: introText,
        ));
      });
    }
  }

  void _generateRandomQuote() {
    final randomQuote = _movieQuotes[_random.nextInt(_movieQuotes.length)];
    _textController.text = randomQuote;
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    if (mounted) {
      setState(() {
        _messages.add(VideoMessage(
          isUser: true,
          text: text,
        ));
        _textController.clear();
      });
    }

    _scrollToBottom();

    // Generate video
    if (mounted) {
      setState(() {
        _isGenerating = true;
        _generationStatus = 'Submitting task...';
      });
    }

    try {
      final videoPath = await _videoService.textToVideo(
        text: text,
        onProgress: (status) {
          if (mounted) {
            setState(() {
              _generationStatus = status;
            });
          }
        },
      );

      if (!mounted) return;

      // Create video player controller
      final controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();

      if (!mounted) {
        controller.dispose();
        return;
      }

      if (mounted) {
        setState(() {
          _messages.add(VideoMessage(
            isUser: false,
            text: '',
            videoPath: videoPath,
            controller: controller,
          ));
          _isGenerating = false;
          _generationStatus = '';
        });
      }

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate video: $e')),
        );
        setState(() {
          _isGenerating = false;
          _generationStatus = '';
        });
      }
    }
  }

  void _playVideo(VideoPlayerController controller) {
    if (_currentPlayingController != null && _currentPlayingController != controller) {
      _currentPlayingController!.pause();
    }

    if (mounted) {
      setState(() {
        _currentPlayingController = controller;
      });
    }

    controller.play();
    controller.setLooping(true);
  }

  void _pauseVideo() {
    _currentPlayingController?.pause();
    if (mounted) {
      setState(() {
        _currentPlayingController = null;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
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
              top: statusBarHeight + 10,
              left: 20,
              child: _buildBackButton(context),
            ),
            Positioned(
              top: statusBarHeight + 78,
              left: 0,
              right: 0,
              bottom: bottomPadding + 80,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: _messages.length + (_isGenerating ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return _buildLoadingMessage();
                  }
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildInputArea(bottomPadding),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(VideoMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/text_to_video_img.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.green : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: message.isUser
                  ? Text(
                      message.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    )
                  : message.text.isNotEmpty
                      ? Text(
                          message.text,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        )
                      : message.videoPath != null && message.controller != null
                          ? _buildVideoPlayer(message.controller!)
                          : const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: ClipOval(
                child: FutureBuilder<String?>(
                  future: _getAvatarFilePath(_avatarPath),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Image.file(
                        File(snapshot.data!),
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/user_qyiaar_icon.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          );
                        },
                      );
                    } else {
                      return Image.asset(
                        'assets/user_qyiaar_icon.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(VideoPlayerController controller) {
    final isPlaying = _currentPlayingController == controller && controller.value.isPlaying;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            if (isPlaying) {
              _pauseVideo();
            } else {
              _playVideo(controller);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isPlaying ? Colors.red : _primaryColor,
              border: Border.all(color: Colors.black, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isPlaying ? 'Pause' : 'Play',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/speech_rob_chat.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
                if (_generationStatus.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _generationStatus,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(double bottomPadding) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottomPadding + 10,
        top: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Text To Video...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.black54),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                style: const TextStyle(fontSize: 16, color: Colors.black),
                maxLines: 1,
                scrollPadding: EdgeInsets.zero,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                scrollController: ScrollController(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _generateRandomQuote,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
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
                  'AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isGenerating ? null : _sendMessage,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isGenerating ? Colors.grey : _primaryColor,
                border: Border.all(color: Colors.black, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ),
        ],
      ),
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
          onTap: () async {
            if (_isGenerating) {
              final shouldPop = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Exit'),
                    content: const Text('Video generation is in progress. If you leave now, the video will not be saved.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('Leave'),
                      ),
                    ],
                  );
                },
              );
              
              if (shouldPop == true && mounted) {
                Navigator.pop(context);
              }
            } else {
              Navigator.pop(context);
            }
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
}

