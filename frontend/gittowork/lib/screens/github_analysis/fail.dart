import 'package:flutter/material.dart';

class FailScreen extends StatelessWidget {
  const FailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 60,
              ),
              const SizedBox(height: 24),
              const Text(
                '분석에 실패했어요',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '현재 선택한 레포지토리 조합에서 분석 가능한 데이터가 없어요.\n\n레포지토리 조합을 삭제하고 다시 만들어주세요.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
