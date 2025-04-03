// company_interaction_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gittowork/widgets/app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/company.dart';
import '../../services/user_api.dart'; // Company 모델 경로

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // 상단: 뒤로가기 버튼과 헤더 텍스트
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
            // 본문: 데이터 로딩, 에러, 빈 데이터 및 리스트 표시
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
                          Text(widget.emptyMessage,
                              style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    );
                  } else {
                    final companies = snapshot.data!;
                    return ListView.builder(
                      itemCount: companies.length,
                      itemBuilder: (context, index) {
                        final company = companies[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(company.name),
                            subtitle: Text(company.description),
                            onTap: () {
                              // 기업 상세 페이지 이동 및 최근 조회한 기업 목록 갱신 로직 추가 가능
                            },
                          ),
                        );
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

// 개별 화면

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
