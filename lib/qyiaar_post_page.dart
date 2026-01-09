import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'profile_post_sumbit_page.dart';
import 'post_history_page.dart';

class QyiaarPostPage extends StatefulWidget {
  const QyiaarPostPage({super.key});

  @override
  State<QyiaarPostPage> createState() => _QyiaarPostPageState();
}

class _QyiaarPostPageState extends State<QyiaarPostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedVideo;
  String? _selectedVoiceTone;
  VideoPlayerController? _videoController;

  final List<String> _voiceTones = [
    'Bubble Voice',
    'Mature Female Voice',
    'Little Boy Voice',
    'Little Girl Voice',
  ];

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null) {
        final videoFile = File(video.path);
        // Verify it's actually a video file by checking extension
        final extension = video.path.toLowerCase();
        if (extension.endsWith('.mp4') || 
            extension.endsWith('.mov') || 
            extension.endsWith('.avi') ||
            extension.endsWith('.mkv')) {
          // Dispose previous controller
          await _videoController?.dispose();
          
          // Create new video controller for thumbnail
          final controller = VideoPlayerController.file(videoFile);
          await controller.initialize();
          
          setState(() {
            _selectedVideo = videoFile;
            _videoController = controller;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a valid video file')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick video: $e')),
        );
      }
    }
  }

  void _showVoiceTonePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Voice Tone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _voiceTones.length,
                itemBuilder: (context, index) {
                  final tone = _voiceTones[index];
                  final isSelected = _selectedVoiceTone == tone;

                  return ListTile(
                    title: Text(tone),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedVoiceTone = tone;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _savePostHistory(String title, String content, String? videoPath, String? voiceTone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsJson = prefs.getStringList('post_history') ?? [];
      
      final postInfo = {
        'title': title,
        'content': content,
        'videoPath': videoPath ?? '',
        'voiceTone': voiceTone ?? '',
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      postsJson.add(jsonEncode(postInfo));
      await prefs.setStringList('post_history', postsJson);
    } catch (e) {
      print('Error saving post history: $e');
    }
  }

  void _handlePost() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter content')),
      );
      return;
    }

    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video')),
      );
      return;
    }

    if (_selectedVoiceTone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a voice tone')),
      );
      return;
    }

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final videoPath = _selectedVideo!.path;
    final voiceTone = _selectedVoiceTone!;

    await _savePostHistory(title, content, videoPath, voiceTone);

    _titleController.clear();
    _contentController.clear();
    await _videoController?.dispose();
    setState(() {
      _selectedVideo = null;
      _selectedVoiceTone = null;
      _videoController = null;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilePostSubmitPage(),
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
              'assets/post_content_bg.png',
              width: screenWidth,
              fit: BoxFit.fitWidth,
            ),
          ),
          Positioned(
            top: statusBarHeight + 10,
            right: 20,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PostHistoryPage(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: const Center(
                    child: Icon(
                      Icons.history,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildSection(
                    'Title',
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter title',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Content',
                    TextField(
                      controller: _contentController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Enter content',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Video',
                    GestureDetector(
                      onTap: _pickVideo,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: _selectedVideo != null && _videoController != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _videoController!.value.isInitialized
                                        ? SizedBox(
                                            width: double.infinity,
                                            height: double.infinity,
                                            child: VideoPlayer(_videoController!),
                                          )
                                        : Container(
                                            width: double.infinity,
                                            height: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          ),
                                  ),
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.play_circle_filled,
                                          color: Colors.white,
                                          size: 50,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () async {
                                        await _videoController?.dispose();
                                        setState(() {
                                          _selectedVideo = null;
                                          _videoController = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.video_library, size: 48, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap to select video',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Voice Tone',
                    GestureDetector(
                      onTap: _showVoiceTonePicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedVoiceTone ?? 'Select voice tone',
                              style: TextStyle(
                                color: _selectedVoiceTone != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handlePost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Post',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

