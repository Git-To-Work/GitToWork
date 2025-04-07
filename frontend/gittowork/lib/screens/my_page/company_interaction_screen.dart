// company_interaction_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gittowork/widgets/app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../../models/company.dart';
import '../../providers/company_detail_provider.dart'; // detail 로드할 때 필요
import '../../services/user_api.dart';
import '../company_recommendation/detail/company_detail.dart';
import 'company_list_view.dart';

class CompanyInteractionScreen extends StatefulWidget {
  final String headerText;
  final Future<List<Company>> Function() fetchCompanies;
  final String emptyMessage;

  const CompanyInteractionScreen({
    super.key,
    required this.headerText,
    required this.fetchCompanies,
    required this.emptyMessage,
  });

  @override
  _CompanyInteractionScreenState createState() => _CompanyInteractionScreenState();
}

class _CompanyInteractionScreenState extends State<CompanyInteractionScreen> {
  late Future<List<Company>> _futureCompanies;

  @override
  void initState() {
    super.initState();
    _futureCompanies = widget.fetchCompanies();
  }

  /// 뒤로갔다가 돌아오면 데이터 새로고침
  /// 상세 페이지에서 Pop된 뒤에 호출하기 위함
  void _refreshCompanies() {
    setState(() {
      _futureCompanies = widget.fetchCompanies();
    });
  }

  /// 상세 페이지로 이동하는 메서드
  void _navigateToCompanyDetail(Company company) {
    // 1. 회사 상세 정보 불러오기
    Provider.of<CompanyDetailProvider>(context, listen: false)
        .loadCompanyDetailFromApi(companyId: company.companyId)
        .then((_) {
      // 2. Navigation으로 상세 페이지 이동 + SlideTransition 애니메이션
      Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) =>
          const CompanyDetailScreen(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            const begin = Offset(0, 1);
            const end = Offset(0, 0);
            const curve = Curves.ease;
            final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ).then((value) {
        // 3. 상세 페이지에서 Pop (뒤로가기) 되면 새로고침
        _refreshCompanies();
      });
    }).catchError((error) {
      debugPrint("회사 상세 API 호출 실패: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.headerText,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // 본문
            Expanded(
              child: FutureBuilder<List<Company>>(
                future: _futureCompanies,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('데이터를 불러오는데 실패했습니다.'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.remove_red_eye, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            widget.emptyMessage,
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  } else {
                    final companies = snapshot.data!;
                    return CompanyListView(
                      companies: companies,
                      onCompanyTap: (company) async {
                        // (선택) 회사 탭 시, '최근 본 기업' 목록에 저장하는 로직 예시
                        final prefs = await SharedPreferences.getInstance();
                        final List<String> recentList =
                            prefs.getStringList('recent_companies') ?? [];

                        // 이미 있는 회사 제거 → 맨 앞에 삽입
                        recentList.removeWhere(
                              (item) => item.contains('"companyId":${company.companyId},'),
                        );

                        final jsonString = jsonEncode({
                          "companyId": company.companyId,
                          "companyName": company.name,
                          "description": company.description,
                          "techStacks": company.techStacks,
                          "scrapped": company.scrapped,
                          "hasActiveJobNotice": company.hasActiveJobNotice,
                        });
                        recentList.insert(0, jsonString);

                        // 최대 20개까지만 관리 예시
                        if (recentList.length > 20) {
                          recentList.removeRange(20, recentList.length);
                        }
                        await prefs.setStringList('recent_companies', recentList);

                        // 회사 상세 페이지로 이동 (Pop 후 _refreshCompanies 실행)
                        _navigateToCompanyDetail(company);
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// 이하 동일(스크랩/좋아요/차단/최근본)

// 스크랩 기업 화면
class ScrapCompanyScreen extends StatelessWidget {
  const ScrapCompanyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CompanyInteractionScreen(
      headerText: "스크랩",
      fetchCompanies: UserApi.fetchScrapCompanies,
      emptyMessage: "스크랩 한 기업이 없습니다",
    );
  }
}

// 좋아요 기업 화면
class LikedCompanyScreen extends StatelessWidget {
  const LikedCompanyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CompanyInteractionScreen(
      headerText: "좋아요",
      fetchCompanies: UserApi.fetchLikedCompanies,
      emptyMessage: "좋아요 한 기업이 없습니다",
    );
  }
}

// 최근 조회한 기업 화면 (SharedPreferences 이용)
class RecentCompanyScreen extends StatelessWidget {
  const RecentCompanyScreen({super.key});

  Future<List<Company>> _fetchRecentCompanies() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? companyStrings = prefs.getStringList("recent_companies");
    if (companyStrings == null) return [];

    // 저장된 JSON을 Company로 복원
    return companyStrings.map((str) {
      final json = jsonDecode(str);
      return Company.fromJson(json);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CompanyInteractionScreen(
      headerText: "최근 조회한 기업",
      fetchCompanies: _fetchRecentCompanies,
      emptyMessage: "최근 조회한 기업이 없습니다",
    );
  }
}

// 차단한 기업 화면
class BlockedCompanyScreen extends StatelessWidget {
  const BlockedCompanyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CompanyInteractionScreen(
      headerText: "차단한 기업",
      fetchCompanies: UserApi.fetchBlockedCompanies,
      emptyMessage: "차단한 기업이 없습니다",
    );
  }
}
