import 'package:flutter/material.dart';
import 'select_repo.dart';
import 'edit_repo.dart';

class MyRepo extends StatefulWidget {
  const MyRepo({super.key});

  @override
  State<MyRepo> createState() => _MyRepoState();
}

class _MyRepoState extends State<MyRepo> {
  int _selectedIndex = 0;

  final List<String> _repoNames = [
    'Repo A',
    'Repo B',
    'Repo C',
    'Repo D',
    'Repo E',
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Repo',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              showDialog(
                                context: context,
                                builder: (context) => const SelectRepoDialog(),
                              );
                            },
                            child: Image.asset(
                              'assets/icons/Add.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              showDialog(
                                context: context,
                                builder: (context) => const EditRepoDialog(),
                              );
                            },
                            child: Image.asset(
                              'assets/icons/Edit.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(thickness: 1, height: 20, color: Colors.black26),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _repoNames.length,
                      itemBuilder: (context, index) {
                        final bool isSelected = (index == _selectedIndex);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _repoNames[index],
                            style: const TextStyle(color: Colors.grey, fontSize: 18),
                          ),
                          trailing: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            child: Image.asset(
                              isSelected
                                  ? 'assets/icons/Choose.png'
                                  : 'assets/icons/Un_Choose.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            ElevatedButton(
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                '선택완료',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
