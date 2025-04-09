import 'package:flutter/material.dart';
import 'package:gittowork/screens/company_recommendation/tech_stacks.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gittowork/services/github_api.dart';
import 'package:gittowork/models/repository.dart';
import 'package:gittowork/providers/search_provider.dart';

import '../../providers/company_provider.dart';

class SearchBarWithFilters extends StatefulWidget {
  const SearchBarWithFilters({super.key});

  @override
  State<SearchBarWithFilters> createState() => _SearchBarWithFiltersState();
}

class _SearchBarWithFiltersState extends State<SearchBarWithFilters> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  List<RepositoryCombination> _combinations = [];
  List<String> _repoOptions = [];
  String selectedRepo = '';
  bool _isRepoLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRepoCombinations();
  }

  Future<void> _loadRepoCombinations() async {
    final storedRepoId = await _secureStorage.read(key: 'selected_repo_id');

    try {
      final combinations = await GitHubApi.fetchMyRepositoryCombinations();
      final options = combinations.map((c) => c.repositoryNames.join(', ')).toList();

      String initialSelectedRepo = options.isNotEmpty ? options.first : '';
      String initialSelectedRepoId = combinations.isNotEmpty ? combinations.first.selectedRepositoryId : '';

      for (int i = 0; i < combinations.length; i++) {
        if (combinations[i].selectedRepositoryId == storedRepoId) {
          initialSelectedRepo = combinations[i].repositoryNames.join(', ');
          initialSelectedRepoId = combinations[i].selectedRepositoryId;
          break;
        }
      }

      if (!mounted) return;

      final provider = Provider.of<SearchFilterProvider>(context, listen: false);
      provider.updateSelectedRepo(initialSelectedRepo, initialSelectedRepoId);

      setState(() {
        _combinations = combinations;
        _repoOptions = options;
        selectedRepo = initialSelectedRepo;
        _isRepoLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRepoLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('조합 레포지토리 불러오기 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (value) {
            Provider.of<SearchFilterProvider>(context, listen: false).updateKeyword(value);
          },
          onSubmitted: (value) async {
            await Provider.of<CompanyProvider>(context, listen: false).loadCompaniesFromApi(
              context: context,
              page: '1',
              size: '20',
              reset: true,
            );
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, size: 28),
            hintText: "검색",
            hintStyle: const TextStyle(fontSize: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(50)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          ),
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterButton("My Repo"),
              _buildFilterButton("기술스택"),
              _buildFilterButton("직무"),
              _buildFilterButton("경력"),
              _buildFilterButton("지역"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton(
        onPressed: () => _showFilterModal(context, title),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          side: const BorderSide(color: Color(0xFF6C6C6C)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(color: Colors.black, fontSize: 16)),
            const SizedBox(width: 6),
            Image.asset('assets/images/Drop_Down.png', width: 16, height: 16),
          ],
        ),
      ),
    );
  }

  void _showFilterModal(BuildContext context, String tabTitle) {
    final searchProvider = Provider.of<SearchFilterProvider>(context, listen: false);
    String localCareer = searchProvider.selectedCareer;
    Set<String> localTechs = Set.from(searchProvider.selectedTechs);
    Set<String> localTags = Set.from(searchProvider.selectedTags);
    Set<String> localRegions = Set.from(searchProvider.selectedRegions);
    String localRepoName = searchProvider.selectedRepoName;
    String localRepoId = searchProvider.selectedRepoId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            Widget buildRepoFilter() {
              if (_isRepoLoading) return const Center(child: CircularProgressIndicator());
              if (_repoOptions.isEmpty) return const Center(child: Text("조회된 조합 레포지토리가 없습니다."));
              return _buildWrapChips(
                _repoOptions,
                localRepoName,
                isSingle: true,
                onSingleSelected: (val) {
                  modalSetState(() {
                    localRepoName = val;
                    final index = _repoOptions.indexOf(val);
                    if (index >= 0 && index < _combinations.length) {
                      localRepoId = _combinations[index].selectedRepositoryId;
                    }
                  });
                },
              );
            }

            return SizedBox(
              height: screenHeight - 130,
              child: DefaultTabController(
                initialIndex: _getInitialIndex(tabTitle),
                length: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30),
                      child: TabBar(
                        isScrollable: false,
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey,
                        labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        indicatorColor: Colors.black,
                        labelPadding: EdgeInsets.zero,
                        tabs: [
                          Tab(child: Center(child: Text('Repo'))),
                          Tab(child: Center(child: Text('기술스택'))),
                          Tab(child: Center(child: Text('직무'))),
                          Tab(child: Center(child: Text('경력'))),
                          Tab(child: Center(child: Text('지역'))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: TabBarView(
                        children: [
                          buildRepoFilter(),
                          _buildSearchableTechStackChips(localTechs, modalSetState),
                          _buildWrapChips([
                            '빅데이터 엔지니어', 'DBA', '웹퍼블리셔', 'HW/임베디드', '게임 클라이언트 개발자',
                            'VR/AR/3D', 'devops/시스템 엔지니어', '기술지원', 'iOS 개발자', 'QA 엔지니어',
                            '블록체인', '안드로이드 개발자', '프론트엔드 개발자', '정보보안 담당자', '게임 서버 개발자',
                            '서버/백엔드 개발자', '크로스플랫폼 앱개발자', '개발 PM', '웹 풀스택 개발자',
                            'SW/솔루션', '인공지능/머신러닝'
                          ], localTags, modalSetState: modalSetState),
                          _buildWrapChips([
                            '전체', '신입', '1년', '2년', '3년', '4년', '5년',
                            '6년', '7년', '8년', '9년', '10년 이상'
                          ], localCareer, isSingle: true, onSingleSelected: (val) {
                            modalSetState(() {
                              localCareer = val;
                            });
                          }),
                          _buildWrapChips([
                            '서울', '경기', '인천', '부산', '대구', '광주', '대전', '울산', '제주'
                          ], localRegions, modalSetState: modalSetState),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16).copyWith(bottom: 60),
                      child: ElevatedButton(
                        onPressed: () async {
                          final provider = Provider.of<SearchFilterProvider>(context, listen: false);
                          provider.updateSelectedRepo(localRepoName, localRepoId);
                          provider.updateCareer(localCareer);
                          provider.updateTechs(localTechs);
                          provider.updateTags(localTags);
                          provider.updateRegions(localRegions);
                          await Provider.of<CompanyProvider>(context, listen: false).loadCompaniesFromApi(
                            context: context,
                            page: '1',
                            size: '20',
                            reset: true,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text("적용하기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _getInitialIndex(String tabTitle) {
    switch (tabTitle) {
      case 'My Repo': return 0;
      case '기술스택': return 1;
      case '직무': return 2;
      case '경력': return 3;
      case '지역': return 4;
      default: return 0;
    }
  }

  Widget _buildWrapChips(
      List<String> options,
      dynamic selected, {
        bool isSingle = false,
        Function(String)? onSingleSelected,
        StateSetter? modalSetState,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: options.map((text) {
          final isSelected = isSingle ? (selected == text) : (selected.contains(text));
          return isSingle
              ? ChoiceChip(
            label: Text(text),
            selected: isSelected,
            showCheckmark: false,
            selectedColor: const Color(0xFF3D3D3D),
            backgroundColor: const Color(0xFFF0F0F0),
            labelStyle: TextStyle(fontSize: 16, color: isSelected ? Colors.white : Colors.black),
            onSelected: (_) => onSingleSelected?.call(text),
          )
              : FilterChip(
            label: Text(text),
            selected: isSelected,
            showCheckmark: false,
            selectedColor: const Color(0xFF3D3D3D),
            backgroundColor: const Color(0xFFF0F0F0),
            labelStyle: TextStyle(fontSize: 16, color: isSelected ? Colors.white : Colors.black),
            onSelected: (bool val) {
              modalSetState?.call(() {
                if (val) {
                  selected.add(text);
                } else {
                  selected.remove(text);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchableTechStackChips(Set<String> selectedTechs, StateSetter modalSetState) {
    TextEditingController searchController = TextEditingController();
    List<String> filteredOptions = [];

    return StatefulBuilder(
      builder: (context, setModalState) {
        void updateSearch(String query) {
          setModalState(() {
            filteredOptions = query.isEmpty
                ? []
                : techStackOptions
                .where((tech) =>
            tech.toLowerCase().contains(query.toLowerCase()) &&
                !selectedTechs.contains(tech))
                .toList();
          });
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: searchController,
                onChanged: updateSearch,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "기술 스택 검색",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
              ),
              const SizedBox(height: 16),
              if (filteredOptions.isNotEmpty)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: filteredOptions.map((text) {
                    return FilterChip(
                      label: Text(text),
                      selected: false,
                      showCheckmark: false,
                      selectedColor: const Color(0xFF3D3D3D),
                      backgroundColor: const Color(0xFFF0F0F0),
                      labelStyle: const TextStyle(fontSize: 16, color: Colors.black),
                      onSelected: (bool val) {
                        modalSetState(() {
                          selectedTechs.add(text);
                          searchController.clear();
                          filteredOptions.clear();
                        });
                      },
                    );
                  }).toList(),
                ),
              if (selectedTechs.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  "선택된 기술 스택",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: selectedTechs.map((tech) {
                    return InputChip(
                      label: Text(tech),
                      onDeleted: () {
                        modalSetState(() {
                          selectedTechs.remove(tech);
                        });
                      },
                      deleteIcon: const Icon(Icons.cancel, size: 18),
                      backgroundColor: const Color(0xFFE0E0E0),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

}
