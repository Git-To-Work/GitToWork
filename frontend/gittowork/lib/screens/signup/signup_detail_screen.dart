import 'package:flutter/material.dart';

class SignupDetailScreen extends StatefulWidget {
  final String nickname;
  final String avatarUrl;

  const SignupDetailScreen({
    Key? key,
    required this.nickname,
    required this.avatarUrl,
  }) : super(key: key);

  @override
  State<SignupDetailScreen> createState() => _SignupDetailScreenState();
}

class _SignupDetailScreenState extends State<SignupDetailScreen> {
  // TextEditingController들을 생성합니다.
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _careerController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // 약관 동의 체크박스 상태
  bool _agreeAll = false; // 전체 동의
  bool _agreeTerm1 = false; // (필수) 약관1
  bool _agreeTerm2 = false; // (필수) 약관2 (gittowork 이용 약관)
  bool _agreeTerm3 = false; // (선택) 약관3 (개인정보 수집 및 이용)
  bool _agreeTerm4 = false; // (선택) 약관4 (추천 기업 알림)

  // 모든 필수 약관이 체크되었는지 확인
  bool get _isRequiredTermsChecked => _agreeTerm1 && _agreeTerm2;

  // 전체 동의 체크 시, 모든 약관에 체크
  void _onAgreeAllChanged(bool? value) {
    if (value == null) return;
    setState(() {
      _agreeAll = value;
      _agreeTerm1 = value;
      _agreeTerm2 = value;
      _agreeTerm3 = value;
      _agreeTerm4 = value;
    });
  }

  // 개별 체크박스 변경 시 전체동의 상태 갱신
  void _onTermChanged(bool? value, String termKey) {
    if (value == null) return;
    setState(() {
      switch (termKey) {
        case 'term1':
          _agreeTerm1 = value;
          break;
        case 'term2':
          _agreeTerm2 = value;
          break;
        case 'term3':
          _agreeTerm3 = value;
          break;
        case 'term4':
          _agreeTerm4 = value;
          break;
      }
      // 모든 항목이 체크되어 있으면 전체동의도 체크
      _agreeAll = _agreeTerm1 && _agreeTerm2 && _agreeTerm3 && _agreeTerm4;
    });
  }

  // 약관 상세보기 다이얼로그
  void _showTermDetail(String termTitle) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(termTitle),
        content: const Text('여기에 약관 상세 내용을 표시합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  // 회원가입 버튼 클릭 시 처리
  void _onSignUp() {
    if (!_isRequiredTermsChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 약관에 동의해주세요.')),
      );
      return;
    }
    // 여기서 폼 검증 로직을 수행하고, 실제 회원가입 API를 호출하는 로직을 추가하세요.
    final name = _nameController.text;
    final birth = _birthController.text;
    final career = _careerController.text;
    final phone = _phoneController.text;

    // 디버그 출력
    debugPrint('회원가입 정보: ');
    debugPrint('GitHub nickname: ${widget.nickname}');
    debugPrint('이름: $name');
    debugPrint('생년월일: $birth');
    debugPrint('경력: $career');
    debugPrint('핸드폰: $phone');
    debugPrint('약관1(필수): $_agreeTerm1');
    debugPrint('약관2(필수): $_agreeTerm2');
    debugPrint('약관3(선택): $_agreeTerm3');
    debugPrint('약관4(선택): $_agreeTerm4');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // GitHub 프로필 이미지
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(widget.avatarUrl),
            ),
            const SizedBox(height: 8),
            // GitHub ID 표시
            Text(
              widget.nickname                                                                                                                             ,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700 ),
            ),
            const SizedBox(height: 16),

            // 이름 입력
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 생년월일 입력
            TextField(
              controller: _birthController,
              decoration: const InputDecoration(
                labelText: '생년월일',
                hintText: 'YYYYMMDD',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // 경력 입력
            TextField(
              controller: _careerController,
              decoration: const InputDecoration(
                labelText: '경력 (예: 5년)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 핸드폰 번호 입력
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '핸드폰 번호',
                hintText: '010-0000-0000',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // 약관 동의 체크박스 섹션
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 전체 동의
                Row(
                  children: [
                    Checkbox(
                      value: _agreeAll,
                      onChanged: _onAgreeAllChanged,
                    ),
                    const Text('모든 약관에 동의합니다. (필수)'),
                  ],
                ),
                const Divider(),

                // 약관1 (필수)
                Row(
                  children: [
                    Checkbox(
                      value: _agreeTerm1,
                      onChanged: (value) => _onTermChanged(value, 'term1'),
                    ),
                    const Text('gittowork 이용 약관에 동의합니다. (필수)'),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showTermDetail('gittowork 이용 약관'),
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
                      value: _agreeTerm2,
                      onChanged: (value) => _onTermChanged(value, 'term2'),
                    ),
                    const Text('개인정보 수집 및 이용에 동의합니다. (필수)'),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showTermDetail('개인정보 수집 및 이용'),
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
                      value: _agreeTerm3,
                      onChanged: (value) => _onTermChanged(value, 'term3'),
                    ),
                    const Text('개인정보 제3자 제공에 동의합니다. (선택)'),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showTermDetail('개인정보 제3자 제공'),
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

                // 약관4 (선택)
                Row(
                  children: [
                    Checkbox(
                      value: _agreeTerm4,
                      onChanged: (value) => _onTermChanged(value, 'term4'),
                    ),
                    const Text('추천 기업 알림을 동의합니다. (선택)'),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showTermDetail('추천 기업 알림'),
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
            ),

            const SizedBox(height: 24),

            // 회원가입 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _onSignUp,
                child: const Text('회원가입'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
