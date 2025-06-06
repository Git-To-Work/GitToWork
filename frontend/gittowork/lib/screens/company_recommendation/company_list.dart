import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gittowork/providers/company_provider.dart';
import 'package:gittowork/providers/company_detail_provider.dart';
import 'detail/company_detail.dart';
import 'package:gittowork/services/company_api.dart';

class CompanyList extends StatefulWidget {
  const CompanyList({super.key});

  @override
  State<CompanyList> createState() => _CompanyListState();
}

class _CompanyListState extends State<CompanyList> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();

    _fetchCompanies(reset: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100 &&
          !_isLoading &&
          _hasMore) {
        _currentPage++;
        _fetchCompanies();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchCompanies({bool reset = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<CompanyProvider>(context, listen: false)
          .loadCompaniesFromApi(
        context: context,
        page: _currentPage.toString(),
        size: _pageSize.toString(),
        reset: reset,
      );

      final fetchedCount = Provider.of<CompanyProvider>(context, listen: false).companies.length;
      if (fetchedCount < _currentPage * _pageSize) {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint("API Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CompanyProvider>(context);
    final companies = provider.companies;
    final isAnalyzing = provider.analyzing;

    if (companies.isEmpty && !_isLoading) {
      return Center(
        child: Text(
          isAnalyzing ? '해당 Repo는 아직 분석중입니다.' : '추천 기업 데이터가 없습니다.',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // ✅ 정상 리스트 렌더링
    return SizedBox(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: companies.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == companies.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final company = companies[index];
          return _buildCompanyCard(company, context, index);
        },
      ),
    );
  }


  Widget _buildCompanyCard(
      Map<String, dynamic> company, BuildContext context, int index) {
    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTap: () {
            final companyId = company["company_id"] as int;
            Provider.of<CompanyDetailProvider>(context, listen: false)
                .loadCompanyDetailFromApi(companyId: companyId)
                .then((_) {
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
              );
            }).catchError((error) {
              debugPrint("회사 상세 API 호출 실패: $error");
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 1),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 75,
                          height: 60,
                          color: Colors.white,
                          child: (company["logo"] != null &&
                              !company["logo"].toString().contains("로고없음"))
                              ? Image.network(
                            company["logo"],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/No_Image.png',
                                fit: BoxFit.contain,
                              );
                            },
                          )
                              : Image.asset(
                            'assets/images/No_Image.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          company["company_name"] ?? "",
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      if (company["hasJobNotice"] ?? false)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 6),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: company["statusColor"] ?? Colors.blue,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              '채용중',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final companyId = company['company_id'] as int;
                                    try {
                                      if (company['scraped'] == true) {
                                        await CompanyApi.unscrapCompany(companyId);
                                      } else {
                                        await CompanyApi.scrapCompany(companyId);
                                      }
                                      setState(() {
                                        company['scraped'] = !(company['scraped'] ?? false);
                                      });
                                    } catch (e) {
                                      debugPrint("❌ 스크랩 토글 실패: $e");
                                    }
                                  },
                                  child: Image.asset(
                                    (company['scraped'] ?? false)
                                        ? 'assets/icons/Saved.png'
                                        : 'assets/icons/Un_Saved.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              company["field_name"] ?? "",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Text(
                      (company["tech_stacks"] as List<dynamic>?)?.join(", ") ??
                          "",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
