import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'Image_qyiaar_page.dart';
import 'Video_qyiaar_page.dart';
import 'qyiaar_figure_detail_page.dart';

enum _MediaType { image, video }

class _ImageItem {
  final String imagePath;
  final String? videoPath;
  final String characterName;
  final Map<String, dynamic> character;
  final int crossAxisCellCount;
  final int mainAxisCellCount;
  final _MediaType mediaType;
  final List<String> allImages;

  _ImageItem({
    required this.imagePath,
    this.videoPath,
    required this.characterName,
    required this.character,
    required this.crossAxisCellCount,
    required this.mainAxisCellCount,
    required this.mediaType,
    required this.allImages,
  });
}

class QyiaarMessagePage extends StatefulWidget {
  const QyiaarMessagePage({super.key});

  @override
  State<QyiaarMessagePage> createState() => QyiaarMessagePageState();
}

class QyiaarMessagePageState extends State<QyiaarMessagePage> with WidgetsBindingObserver {
  List<_ImageItem> _imageItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAllCharacterImages();
  }

  void refresh() {
    _loadAllCharacterImages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAllCharacterImages();
    }
  }

  void refreshData() {
    _loadAllCharacterImages();
  }

  Future<void> _loadAllCharacterImages() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/qyiaar_figure.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      final allCharacters = jsonData.cast<Map<String, dynamic>>();
      final filtered = await _filterBlockedCharacters(allCharacters);
      
      final List<_ImageItem> imageItems = [];
      
      for (final character in filtered) {
        final nickname = character['QyiaarNickName'] as String? ?? '';
        final photoArray = character['QyiaarShowPhotoArray'] as List<dynamic>? ?? [];
        final videoArray = character['QyiaarShowVideoArray'] as List<dynamic>? ?? [];
        final thumbnailArray = character['QyiaarShowThumbnailArray'] as List<dynamic>? ?? [];
        
        final List<String> allImagePaths = photoArray
            .map((e) => e as String)
            .where((path) => path.isNotEmpty)
            .toList();
        
        for (int i = 0; i < photoArray.length; i++) {
          final imagePath = photoArray[i] as String? ?? '';
          if (imagePath.isNotEmpty) {
            final patternIndex = imageItems.length % 4;
            int crossAxisCellCount;
            int mainAxisCellCount;
            
            switch (patternIndex) {
              case 0:
                crossAxisCellCount = 2;
                mainAxisCellCount = 2;
                break;
              case 1:
                crossAxisCellCount = 1;
                mainAxisCellCount = 1;
                break;
              case 2:
                crossAxisCellCount = 1;
                mainAxisCellCount = 1;
                break;
              case 3:
                crossAxisCellCount = 1;
                mainAxisCellCount = 2;
                break;
              default:
                crossAxisCellCount = 1;
                mainAxisCellCount = 1;
            }
            
            imageItems.add(_ImageItem(
              imagePath: imagePath,
              characterName: nickname,
              character: character,
              crossAxisCellCount: crossAxisCellCount,
              mainAxisCellCount: mainAxisCellCount,
              mediaType: _MediaType.image,
              allImages: allImagePaths,
            ));
          }
        }
        
        for (int i = 0; i < videoArray.length; i++) {
          final videoPath = videoArray[i] as String? ?? '';
          if (videoPath.isNotEmpty) {
            final thumbnailPath = (i < thumbnailArray.length)
                ? thumbnailArray[i] as String? ?? ''
                : '';
            
            final displayImage = thumbnailPath.isNotEmpty
                ? thumbnailPath
                : (photoArray.isNotEmpty ? photoArray[0] as String : '');
            
            if (displayImage.isNotEmpty) {
              final patternIndex = imageItems.length % 4;
              int crossAxisCellCount;
              int mainAxisCellCount;
              
              switch (patternIndex) {
                case 0:
                  crossAxisCellCount = 2;
                  mainAxisCellCount = 2;
                  break;
                case 1:
                  crossAxisCellCount = 1;
                  mainAxisCellCount = 1;
                  break;
                case 2:
                  crossAxisCellCount = 1;
                  mainAxisCellCount = 1;
                  break;
                case 3:
                  crossAxisCellCount = 1;
                  mainAxisCellCount = 2;
                  break;
                default:
                  crossAxisCellCount = 1;
                  mainAxisCellCount = 1;
              }
              
              imageItems.add(_ImageItem(
                imagePath: displayImage,
                videoPath: videoPath,
                characterName: nickname,
                character: character,
                crossAxisCellCount: crossAxisCellCount,
                mainAxisCellCount: mainAxisCellCount,
                mediaType: _MediaType.video,
                allImages: allImagePaths,
              ));
            }
          }
        }
      }
      
      setState(() {
        _imageItems = imageItems;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading character images: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _filterBlockedCharacters(
    List<Map<String, dynamic>> characters,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final blockedList = prefs.getStringList('blocked_characters') ?? [];
    final mutedList = prefs.getStringList('muted_characters') ?? [];
    final allBlocked = {...blockedList, ...mutedList};

    return characters.where((character) {
      final nickname = character['QyiaarNickName'] as String? ?? '';
      return !allBlocked.contains(nickname);
    }).toList();
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
              'assets/circle_content_bg.png',
              width: screenWidth,
              fit: BoxFit.fitWidth,
            ),
          ),
          Positioned(
            top: statusBarHeight + 20,
            right: 20,
            child: Container(
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
                    // TODO: 添加眼睛按钮的点击事件
                  },
                  borderRadius: BorderRadius.circular(22),
                  child: const Center(
                    child: Icon(
                      Icons.visibility,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: statusBarHeight + 60,
            left: 0,
            right: 0,
            bottom: bottomPadding + 110,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _imageItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.message_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No images available',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: StaggeredGrid.count(
                          crossAxisCount: 4,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          children: _imageItems.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return StaggeredGridTile.count(
                              crossAxisCellCount: item.crossAxisCellCount,
                              mainAxisCellCount: item.mainAxisCellCount,
                              child: _CharacterImageTile(
                                imagePath: item.imagePath,
                                characterName: item.characterName,
                                mediaType: item.mediaType,
                                videoPath: item.videoPath,
                                character: item.character,
                                allImages: item.allImages,
                                imageIndex: item.mediaType == _MediaType.image
                                    ? (item.allImages.indexOf(item.imagePath) >= 0
                                        ? item.allImages.indexOf(item.imagePath)
                                        : 0)
                                    : 0,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _CharacterImageTile extends StatelessWidget {
  final String imagePath;
  final String characterName;
  final _MediaType mediaType;
  final String? videoPath;
  final Map<String, dynamic> character;
  final List<String> allImages;
  final int imageIndex;

  const _CharacterImageTile({
    required this.imagePath,
    required this.characterName,
    required this.mediaType,
    this.videoPath,
    required this.character,
    required this.allImages,
    required this.imageIndex,
  });

  void _onTap(BuildContext context) {
    if (mediaType == _MediaType.video && videoPath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoQyiaarPage(
            videoPath: videoPath!,
            character: character,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageQyiaarPage(
            imagePath: imagePath,
            imageArray: allImages,
            initialIndex: imageIndex >= 0 ? imageIndex : 0,
            character: character,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
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
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
              if (mediaType == _MediaType.video)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QyiaarFigureDetailPage(
                          character: character,
                        ),
                      ),
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 23,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 0.5),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              character['QyiaarUserIcon'] as String? ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[400],
                                  child: const Icon(
                                    Icons.person,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            characterName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
