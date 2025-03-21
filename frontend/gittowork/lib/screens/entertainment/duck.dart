import 'dart:math';
import 'dart:ui';

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
                        // 운세 버튼 클릭 시 원형 애니메이션으로 LuckyScreen으로 이동
                        Navigator.of(context).push(
                          CircularRevealRoute(
                            page: const LuckyScreen(),
                          ),
                        );
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
                        // 퀴즈 버튼 클릭 시 원형 애니메이션으로 QuizScreen으로 이동
                        Navigator.of(context).push(
                          CircularRevealRoute(
                            page: const QuizScreen(),
                          ),
                        );
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

/// 커스텀 동그라미 전환 애니메이션 라우트
class CircularRevealRoute extends PageRouteBuilder {
  final Widget page;

  CircularRevealRoute({required this.page})
      : super(
    transitionDuration: const Duration(milliseconds: 700),
    reverseTransitionDuration: const Duration(milliseconds: 700),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder:
        (context, animation, secondaryAnimation, child) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final size = MediaQuery.of(context).size;
          // 최종 동그라미 반지름: 화면 대각선 길이를 사용
          final finalRadius = sqrt(pow(size.width, 2) + pow(size.height, 2));

          double t = animation.value;
          Offset animatedCenter;
          double animatedRadius;

          if (t < 0.5) {
            // 첫 단계: 동그라미가 화면 밑에서 중앙으로 이동 (크기는 고정 40)
            double tPos = t / 0.5;
            // 초기 위치: 화면 밑 (동그라미의 반지름만큼 아래에서 시작)
            final Offset startCenter = Offset(size.width / 2, size.height + 40);
            // 최종 위치: 화면 중앙
            final Offset endCenter = Offset(size.width / 2, size.height / 2);
            animatedCenter = Offset.lerp(startCenter, endCenter, Curves.easeOut.transform(tPos))!;
            animatedRadius = 40;
          } else {
            // 두 번째 단계: 동그라미는 중앙에 고정, 크기가 40에서 finalRadius까지 확장
            double tReveal = (t - 0.5) / 0.5;
            animatedCenter = Offset(size.width / 2, size.height / 2);
            animatedRadius = lerpDouble(40, finalRadius, Curves.easeOut.transform(tReveal))!;
          }

          return ClipPath(
            clipper: CircleRevealClipper(
              center: animatedCenter,
              radius: animatedRadius,
            ),
            child: child,
          );
        },
        child: child,
      );
    },
  );
}

/// 지정된 center와 radius를 가진 원형 영역을 반환하는 커스텀 클리퍼
class CircleRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  CircleRevealClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(CircleRevealClipper oldClipper) {
    return center != oldClipper.center || radius != oldClipper.radius;
  }
}