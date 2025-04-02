import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gittowork/services/github_api.dart';
import 'package:gittowork/models/repository.dart';
import 'package:gittowork/providers/search_provider.dart';

class SearchBarWithFilters extends StatefulWidget {
  const SearchBarWithFilters({super.key});

  @override
  State<SearchBarWithFilters> createState() => _SearchBarWithFiltersState();
}

class _SearchBarWithFiltersState extends State<SearchBarWithFilters> {
  // My Repo 탭 관련 상태
  List<RepositoryCombination> _combinations = [];
  List<String> _repoOptions = ['전체'];
  String selectedRepo = '전체';
  bool _isRepoLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRepoCombinations();
  }

  Future<void> _loadRepoCombinations() async {
    try {
      final combinations = await GitHubApi.fetchMyRepositoryCombinations();
      final options = ['전체', ...combinations.map((c) => c.repositoryNames.join(', '))];
      setState(() {
        _combinations = combinations;
        _repoOptions = options;
        selectedRepo = options.first;
        _isRepoLoading = false;
      });
    } catch (e) {
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
        // 검색 텍스트 필드
        TextField(
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
        // 필터 버튼들
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
    // Provider에서 이전에 적용된 필터 값을 가져옴 (기술스택, 직무, 경력, 지역)
    final searchProvider = Provider.of<SearchFilterProvider>(context, listen: false);
    // 로컬 임시 변수로 복사 (모달 내 선택 변경시만 반영)
    String localCareer = searchProvider.selectedCareer;
    Set<String> localTechs = Set.from(searchProvider.selectedTechs);
    Set<String> localTags = Set.from(searchProvider.selectedTags);
    Set<String> localRegions = Set.from(searchProvider.selectedRegions);

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
            // 로컬 필터 UI 위젯 정의
            Widget buildLocalCareerFilter() {
              final options = [
                '전체', '신입', '1년', '2년', '3년', '4년', '5년',
                '6년', '7년', '8년', '9년', '10년 이상'
              ];
              return _buildWrapChips(options, localCareer, isSingle: true,
                  onSingleSelected: (val) {
                    modalSetState(() {
                      localCareer = val;
                    });
                  });
            }

            Widget buildLocalTechFilter() {
              final options = ['JavaScript', 'Python', 'Dart', 'Flutter', 'Spring', 'React', 'Node.js', 'Java'];
              return _buildWrapChips(options, localTechs, modalSetState: modalSetState);
            }

            Widget buildLocalTagFilter() {
              final options = [
                '#4.5일제', '#재택근무', '#유연근무제', '#시차출근제', '#인센티브', '#코드리뷰',
                '#반바지/슬리퍼 OK', '#자유복장', '#맛있는간식냠냠', '#맥북으로개발', '#닉네임사용', '#수평적조직',
                '#반려동물', '#누적투자금100억이상', '#스톡옵션제공', '#도서구입비지원', '#택시비지원', '#병역특례', '#전공우대'
              ];
              return _buildWrapChips(options, localTags, modalSetState: modalSetState);
            }

            Widget buildLocalRegionFilter() {
              final options = ['서울', '경기', '인천', '부산', '대구', '광주', '대전', '울산', '제주'];
              return _buildWrapChips(options, localRegions, modalSetState: modalSetState);
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
                    const TabBar(
                      isScrollable: true,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      indicatorColor: Colors.black,
                      labelPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                      tabs: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Tab(text: 'My Repo'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Tab(text: '기술스택'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Tab(text: '직무'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Tab(text: '경력'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Tab(text: '지역'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // My Repo 탭은 기존 UI 그대로 사용
                          _buildRepoFilter(modalSetState),
                          buildLocalTechFilter(),
                          buildLocalTagFilter(),
                          buildLocalCareerFilter(),
                          buildLocalRegionFilter(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16).copyWith(bottom: 60),
                      child: ElevatedButton(
                        onPressed: () {
                          // 적용하기 버튼 클릭 시 Provider에 로컬 필터 값을 업데이트
                          final provider = Provider.of<SearchFilterProvider>(context, listen: false);
                          provider.updateCareer(localCareer);
                          provider.updateTechs(localTechs);
                          provider.updateTags(localTags);
                          provider.updateRegions(localRegions);
                          Navigator.pop(context); // 모달 닫기
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          "적용하기",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
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
      case 'My Repo':
        return 0;
      case '기술스택':
        return 1;
      case '직무':
        return 2;
      case '경력':
        return 3;
      case '지역':
        return 4;
      default:
        return 0;
    }
  }

  // My Repo 탭 UI (기존 Chip 방식)
  Widget _buildRepoFilter(StateSetter modalSetState) {
    if (_isRepoLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_repoOptions.isEmpty) {
      return const Center(child: Text("조회된 조합 레포지토리가 없습니다."));
    } else {
      return _buildWrapChips(_repoOptions, selectedRepo, isSingle: true, onSingleSelected: (val) {
        modalSetState(() {
          selectedRepo = val;
        });
      });
    }
  }

  // 기존 나머지 필터 UI (Provider와는 별도로, 모달 내 로컬 값으로 대체됨)
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
            showCheckmark: false,
            label: Text(text),
            selected: isSelected,
            selectedColor: const Color(0xFF3D3D3D),
            backgroundColor: const Color(0xFFF0F0F0),
            labelStyle: TextStyle(fontSize: 16, color: isSelected ? Colors.white : Colors.black),
            onSelected: (_) {
              if (onSingleSelected != null) onSingleSelected(text);
            },
          )
              : FilterChip(
            showCheckmark: false,
            label: Text(text),
            selected: isSelected,
            selectedColor: const Color(0xFF3D3D3D),
            backgroundColor: const Color(0xFFF0F0F0),
            labelStyle: TextStyle(fontSize: 16, color: isSelected ? Colors.white : Colors.black),
            onSelected: (selectedVal) {
              modalSetState?.call(() {
                if (selectedVal) {
                  selected.add(text);
                } else {
                  selected.remove(text);
                }
              });
              setState(() {});
            },
          );
        }).toList(),
      ),
    );
  }
}
