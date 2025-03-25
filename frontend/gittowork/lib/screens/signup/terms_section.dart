import 'package:flutter/material.dart';

class TermsSection extends StatelessWidget {
  final bool agreeAll;
  final bool agreeTerm1;
  final bool agreeTerm2;
  final bool agreeTerm3;
  final ValueChanged<bool?> onAgreeAllChanged;
  final Function(bool?, String) onTermChanged;
  final VoidCallback onShowTermDetailTerm1;
  final VoidCallback onShowTermDetailTerm2;
  final VoidCallback onShowTermDetailTerm3;

  const TermsSection({
    super.key,
    required this.agreeAll,
    required this.agreeTerm1,
    required this.agreeTerm2,
    required this.agreeTerm3,
    required this.onAgreeAllChanged,
    required this.onTermChanged,
    required this.onShowTermDetailTerm1,
    required this.onShowTermDetailTerm2,
    required this.onShowTermDetailTerm3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 전체 동의
        Row(
          children: [
            Checkbox(
              value: agreeAll,
              onChanged: onAgreeAllChanged,
              checkColor: Colors.white,
              activeColor: const Color(0xFF2C2C2C),
            ),
            const Text('모든 약관에 동의합니다. (필수)'),
          ],
        ),
        const Divider(),
        // 약관1 (필수)
        Row(
          children: [
            Checkbox(
              value: agreeTerm1,
              onChanged: (value) => onTermChanged(value, 'term1'),
              checkColor: Colors.white,
              activeColor: const Color(0xFF2C2C2C),
            ),
            const Text('gittowork 이용 약관에 동의합니다. (필수)'),
            const Spacer(),
            GestureDetector(
              onTap: onShowTermDetailTerm1,
              child: const Text(
                '상세보기',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        // 약관2 (필수)
        Row(
          children: [
            Checkbox(
              value: agreeTerm2,
              onChanged: (value) => onTermChanged(value, 'term2'),
              checkColor: Colors.white,
              activeColor: const Color(0xFF2C2C2C),
            ),
            const Text('개인정보 수집 및 이용에 동의합니다. (필수)'),
            const Spacer(),
            GestureDetector(
              onTap: onShowTermDetailTerm2,
              child: const Text(
                '상세보기',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        // 약관3 (선택)
        Row(
          children: [
            Checkbox(
              value: agreeTerm3,
              onChanged: (value) => onTermChanged(value, 'term3'),
              checkColor: Colors.white,
              activeColor: const Color(0xFF2C2C2C),
            ),
            const Text('추천 기업 알림을 동의합니다. (선택)'),
            const Spacer(),
            GestureDetector(
              onTap: onShowTermDetailTerm3,
              child: const Text(
                '상세보기',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
