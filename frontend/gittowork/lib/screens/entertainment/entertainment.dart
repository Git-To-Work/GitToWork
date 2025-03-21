import 'package:flutter/material.dart';
import 'duck.dart';
import 'lucky.dart';
import 'quiz.dart';

class EntertainmentScreen extends StatefulWidget {
  const EntertainmentScreen({super.key});

  @override
  State<EntertainmentScreen> createState() => _EntertainmentScreenState();
}

class _EntertainmentScreenState extends State<EntertainmentScreen> {
  // Remove const from the list
  final List<Widget> _screens = [
    DuckScreen(), // We’ll replace this instance with one that has a callback
    const LuckyScreen(),
    const QuizScreen(),
  ];

  int _currentIndex = 0;

  // Callback to change the current screen
  void _changeScreen(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Replace the DuckScreen in the list with one that has the callback
    List<Widget> screens = _screens.map((screen) {
      if (screen is DuckScreen) {
        return DuckScreen(onChangeScreen: _changeScreen);
      }
      return screen;
    }).toList();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
    );
  }
}
