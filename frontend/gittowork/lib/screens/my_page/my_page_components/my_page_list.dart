import 'package:flutter/material.dart';
import 'package:gittowork/models/interest_field.dart';
import 'package:gittowork/screens/my_page/my_page_components/terms_service_screen.dart';
import '../../../models/user_profile.dart';
import '../company_interaction_screen.dart';
import '../my_info_edit_screen.dart';
import '../my_page_screen.dart';

class MyPageList extends StatelessWidget {
  final UserProfile userProfile;
  final InterestField interestField;

  const MyPageList({
    super.key,
    required this.userProfile,
    required this.interestField,
  });

  @override
  Widget build(BuildContext context) {
    // 화면에 표시할 타일들
    final tiles = [
      _MyPageListTile(
        title: '나의 정보 관리',
        onTap: () async {
          // 1) 정보 수정 화면으로 이동, 결과(bool) 받기
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => MyInfoEditScreen(
                userProfile: userProfile,
                interestField: interestField, // 관심 분야 정보 함께 전달
              ),
            ),
          );

          // 2) 만약 true가 넘어왔다면, MyPageScreen의 loadProfileAgain() 호출
          if (result == true) {
            final parentState = context.findAncestorStateOfType<MyPageScreenState>();
            parentState?.loadProfileAgain();
          }
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
            color: Colors.grey.shade300,
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
              offset: Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(children: children),
      ),
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
        contentPadding: EdgeInsets.zero,
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
