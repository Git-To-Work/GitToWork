import 'package:flutter/material.dart';

Future<bool?> showCustomConfirmDialog({
  required BuildContext context,
  required String content,
  String? subText,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24), // ✅ 좌우 공백 15
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/Big_Logo_White.png', // ✅ 이미지로 교체
                width: 130,
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: const TextStyle(fontSize: 24), // ✅ 글자 크기 약간 키움
              ),
              if (subText != null) ...[
                const SizedBox(height: 10),
                Text(
                  subText,
                  style: const TextStyle(fontSize: 16, color: Colors.grey), // ✅ 글자 크기 약간 키움
                ),
              ],
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      "취소",
                      style: TextStyle(fontSize: 20, color: Colors.grey), // ✅ 크기 키움
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      "확인",
                      style: TextStyle(fontSize: 20, color: Colors.black), // ✅ 크기 키움
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
