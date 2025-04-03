import 'package:flutter/material.dart';
import '../../services/github_api.dart'; // GitHub API 호출용 파일
import '../../models/repository.dart'; // Repository 모델
import 'my_repo.dart'; // 조합 레포지토리 선택 화면

class SelectRepoDialog extends StatefulWidget {
  const SelectRepoDialog({super.key});

  @override
  State<SelectRepoDialog> createState() => _SelectRepoDialogState();
}

class _SelectRepoDialogState extends State<SelectRepoDialog> {
  List<Repository> _repositories = [];
  List<bool> _selectedList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRepositories();
  }

  Future<void> _loadRepositories() async {
    try {
      final repos = await GitHubApi.fetchMyRepositories();
      setState(() {
        _repositories = repos;
        _selectedList = List<bool>.filled(repos.length, false);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('레포지토리 불러오기 실패: $e')),
      );
    }
  }

  Future<void> _saveSelectedRepositories() async {
    List<int> selectedRepoIds = [];
    for (int i = 0; i < _repositories.length; i++) {
      if (_selectedList[i]) {
        selectedRepoIds.add(_repositories[i].repoId);
      }
    }

    bool isDuplicate = false;

    try {
      final resultMessage = await GitHubApi.saveSelectedRepository(selectedRepoIds);

      if (resultMessage == '이미 등록된 레포지토리 조합입니다.') {
        isDuplicate = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 등록된 조합입니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultMessage)),
        );
      }
    } catch (e) {
      isDuplicate = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('레포지토리 선택 저장 실패: $e')),
      );
    }

    if (!isDuplicate) {
      try {
        await GitHubApi.requestRepositoryAnalysis(selectedRepoIds);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('레포지토리 분석 요청 실패: $e')),
        );
      }

      Navigator.of(context).pop(); // ✅ 중복이 아닌 경우에만 닫힘
      showDialog(
        context: context,
        builder: (context) => const MyRepo(),
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
            // 컨텐츠 영역
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Select Repo',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 10),
                  const Divider(thickness: 1, height: 20, color: Colors.black54),
                  // 고정 높이 영역 (항목 수와 상관없이 300픽셀 유지)
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: _repositories.length,
                      itemBuilder: (context, index) {
                        final bool isSelected = _selectedList[index];
                        final repo = _repositories[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            repo.repoName,
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
                                  ? 'assets/icons/Checked.png'
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
                  '분석하기',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                onPressed: _saveSelectedRepositories,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
