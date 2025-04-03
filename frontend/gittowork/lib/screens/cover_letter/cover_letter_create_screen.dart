import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gittowork/providers/auth_provider.dart';
import 'components/user_profile_card.dart';
import 'components/cover_letter_upload_form.dart';
import 'package:gittowork/widgets/app_bar.dart';

class CoverLetterCreateScreen extends StatefulWidget {
  const CoverLetterCreateScreen({super.key});

  @override
  State<CoverLetterCreateScreen> createState() => _CoverLetterCreateScreenState();
}

class _CoverLetterCreateScreenState extends State<CoverLetterCreateScreen> {
  // CoverLetterUploadForm을 조작하기 위한 GlobalKey
  final GlobalKey<CoverLetterUploadFormState> _formKey =
  GlobalKey<CoverLetterUploadFormState>();

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<AuthProvider>(context).userProfile;

    return Scaffold(
      appBar: CustomAppBar(),
      body: userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 카드
            UserProfileCard(userProfile: userProfile),
            const SizedBox(height: 40),
            // 자기소개서 업로드 폼 (버튼 없이)
            CoverLetterUploadForm(key: _formKey),
          ],
        ),
      ),

      // 하단에 고정된 작성완료 버튼
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(30, 0, 30, 60), // 왼/오른쪽 패딩 + 아래 30px 여백
        child: SizedBox(
          height: 60,
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C2C2C),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: () {
              _formKey.currentState?.submitCoverLetter();
            },
            child: const Text(
              '작성완료',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
