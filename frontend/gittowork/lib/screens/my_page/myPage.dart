import 'package:flutter/material.dart';
import 'package:gittowork/widgets/app_bar.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: const Center(
        child: Text(
          '마이페이지 화면',
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}
