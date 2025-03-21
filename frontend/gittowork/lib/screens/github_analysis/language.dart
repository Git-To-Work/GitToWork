import 'package:flutter/material.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  Widget buildBox(String text,
      {Color? color,
        Gradient? gradient,
        String? percentText,
        Alignment percentAlign = Alignment.topRight}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4.0), // 그림자를 위한 여백 추가
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color,
              gradient: gradient,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25), // 좀 더 진한 그림자
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: text == 'Python'
                      ? 32
                      : text == 'Java Script'
                      ? 24
                      : 16,
                  fontWeight: FontWeight.bold,
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

    return Container(
      width: double.infinity,
      height: 200,
      margin: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Python
          Expanded(
            flex: 1,
            child: buildBox(
              'Python',
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF87A6EF),
                  Color(0xFFB2C6F5),
                ],
                stops: [0.5, 1.0],
              ),
              percentText: '70%',
              percentAlign: Alignment.topRight,
            ),
          ),
          SizedBox(width: gap),
          // 오른쪽 영역
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Java Script
                Expanded(
                  flex: 5,
                  child: buildBox(
                    'Java Script',
                    gradient: const LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [
                        Color(0xFF7ADB7F),
                        Color(0xFFA7DEA9),
                      ],
                      stops: [0.46, 1.0],
                    ),
                    percentText: '70%',
                    percentAlign: Alignment.bottomLeft,
                  ),
                ),
                SizedBox(height: gap),
                // JAVA와 other
                Expanded(
                  flex: 3,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double height = constraints.maxHeight;
                      return Row(
                        children: [
                          Expanded(
                            child: buildBox(
                              'JAVA',
                              gradient: const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Color(0xFFF3A57B),
                                  Color(0xFFFFD0B7),
                                ],
                                stops: [0.44, 1.0],
                              ),
                              percentText: '10%',
                              percentAlign: Alignment.topLeft,
                            ),
                          ),
                          SizedBox(width: gap),
                          Container(
                            width: height,
                            height: height,
                            child: buildBox(
                              'other',
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFAEA71),
                                  Color(0xFFFAEA71),
                                ],
                                stops: [0.59, 1.0],
                              ),
                              percentText: '5%',
                              percentAlign: Alignment.topLeft,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
