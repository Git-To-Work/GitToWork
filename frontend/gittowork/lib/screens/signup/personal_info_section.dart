import 'package:flutter/material.dart';
import '../../widgets/build_ios_like_row.dart';
import '../../utils/phone_number_formatter.dart';

class PersonalInfoSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController birthController;
  final TextEditingController careerController;
  final TextEditingController phoneController;
  final VoidCallback onBirthPicker;
  final VoidCallback onCareerPicker;

  const PersonalInfoSection({
    super.key,
    required this.nameController,
    required this.birthController,
    required this.careerController,
    required this.phoneController,
    required this.onBirthPicker,
    required this.onCareerPicker,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 이름 입력
        buildIosLikeRow(
          controller: nameController,
          label: '이름',
          hintText: '홍길동',
        ),
        // 생년월일 선택 (탭하면 date picker 호출)
        GestureDetector(
          onTap: onBirthPicker,
          child: AbsorbPointer(
            child: buildIosLikeRow(
              controller: birthController,
              label: '생년월일',
              hintText: 'YYYYMMDD',
            ),
          ),
        ),
        // 경력 선택 (탭하면 경력 picker 호출)
        GestureDetector(
          onTap: onCareerPicker,
          child: AbsorbPointer(
            child: buildIosLikeRow(
              controller: careerController,
              label: '경력 (년)',
              hintText: '0년',
            ),
          ),
        ),
        // 핸드폰 번호 입력
        buildIosLikeRow(
          controller: phoneController,
          label: '핸드폰',
          hintText: '010-0000-0000',
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneNumberFormatter()],
        ),
      ],
    );
  }
}
