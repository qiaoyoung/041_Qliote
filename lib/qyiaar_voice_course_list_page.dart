import 'package:flutter/material.dart';

class VoiceCourse {
  final String title;
  final String level;
  final List<String> techniques;
  final String source;

  VoiceCourse({
    required this.title,
    required this.level,
    required this.techniques,
    required this.source,
  });
}

class QyiaarVoiceCourseListPage extends StatelessWidget {
  const QyiaarVoiceCourseListPage({super.key});

  List<VoiceCourse> _getCourses() {
    return [
      VoiceCourse(
        title: 'Voice Acting Basics',
        level: 'Beginner',
        techniques: [
          'Basic Pronunciation Practice: Master the pronunciation of initials and finals in standard Mandarin',
          'Breath Control: Learn diaphragmatic breathing to improve voice stability and endurance',
          'Emotional Expression: Understand how different emotions are reflected in voice',
          'Basic Rhythm: Master the fundamentals of speech rate, pauses, and stress',
        ],
        source: 'Source: Chinese Voice Acting Network - Voice Acting Fundamentals',
      ),
      VoiceCourse(
        title: 'Voice Acting Intermediate',
        level: 'Intermediate',
        techniques: [
          'Character Building: Learn how to create different character personalities through voice',
          'Voice Variation: Master techniques for changing timbre and pitch to portray different characters',
          'Emotional Layers: Deepen understanding of complex emotional expression',
          'Dubbing Rhythm: Learn how to synchronize voice with visual rhythm',
          'Lip Sync: Master the basic techniques of lip synchronization',
        ],
        source: 'Source: Voice Acting Art Magazine - Intermediate Voice Acting Techniques',
      ),
      VoiceCourse(
        title: 'Voice Acting Advanced',
        level: 'Advanced',
        techniques: [
          'Multi-Character Switching: Master the ability to quickly switch between different characters in the same work',
          'Voice Performance: Deeply study the artistry and expressiveness of voice performance',
          'Professional Equipment Usage: Understand the use of professional recording equipment and software',
          'Post-Production: Learn post-processing and sound effects production for voice acting',
          'Industry Standards: Master professional standards and ethics in the voice acting industry',
          'Practical Training: Enhance voice acting skills through real projects',
        ],
        source: 'Source: Professional Voice Acting Training Institute - Advanced Course System',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final courses = _getCourses();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(courses.length * 2 - 1, (index) {
          if (index.isOdd) {
            return const SizedBox(height: 20);
          }
          final courseIndex = index ~/ 2;
          final course = courses[courseIndex];

          return _buildCourseCard(context, screenWidth, course);
        }),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, double screenWidth, VoiceCourse course) {
    return Container(
      width: screenWidth - 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    course.level,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Voice Acting Techniques:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            ...course.techniques.map((technique) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          technique,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.source,
                    size: 16,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      course.source,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

