import 'package:flutter/material.dart';

class LuckyScreen extends StatelessWidget {
  const LuckyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('운세')),
      body: const Center(child: Text('운세 화면')),
    );
  }
}
