import 'package:flutter/material.dart';

Future<void> showCustomAlertDialog({
  required BuildContext context,
  required String content,
  String? subText,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/Big_Logo_White.png',
                width: 130,
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: const TextStyle(fontSize: 24),
              ),
              if (subText != null) ...[
                const SizedBox(height: 10),
                Text(
                  subText,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "확인",
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
