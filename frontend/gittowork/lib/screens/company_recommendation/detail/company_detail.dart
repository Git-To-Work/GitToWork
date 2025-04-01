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

class CompanyDetailScreen extends StatefulWidget {
  const CompanyDetailScreen({super.key});

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  bool isSaved = false;

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
        Image.asset(
          // 'assets/images/${company["logo"] ?? "default_logo.png"}',
          'assets/images/samsung.png',
          width: 60,
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
                    .updateScrapStatus(companyId, false); // ✅ Provider 업데이트
              } else {
                await CompanyApi.scrapCompany(companyId);
                setState(() {
                  company['scraped'] = true;
                });
                Provider.of<CompanyProvider>(context, listen: false)
                    .updateScrapStatus(companyId, true); // ✅ Provider 업데이트
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


      ],
    );
  }

}
