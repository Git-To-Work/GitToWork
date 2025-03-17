import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => onItemTapped(0),
                child: const Text("1"),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => onItemTapped(1),
                child: const Text("2"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
