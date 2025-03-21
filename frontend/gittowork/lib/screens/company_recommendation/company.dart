import 'package:flutter/material.dart';
import 'package:gittowork/widgets/app_bar.dart';

class CompanyScreen extends StatelessWidget {
  const CompanyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: const Center(
        child: Text(
          '기업 화면',
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}