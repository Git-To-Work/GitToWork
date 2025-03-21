import 'package:flutter/material.dart';
import 'lucky.dart';
import 'quiz.dart';

class DuckScreen extends StatelessWidget {
  final Function(int)? onChangeScreen;

  const DuckScreen({super.key, this.onChangeScreen});

  @override
  Widget build(BuildContext context) {
    double availableWidth = MediaQuery.of(context).size.width - 40;
    double boxWidth = (availableWidth - 30) / 2;
    double boxHeight = boxWidth;

    return Container(
      color: const Color(0xFF6D6D6D),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          const Positioned(
            top: -30,
            left: 0,
            right: 0,
            child: Image(
              image: AssetImage('assets/images/Light.jpg'),
            ),
          ),
          Positioned(
            top: 330,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: InkWell(
                      onTap: () {
                        // 운세 버튼 클릭 시 콜백 호출하여 LuckyScreen으로 변경
                        if (onChangeScreen != null) {
                          onChangeScreen!(1);
                        }
                      },
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            '운세',
                            style: TextStyle(
                              fontSize: 50,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 30),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: InkWell(
                      onTap: () {
                        // 퀴즈 버튼 클릭 시 콜백 호출하여 QuizScreen으로 변경
                        if (onChangeScreen != null) {
                          onChangeScreen!(2);
                        }
                      },
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            '퀴즈',
                            style: TextStyle(
                              fontSize: 50,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 530,
            left: 20,
            right: 20,
            child: Image(image: AssetImage('assets/images/Circle.png')),
          ),
          Positioned(
            top: 490,
            bottom: 0,
            left: 0,
            right: 0,
            child: Transform.scale(
              scale: 1.05,
              child: Image(
                image: AssetImage('assets/images/Duck.gif'),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
