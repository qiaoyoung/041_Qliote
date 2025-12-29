import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class ZhipuTTSService {
  static const String _apiKey = '31b048ca84154339a8914da617f335d7.dIjXF06TRaGBOK0E';
  static const String _apiUrl = 'https://open.bigmodel.cn/api/paas/v4/audio/speech';
  
  // Voice roles in English
  static const List<String> voiceRoles = [
    'tongtong',  // 彤彤 (default)
    'xiaochen',  // 小陈
    'chuichui',  // 锤锤
    'jam',       // jam
    'kazi',      // kazi
    'douji',     // douji
    'luodo',     // luodo
  ];

  Future<String> textToSpeech({
    required String text,
    String voice = 'tongtong',
  }) async {
    try {
      // Check if text is empty
      if (text.trim().isEmpty) {
        throw Exception('Text cannot be empty');
      }

      // 智谱AI TTS API 使用 input 字段而不是 text
      final requestBody = {
        'model': 'glm-tts',
        'input': text.trim(),
        'voice': voice,
                  "speed": 1.0,
          "volume": 1.0,
        "response_format": "wav",
      };

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        // Check if response has content
        if (response.bodyBytes.isEmpty) {
          throw Exception('API returned empty audio data');
        }

        // Check file format by examining file header
        String fileExtension = 'mp3'; // Default to mp3 as it's more common
        final bytes = response.bodyBytes;
        
        // Check file header to determine format
        if (bytes.length >= 4) {
          // WAV files start with "RIFF"
          if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
            fileExtension = 'wav';
          }
          // MP3 files may start with ID3 tag or MPEG header
          else if ((bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) || // ID3
                   (bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0)) { // MPEG header
            fileExtension = 'mp3';
          }
          // Check Content-Type header as fallback
          else {
            final contentType = response.headers['content-type']?.toLowerCase() ?? '';
            if (contentType.contains('wav') || contentType.contains('wave')) {
              fileExtension = 'wav';
            } else if (contentType.contains('mp3') || contentType.contains('mpeg')) {
              fileExtension = 'mp3';
            } else if (contentType.contains('audio/mpeg') || contentType.contains('audio/mp3')) {
              fileExtension = 'mp3';
            } else if (contentType.contains('audio/wav') || contentType.contains('audio/wave')) {
              fileExtension = 'wav';
            }
          }
        }

        // Save audio to permanent directory (Documents)
        final directory = await getApplicationDocumentsDirectory();
        final audioDir = Directory(path.join(directory.path, 'voice_history'));
        if (!await audioDir.exists()) {
          await audioDir.create(recursive: true);
        }
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'tts_$timestamp.$fileExtension';
        final filePath = path.join(audioDir.path, fileName);
        
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        // Verify file was created and has content
        if (!await file.exists()) {
          throw Exception('Failed to create audio file');
        }
        
        final fileSize = await file.length();
        if (fileSize == 0) {
          throw Exception('Audio file is empty');
        }
        
        if (fileSize < 100) {
          throw Exception('Audio file is too small (${fileSize} bytes), may be corrupted');
        }
        
        // Save audio file info to SharedPreferences
        await _saveAudioFileInfo(filePath, text, voice, timestamp);
        
        return filePath;
      } else {
        final errorMessage = 'TTS API error: ${response.statusCode}';
        final errorBody = response.body.isNotEmpty 
            ? response.body 
            : 'No error details';
        throw Exception('$errorMessage - $errorBody');
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        throw Exception('API endpoint not found (404). Please check the API URL and ensure the service is available.');
      }
      throw Exception('Failed to convert text to speech: $e');
    }
  }

  Future<void> _saveAudioFileInfo(String filePath, String text, String voice, int timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing audio files list
      final audioFilesJson = prefs.getStringList('audio_files') ?? [];
      
      // Create audio file info
      final audioInfo = {
        'filePath': filePath,
        'text': text,
        'voice': voice,
        'timestamp': timestamp,
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      // Add to list
      audioFilesJson.add(jsonEncode(audioInfo));
      
      // Save back to SharedPreferences
      await prefs.setStringList('audio_files', audioFilesJson);
      
      // Update audio count
      await prefs.setInt('audio_files_count', audioFilesJson.length);
    } catch (e) {
      // Ignore errors when saving file info
    }
  }

  static Future<List<Map<String, dynamic>>> getAudioFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final audioFilesJson = prefs.getStringList('audio_files') ?? [];
      
      return audioFilesJson.map((json) {
        return jsonDecode(json) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<int> getAudioFilesCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('audio_files_count') ?? 0;
    } catch (e) {
      return 0;
    }
  }
}

