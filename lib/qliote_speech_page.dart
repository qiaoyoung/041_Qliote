import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'services/zhipu_tts_service.dart';

const Color _primaryColor = Color(0xFFFE69A8);

class ChatMessage {
  final bool isUser;
  final String text;
  final String? audioPath;
  final String voice;
  final bool isIntroduction;
  final int? durationSeconds; // 音频时长（秒）

  ChatMessage({
    required this.isUser,
    required this.text,
    this.audioPath,
    required this.voice,
    this.isIntroduction = false,
    this.durationSeconds,
  });
}

class QlioteSpeechPage extends StatefulWidget {
  const QlioteSpeechPage({super.key});

  @override
  State<QlioteSpeechPage> createState() => _QlioteSpeechPageState();
}

class _QlioteSpeechPageState extends State<QlioteSpeechPage> {
  final TextEditingController _textController = TextEditingController();
  final ZhipuTTSService _ttsService = ZhipuTTSService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _durationPlayer = AudioPlayer(); // 用于获取时长的临时播放器
  final ScrollController _scrollController = ScrollController();
  
  String _selectedVoice = 'tongtong';
  List<ChatMessage> _messages = [];
  bool _isGenerating = false;
  String? _currentPlayingAudioPath;
  bool _hasPlayedIntro = false;
  StreamSubscription? _playerCompleteSubscription;
  String? _avatarPath;
  final Random _random = Random();

