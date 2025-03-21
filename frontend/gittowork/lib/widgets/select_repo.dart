import 'package:flutter/material.dart';

class SelectRepoDialog extends StatefulWidget {
  const SelectRepoDialog({super.key});

  @override
  State<SelectRepoDialog> createState() => _SelectRepoDialogState();
}

class _SelectRepoDialogState extends State<SelectRepoDialog> {
  final List<bool> _selectedList = [false, false, false, false, false];

  final List<String> _repoNames = [
    'First Repository',
    'Second Repository',
    'Repository 3',
    'Repository 4',
    'Seongwon'
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select Repo',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 10),
                  const Divider(thickness: 1, height: 20, color: Colors.black54),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _repoNames.length,
                      itemBuilder: (context, index) {
                        final bool isSelected = _selectedList[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _repoNames[index],
                            style: const TextStyle(color: Colors.grey, fontSize: 18),
                          ),
                          trailing: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedList[index] = !_selectedList[index];
                              });
                            },
                            child: Image.asset(
                              isSelected
                                  ? 'assets/icons/Choose.png'
                                  : 'assets/icons/Un_Checked.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedList[index] = !_selectedList[index];
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

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
                  '분석하기',
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
