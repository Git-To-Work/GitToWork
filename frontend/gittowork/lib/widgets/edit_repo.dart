import 'package:flutter/material.dart';

class EditRepoDialog extends StatefulWidget {
  const EditRepoDialog({super.key});

  @override
  State<EditRepoDialog> createState() => _EditRepoDialogState();
}

class _EditRepoDialogState extends State<EditRepoDialog> {
  final List<String> _repoNames = [
    'Total',
    'First Repo',
    'Second Repo',
    'Mkos47635, mkos12..',
    'Third (분석중..)',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 컨텐츠 영역
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Select Repo',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Divider(thickness: 1, height: 20, color: Colors.black54),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _repoNames.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _repoNames[index],
                              style: const TextStyle(color: Colors.grey, fontSize: 18),
                            ),
                            trailing: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _repoNames.removeAt(index);
                                });
                              },
                              child: Image.asset(
                                'assets/icons/Delete.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 버튼 영역
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                child: const Text(
                  '완료',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
