import 'package:flutter/material.dart';

class AnalysingScreen extends StatelessWidget {
  const AnalysingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 20),
      child: AnalysingCard(),
    );
  }
}

class AnalysingCard extends StatelessWidget {
  const AnalysingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = screenWidth - 20; // 전체 너비 - 20

    return Container(
      width: double.infinity,
      height: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: const Color(0xFFD6D6D6),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(64, 0, 0, 0),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Spacer(flex: 2), // 위 공간 확보 (20 정도 위로 올림 효과)
          Image.asset(
            'assets/images/Loading.gif',
            width: imageWidth,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          const Text(
            '열심히 분석중입니다!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '분석이 완료되면 알림을 보내드릴게요 📩',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF4D4D4D),
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 5),
        ],
      ),
    );
  }
}
