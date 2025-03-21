import 'package:flutter/material.dart';
import 'package:gittowork/widgets/app_bar_back.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomBackAppBar(),
      body: const Center(child: Text('퀴즈 화면')),
    );
  }
}
