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
            Expanded(
              child: TextButton(
                onPressed: () => onItemTapped(2),
                child: const Text("3"),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => onItemTapped(3),
                child: const Text("4"),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => onItemTapped(4),
                child: const Text("5"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
