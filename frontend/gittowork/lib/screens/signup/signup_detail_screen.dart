import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bottom_picker/bottom_picker.dart';
import 'package:flutter/services.dart';
import '../../widgets/build_ios_like_row.dart';
import 'business_interest_screen.dart';

class SignupDetailScreen extends StatefulWidget {
  final String nickname;
  final String avatarUrl;

  const SignupDetailScreen({
    super.key,
    required this.nickname,
    required this.avatarUrl,
  });

  @override
  State<SignupDetailScreen> createState() => _SignupDetailScreenState();
}
// 핸드폰 번호 입력시 자동 '-' 삽입을 위한 커스텀 텍스트 포맷터
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue,
      TextEditingValue newValue) {
    // 숫자만 추출
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = '';
    if (digits.length <= 3) {
      formatted = digits;
    } else if (digits.length <= 7) {
      formatted = digits.substring(0, 3) + '-' + digits.substring(3);
    } else {
      formatted = digits.substring(0, 3) +
          '-' +
          digits.substring(3, 7) +
          '-' +
          digits.substring(7, digits.length > 11 ? 11 : digits.length);
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
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
  bool _agreeTerm3 = false; // (선택) 약관4 (추천 기업 알림)

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
      }
      // 모든 항목이 체크되어 있으면 전체동의도 체크
      _agreeAll = _agreeTerm1 && _agreeTerm2 && _agreeTerm3;
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

    // 백엔드 전송 파라미터 생성 (백엔드 미구현 상태이므로 실제 전송 코드는 주석 처리)
    final signupParams = {
      'name': name,
      'birthDt': birth, // 0000-00-00 형식
      'phone': phone,   // 010-0000-0000 형식
      'experience': career,
      // 'interestsFields': null, // business_interest_screen.dart에서 최대 5개 선택 처리 예정
      'privacyPolicyAgreed': _agreeTerm1 && _agreeTerm2, // required: 개인정보 수집 및 이용에 동의 여부
      'notificationAgreed': _agreeTerm3,                 // 선택: 추천 기업 알림 동의 여부
    };

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

    // TODO: 백엔드 API 호출 - 입력받은 회원 정보와 개인정보 동의 정보를 전송 (미구현 상태)
    // 예: ApiService.sendSignupData(signupParams);

    // business_interest_screen.dart 로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusinessInterestScreen(
          signupParams: signupParams,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(30.0, 50.0, 30.0, 0.0),
        child: Stack(

          children: [
            // 로고 이미지
            Positioned(
              top: 50,
              left: 0,
              child: Image.asset(
                'assets/images/github_logo.png', // 이미지 경로
                width: 100,
              ),
            ),
            Column(
              children: [
                // 상단 '회원가입' 텍스트
                const Center(
                  child: Text(
                    '회원가입',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                CircleAvatar(
                  radius: 85,
                  backgroundImage: NetworkImage(widget.avatarUrl),
                ),
                const SizedBox(height: 8),
                // GitHub ID 표시
                Text(
                  widget.nickname                                                                                                                             ,
                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w500 ),
                ),
                const SizedBox(height: 10),

                // 이름 입력
                buildIosLikeRow(
                  controller: _nameController,
                  label: '이름',
                  hintText: '홍길동',
                ),

                GestureDetector(
                  onTap: () {
                    BottomPicker.date(
                      pickerTitle: const Text(
                        '생년월일',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      dateOrder: DatePickerDateOrder.ymd,
                      initialDateTime: DateTime(1996, 10, 22),
                      maxDateTime: DateTime(2010),
                      minDateTime: DateTime(1960),
                      pickerTextStyle: const TextStyle(
                        color: Color(0xFF2C2C2C),
                        fontWeight: FontWeight.w500,
                        fontSize: 25,
                      ),
                      onChange: (selectedDate) {
                        print(selectedDate);
                      },
                      onSubmit: (selectedDate) {
                        print(selectedDate);
                        setState(() {
                          _birthController.text =
                          selectedDate.toString().split(' ')[0];
                        });
                      },
                      dismissable: true,
                      displayCloseIcon: false,
                      // 버튼 콘텐츠를 중앙 정렬하고 흰색 텍스트 적용
                      buttonContent: const Center(
                        child: Text(
                          "선택",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      buttonSingleColor: const Color(0xFF2C2C2C),
                      // buttonStyle을 따로 지정할 수 있으나 기본값으로 두어도 무방합니다.
                      buttonStyle: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ).show(context);
                  },
                  child: AbsorbPointer(
                    child: buildIosLikeRow(
                      controller: _birthController,
                      label: '생년월일',
                      hintText: 'YYYYMMDD',
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    // 0년부터 9년까지 생성 후 마지막에 "10년 이상" 추가
                    final careerItems = List<Widget>.generate(
                      10,
                          (index) => Center(child: Text('$index년')),
                    )..add(const Center(child: Text('10년 이상')));

                    BottomPicker(
                      items: careerItems,
                      pickerTitle: const Text(
                        "경력 선택",
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                      ),
                      titleAlignment: Alignment.center,
                      pickerTextStyle: const TextStyle(
                        color: Color(0xFF2C2C2C),
                        fontWeight: FontWeight.w500,
                        fontSize: 25,
                      ),
                      onSubmit: (selectedIndex) {
                        setState(() {
                          _careerController.text = careerItems[selectedIndex] is Center
                              ? (careerItems[selectedIndex] as Center)
                              .child
                              .toString() // 간단한 문자열 변환 (실제라면 데이터를 따로 관리)
                              : "";
                          // 또는 직접 인덱스 값을 사용하여 텍스트 지정:
                          _careerController.text = selectedIndex < 10
                              ? '$selectedIndex년'
                              : '10년 이상';
                        });
                      },
                      dismissable: true,
                      displayCloseIcon: false,
                      // 버튼 콘텐츠 중앙 정렬 및 흰색 텍스트 적용
                      buttonContent: const Center(
                        child: Text(
                          "선택",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      buttonSingleColor: const Color(0xFF2C2C2C),
                      buttonStyle: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ).show(context);
                  },
                  child: AbsorbPointer(
                    child: buildIosLikeRow(
                      controller: _careerController,
                      label: '경력 (년)',
                      hintText: '0년',
                    ),
                  ),
                ),

                // 핸드폰 번호 입력
                buildIosLikeRow(
                  controller: _phoneController,
                  label: '핸드폰',
                  hintText: '010-0000-0000',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneNumberFormatter()],
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
                          checkColor: const Color(0xFFFFFFFF),
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
                          value: _agreeTerm1,
                          checkColor: const Color(0xFFFFFFFF),
                          activeColor: const Color(0xFF2C2C2C),
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
                          checkColor: const Color(0xFFFFFFFF),
                          activeColor: const Color(0xFF2C2C2C),
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
                          checkColor: const Color(0xFFFFFFFF),
                          activeColor: const Color(0xFF2C2C2C),
                          onChanged: (value) => _onTermChanged(value, 'term3'),
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

                const SizedBox(height: 20),

                // 회원가입 버튼
                SizedBox(
                  width: double.infinity,
                  height: 70,
                  child: Container(
                    color: const Color(0xFF2C2C2C),
                    child: Center(
                      child: GestureDetector(
                        onTap: _onSignUp,
                        child: const Text('회원가입',
                          style: TextStyle(
                            color: Color(0xFFD6D6D6),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 50,
                ),
              ],
            )
            // GitHub 프로필 이미지

          ],
        ),
      ),
    );
  }

}
