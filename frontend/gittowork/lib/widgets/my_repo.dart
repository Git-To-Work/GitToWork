import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'select_repo.dart';
import 'edit_repo.dart';
import '../../services/github_api.dart'; // GitHub API 호출용 파일
import '../../models/repository.dart'; // CombinationRepository 모델이 포함되어 있음

class MyRepo extends StatefulWidget {
  const MyRepo({super.key});

  @override
  State<MyRepo> createState() => _MyRepoState();
}

class _MyRepoState extends State<MyRepo> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  int _selectedIndex = 0;
  List<RepositoryCombination> _combinations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCombinations();
  }

  Future<void> _loadCombinations() async {
    try {
      final combinations = await GitHubApi.fetchMyRepositoryCombinations();
      setState(() {
        _combinations = combinations;
        _selectedIndex = combinations.isNotEmpty ? 0 : -1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('조합 레포지토리 불러오기 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 350,
        height: 467,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
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
                  SizedBox(
                    height: 300,
                    child: _combinations.isEmpty
                        ? const Center(
                      child: Text("조회된 조합 레포지토리가 없습니다."),
                    )
                        : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _combinations.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _selectedIndex;
                        final combination = _combinations[index];
                        final combinedNames = combination.repositoryNames.join(', ');
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            combinedNames,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 18),
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
                  '선택하기',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                onPressed: () async {
                  if (_selectedIndex >= 0 &&
                      _selectedIndex < _combinations.length) {
                    final selectedRepoId =
                        _combinations[_selectedIndex].selectedRepositoryId;

                    debugPrint("선택된 Repository ID: $selectedRepoId");

                    // secure storage에 저장
                    await _secureStorage.write(
                      key: 'selected_repo_id',
                      value: selectedRepoId,
                    );
                    debugPrint("🔐 저장된 selected_repo_id: $selectedRepoId");

                    try {
                      debugPrint("분석 데이터 실행");
                      final result = await GitHubApi.fetchGithubAnalysis(
                        context: context,
                        selectedRepositoryId: selectedRepoId,
                      );
                      if (result['analyzing'] == true) {
                        debugPrint("⌛ 아직 분석 중입니다.");
                      } else {
                        debugPrint("✅ 분석 결과 저장 완료");
                      }
                    } catch (e) {
                      debugPrint("❌ 분석 데이터 불러오기 실패: $e");
                    }
                  } else {
                    debugPrint("선택된 Repository가 없습니다.");
                  }
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
