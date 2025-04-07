import 'package:flutter/services.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // 숫자만 추출
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = '';
    if (digits.length <= 3) {
      formatted = digits;
    } else if (digits.length <= 7) {
      formatted = '${digits.substring(0, 3)}-${digits.substring(3)}';
    } else {
      formatted = '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7, digits.length > 11 ? 11 : digits.length)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
