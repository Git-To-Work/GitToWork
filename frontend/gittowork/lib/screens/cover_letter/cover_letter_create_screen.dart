import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gittowork/providers/auth_provider.dart';
import 'components/user_profile_card.dart';
import 'components/cover_letter_upload_form.dart';
import 'package:gittowork/widgets/app_bar.dart';

class CoverLetterCreateScreen extends StatelessWidget {
  const CoverLetterCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<AuthProvider>(context).userProfile;

    return Scaffold(
      appBar: CustomAppBar(),
      body: userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserProfileCard(userProfile: userProfile),
            const SizedBox(height: 40),
            const CoverLetterUploadForm(),
          ],
        ),
      ),
    );
  }
}
