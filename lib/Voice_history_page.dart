import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'services/zhipu_tts_service.dart';

const Color _primaryColor = Color(0xFFFE69A8);

class VoiceHistoryPage extends StatefulWidget {
  const VoiceHistoryPage({super.key});

  @override
  State<VoiceHistoryPage> createState() => _VoiceHistoryPageState();
}

class _VoiceHistoryPageState extends State<VoiceHistoryPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Map<String, dynamic>> _audioFiles = [];
  String? _currentPlayingPath;
  StreamSubscription? _playerCompleteSubscription;

  @override
  void initState() {
    super.initState();
    _loadAudioFiles();
  }

  @override
  void dispose() {
    _playerCompleteSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadAudioFiles() async {
    final files = await ZhipuTTSService.getAudioFiles();
    // Sort by timestamp (newest first)
    files.sort((a, b) {
      final timestampA = a['timestamp'] as int? ?? 0;
      final timestampB = b['timestamp'] as int? ?? 0;
      return timestampB.compareTo(timestampA);
    });
    
    setState(() {
      _audioFiles = files;
    });
  }

  Future<void> _playAudio(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio file does not exist')),
        );
        return;
      }

      if (_currentPlayingPath != null) {
        await _audioPlayer.stop();
        await _audioPlayer.release();
      }

      setState(() {
        _currentPlayingPath = path;
      });

      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _playerCompleteSubscription?.cancel();
      
      await _audioPlayer.play(DeviceFileSource(path));

      _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _currentPlayingPath = null;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play audio: $e')),
        );
        setState(() {
          _currentPlayingPath = null;
        });
      }
    }
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      _currentPlayingPath = null;
    });
  }

  Future<void> _deleteAudio(int index) async {
    try {
      final audioInfo = _audioFiles[index];
      final filePath = audioInfo['filePath'] as String?;
      
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Remove from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final audioFilesJson = prefs.getStringList('audio_files') ?? [];
      audioFilesJson.removeAt(index);
      await prefs.setStringList('audio_files', audioFilesJson);
      await prefs.setInt('audio_files_count', audioFilesJson.length);

      // Reload list
      await _loadAudioFiles();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio file deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete audio: $e')),
        );
      }
    }
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
            top: statusBarHeight + 10,
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
            top: statusBarHeight + 78,
            left: 0,
            right: 0,
            bottom: bottomPadding + 20,
            child: _audioFiles.isEmpty
                ? Center(
                    child: Text(
                      'No audio files yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _audioFiles.length,
                    itemBuilder: (context, index) {
                      final audioInfo = _audioFiles[index];
                      final filePath = audioInfo['filePath'] as String?;
                      final text = audioInfo['text'] as String? ?? '';
                      final voice = audioInfo['voice'] as String? ?? '';
                      final createdAt = audioInfo['createdAt'] as String?;
                      final isPlaying = _currentPlayingPath == filePath;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (isPlaying) {
                                      _stopAudio();
                                    } else if (filePath != null) {
                                      _playAudio(filePath);
                                    }
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isPlaying ? Colors.red : _primaryColor,
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black,
                                          offset: Offset(2, 2),
                                          blurRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isPlaying ? Icons.stop : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        text.isNotEmpty ? text : 'Audio ${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (createdAt != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDateTime(createdAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteAudio(index),
                                ),
                              ],
                            ),
                            if (voice.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Voice: $voice',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

