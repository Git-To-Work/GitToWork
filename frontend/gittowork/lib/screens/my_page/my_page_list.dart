import 'package:flutter/material.dart';
import 'package:gittowork/screens/my_page/terms_service_screen.dart';
import '../../../models/user_profile.dart';
import 'my_info_edit_screen.dart';

class MyPageList extends StatelessWidget {
  final UserProfile userProfile;

  const MyPageList({
    super.key,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1) 나의 정보 관리
        _MyPageListTile(
          title: '나의 정보 관리',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MyInfoEditScreen(userProfile: userProfile),
              ),
            );
          },
        ),
        // 2) 내가 차단한 기업
        _MyPageListTile(
          title: '내가 차단한 기업',
          onTap: () {
            // TODO: 이동 or 액션
          },
        ),
        // 3) 서비스 이용 약관
        _MyPageListTile(
          title: '서비스 이용 약관',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TermsServiceScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MyPageListTile extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _MyPageListTile({
    super.key,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: ListTile(
        title: Text(title),
        onTap: onTap,
      ),
    );
  }
}
