import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'Privacy_Policy_page.dart';
import 'User_Agreement_page.dart';
import 'qliote_editor_page.dart';
import 'Voice_history_page.dart';

class QlioteProfilePage extends StatefulWidget {
  const QlioteProfilePage({super.key});

  @override
  State<QlioteProfilePage> createState() => _QlioteProfilePageState();
}

class _QlioteProfilePageState extends State<QlioteProfilePage> with WidgetsBindingObserver {
  String _nickname = 'Qliote';
  String? _avatarPath;
  int _audioFilesCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final audioCount = await _getAudioFilesCount();
    setState(() {
      _nickname = prefs.getString('user_nickname') ?? 'Qliote';
      _avatarPath = prefs.getString('user_avatar_path');
      _audioFilesCount = audioCount;
    });
  }

  Future<int> _getAudioFilesCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('audio_files_count') ?? 0;
    } catch (e) {
      return 0;
    }
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

  Future<void> _rateApp() async {
    try {
      final InAppReview inAppReview = InAppReview.instance;
      
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        // 如果无法显示评分弹窗，可以打开 App Store 页面
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

  Future<void> _shareApp() async {
    try {
      // 使用 iOS 系统原生分享功能
      // 注意：需要将 YOUR_APP_ID 替换为实际的 App Store ID（应用上架后获得）
      // 格式：https://apps.apple.com/app/id[APP_ID]
      const String appStoreUrl = 'https://apps.apple.com/app/idYOUR_APP_ID';
      const String shareText = 'Check out Qliote app! $appStoreUrl';
      
      await Share.share(
        shareText,
        subject: 'Qliote App',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share app: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/profile_content_bg.png',
              width: screenWidth,
              fit: BoxFit.fitWidth,
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
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
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black,
                                    offset: Offset(4, 4),
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
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Image.asset(
                                            'assets/user_qliote_icon.png',
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      );
                                    } else {
                                      return Image.asset(
                                        'assets/user_qliote_icon.png',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _nickname,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFF9C4), Color(0xFFFFE0E6)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
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
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const VoiceHistoryPage(),
                                      ),
                                    );
                                    // 返回后刷新数据
                                    await _loadUserData();
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Text(
                                      'Voice History',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Currently, $_audioFilesCount audio files have been generated.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFAEAEAE),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildAppAgreementSection(context),
                  const SizedBox(height: 20),
                  _buildAppInfoSection(context),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 130),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppAgreementSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'App Agreement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildMenuItem(
            imagePath: 'assets/profile_qliote_terms.png',
            title: 'User Agreement',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserAgreementPage(),
                ),
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          _buildMenuItem(
            imagePath: 'assets/profile_qliote_privacy.png',
            title: 'Privacy Policy',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'App Info',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildMenuItem(
            imagePath: 'assets/profile_qliote_editor.png',
            title: 'Editor Info',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QlioteEditorPage(),
                ),
              );
              if (result != null) {
                await _loadUserData();
              }
            },
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          _buildMenuItem(
            imagePath: 'assets/profile_qliote_share.png',
            title: 'Share App To Friend',
            onTap: () async {
              await _shareApp();
            },
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          _buildMenuItem(
            imagePath: 'assets/profile_qliote_rate.png',
            title: 'Give A Rate To App',
            onTap: () async {
              await _rateApp();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    String? imagePath,
    IconData? icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              if (imagePath != null)
                Image.asset(
                  imagePath,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                )
              else if (icon != null)
                Icon(icon, color: Colors.black, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.black,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

