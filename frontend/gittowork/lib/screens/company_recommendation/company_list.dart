import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gittowork/providers/company_provider.dart';
import '../../providers/company_detail_provider.dart';
import 'detail/company_detail.dart';
import 'package:gittowork/services/company_api.dart';


class CompanyList extends StatelessWidget {
  const CompanyList({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider에서 저장된 추천 기업 데이터를 가져옵니다.
    final companies = Provider.of<CompanyProvider>(context).companies;

    if (companies.isEmpty) {
      return const Center(child: Text('추천 기업 데이터가 없습니다.'));
    }

    return SizedBox(
      height: 570,
      child: ListView.builder(
        itemCount: companies.length,
        itemBuilder: (context, index) {
          final company = companies[index];
          return _buildCompanyCard(company, context, index);
        },
      ),
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> company, BuildContext context, int index) {
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
                  pageBuilder: (context, animation, secondaryAnimation) => const CompanyDetailScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0, 1);
                    const end = Offset(0, 0);
                    const curve = Curves.ease;
                    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
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
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  company["company_name"] ?? "",
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                                ),
                                if (company["has_job_notice"] && company["status"] != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: company["statusColor"] ?? Colors.blue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      company["status"] ?? "",
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                ],
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Text(
                      (company["tech_stacks"] as List<dynamic>?)?.join(", ") ?? "",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
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
