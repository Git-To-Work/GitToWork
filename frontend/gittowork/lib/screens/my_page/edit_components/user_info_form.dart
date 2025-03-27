import 'package:flutter/material.dart';
import '../../../../utils/phone_number_formatter.dart';
import '../../../../widgets/build_ios_like_row.dart';

class UserInfoForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController birthController;
  final TextEditingController experienceController;
  final TextEditingController phoneController;
  final VoidCallback onExperienceTap;

  const UserInfoForm({
    super.key,
    required this.nameController,
    required this.birthController,
    required this.experienceController,
    required this.phoneController,
    required this.onExperienceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 이름 (수정 불가)
        AbsorbPointer(
          child: buildIosLikeRow(
            label: '이름',
            hintText: '홍길동',
            controller: nameController,
          ),
        ),

        // 생년월일 (수정 불가)
        AbsorbPointer(
          child: buildIosLikeRow(
            label: '생년월일',
            hintText: 'YYYYMMDD',
            controller: birthController,
          ),
        ),

        // 경력 (탭하면 picker 호출)
        GestureDetector(
          onTap: onExperienceTap,
          child: AbsorbPointer(
            child: buildIosLikeRow(
              label: '경력 (년)',
              hintText: '0년',
              controller: experienceController,
            ),
          ),
        ),

        // 핸드폰 (수정 가능)
        buildIosLikeRow(
          label: '핸드폰',
          hintText: '010-0000-0000',
          controller: phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneNumberFormatter()],
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
