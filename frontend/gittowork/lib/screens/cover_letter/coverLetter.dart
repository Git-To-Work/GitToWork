import 'package:flutter/material.dart';
import 'package:gittowork/widgets/app_bar.dart';

class CoverLetterScreen extends StatelessWidget {
  const CoverLetterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: const Center(
        child: Text(
          '자소서 화면',
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}
