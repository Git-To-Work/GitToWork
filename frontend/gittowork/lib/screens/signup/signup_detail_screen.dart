import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bottom_picker/bottom_picker.dart';
import 'terms_section.dart';
import 'personal_info_section.dart';
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

class _SignupDetailScreenState extends State<SignupDetailScreen> {
  // 컨트롤러 선언
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _careerController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // 약관 동의 상태
  bool _agreeAll = false;
  bool _agreeTerm1 = false;
  bool _agreeTerm2 = false;
  bool _agreeTerm3 = false;

  bool get _isRequiredTermsChecked => _agreeTerm1 && _agreeTerm2;

  void _onAgreeAllChanged(bool? value) {
    if (value == null) return;
    setState(() {
      _agreeAll = value;
      _agreeTerm1 = value;
      _agreeTerm2 = value;
      _agreeTerm3 = value;
    });
  }

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
      _agreeAll = _agreeTerm1 && _agreeTerm2 && _agreeTerm3;
    });
  }

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

  // 생년월일 선택 다이얼로그
  void _pickBirthDate() {
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
      onSubmit: (selectedDate) {
        setState(() {
          _birthController.text = selectedDate.toString().split(' ')[0];
        });
      },
      dismissable: true,
      displayCloseIcon: false,
      buttonContent: const Center(
        child: Text("선택", style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      buttonSingleColor: const Color(0xFF2C2C2C),
      buttonStyle: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
    ).show(context);
  }

  // 경력 선택 다이얼로그
  void _pickCareer() {
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
          _careerController.text = selectedIndex < 10 ? '$selectedIndex년' : '10년 이상';
        });
      },
      dismissable: true,
      displayCloseIcon: false,
      buttonContent: const Center(
        child: Text("선택", style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      buttonSingleColor: const Color(0xFF2C2C2C),
      buttonStyle: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
    ).show(context);
  }

  void _onSignUp() {
    if (!_isRequiredTermsChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 약관에 동의해주세요.')),
      );
      return;
    }
    final signupParams = {
      'name': _nameController.text,
      'birthDt': _birthController.text,
      'phone': _phoneController.text,
      'experience': int.tryParse(_careerController.text.replaceAll(RegExp(r'\D'), '')) ?? 0,
      'privacyPolicyAgreed': _agreeTerm1 && _agreeTerm2,
      'notificationAgreed': _agreeTerm3,
    };

    // business_interest_screen.dart로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusinessInterestScreen(signupParams: signupParams),
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
                'assets/images/github_logo.png',
                width: 100,
              ),
            ),
            Column(
              children: [
                const Center(
                  child: Text(
                    '회원가입',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                CircleAvatar(
                  radius: 85,
                  backgroundImage: NetworkImage(widget.avatarUrl),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.nickname,
                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                PersonalInfoSection(
                  nameController: _nameController,
                  birthController: _birthController,
                  careerController: _careerController,
                  phoneController: _phoneController,
                  onBirthPicker: _pickBirthDate,
                  onCareerPicker: _pickCareer,
                ),
                const SizedBox(height: 24),
                TermsSection(
                  agreeAll: _agreeAll,
                  agreeTerm1: _agreeTerm1,
                  agreeTerm2: _agreeTerm2,
                  agreeTerm3: _agreeTerm3,
                  onAgreeAllChanged: _onAgreeAllChanged,
                  onTermChanged: _onTermChanged,
                  onShowTermDetailTerm1: () => _showTermDetail('gittowork 이용 약관'),
                  onShowTermDetailTerm2: () => _showTermDetail('개인정보 수집 및 이용'),
                  onShowTermDetailTerm3: () => _showTermDetail('추천 기업 알림'),
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
                        child: const Text(
                          '회원가입',
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
                Container(height: 50),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
