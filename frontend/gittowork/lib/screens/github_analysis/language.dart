import 'package:flutter/material.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: const Center(
        child: Text(
          'language',
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}
