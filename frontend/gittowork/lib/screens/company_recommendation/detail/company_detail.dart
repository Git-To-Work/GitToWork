import 'package:flutter/material.dart';
import 'package:gittowork/widgets/app_bar_logo_back.dart';
import 'package:gittowork/screens/company_recommendation/detail/stat_card.dart';
import 'package:gittowork/screens/company_recommendation/detail/job_card.dart';
import 'package:gittowork/screens/company_recommendation/detail/other_info.dart';
import 'package:gittowork/screens/company_recommendation/detail/choose_bar.dart';

class CompanyDetailScreen extends StatefulWidget {
  const CompanyDetailScreen({super.key});

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  bool isSaved = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomBackAppBar(),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompanyInfo(),
            const SizedBox(height: 30),
            const StatCardSection(),
            const SizedBox(height: 30),
            const JobCardSection(),
            const SizedBox(height: 20),
            const WelfareSection(),
          ],
        ),
      ),
      bottomNavigationBar: const ChooseView(),
    );
  }

  Widget _buildCompanyInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/samsung.png',
          width: 60,
          height: 60,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '티엔에이치',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                '제조·기술·서비스',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              isSaved = !isSaved;
            });
          },
          child: Image.asset(
            isSaved ? 'assets/icons/Saved.png' : 'assets/icons/Un_Saved.png',
            width: 28,
            height: 28,
          ),
        ),
      ],
    );
  }
}
