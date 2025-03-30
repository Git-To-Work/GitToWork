import 'package:flutter/material.dart';
import '../../services/github_api.dart'; // GitHub API 호출용 파일
import '../../models/repository.dart'; // CombinationRepository 모델이 포함되어 있음
import 'my_repo.dart'; // 조합 레포지토리 선택 화면

class EditRepoDialog extends StatefulWidget {
  const EditRepoDialog({super.key});

  @override
  State<EditRepoDialog> createState() => _EditRepoDialogState();
}

class _EditRepoDialogState extends State<EditRepoDialog> {
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

  Future<void> _deleteCombination(int index) async {
    final combination = _combinations[index];
    try {
      // API 호출 시 selectedRepositoryId는 String 타입입니다.
      await GitHubApi.deleteRepositoryCombination(combination.selectedRepositoryId);
      setState(() {
        _combinations.removeAt(index);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('조합 레포지토리 삭제 실패: $e')),
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
          children: [
            // 컨텐츠 영역
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Edit Repo',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Divider(thickness: 1, height: 20, color: Colors.black54),
                  // 고정 높이 영역: 항상 300픽셀 영역 유지
                  SizedBox(
                    height: 300,
                    child: _combinations.isEmpty
                        ? const Center(child: Text("조회된 조합 레포지토리가 없습니다."))
                        : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _combinations.length,
                      itemBuilder: (context, index) {
                        final combination = _combinations[index];
                        final combinedNames = combination.repositoryNames.join(', ');
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            combinedNames,
                            style: const TextStyle(color: Colors.grey, fontSize: 18),
                          ),
                          trailing: GestureDetector(
                            onTap: () {
                              _deleteCombination(index);
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
                onPressed: (){
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (context) =>
                    const MyRepo(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
