import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class VideoQyiaarPage extends StatefulWidget {
  final String videoPath;
  final Map<String, dynamic> character;

  const VideoQyiaarPage({
    super.key,
    required this.videoPath,
    required this.character,
  });

  @override
  State<VideoQyiaarPage> createState() => _VideoQyiaarPageState();
}

class _VideoQyiaarPageState extends State<VideoQyiaarPage> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    // Hide controls after 3 seconds
    _startHideControlsTimer();
  }

  Future<void> _initializeVideo() async {
    try {
      // Try using path with 'assets/' prefix first
      // Path format from JSON: "assets/qyiaarfigure/1/character_1_video_1.mp4"
      String assetPath = widget.videoPath;
      String assetPathForController = assetPath;
      
      // Debug: print the path being used
      debugPrint('Loading video asset with full path: $assetPathForController');
      debugPrint('Original path: $assetPath');
      
      // Verify asset exists by trying to load it
      try {
        await rootBundle.load(assetPath);
        debugPrint('Asset verified: $assetPath exists');
      } catch (e) {
        debugPrint('Warning: Could not verify asset $assetPath: $e');
        // Continue anyway, sometimes rootBundle.load fails but VideoPlayerController works
      }
      
      // Try loading the video with full path (including 'assets/')
      _controller = VideoPlayerController.asset(assetPathForController);
      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _duration = _controller!.value.duration;
        });
        
        _controller!.addListener(_videoListener);
        _controller!.play();
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      // Get assetPath again for error message
      String assetPath = widget.videoPath;
      String assetPathForController = assetPath;
      
      debugPrint('Video loading error: $e');
      debugPrint('Original path: $assetPath');
      debugPrint('Attempted path (with assets/): $assetPathForController');
      
      // Try to verify if asset exists
      try {
        await rootBundle.load(assetPath);
        debugPrint('Asset exists but VideoPlayerController failed to load it');
      } catch (loadError) {
        debugPrint('Asset verification failed: $loadError');
      }
      
      // If failed with assets/ prefix, try without it
      if (assetPath.startsWith('assets/')) {
        String pathWithoutAssets = assetPath.substring(7);
        debugPrint('Trying alternative path without assets/: $pathWithoutAssets');
        try {
          _controller = VideoPlayerController.asset(pathWithoutAssets);
          await _controller!.initialize();
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _duration = _controller!.value.duration;
            });
            _controller!.addListener(_videoListener);
            _controller!.play();
            setState(() {
              _isPlaying = true;
            });
            return; // Success with alternative path
          }
        } catch (e2) {
          debugPrint('Alternative path also failed: $e2');
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load video: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _videoListener() {
    if (_controller != null && mounted) {
      setState(() {
        _position = _controller!.value.position;
        _isPlaying = _controller!.value.isPlaying;
      });
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  void _togglePlayPause() {
    if (_controller != null) {
      if (_isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
      setState(() {
        _isPlaying = !_isPlaying;
      });
      _startHideControlsTimer();
    }
  }

  void _seekTo(Duration position) {
    if (_controller != null) {
      _controller!.seekTo(position);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  String _getAvatarPath() {
    return widget.character['QyiaarUserIcon'] ?? '';
  }

  String _getBackgroundImage() {
    final photoArray = widget.character['QyiaarShowPhotoArray'] as List<dynamic>?;
    if (photoArray != null && photoArray.isNotEmpty) {
      return photoArray[0] as String;
    }
    return 'assets/base_Content_bg.png';
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
      child: const Center(
        child: Icon(
          Icons.arrow_back,
          color: Colors.black,
          size: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final avatarPath = _getAvatarPath();
    final backgroundImage = _getBackgroundImage();
    final nickname = widget.character['QyiaarNickName'] ?? '';

    final statusBarHeight = MediaQuery.of(context).padding.top;

    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        // Check if tap is in back button area (left: 20, top: statusBarHeight + 20, size: 64x64)
        final backButtonLeft = 20.0;
        final backButtonTop = statusBarHeight + 20.0;
        final backButtonSize = 64.0; // Match the actual clickable area
        
        // Get screen position
        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final localPosition = renderBox.globalToLocal(details.globalPosition);
          
          // Check if tap is outside back button area
          if (localPosition.dx < backButtonLeft || 
              localPosition.dx > backButtonLeft + backButtonSize ||
              localPosition.dy < backButtonTop || 
              localPosition.dy > backButtonTop + backButtonSize) {
            // Tap is outside back button area, toggle controls
            _toggleControls();
          }
        } else {
          // Fallback: toggle controls if we can't determine position
          _toggleControls();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          automaticallyImplyLeading: false,
        ),
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                backgroundImage,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/base_Content_bg.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
            
            // Video player overlay
            if (_isInitialized && _controller != null)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            
            // Transparent overlay for back button area to prevent video player from intercepting taps
            // This must be before back button in stack order but will be covered by back button
            Positioned(
              top: statusBarHeight + 20,
              left: 20,
              child: AbsorbPointer(
                child: Container(
                  width: 64,
                  height: 64,
                  color: Colors.transparent,
                ),
              ),
            ),
        
            // Bottom controls
            if (_showControls)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress bar
                        if (_isInitialized && _controller != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Text(
                                  _formatDuration(_position),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: _position.inMilliseconds.toDouble(),
                                    min: 0,
                                    max: _duration.inMilliseconds.toDouble(),
                                    activeColor: Colors.white,
                                    inactiveColor: Colors.white.withOpacity(0.3),
                                    onChanged: (value) {
                                      _seekTo(Duration(milliseconds: value.toInt()));
                                    },
                                  ),
                                ),
                                Text(
                                  _formatDuration(_duration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // Play/Pause button
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isPlaying ? Colors.red.withOpacity(0.8) : Colors.green.withOpacity(0.8),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // Back button positioned on top (last in stack to ensure it's visible)
            // Use GestureDetector with opaque behavior to capture taps
            Positioned(
              top: statusBarHeight + 20,
              left: 20,
              child: GestureDetector(
                onTap: () {
                  debugPrint('Back button tapped');
                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                  Navigator.pop(context);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  color: Colors.transparent,
                  child: _buildBackButton(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

