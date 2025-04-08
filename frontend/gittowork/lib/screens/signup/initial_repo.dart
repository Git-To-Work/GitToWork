import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../layouts/appbar_bottom_nav_layout.dart';
import '../../services/company_api.dart';
import '../../widgets/app_bar.dart';
import '../../services/github_api.dart';
import '../../models/repository.dart';

class InitialRepoScreen extends StatefulWidget {
  const InitialRepoScreen({super.key});

  @override
  State<InitialRepoScreen> createState() => _InitialRepoScreenState();
}

class _InitialRepoScreenState extends State<InitialRepoScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  List<Repository> _repos = [];
  List<bool> _selectedList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRepositories();
  }

  Future<void> _loadRepositories() async {
    final repos = await GitHubApi.fetchMyRepositories();
    setState(() {
      _repos = repos;
      _selectedList = List<bool>.filled(repos.length, false);
      _isLoading = false;
    });
  }

  Future<void> _storeSelectedRepoIds(List<int> selectedRepoIds) async {
    final repoIdsString = selectedRepoIds.join(',');
    await _secureStorage.delete(key: 'selected_repo_ids'); // 기존 데이터 삭제
    await _secureStorage.write(key: 'selected_repo_ids', value: repoIdsString); // 새 데이터 저장
    debugPrint("🔐 저장된 Repo IDs: $repoIdsString");

    try {
      await GitHubApi.saveSelectedRepository(selectedRepoIds);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('레포지토리 선택 저장 실패: $e')),
      );
    }

    try {
      await GitHubApi.requestRepositoryAnalysis(context, selectedRepoIds);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('레포지토리 분석 요청 실패: $e')),
      );
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppBarBottomNavLayout()),
    );

    try{
      await CompanyApi.requestCompanyAnalysis();
    } catch (e){
      debugPrint("❌company 분석 요청 실패 : $e");
    }

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 10.0, top: 20.0, bottom: 20.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GitHub 저장소를 선택해주세요',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '원활한 분석을 위해 최소 1개 이상의 레포지토리를 선택해야 합니다.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: ListView.builder(
                itemCount: _repos.length,
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(_repos[index].repoName),
                  trailing: Checkbox(
                    value: _selectedList[index],
                    activeColor: Colors.black,
                    checkColor: Colors.white,
                    onChanged: (value) {
                      setState(() {
                        _selectedList[index] = value ?? false;
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      _selectedList[index] = !_selectedList[index];
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    final selectedRepoIds = <int>[];
                    for (int i = 0; i < _repos.length; i++) {
                      if (_selectedList[i]) {
                        selectedRepoIds.add(_repos[i].repoId);
                      }
                    }

                    // ❗ 아무것도 선택 안했을 때 처리
                    if (selectedRepoIds.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('최소 1개 이상의 저장소를 선택해주세요.')),
                      );
                      return;
                    }

                    debugPrint("✅ 선택된 저장소 ID: $selectedRepoIds");
                    await _storeSelectedRepoIds(selectedRepoIds);
                  },

                  child: const Text(
                    '분석 시작',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
