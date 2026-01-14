import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'services/zhipu_tts_service.dart';

class CharacterChatMessage {
  final bool isUser;
  final String text;
  final String? audioPath;
  final String voice;
  final bool isIntroduction;
  final int? durationSeconds;
  final DateTime timestamp;

  CharacterChatMessage({
    required this.isUser,
    required this.text,
    this.audioPath,
    required this.voice,
    this.isIntroduction = false,
    this.durationSeconds,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'isUser': isUser,
      'text': text,
      'audioPath': audioPath,
      'voice': voice,
      'isIntroduction': isIntroduction,
      'durationSeconds': durationSeconds,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CharacterChatMessage.fromJson(Map<String, dynamic> json) {
    return CharacterChatMessage(
      isUser: json['isUser'] as bool,
      text: json['text'] as String,
      audioPath: json['audioPath'] as String?,
      voice: json['voice'] as String,
      isIntroduction: json['isIntroduction'] as bool? ?? false,
      durationSeconds: json['durationSeconds'] as int?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class QyiaarCharacterChatPage extends StatefulWidget {
  final Map<String, dynamic> character;

  const QyiaarCharacterChatPage({
    super.key,
    required this.character,
  });

  @override
  State<QyiaarCharacterChatPage> createState() => _QyiaarCharacterChatPageState();
}

class _QyiaarCharacterChatPageState extends State<QyiaarCharacterChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ZhipuTTSService _ttsService = ZhipuTTSService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _durationPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();
  
  String _selectedVoice = 'tongtong';
  List<CharacterChatMessage> _messages = [];
  bool _isGenerating = false;
  String? _currentPlayingAudioPath;
  bool _hasPlayedIntro = false;
  StreamSubscription? _playerCompleteSubscription;
  String? _avatarPath;
  String? _characterAvatarPath;

  String get _characterNickname => widget.character['QyiaarNickName'] as String? ?? '';
  String get _characterSayhi => widget.character['QyiaarShowSayhi'] as String? ?? '';

  @override
  void initState() {
    super.initState();
    _characterAvatarPath = widget.character['QyiaarUserIcon'] as String? ?? '';
    _loadUserAvatar();
    _loadChatHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_messages.isEmpty) {
        _playIntroduction();
      }
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

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatKey = 'chat_history_${_characterNickname}';
      final chatJson = prefs.getString(chatKey);
      
      if (chatJson != null) {
        final List<dynamic> messagesJson = json.decode(chatJson);
        final List<CharacterChatMessage> loadedMessages = [];
        
        for (final json in messagesJson) {
          final message = CharacterChatMessage.fromJson(json as Map<String, dynamic>);
          
          if (message.audioPath != null && message.audioPath!.isNotEmpty) {
            final audioFile = File(message.audioPath!);
            if (!await audioFile.exists()) {
              continue;
            }
          }
          
          loadedMessages.add(message);
        }
        
        setState(() {
          _messages = loadedMessages;
          _hasPlayedIntro = loadedMessages.any((msg) => msg.isIntroduction);
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatKey = 'chat_history_${_characterNickname}';
      final messagesJson = _messages.map((msg) => msg.toJson()).toList();
      await prefs.setString(chatKey, json.encode(messagesJson));
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }

  @override
  void dispose() {
    _playerCompleteSubscription?.cancel();
    _textController.dispose();
    _audioPlayer.dispose();
    _durationPlayer.dispose();
    _scrollController.dispose();
    _saveChatHistory();
    super.dispose();
  }

  Future<void> _playIntroduction() async {
    if (_hasPlayedIntro || _characterSayhi.isEmpty) return;
    
    _hasPlayedIntro = true;
    
    setState(() {
      _messages.add(CharacterChatMessage(
        isUser: false,
        text: _characterSayhi,
        voice: _selectedVoice,
        isIntroduction: true,
        timestamp: DateTime.now(),
      ));
    });
    
    await _saveChatHistory();
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(CharacterChatMessage(
        isUser: true,
        text: text,
        voice: _selectedVoice,
        timestamp: DateTime.now(),
      ));
      _textController.clear();
    });

    await _saveChatHistory();
    _scrollToBottom();

    setState(() {
      _isGenerating = true;
    });

    try {
      final audioPath = await _ttsService.textToSpeech(
        text: text,
        voice: _selectedVoice,
      );

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
        _messages.add(CharacterChatMessage(
          isUser: false,
          text: '',
          audioPath: audioPath,
          voice: _selectedVoice,
          isIntroduction: false,
          durationSeconds: durationSeconds,
          timestamp: DateTime.now(),
        ));
        _isGenerating = false;
      });

      await _saveChatHistory();
      _scrollToBottom();
      await _playAudio(audioPath);
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

  Future<void> _playAudio(String audioPath) async {
    if (_currentPlayingAudioPath == audioPath) {
      await _audioPlayer.stop();
      setState(() {
        _currentPlayingAudioPath = null;
      });
      return;
    }

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(audioPath));
      
      setState(() {
        _currentPlayingAudioPath = audioPath;
      });

      _playerCompleteSubscription?.cancel();
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
          SnackBar(content: Text('Failed to play audio: $e')),
        );
      }
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

  Widget _buildBackButton(BuildContext context) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(22),
          child: const Center(
            child: Icon(
              Icons.arrow_back,
              color: Colors.black,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(CharacterChatMessage message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: ClipOval(
                child: _characterAvatarPath != null && _characterAvatarPath!.isNotEmpty
                    ? Image.asset(
                        _characterAvatarPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/user_qyiaar_icon.png',
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        'assets/user_qyiaar_icon.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFFE69A8) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: message.audioPath != null && message.audioPath!.isNotEmpty
                  ? _buildAudioMessage(message)
                  : message.text.isNotEmpty
                      ? Text(
                          message.text,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black,
                            fontSize: 14,
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            FutureBuilder<String?>(
              future: _getAvatarFilePath(_avatarPath),
              builder: (context, snapshot) {
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: ClipOval(
                    child: snapshot.hasData && snapshot.data != null
                        ? Image.file(
                            File(snapshot.data!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/user_qyiaar_icon.png',
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            'assets/user_qyiaar_icon.png',
                            fit: BoxFit.cover,
                          ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAudioMessage(CharacterChatMessage message) {
    final isPlaying = _currentPlayingAudioPath == message.audioPath;
    final duration = message.durationSeconds;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (message.audioPath != null) {
              _playAudio(message.audioPath!);
            }
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPlaying ? Colors.red : Colors.green,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        if (duration != null) ...[
          const SizedBox(width: 8),
          Text(
            '${duration}s',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
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
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: ClipOval(
              child: _characterAvatarPath != null && _characterAvatarPath!.isNotEmpty
                  ? Image.asset(
                      _characterAvatarPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/user_qyiaar_icon.png',
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      'assets/user_qyiaar_icon.png',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
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
        top: 12,
        bottom: bottomPadding + 12,
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
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFE69A8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    final imageTop = statusBarHeight + 80;
    final chatAreaTop = imageTop + 120;
    final chatAreaHeight = MediaQuery.of(context).size.height - chatAreaTop - 100 - bottomPadding;

    return Scaffold(
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildInputArea(bottomPadding),
          ),
        ],
      ),
    );
  }
}
