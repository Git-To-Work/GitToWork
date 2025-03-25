import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gittowork/widgets/app_bar.dart';
import '../../../models/user_profile.dart';
import '../../../utils/phone_number_formatter.dart';

import '../signup/business_interest_screen.dart';

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
  final TextEditingController _phoneController = TextEditingController();

  bool _serviceNotification = false; // 서비스 알림 수신 설정

  @override
  void initState() {
    super.initState();
    // 초기값 설정 (API or userProfile에서 가져온 값)
    _nicknameController.text = widget.userProfile.nickname;
    _nameController.text = widget.userProfile.name; // readOnly
    _birthController.text = widget.userProfile.dateOfBirth; // readOnly
    _phoneController.text = widget.userProfile.phone;
    // _serviceNotification = ... // userProfile에 관련 필드가 있으면 적용
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _nameController.dispose();
    _birthController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // 관심 비즈니스 분야 수정 페이지로 이동
  Future<void> _goToBusinessInterestScreen() async {
    // 현재 userProfile.interestFields는 ["솔루션 SI", "빅데이터", ...] 등
    final currentFields = widget.userProfile.interestFields;

    final updatedFields = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessInterestScreen.edit(
          initialSelectedFields: currentFields,
        ),
      ),
    );

    if (updatedFields != null) {
      // 새로 선택된 분야 리스트로 갱신
      setState(() {
        widget.userProfile.interestFields
          ..clear()
          ..addAll(updatedFields);
      });
    }
  }

  // 나의 정보 수정 완료
  void _onUpdateInfo() {
    final updatedPhone = _phoneController.text;
    final updatedNotification = _serviceNotification;

    debugPrint('수정할 전화번호: $updatedPhone');
    debugPrint('서비스 알림 수신 설정: $updatedNotification');
    debugPrint('새 관심 분야: ${widget.userProfile.interestFields}');

    // TODO: 실제 API 통신으로 서버에 수정 요청
    // ex) ApiService.updateUserProfile(...)

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final interestFields = widget.userProfile.interestFields; // 최대 5개

    return Scaffold(
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            // 상단 아바타 & 닉네임
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(widget.userProfile.avatarUrl),
            ),
            const SizedBox(height: 8),
            Text(
              _nicknameController.text,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 관심 비즈니스 분야 선택 버튼
            SizedBox(
              width: 360,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C2C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _goToBusinessInterestScreen,
                child: const Text(
                  '관심 비즈니스 분야 선택',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 이미 선택된 관심 비즈니스 분야 (최대 5개)
            if (interestFields.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: interestFields.take(5).map((field) {
                    final randomColor = _getRandomColor();
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: randomColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        field,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 24),

            // 이름 (수정 불가)
            _buildReadOnlyField(label: '이름', controller: _nameController),

            // 생년월일 (수정 불가)
            _buildReadOnlyField(label: '생년월일', controller: _birthController),

            // 핸드폰 (수정 가능)
            _buildEditableField(
              label: '핸드폰',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 16),

            // 서비스 알림 수신 설정 (Switch)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '서비스 알림 수신 설정',
                  style: TextStyle(fontSize: 16),
                ),
                Switch(
                  value: _serviceNotification,
                  onChanged: (value) {
                    setState(() {
                      _serviceNotification = value;
                    });
                  },
                  activeColor: const Color(0xFF2C2C2C),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 나의 정보 수정 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
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
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 이름/생년월일용 (수정 불가)
  Widget _buildReadOnlyField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Color(0xFFF0F0F0),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // 핸드폰 등 (수정 가능)
  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: keyboardType == TextInputType.phone
              ? [PhoneNumberFormatter()]
              : null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // 랜덤 색상 (파스텔 계열 등) 생성 예시
  Color _getRandomColor() {
    final random = Random();
    final r = random.nextInt(100) + 100; // 100~199
    final g = random.nextInt(100) + 100; // 100~199
    final b = random.nextInt(100) + 100; // 100~199
    return Color.fromARGB(255, r, g, b);
  }
}
