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

          // 운세, 퀴즈 / Circle / Duck을 하나로 묶어서 이동 가능
          Positioned(
            top: 300, // 이 값을 조정하면 세 개가 동시에 이동
            left: 0,
            right: 0,
            child: Column(
              children: [
                // (운세, 퀴즈 버튼)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              CircularRevealRoute(page: const LuckyScreen()),
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
                            Navigator.of(context).push(
                              CircularRevealRoute(page: const QuizScreen()),
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
                const SizedBox(height: 20), // 간격 추가 가능

                // Circle 이미지
                const Image(
                  image: AssetImage('assets/images/Circle.png'),
                ),
                const SizedBox(height: 20), // 간격 추가 가능

                // Duck 애니메이션
                Transform.scale(
                  scale: 1.05,
                  child: const Image(
                    image: AssetImage('assets/images/Duck.gif'),
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
          final finalRadius = sqrt(pow(size.width, 2) + pow(size.height, 2));

          double t = animation.value;
          Offset animatedCenter;
          double animatedRadius;

          if (t < 0.5) {
            double tPos = t / 0.5;
            final Offset startCenter = Offset(size.width / 2, size.height + 40);
            final Offset endCenter = Offset(size.width / 2, size.height / 2);
            animatedCenter = Offset.lerp(startCenter, endCenter, Curves.easeOut.transform(tPos))!;
            animatedRadius = 40;
          } else {
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
