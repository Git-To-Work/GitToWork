import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gittowork/models/company.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/company_api.dart';

class CompanyListView extends StatefulWidget {
  final List<Company> companies;

  final Function(Company)? onCompanyTap;

  const CompanyListView({
    super.key,
    required this.companies,
    this.onCompanyTap,
  });

  @override
  State<CompanyListView> createState() => _CompanyListViewState();
}

class _CompanyListViewState extends State<CompanyListView> {
  @override
  Widget build(BuildContext context) {
    // 데이터가 없으면 간단 메시지
    if (widget.companies.isEmpty) {
      return const Center(child: Text('기업 정보가 없습니다.'));
    }

    return ListView.builder(
      itemCount: widget.companies.length,
      itemBuilder: (context, index) {
        final company = widget.companies[index];
        return _buildCompanyCard(company);
      },
    );
  }

  Widget _buildCompanyCard(Company company) {
    return GestureDetector(
      onTap: () {
        if (widget.onCompanyTap != null) {
          widget.onCompanyTap!(company);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(64, 0, 0, 0),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildCompanyCardContents(company),
        ),
      ),
    );
  }

  Widget _buildCompanyCardContents(Company company) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단: 로고 + 기업명 + 스크랩 아이콘
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 로고 (임시 예시로 asset 사용)
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Container(
                width: 75,
                height: 60,
                color: Colors.white,
                child: Image.asset(
                  'assets/images/samsung.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 기업명 + 채용중 뱃지 + 스크랩 아이콘
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          company.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (company.hasActiveJobNotice)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '채용중',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _toggleScrap(company),
                        child: Image.asset(
                          company.scrapped
                              ? 'assets/icons/Saved.png'
                              : 'assets/icons/Un_Saved.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ],
                  ),

                  // 분야 혹은 부가설명
                  const SizedBox(height: 4),
                  Text(
                    company.description,
                    style: const TextStyle(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 하단: 기술 스택
        Text(
          company.techStacks.join(", "),
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  /// 스크랩/언스크랩 처리 함수
  Future<void> _toggleScrap(Company company) async {
    try {
      if (company.scrapped) {
        // 이미 스크랩 상태면 → 언스크랩
        await CompanyApi.unscrapCompany(company.companyId);
        setState(() => company.scrapped = false);
        setState(() {
          widget.companies.removeWhere((c) => c.companyId == company.companyId);
        });

        // SharedPreferences “recent_companies” 목록에서도 해당 회사ID scrapped=false로 변경
        await _updateRecentCompanyScrapState(company.companyId, false);
      } else {
        // 스크랩
        await CompanyApi.scrapCompany(company.companyId);
        setState(() => company.scrapped = true);

        await _updateRecentCompanyScrapState(company.companyId, true);
      }
    } catch (e) {
      debugPrint("❌ 스크랩 토글 실패: $e");
    }
  }

  /// SharedPreferences에 저장된 '최근 본 기업' 데이터 중,
  /// 해당 `companyId`의 `scrapped` 필드를 `newScrapped`로 갱신
  Future<void> _updateRecentCompanyScrapState(int companyId, bool newScrapped) async {
    final prefs = await SharedPreferences.getInstance();
    final recentList = prefs.getStringList('recent_companies') ?? [];

    for (int i = 0; i < recentList.length; i++) {
      final jsonMap = jsonDecode(recentList[i]) as Map<String, dynamic>;

      // Company.fromJson 구조에 맞춰서 companyId나 키 이름 확인
      if (jsonMap['companyId'] == companyId) {
        jsonMap['scrapped'] = newScrapped;
        recentList[i] = jsonEncode(jsonMap);
        break;
      }
    }

    await prefs.setStringList('recent_companies', recentList);
  }
}
