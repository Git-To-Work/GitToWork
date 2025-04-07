import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:gittowork/widgets/app_bar.dart';
import '../../../models/user_profile.dart';
import '../../models/interest_field.dart';
import '../../services/user_api.dart';
import '../signup/business_interest_screen.dart';
import 'edit_components/avatar_nickname_section.dart';
import 'edit_components/interest_fields_section.dart';
import 'edit_components/user_info_form.dart';
import 'edit_components/notification_switch.dart';
import 'package:bottom_picker/bottom_picker.dart';

import 'my_page_screen.dart';

class MyInfoEditScreen extends StatefulWidget {
  /// [userProfile]는 사용자 프로필 정보 (관심 분야 이름 없음)
  final UserProfile userProfile;
  /// [interestField]는 관심 분야 (이름 + ID 목록)
  final InterestField interestField;

  const MyInfoEditScreen({
    super.key,
    required this.userProfile,
    required this.interestField,
  });

  @override
  State<MyInfoEditScreen> createState() => _MyInfoEditScreenState();
}

class _MyInfoEditScreenState extends State<MyInfoEditScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _serviceNotification = false;

  // 관심 분야 ID 목록 (서버 전송용)
  final List<int> _selectedFieldIds = [];
  // 관심 분야 이름 목록 (화면 표시용)
  final List<String> _selectedFieldNames = [];

  @override
  void initState() {
    super.initState();
    // 사용자 프로필 초기화
    _nicknameController.text = widget.userProfile.nickname;
    _nameController.text = widget.userProfile.name;
    _birthController.text = widget.userProfile.birthDt;
    _experienceController.text =
    widget.userProfile.experience >= 10 ? '10년 이상' : '${widget.userProfile.experience}년';
    _phoneController.text = widget.userProfile.phone;
    _serviceNotification = widget.userProfile.notificationAgreed;

    // 초기 관심 분야
    // (백엔드가 'my-interest-field'로 넘겨준 값이라면, 여기서 자동 체크하도록 구성 가능)
    _selectedFieldIds.addAll(widget.interestField.interestFieldIds);
    _selectedFieldNames.addAll(widget.interestField.interestFieldNames);
  }

  Future<void> _goToBusinessInterestScreen() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessInterestScreen.edit(
          initialSelectedFields: _selectedFieldNames,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        // 화면 표시용 이름 배열 업데이트
        _selectedFieldNames
          ..clear()
          ..addAll(result['fieldNames']);

        // 서버 전송용 ID 배열도 반드시 업데이트
        _selectedFieldIds
          ..clear()
          ..addAll(result['fieldIds']);
      });
    }
  }



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
          _experienceController.text = selectedIndex < 10 ? '$selectedIndex년' : '10년 이상';
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

  Future<void> _onUpdateInfo() async {
    final updatedExperience = _experienceController.text.contains('10년 이상')
        ? 10
        : int.parse(_experienceController.text.replaceAll(RegExp(r'\D'), ''));

    final profileParams = {
      'userId': widget.userProfile.userId,
      'name': widget.userProfile.name,
      'birthDt': widget.userProfile.birthDt,
      'experience': updatedExperience,
      'phone': _phoneController.text,
      'notificationAgreed': _serviceNotification,
    };

    final profileSuccess = await UserApi.updateUserProfile(profileParams);

    if (!mounted) return;

    if (profileSuccess) {
      if (_serviceNotification) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await UserApi.updateFcmToken(token);
        }
      } else {
        await UserApi.updateFcmToken('');
      }
      if(!mounted){
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MyPageScreen(), // 실제 MyPageScreen 생성자에 맞게 수정
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원 정보 수정에 실패했습니다. 다시 시도해주세요.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
        child: Column(
          children: [
            AvatarNicknameSection(
              avatarUrl: widget.userProfile.avatarUrl,
              nickname: _nicknameController.text,
            ),
            InterestFieldsSection(
              interestFields: _selectedFieldNames,
              onEditPressed: _goToBusinessInterestScreen,
            ),
            UserInfoForm(
              nameController: _nameController,
              birthController: _birthController,
              experienceController: _experienceController,
              phoneController: _phoneController,
              onExperienceTap: _pickCareer,
            ),
            NotificationSwitch(
              value: _serviceNotification,
              onChanged: (val) => setState(() => _serviceNotification = val),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _onUpdateInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C2C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '나의 정보 수정',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
