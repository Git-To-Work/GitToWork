import 'package:flutter/material.dart';
import '../../../../utils/phone_number_formatter.dart';

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
        _buildReadOnlyField('이름', nameController),
        _buildReadOnlyField('생년월일', birthController),
        GestureDetector(
          onTap: onExperienceTap,
          child: AbsorbPointer(child: _buildEditableField('경력', experienceController)),
        ),
        _buildEditableField('핸드폰', phoneController, keyboardType: TextInputType.phone),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
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

  Widget _buildEditableField(String label, TextEditingController controller,
      {TextInputType? keyboardType}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: keyboardType == TextInputType.phone ? [PhoneNumberFormatter()] : null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
}
