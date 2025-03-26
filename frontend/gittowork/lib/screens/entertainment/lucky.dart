import 'package:flutter/material.dart';
import 'package:gittowork/widgets/app_bar_back.dart';

class LuckyScreen extends StatelessWidget {
  const LuckyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomBackAppBar(),
      body: const Center(child: Text('운세 화면')),
    );
  }
}
