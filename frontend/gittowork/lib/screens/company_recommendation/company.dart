import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gittowork/widgets/app_bar.dart';
import 'package:gittowork/screens/company_recommendation/search.dart';
import 'package:gittowork/screens/company_recommendation/company_list.dart';
import 'package:gittowork/providers/search_provider.dart';

import '../../providers/company_provider.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  @override
  Widget build(BuildContext context) {
    final isHiring = Provider.of<SearchFilterProvider>(context).isHiring;

    return Scaffold(
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SearchBarWithFilters(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text(
                    "AI 기업 추천",
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isHiring,
                        checkColor: Colors.white,
                        activeColor: const Color(0xFF2C2C2C),
                        visualDensity: const VisualDensity(horizontal: -4.0, vertical: -2),
                        onChanged: (bool? value) async {
                          // ✅ 1. 상태 업데이트
                          Provider.of<SearchFilterProvider>(context, listen: false)
                              .updateIsHiring(value ?? false);

                          // ✅ 2. API 호출
                          await Provider.of<CompanyProvider>(context, listen: false)
                              .loadCompaniesFromApi(
                            context: context,
                            page: '1',
                            size: '20',
                            reset: true,
                          );
                        },
                      ),
                      const Text("채용중인 기업", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
            const Expanded(child: CompanyList()),
          ],
        ),
      ),
    );
  }
}
