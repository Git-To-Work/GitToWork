import 'package:flutter/material.dart';

class EntertainmentScreen extends StatelessWidget {
  const EntertainmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 전체 가로 너비에서 좌우 20씩 패딩을 빼면 사용 가능한 너비
    double availableWidth = MediaQuery.of(context).size.width - 40;
    // 두 상자 사이 간격 30을 고려하여 한 상자의 너비 계산
    double boxWidth = (availableWidth - 30) / 2;
    // 정사각형이므로 높이도 boxWidth와 같습니다.
    double boxHeight = boxWidth;
    // 두 상자 Positioned의 top은 330으로 고정되어 있으므로,
    // 그 아래 10픽셀 간격 후에 Circle.png를 배치합니다.

    return Container(
      color: const Color(0xFF6D6D6D), // 전체 배경색
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          // (1) Light.jpg - 가장 아래에 배치 (조금 더 위로)
          const Positioned(
            top: -30,
            left: 0,
            right: 0,
            child: Image(
              image: AssetImage('assets/images/Light.jpg'),
            ),
          ),
          // (2) 두 정사각형 상자 - 중간 레이어
          const Positioned(
            top: 330,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1, // 정사각형
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Center(
                        child: Text(
                          '운세',
                          style: TextStyle(
                            fontSize: 50,
                            color: Colors.black,
                            fontWeight: FontWeight.bold, // Bold 추가
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 30), // 상자 사이 30픽셀 간격
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Center(
                        child: Text(
                          '퀴즈',
                          style: TextStyle(
                            fontSize: 50,
                            color: Colors.black,
                            fontWeight: FontWeight.bold, // Bold 추가
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // (3) Circle.png - 두 상자 바로 아래에 배치, 상자 너비의 합과 같음.
          Positioned(
            top: 530,
            left: 20,
            right: 20,
            child: Image.asset('assets/images/Circle.png'),
          ),
          // (4) Duck.gif - 가장 위 레이어, 겹치더라도 위에 표시됨.
          Positioned(
            top: 490,
            bottom: 0,
            left: 0,
            right: 0,
            child: Transform.scale(
              scale: 1.05, // 5% 크기 증가
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
