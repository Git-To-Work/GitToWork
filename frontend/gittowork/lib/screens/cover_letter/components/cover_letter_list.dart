import 'package:flutter/material.dart';
import '../../../services/cover_letter_api.dart';
import '../cover_letter_detail_screen.dart';
import 'cover_letter_card.dart';

class CoverLetterData {
  final int fileId;
  final String fileName;
  final String title;
  final String fileUrl;
  final String date;

  CoverLetterData({
    required this.fileId,
    required this.fileName,
    required this.title,
    required this.fileUrl,
    required this.date,
  });

  // 서버 응답 JSON 구조를 받아서 모델로 변환
  factory CoverLetterData.fromJson(Map<String, dynamic> json) {
    return CoverLetterData(
      fileId: json['fileId'] ?? 0,
      fileName: json['fileName'] ?? '',
      title: json['title'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      // 아직 createDttm 이 없으므로 일단 빈 문자열로 처리. 추후 API가 date를 넘겨주면 교체
      date: json['createDttm'] ?? '',
    );
  }
}

class CoverLetterList extends StatefulWidget {
  const CoverLetterList({super.key});

  @override
  State<CoverLetterList> createState() => _CoverLetterListState();
}

class _CoverLetterListState extends State<CoverLetterList> {
  // API에서 받아온 실제 자기소개서 목록
  List<CoverLetterData> coverLetters = [];

  @override
  void initState() {
    super.initState();
    _loadCoverLetters();
  }

  // 서버로부터 자기소개서 목록을 가져와서 상태 업데이트
  Future<void> _loadCoverLetters() async {
    try {
      final responseList = await CoverLetterApi.fetchCoverLetterList();
      setState(() {
        coverLetters = responseList
            .map((item) => CoverLetterData.fromJson(item))
            .toList();
      });
    } catch (e) {
      // 실제 앱에서는 에러 처리 로직 추가
      debugPrint('자기소개서 목록 불러오기 실패: $e');
    }
  }

  // 특정 자기소개서를 삭제
  Future<void> _deleteCoverLetter(int coverLetterId) async {
    try {
      await CoverLetterApi.deleteCoverLetter(coverLetterId);

      // 삭제 성공 후, 리스트에서 해당 아이템만 제거
      setState(() {
        coverLetters.removeWhere((coverLetter) => coverLetter.fileId == coverLetterId);
      });
    } catch (e) {
      // 실제 앱에서는 에러 처리 로직 추가
      debugPrint('자기소개서 삭제 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: coverLetters.length,
      separatorBuilder: (BuildContext context, int index) =>
      const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final coverLetter = coverLetters[index];
        return InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (ctx) {
                return SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.95, // 화면 거의 전체 차지
                  child: CoverLetterDetailScreen(
                    coverLetterId: coverLetter.fileId,
                  ),
                );
              },
            );
          },
          child: Padding(
            padding: EdgeInsets.zero,
            child: CoverLetterCard(
              // card 위젯으로 제목, 날짜, 삭제 버튼 등을 표시한다고 가정
              date: coverLetter.date.isNotEmpty ? coverLetter.date : '',
              title: coverLetter.title,
              onDelete: () async {
                final confirmDelete = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('삭제 확인'),
                    content: const Text('정말 이 자기소개서를 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                );
                // 사용자가 "삭제"를 눌렀을 때만 실제 삭제
                if (confirmDelete == true) {
                  _deleteCoverLetter(coverLetter.fileId);
                }
              },
            ),
          ),
        );
      },
    );
  }
}