  // 电影经典台词列表
  static const List<String> _movieQuotes = [
    "May the Force be with you.",
    "I'll be back.",
    "You can't handle the truth!",
    "Here's looking at you, kid.",
    "Life is like a box of chocolates, you never know what you're gonna get.",
    "To infinity and beyond!",
    "I'm the king of the world!",
    "You talking to me?",
    "Keep your friends close, but your enemies closer.",
    "Houston, we have a problem.",
    "There's no place like home.",
    "I'll have what she's having.",
    "You had me at hello.",
    "I see dead people.",
    "The stuff that dreams are made of.",
    "Fasten your seatbelts. It's going to be a bumpy night.",
    "I'm walking here!",
    "Nobody puts Baby in a corner.",
    "I feel the need—the need for speed!",
    "Say hello to my little friend!",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserAvatar();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playIntroduction();
    });
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
    _playerCompleteSubscription?.cancel();
    _textController.dispose();
    _audioPlayer.dispose();
    _durationPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _playIntroduction() async {
    if (_hasPlayedIntro) return;
    
    _hasPlayedIntro = true;
    const introText = 'Hello! I am a text-to-speech assistant. I help you better understand pronunciation standards related to dubbing. I have multiple voice roles to choose from, each with unique characteristics. You can send me text, and I will convert it to speech using the selected voice role.';
    
    // 自我介绍只显示文字，不调用API生成音频
    setState(() {
      _messages.add(ChatMessage(
        isUser: false,
        text: introText,
        voice: _selectedVoice,
        isIntroduction: true,
      ));
    });
  }

  Future<void> _rateApp() async {
    try {
      final InAppReview inAppReview = InAppReview.instance;
      
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        await inAppReview.openStoreListing();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open rating: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        isUser: true,
        text: text,
        voice: _selectedVoice,
      ));
      _textController.clear();
    });

    _scrollToBottom();

    // Generate AI response
    setState(() {
      _isGenerating = true;
    });

    try {
      // 调用TTS API生成音频
      final audioPath = await _ttsService.textToSpeech(
        text: text,
        voice: _selectedVoice,
      );

      // 获取音频时长（使用临时播放器）
      int? durationSeconds;
      try {
        await _durationPlayer.setSource(DeviceFileSource(audioPath));
        final duration = await _durationPlayer.getDuration();
        if (duration != null) {
          durationSeconds = duration.inSeconds;
        }
        await _durationPlayer.stop();
      } catch (e) {
        // 如果获取时长失败，继续播放，不显示时长
      }

      setState(() {
        // AI回复只显示音频，不显示文字
        _messages.add(ChatMessage(
          isUser: false,
          text: '', // 不显示文字
          audioPath: audioPath,
          voice: _selectedVoice,
          isIntroduction: false,
          durationSeconds: durationSeconds,
        ));
        _isGenerating = false;
      });

      _scrollToBottom();
      await _playAudio(audioPath);
      
      // 通知 profile 页面更新音频文件数量
      // 通过 SharedPreferences 已经自动更新，profile 页面会在返回时刷新
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate speech: $e')),
        );
      }
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _playAudio(String path) async {
    try {
      // Verify file exists before playing
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Audio file does not exist: $path');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Audio file is empty');
      }

      if (fileSize < 100) {
        throw Exception('Audio file is too small, may be corrupted');
      }

      // Stop and release previous audio if playing
      if (_currentPlayingAudioPath != null) {
        try {
          await _audioPlayer.stop();
          await _audioPlayer.release();
        } catch (e) {
          // Ignore errors when stopping previous audio
        }
      }

      setState(() {
        _currentPlayingAudioPath = path;
      });

      // Set release mode to release resources after playback
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      
      // Cancel previous subscription if exists
      await _playerCompleteSubscription?.cancel();
      
      // Play audio directly
      await _audioPlayer.play(DeviceFileSource(path));

      // Listen for completion
      _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _currentPlayingAudioPath = null;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play audio: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _currentPlayingAudioPath = null;
        });
      }
    }
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      _currentPlayingAudioPath = null;
    });
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

  void _generateRandomQuote() {
    final randomQuote = _movieQuotes[_random.nextInt(_movieQuotes.length)];
    _textController.text = randomQuote;
  }

  String _getVoiceInitial(String voice) {
    if (voice.isEmpty) return '';
    return voice[0].toUpperCase();
  }

  void _showVoiceSelectorSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Select Voice Role'),
        actions: ZhipuTTSService.voiceRoles.map((voice) {
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedVoice = voice;
              });
              Navigator.pop(context);
            },
            child: Text(
              voice,
              style: TextStyle(
                color: _selectedVoice == voice ? _primaryColor : CupertinoColors.black,
                fontWeight: _selectedVoice == voice ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    // Calculate image area height (image at y:116, estimated height ~200)
    const imageTop = 116.0;
    const estimatedImageHeight = 200.0;
    final imageBottom = imageTop + estimatedImageHeight;
    final chatAreaTop = imageBottom + 40;
    const inputAreaHeight = 80.0;
    final chatAreaHeight = screenHeight - chatAreaTop - bottomPadding - inputAreaHeight;

    return GestureDetector(
      onTap: () {
        // 点击空白区域时关闭键盘
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
              'assets/speech_content_bg.png',
              width: screenWidth,
              fit: BoxFit.fitWidth,
            ),
          ),
          Positioned(
            top: statusBarHeight + 20,
            left: 20,
            child: _buildBackButton(context),
          ),
          Positioned(
            top: imageTop,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: _rateApp,
              child: Image.asset(
                'assets/Speech_give_good_review.png',
                width: screenWidth - 40,
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
          // Chat area
          Positioned(
            top: chatAreaTop,
            left: 0,
            right: 0,
            height: chatAreaHeight,
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
          // Input area at bottom
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

  Widget _buildVoiceSelector() {
    return GestureDetector(
      onTap: _showVoiceSelectorSheet,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            _getVoiceInitial(_selectedVoice),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
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
                  'assets/speech_rob_chat.png',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  : message.isIntroduction
                      ? Text(
                          message.text,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (message.audioPath != null)
                              GestureDetector(
                                onTap: () {
                                  if (_currentPlayingAudioPath == message.audioPath) {
                                    _stopAudio();
                                  } else {
                                    _playAudio(message.audioPath!);
                                  }
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentPlayingAudioPath == message.audioPath
                                        ? Colors.red
                                        : _primaryColor,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black,
                                        offset: Offset(2, 2),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _currentPlayingAudioPath == message.audioPath
                                        ? Icons.stop
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              )
                            else
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            if (message.audioPath != null && message.durationSeconds != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${message.durationSeconds}s',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
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
                            'assets/user_qliote_icon.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          );
                        },
                      );
                    } else {
                      return Image.asset(
                        'assets/user_qliote_icon.png',
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
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
          // 角色选择器
          _buildVoiceSelector(),
          const SizedBox(width: 10),
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
                  hintText: 'Text To Voice...',
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
          // AI按钮
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
          // 发送按钮
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
}
