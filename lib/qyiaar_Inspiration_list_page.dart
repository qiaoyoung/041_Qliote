import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'Video_qyiaar_page.dart';
import 'report_page.dart';
import 'qyiaar_figure_detail_page.dart';

class QyiaarInspirationListPage extends StatelessWidget {
  final List<Map<String, dynamic>> filteredCharacters;
  final Function(BuildContext, Map<String, dynamic>) onShowActionSheet;
  final VoidCallback? onRefreshData;

  const QyiaarInspirationListPage({
    super.key,
    required this.filteredCharacters,
    required this.onShowActionSheet,
    this.onRefreshData,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return _buildCharacterList(context, screenWidth);
  }

  Widget _buildCharacterList(BuildContext context, double screenWidth) {
    final itemWidth = screenWidth - 40;
    final spacing = 20.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(filteredCharacters.length * 2 - 1, (index) {
          if (index.isOdd) {
            return SizedBox(height: spacing);
          }
          final characterIndex = index ~/ 2;
          final character = filteredCharacters[characterIndex];
          final thumbnailArray = character['QyiaarShowThumbnailArray'] as List<dynamic>?;
          final thumbnailPath = thumbnailArray != null && thumbnailArray.isNotEmpty
              ? thumbnailArray[0] as String
              : null;

          final videoArray = character['QyiaarShowVideoArray'] as List<dynamic>?;
          final videoPath = videoArray != null && videoArray.isNotEmpty
              ? videoArray[0] as String
              : null;

          final nickname = character['QyiaarNickName'] as String? ?? '';
          final avatarPath = character['QyiaarUserIcon'] as String? ?? '';

          return GestureDetector(
            onTap: () {
              if (videoPath != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoQyiaarPage(
                      videoPath: videoPath,
                      character: character,
                    ),
                  ),
                );
              }
            },
            child: SizedBox(
              width: itemWidth,
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/inspiration_video_cell_bg.png'),
                    fit: BoxFit.fill,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: thumbnailPath != null
                            ? Image.asset(
                                thumbnailPath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.error, color: Colors.grey),
                                  );
                                },
                              )
                            : const Center(
                                child: Icon(Icons.image, color: Colors.grey),
                              ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          color: Colors.black.withOpacity(0.5),
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
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            onShowActionSheet(context, character);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.report,
                              color: Colors.black,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                            ),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => QyiaarFigureDetailPage(
                                        character: character,
                                        onDataChanged: () {
                                          if (onRefreshData != null) {
                                            onRefreshData!();
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                  if (result == true && onRefreshData != null) {
                                    onRefreshData!();
                                  }
                                },
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1),
                                  ),
                                  child: ClipOval(
                                    child: avatarPath.isNotEmpty
                                        ? Image.asset(
                                            avatarPath,
                                            width: 24,
                                            height: 24,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/user_qyiaar_icon.png',
                                                width: 24,
                                                height: 24,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          )
                                        : Image.asset(
                                            'assets/user_qyiaar_icon.png',
                                            width: 24,
                                            height: 24,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QyiaarFigureDetailPage(
                                          character: character,
                                          onDataChanged: () {
                                            if (onRefreshData != null) {
                                              onRefreshData!();
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                    if (result == true && onRefreshData != null) {
                                      onRefreshData!();
                                    }
                                  },
                                  child: Text(
                                    nickname,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

