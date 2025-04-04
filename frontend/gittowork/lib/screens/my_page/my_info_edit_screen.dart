import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:gittowork/widgets/app_bar.dart';
import '../../../models/user_profile.dart';
import '../../services/user_api.dart';
import '../signup/business_interest_screen.dart';
import 'edit_components/avatar_nickname_section.dart';
import 'edit_components/interest_fields_section.dart';
import 'edit_components/user_info_form.dart';
import 'edit_components/notification_switch.dart';
import 'package:bottom_picker/bottom_picker.dart';

class MyInfoEditScreen extends StatefulWidget {
  final UserProfile userProfile;

  const MyInfoEditScreen({
    super.key,
    required this.userProfile,
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

  // 추가: 화면용, 전송용 각각 관리
  final List<int> _interestFieldIds = [];

  @override
  void initState() {
    super.initState();
    _nicknameController.text = widget.userProfile.nickname;
    _nameController.text = widget.userProfile.name;
    _birthController.text = widget.userProfile.birthDt;
    _experienceController.text = widget.userProfile.experience >= 10
        ? '10년 이상'
        : '${widget.userProfile.experience}년';
    _phoneController.text = widget.userProfile.phone;
    _serviceNotification = widget.userProfile.notificationAgreed;
  }

  Future<void> _goToBusinessInterestScreen() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessInterestScreen.edit(
          initialSelectedFields: widget.userProfile.interestFields,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        // 화면 표시용 이름 배열 업데이트
        widget.userProfile.interestFields
          ..clear()
          ..addAll(result['fieldNames']);

        // 서버 전송용 ID 배열도 반드시 업데이트 해야 함 (추가 필수!!)
        _interestFieldIds
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

    final updateParams = {
      'userId': widget.userProfile.userId,
      'interestsFields': _interestFieldIds,
      'name': widget.userProfile.name,
      'birthDt': widget.userProfile.birthDt,
      'experience': updatedExperience,
      'phone': _phoneController.text,
      'notificationAgreed': _serviceNotification, // 👈 명확히 전송
    };

    debugPrint('전송할 관심 분야 ID: $_interestFieldIds');
    debugPrint('서비스 알림 수신 설정: $_serviceNotification'); // 추가 로그

    final success = await UserApi.updateUserProfile(updateParams);

    // 위젯이 여전히 마운트되어 있는지 체크
    if (!mounted) return;

    if (success) {
      if (_serviceNotification) {
        // 스위치 ON -> FCM 토큰 얻어서 등록
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await UserApi.updateFcmToken(token);
        }
      } else {
        // 스위치 OFF -> DB 토큰 비우기
        await UserApi.updateFcmToken('');
      }
      Navigator.pop(context);
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
              interestFields: widget.userProfile.interestFields,
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
