import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gittowork/providers/github_analysis_provider.dart';

class RepoScreen extends StatelessWidget {
  const RepoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFDFF),
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Repo : mkos47635',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Last Analysis : 2025/03/11 13:03:13',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () {
                context.read<GitHubAnalysisProvider>().incrementTestData();
              },
              child: Image.asset(
                'assets/images/Reload.png',
                width: 20,
                height: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
