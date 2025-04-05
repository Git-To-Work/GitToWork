import 'package:flutter/material.dart';
import '../../services/github_api.dart';
import '../../models/repository.dart';
import '../widgets/alert_modal.dart';
import '../widgets/my_repo.dart';

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
      if (!mounted) return;
      setState(() {
        _repositories = repos;
        _selectedList = List<bool>.filled(repos.length, false);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSelectedRepositories() async {
    List<int> selectedRepoIds = [];
    for (int i = 0; i < _repositories.length; i++) {
      if (_selectedList[i]) {
        selectedRepoIds.add(_repositories[i].repoId);
      }
    }

    if (selectedRepoIds.isEmpty) {
      await showCustomAlertDialog(
        context: context,
        content: "선택된 레포지토리가 없습니다!",
        subText: "1개 이상의 레포지토리를 선택해주세요.",
      );
      return;
    }

    bool isDuplicate = false;

    try {
      final resultMessage = await GitHubApi.saveSelectedRepository(selectedRepoIds);
      if (!mounted) return;
      if (resultMessage == '이미 등록된 레포지토리 조합입니다.') {
        isDuplicate = true;
        await showCustomAlertDialog(
          context: context,
          content: "이미 등록된 레포지토리 조합입니다.",
        );
      }
    } catch (e) {
      isDuplicate = true;
      if (!mounted) return;
    }

    if (!isDuplicate) {
      try {
        await GitHubApi.requestRepositoryAnalysis(context, selectedRepoIds);
        if (!mounted) return;
      } catch (e) {
        if (!mounted) return;
      }
      if (!mounted) return;
      await showCustomAlertDialog(
        context: context,
        content: "분석을 시작했어요!",
        subText: "분석이 완료되면 알림으로 알려드릴게요 📩",
      );
      Navigator.of(context).pop();
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
                        'Select Repo',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            builder: (context) => const MyRepo(),
                          );
                        },
                        child: Image.asset(
                          'assets/icons/Back.png',
                          width: 26,
                          height: 26,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(
                    thickness: 1,
                    height: 20,
                    color: Colors.black54,
                  ),
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
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 18),
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
            // 하단 버튼
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
                onPressed: _saveSelectedRepositories,
                child: const Text(
                  '분석하기',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
