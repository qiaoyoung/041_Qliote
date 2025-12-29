import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class ZhipuVideoService {
  static const String _apiKey = '31b048ca84154339a8914da617f335d7.dIjXF06TRaGBOK0E';
  static const String _apiUrl = 'https://open.bigmodel.cn/api/paas/v4/videos/generations';
  static const String _taskUrl = 'https://open.bigmodel.cn/api/paas/v4/videos/tasks';

  Future<String> textToVideo({
    required String text,
    Function(String)? onProgress,
  }) async {
    try {
      // Check if text is empty
      if (text.trim().isEmpty) {
        throw Exception('Text cannot be empty');
      }

      final requestBody = {
        'model': 'cogvideox-3',
        'prompt': text.trim(),
        'quality': 'quality',
        'with_audio': true,
        'size': '1920x1080',
        'fps': 30,
      };

      // Step 1: Submit video generation task
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        final errorMessage = 'Video API error: ${response.statusCode}';
        final errorBody = response.body.isNotEmpty 
            ? response.body 
            : 'No error details';
        throw Exception('$errorMessage - $errorBody');
      }

      final responseData = jsonDecode(response.body);
      
      // Check if response contains task ID
      String? taskId;
      String? taskStatus;
      
      if (responseData is Map<String, dynamic>) {
        taskId = responseData['id'] as String?;
        taskStatus = responseData['task_status'] as String?;
        
        // If task is already completed, get video URL directly
        if (taskStatus == 'SUCCESS' || taskStatus == 'COMPLETED') {
          String? videoUrl = responseData['data']?[0]?['url'] as String? ??
                             responseData['video_url'] as String? ??
                             responseData['url'] as String?;
          
          if (videoUrl != null && videoUrl.isNotEmpty) {
            return await _downloadAndSaveVideo(videoUrl, text);
          }
        }
      }

      if (taskId == null || taskId.isEmpty) {
        throw Exception('No task ID in API response. Response: ${response.body}');
      }

      // Step 2: Poll task status until completion
      onProgress?.call('Task submitted, waiting for processing...');
      
      String? videoUrl;
      int maxAttempts = 120; // Maximum 10 minutes (120 * 5 seconds)
      int attempt = 0;
      
      while (attempt < maxAttempts) {
        await Future.delayed(const Duration(seconds: 5)); // Wait 5 seconds between polls
        
        // Try different possible API endpoints for querying task status
        http.Response? taskResponse;
        
        // Method 1: Try GET with task ID in path
        try {
          taskResponse = await http.get(
            Uri.parse('$_taskUrl/$taskId'),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
          );
        } catch (e) {
          // Method 2: Try GET with task ID as query parameter
          try {
            taskResponse = await http.get(
              Uri.parse('$_apiUrl?task_id=$taskId'),
              headers: {
                'Authorization': 'Bearer $_apiKey',
                'Content-Type': 'application/json',
              },
            );
          } catch (e2) {
            // Method 3: Try POST to query task status
            try {
              taskResponse = await http.post(
                Uri.parse('$_taskUrl'),
                headers: {
                  'Authorization': 'Bearer $_apiKey',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({'task_id': taskId}),
              );
            } catch (e3) {
              // If all methods fail, continue polling
              attempt++;
              continue;
            }
          }
        }

        if (taskResponse != null && taskResponse.statusCode == 200) {
          final taskData = jsonDecode(taskResponse.body);
          
          if (taskData is Map<String, dynamic>) {
            taskStatus = taskData['task_status'] as String?;
            
            if (taskStatus == 'SUCCESS' || taskStatus == 'COMPLETED') {
              // Task completed, get video URL
              videoUrl = taskData['data']?[0]?['url'] as String? ??
                         taskData['data']?[0]?['video_url'] as String? ??
                         taskData['video_url'] as String? ??
                         taskData['url'] as String?;
              
              if (videoUrl != null && videoUrl.isNotEmpty) {
                onProgress?.call('Video generated, downloading...');
                return await _downloadAndSaveVideo(videoUrl, text);
              }
            } else if (taskStatus == 'FAILED' || taskStatus == 'ERROR') {
              final errorMsg = taskData['error']?['message'] as String? ?? 
                              taskData['message'] as String? ?? 
                              'Task failed';
              throw Exception('Video generation failed: $errorMsg');
            } else if (taskStatus == 'PROCESSING' || taskStatus == 'PENDING') {
              onProgress?.call('Processing... (${attempt + 1}/$maxAttempts)');
              attempt++;
              continue;
            }
          }
        } else if (taskResponse != null && taskResponse.statusCode == 404) {
          // Task not found, might need to use original response
          // Try to get video URL from original response if available
          if (responseData is Map<String, dynamic>) {
            videoUrl = responseData['data']?[0]?['url'] as String? ??
                       responseData['video_url'] as String? ??
                       responseData['url'] as String?;
            
            if (videoUrl != null && videoUrl.isNotEmpty) {
              onProgress?.call('Video generated, downloading...');
              return await _downloadAndSaveVideo(videoUrl, text);
            }
          }
        }
        
        attempt++;
      }

      throw Exception('Video generation timeout. Task status: $taskStatus');
    } catch (e) {
      throw Exception('Failed to generate video: $e');
    }
  }

  Future<String> _downloadAndSaveVideo(String videoUrl, String text) async {
    // Download video file
    final videoResponse = await http.get(Uri.parse(videoUrl));
    if (videoResponse.statusCode != 200) {
      throw Exception('Failed to download video: ${videoResponse.statusCode}');
    }

    // Save video to permanent directory
    final directory = await getApplicationDocumentsDirectory();
    final videoDir = Directory(path.join(directory.path, 'video_history'));
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'video_$timestamp.mp4';
    final filePath = path.join(videoDir.path, fileName);

    final file = File(filePath);
    await file.writeAsBytes(videoResponse.bodyBytes);

    // Verify file was created
    if (!await file.exists()) {
      throw Exception('Failed to create video file');
    }

    final fileSize = await file.length();
    if (fileSize == 0) {
      throw Exception('Video file is empty');
    }

    // Save video file info to SharedPreferences
    await _saveVideoFileInfo(filePath, text, timestamp);

    return filePath;
  }

  Future<void> _saveVideoFileInfo(String filePath, String text, int timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing video files list
      final videoFilesJson = prefs.getStringList('video_files') ?? [];
      
      // Create video file info
      final videoInfo = {
        'filePath': filePath,
        'text': text,
        'timestamp': timestamp,
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      // Add to list
      videoFilesJson.add(jsonEncode(videoInfo));
      
      // Save back to SharedPreferences
      await prefs.setStringList('video_files', videoFilesJson);
      
      // Update video count
      await prefs.setInt('video_files_count', videoFilesJson.length);
    } catch (e) {
      // Ignore errors when saving file info
    }
  }

  static Future<List<Map<String, dynamic>>> getVideoFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videoFilesJson = prefs.getStringList('video_files') ?? [];
      
      return videoFilesJson.map((json) {
        return jsonDecode(json) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<int> getVideoFilesCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('video_files_count') ?? 0;
    } catch (e) {
      return 0;
    }
  }
}

