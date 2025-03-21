import 'package:flutter/material.dart';

Widget buildIosLikeRow({
  required String label,
  required String hintText,
  TextEditingController? controller,
  keyboardType,
  inputFormatters,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    decoration: const BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Colors.grey, width: 0.5),
      ),
    ),
    child: Row(
      children: [
        // 왼쪽 라벨
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // 오른쪽 입력 필드
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none, // 밑줄 제거
            ),
          ),
        ),
      ],
    ),
  );
}
