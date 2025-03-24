import 'package:flutter/material.dart';
import 'package:gittowork/providers/company_data.dart'; // 🔹 데이터 가져오기

class CompanyList extends StatelessWidget {
  const CompanyList({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: CompanyData.companies.length, // 🔹 데이터 가져오기
        itemBuilder: (context, index) {
          final company = CompanyData.companies[index];
          return _buildCompanyCard(company);
        },
      ),
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> company) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
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
                      company["logo"],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 회사 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            company["name"],
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                          ),
                          if (company.containsKey("status")) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: company["statusColor"],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                company["status"],
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company["position"],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.bookmark_border, size: 24, color: Colors.black54),
              ],
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Text(
                company["skills"].join(", "),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }


}
