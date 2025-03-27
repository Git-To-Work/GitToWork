import 'package:flutter/material.dart';

class TermsSection extends StatefulWidget {
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
  _TermsSectionState createState() => _TermsSectionState();
}

class _TermsSectionState extends State<TermsSection> {
  bool showDetailTerm1 = false;
  bool showDetailTerm2 = false;
  bool showDetailTerm3 = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 전체 동의
        Row(
          children: [
            Checkbox(
              value: widget.agreeAll,
              onChanged: widget.onAgreeAllChanged,
              checkColor: Colors.white,
              activeColor: const Color(0xFF2C2C2C),
            ),
            const Text('모든 약관에 동의합니다. (필수)'),
          ],
        ),
        const Divider(),
        // 약관1 (필수)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: widget.agreeTerm1,
                  onChanged: (value) => widget.onTermChanged(value, 'term1'),
                  checkColor: Colors.white,
                  activeColor: const Color(0xFF2C2C2C),
                ),
                const Text('gittowork 이용 약관에 동의합니다. (필수)'),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showDetailTerm1 = !showDetailTerm1;
                    });
                    widget.onShowTermDetailTerm1();
                  },
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
            if (showDetailTerm1)
              const Padding(
                padding: EdgeInsets.only(left: 32.0, top: 4.0),
                child: Text(
                  'gittowork 이용 약관에 동의하셨습니다.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8.0),
        // 약관2 (필수)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: widget.agreeTerm2,
                  onChanged: (value) => widget.onTermChanged(value, 'term2'),
                  checkColor: Colors.white,
                  activeColor: const Color(0xFF2C2C2C),
                ),
                const Text('개인정보 수집 및 이용에 동의합니다. (필수)'),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showDetailTerm2 = !showDetailTerm2;
                    });
                    widget.onShowTermDetailTerm2();
                  },
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
            if (showDetailTerm2)
              const Padding(
                padding: EdgeInsets.only(left: 32.0, top: 4.0),
                child: Text(
                  '개인정보 수집 및 이용에 동의하셨습니다.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8.0),
        // 약관3 (선택)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: widget.agreeTerm3,
                  onChanged: (value) => widget.onTermChanged(value, 'term3'),
                  checkColor: Colors.white,
                  activeColor: const Color(0xFF2C2C2C),
                ),
                const Text('추천 기업 알림을 동의합니다. (선택)'),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showDetailTerm3 = !showDetailTerm3;
                    });
                    widget.onShowTermDetailTerm3();
                  },
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
            if (showDetailTerm3)
              const Padding(
                padding: EdgeInsets.only(left: 32.0, top: 4.0),
                child: Text(
                  '추천 기업 알림 동의가 선택되었습니다.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
