import 'package:flutter/material.dart';

class SearchBarWithFilters extends StatefulWidget {
  const SearchBarWithFilters({super.key});

  @override
  State<SearchBarWithFilters> createState() => _SearchBarWithFiltersState();
}

class _SearchBarWithFiltersState extends State<SearchBarWithFilters> {
  String selectedCareer = '전체';
  Set<String> selectedTags = {};
  Set<String> selectedTechs = {};
  Set<String> selectedRegions = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                      // labelPadding은 너무 작게 설정
                      labelPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                      tabs: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14), // 총 15 간격
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
                          _buildRepoFilter(modalSetState),
                          _buildTechFilter(modalSetState),
                          _buildTagFilter(modalSetState),
                          _buildCareerFilter(modalSetState),
                          _buildRegionFilter(modalSetState),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16).copyWith(bottom: 60),
                      child: ElevatedButton(
                        onPressed: () {
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
      case 'Repo':
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

  Widget _buildRepoFilter(StateSetter modalSetState) {
    final options = ['전체', 'Repo1', 'Repo2', 'Repo3', 'Repo4', 'Repo5'];
    return _buildWrapChips(options, selectedCareer, isSingle: true, onSingleSelected: (val) {
      modalSetState(() => selectedCareer = val);
    });
  }

  Widget _buildCareerFilter(StateSetter modalSetState) {
    final options = ['전체', '신입', '1년', '2년', '3년', '4년', '5년', '6년', '7년', '8년', '9년', '10년 이상'];
    return _buildWrapChips(options, selectedCareer, isSingle: true, onSingleSelected: (val) {
      modalSetState(() => selectedCareer = val);
    });
  }

  Widget _buildTagFilter(StateSetter modalSetState) {
    final options = [
      '#빅데이터 엔지니어', '#DBA', '#웹퍼블리셔', '#HW/임베디드', '#게임 클라이언트 개발자',
      '#VR/AR/3D', '#devops/시스템 엔지니어', '#기술지원', '#iOS 개발자', '#QA 엔지니어',
      '#블록체인', '#안드로이드 개발자', '#프론트엔드 개발자', '#정보보안 담당자', '#게임 서버 개발자',
      '#서버/백엔드 개발자', '#크로스플랫폼 앱개발자', '#개발 PM', '#웹 풀스택 개발자',
      '#SW/솔루션', '#인공지능/머신러닝'
    ];
    return _buildWrapChips(options, selectedTags, modalSetState: modalSetState);
  }

  Widget _buildTechFilter(StateSetter modalSetState) {
    final options = ['JavaScript', 'Python', 'Dart', 'Flutter', 'Spring', 'React', 'Node.js', 'Java'];
    return _buildWrapChips(options, selectedTechs, modalSetState: modalSetState);
  }

  Widget _buildRegionFilter(StateSetter modalSetState) {
    final options = ['서울', '경기', '인천', '부산', '대구', '광주', '대전', '울산', '제주'];
    return _buildWrapChips(options, selectedRegions, modalSetState: modalSetState);
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
