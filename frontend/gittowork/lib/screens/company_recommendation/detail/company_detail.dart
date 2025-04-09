import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gittowork/widgets/app_bar_logo_back.dart';
import 'package:gittowork/screens/company_recommendation/detail/stat_card.dart';
import 'package:gittowork/screens/company_recommendation/detail/job_card.dart';
import 'package:gittowork/screens/company_recommendation/detail/other_info.dart';
import 'package:gittowork/screens/company_recommendation/detail/choose_bar.dart';
import 'package:provider/provider.dart';
import 'package:gittowork/providers/company_detail_provider.dart';
import 'package:gittowork/providers/company_provider.dart';
import 'package:gittowork/services/company_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanyDetailScreen extends StatefulWidget {
  const CompanyDetailScreen({super.key});

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  bool isSaved = false;
  /// 이 화면에서 "최근 본 기업" SharedPreferences 저장을
  /// 중복으로 하지 않기 위해, 한 번만 처리하도록 관리
  bool _savedToRecent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /// Provider에서 companyDetail['result']를 가져와서 Null이 아닌 시점에만 한 번 저장
    if (!_savedToRecent) {
      final provider = Provider.of<CompanyDetailProvider>(context);
      final company = provider.companyDetail?['result'];
      if (company != null) {
        _saveToRecentCompanies(company);
        _savedToRecent = true; // 중복 방지
      }
    }
  }

  /// "최근 본 기업" SharedPreferences에 현재 회사 정보를 저장
  Future<void> _saveToRecentCompanies(Map<String, dynamic> company) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> recentList = prefs.getStringList('recent_companies') ?? [];

      // 기존에 companyId가 같다면 제거
      final companyId = company['company_id'];
      recentList.removeWhere((item) => item.contains('"companyId":$companyId,'));

      // JSON 변환 시, 기존과 동일한 구조를 유지해 주시면 좋습니다.
      final jsonString = jsonEncode({
        "companyId": company['company_id'],
        "companyName": company['company_name'],
        "description": company['field_name'] ?? "",
        "scrapped": company['scraped'] ?? false,
        "hasActiveJobNotice": company['has_job_notice'] ?? false,
        "techStacks": company['techStacks'] ?? [],
      });

      // 맨 앞으로 삽입
      recentList.insert(0, jsonString);

      // 최대 20개까지 관리 (필요 시)
      if (recentList.length > 20) {
        recentList.removeRange(20, recentList.length);
      }

      await prefs.setStringList('recent_companies', recentList);
    } catch (e) {
      debugPrint("❌ 최근 본 기업 저장 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompanyDetailProvider>(
      builder: (context, provider, child) {
        final company = provider.companyDetail?['result'];
        if (company == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: const CustomBackAppBar(),
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCompanyInfo(company),
                const SizedBox(height: 30),
                const StatCardSection(),
                const SizedBox(height: 30),
                const JobCardSection(),
                const SizedBox(height: 20),
                const WelfareSection(),
              ],
            ),
          ),
          bottomNavigationBar: ChooseView(
            companyId: company['company_id'],
            initialLiked: company['liked'] ?? false,
            initialBlacklisted: company['blacklisted'] ?? false,
          ),
        );

      },
    );
  }


  Widget _buildCompanyInfo(Map<String, dynamic> company) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          (company["logo"] != null &&
              company["logo"].toString().isNotEmpty &&
              !company["logo"].toString().contains("로고없음"))
              ? Image.network(
            company["logo"],
            width: 75,
            height: 60,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/No_Image.png',
                width: 75,
                height: 60,
                fit: BoxFit.contain,
              );
            },
          )
              : Image.asset(
            'assets/images/No_Image.png',
            width: 75,
            height: 60,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company["company_name"] ?? '',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  company["field_name"] ?? '',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
          // 스크랩 버튼 그대로 유지
          GestureDetector(
            onTap: () async {
              final companyId = company['company_id'];
              try {
                if (company['scraped'] == true) {
                  await CompanyApi.unscrapCompany(companyId);
                  setState(() {
                    company['scraped'] = false;
                  });
                  Provider.of<CompanyProvider>(context, listen: false)
                      .updateScrapStatus(companyId, false);
                  await _updateRecentCompanyScrapState(companyId, false);
                } else {
                  await CompanyApi.scrapCompany(companyId);
                  setState(() {
                    company['scraped'] = true;
                  });
                  Provider.of<CompanyProvider>(context, listen: false)
                      .updateScrapStatus(companyId, true);
                  await _updateRecentCompanyScrapState(companyId, true);
                }
              } catch (e) {
                debugPrint('❌ 스크랩 요청 실패: $e');
              }
            },
            child: Image.asset(
              (company['scraped'] ?? false)
                  ? 'assets/icons/Saved.png'
                  : 'assets/icons/Un_Saved.png',
              width: 28,
              height: 28,
            ),
          ),
        ]

    );
  }

  /// '최근 본 기업' SharedPreferences에 있는 companyId 회사의 scrap 여부만 갱신
  Future<void> _updateRecentCompanyScrapState(int companyId, bool newScrapped) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> recentList = prefs.getStringList('recent_companies') ?? [];

    for (int i = 0; i < recentList.length; i++) {
      final jsonMap = jsonDecode(recentList[i]) as Map<String, dynamic>;
      if (jsonMap['companyId'] == companyId) {
        jsonMap['scrapped'] = newScrapped;
        recentList[i] = jsonEncode(jsonMap);
        break;
      }
    }
    await prefs.setStringList('recent_companies', recentList);
  }
}
