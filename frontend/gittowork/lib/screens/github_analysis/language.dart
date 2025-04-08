import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/github_analysis_provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  /// 언어 코드 → 라벨 변환 함수
  String getLanguageLabel(String key) {
    const languageMap = {
      'java': 'JAVA',
      'js': 'Java Script',
      'javascript': 'Java Script',
      'ts': 'Type Script',
      'cs': 'C#',
      'py': 'Python',
      'python': 'Python',
      'php': 'PHP',
      'cpp': 'C/C++',
      'c++': 'C/C++',
      'html': 'HTML',
      'css': 'CSS',
      'xml': 'XML',
      'go': 'Go',
      'kt': 'Kotlin',
      'kotlin': 'Kotlin',
      'swift': 'Swift',
      'ruby': 'Ruby',
      'groovy': 'Groovy',
      'plsql': 'PL/SQL',
      'scala': 'Scala',
    };

    final lowerKey = key.toLowerCase();
    return languageMap[lowerKey] ?? key;
  }

  Widget buildBox(
      String text, {
        double fontSize = 16,
        Color? color,
        Gradient? gradient,
        String? percentText,
        Alignment percentAlign = Alignment.topRight,
        bool shiftTextDown = false,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4.0),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color,
              gradient: gradient,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Align(
              alignment: shiftTextDown ? const Alignment(0, 0.2) : Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (percentText != null)
            Positioned(
              top: percentAlign.y < 0 ? 6 : null,
              bottom: percentAlign.y > 0 ? 6 : null,
              left: percentAlign.x < 0 ? 6 : null,
              right: percentAlign.x > 0 ? 6 : null,
              child: Text(
                percentText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = 14.0;

    final languageRatios =
        Provider.of<GitHubAnalysisProvider>(context).languageRatios;

    final sortedEntries = languageRatios.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sortedEntries.take(3).toList();
    final others = sortedEntries.skip(3);
    final otherPercent =
    others.fold<double>(0, (sum, e) => sum + e.value);

    final lan1 = top3.length > 0 ? top3[0] : const MapEntry('N/A', 0.0);
    final lan2 = top3.length > 1 ? top3[1] : const MapEntry('N/A', 0.0);
    final lan3 = top3.length > 2 ? top3[2] : const MapEntry('N/A', 0.0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final leftBoxWidth = (totalWidth - gap) / 2;

          return Row(
            children: [
              SizedBox(
                width: leftBoxWidth,
                height: leftBoxWidth,
                child: buildBox(
                  getLanguageLabel(lan1.key),
                  fontSize: 32,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF87A6EF), Color(0xFFB2C6F5)],
                    stops: [0.5, 1.0],
                  ),
                  percentText: '${lan1.value.toStringAsFixed(1)}%',
                  percentAlign: Alignment.topRight,
                ),
              ),
              SizedBox(width: gap),
              SizedBox(
                width: leftBoxWidth,
                height: leftBoxWidth,
                child: Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: buildBox(
                        getLanguageLabel(lan2.key),
                        fontSize: 24,
                        gradient: const LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: [Color(0xFF7ADB7F), Color(0xFFA7DEA9)],
                          stops: [0.46, 1.0],
                        ),
                        percentText: '${lan2.value.toStringAsFixed(1)}%',
                        percentAlign: Alignment.bottomLeft,
                      ),
                    ),
                    SizedBox(height: gap),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Expanded(
                            child: buildBox(
                              getLanguageLabel(lan3.key),
                              fontSize: 16,
                              gradient: const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Color(0xFFF3A57B),
                                  Color(0xFFFFD0B7)
                                ],
                                stops: [0.44, 1.0],
                              ),
                              percentText:
                              '${lan3.value.toStringAsFixed(1)}%',
                              percentAlign: Alignment.topLeft,
                              shiftTextDown: true,
                            ),
                          ),
                          SizedBox(width: gap),
                          AspectRatio(
                            aspectRatio: 1,
                            child: buildBox(
                              'Other',
                              fontSize: 16,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFAEA71), Color(0xFFFAEA71)],
                                stops: [0.59, 1.0],
                              ),
                              percentText:
                              '${otherPercent.toStringAsFixed(1)}%',
                              percentAlign: Alignment.topLeft,
                              shiftTextDown: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
