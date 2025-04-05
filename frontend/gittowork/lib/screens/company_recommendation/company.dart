import 'package:flutter/material.dart';
import 'package:gittowork/widgets/app_bar.dart';
import 'package:gittowork/screens/company_recommendation/search.dart';
import 'package:gittowork/screens/company_recommendation/company_list.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  bool _isHiring = false; // 체크박스 상태 관리!

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchBarWithFilters(),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: const Text(
                    "AI 기업 추천",
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isHiring,
                        checkColor: const Color(0xFFFFFFFF),
                        activeColor: const Color(0xFF2C2C2C),
                        visualDensity: VisualDensity(horizontal: -4.0, vertical: -2),
                        onChanged: (bool? value) {
                          setState(() {
                            _isHiring = value ?? false;
                          });
                        },
                      ),
                      const Text(
                        "채용중인 기업",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Expanded(
              child: CompanyList(),
            ),
          ],
        ),
      ),
    );
  }
}
