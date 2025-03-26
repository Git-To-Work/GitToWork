import 'package:flutter/material.dart';
import 'cover_letter_card.dart';

class CoverLetterData {
  final String date;
  final String title;

  CoverLetterData({required this.date, required this.title});
}

class CoverLetterList extends StatelessWidget {
  CoverLetterList({super.key});

  // TODO: Replace 실제 데이터와 변경
  final List<CoverLetterData> coverLetters = [
    CoverLetterData(date: '2023-10-26 10:10', title: '컴퓨터공학과 전공으로 준비된 인재'),
    CoverLetterData(date: '2023-10-25 11:15', title: '웹 개발 전문가로서의 역량 어필'),
    CoverLetterData(date: '2023-10-24 09:30', title: '인공지능 분야 연구 경험 강조'),
    CoverLetterData(date: '2023-10-23 14:45', title: '클라우드 기반 서비스 구축 경험'),
    CoverLetterData(date: '2023-10-22 16:20', title: '데이터 분석 및 활용 능력'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: coverLetters.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final coverLetter = coverLetters[index];
        return Padding(
          padding: EdgeInsets.zero,

          child: CoverLetterCard(
            date: coverLetter.date,
            title: coverLetter.title,

            onDelete: () {
              // 삭제 로직 추가
            },
          ),
        );
      },
    );
  }
}
