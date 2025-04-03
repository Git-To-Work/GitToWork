import 'package:flutter/material.dart';
import 'package:gittowork/screens/my_page/my_page_components/terms_service_screen.dart';
import '../../../models/user_profile.dart';
import '../company_interaction_screen.dart';
import '../my_info_edit_screen.dart';

class MyPageList extends StatelessWidget {
  final UserProfile userProfile;

  const MyPageList({
    super.key,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    // 화면에 표시할 타일들
    final tiles = [
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
      _MyPageListTile(
        title: '내가 차단한 기업',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BlockedCompanyScreen()),
          );
        },
      ),
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
    ];

    // 타일과 구분선을 교차로 삽입하기 위한 children 리스트
    final List<Widget> children = [];
    for (int i = 0; i < tiles.length; i++) {
      children.add(tiles[i]);
      // 마지막 타일이 아니라면 구분선 추가
      if (i < tiles.length - 1) {
        children.add(
          Container(
            height: 1,
            color: Colors.grey.shade300, // 원하는 구분선 색
          ),
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
      child: Container(
        // Rectangle 스타일
        padding: const EdgeInsets.all(30), // 전체 컨테이너 패딩
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFD6D6D6), // Stroke 색상
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 2), // 그림자 수직 이동
              blurRadius: 6,       // 그림자 번짐 정도
            ),
          ],
        ),
        // 메뉴(타일)들과 구분선을 표시
        child: Column(
          children: children,
        ),
      )
    );
  }
}

class _MyPageListTile extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _MyPageListTile({
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // 각 메뉴의 세로 간격
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListTile(
        contentPadding: EdgeInsets.zero, // ListTile 기본 패딩 제거
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8A8A8A),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 20,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
