import 'package:flutter/material.dart';
import 'package:gittowork/widgets/app_bar.dart';
import '../../services/cover_letter_api.dart';

// 컴포넌트 위젯
import 'components/cover_letter_rose_chart.dart';
import 'components/cover_letter_ai_analysis_box.dart';
import 'components/cover_letter_pdf_viewer.dart';

class CoverLetterDetailScreen extends StatefulWidget {
  final int coverLetterId;

  const CoverLetterDetailScreen({super.key, required this.coverLetterId});

  @override
  State<CoverLetterDetailScreen> createState() =>
      _CoverLetterDetailScreenState();
}

class _CoverLetterDetailScreenState extends State<CoverLetterDetailScreen> {
  bool isLoading = false;
  // 분석 결과
  String? aiAnalysisResult;
  // 차트 데이터
  List<Map<String, dynamic>> roseData = [];
  // PDF URL
  String? pdfUrl;

  Future<void> _fetchCoverLetterAnalysis() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await CoverLetterApi.getCoverLetterAnalysis(widget.coverLetterId);

      final results = response['results'];
      if (results != null) {
        aiAnalysisResult = results['aiAnalysisResult'];
        pdfUrl = results['fileUrl'];

        final stat = results['stat'] as Map<String, dynamic>?;
        if (stat != null) {
          roseData = [
            {'name': '글로벌', 'value': stat['globalCapability'] ?? 0},
            {'name': '도전정신', 'value': stat['challengeSpirit'] ?? 0},
            {'name': '성실성', 'value': stat['sincerity'] ?? 0},
            {'name': '의사소통', 'value': stat['communicationSkill'] ?? 0},
            {'name': '성취지향성', 'value': stat['achievementOrientation'] ?? 0},
            {'name': '책임감', 'value': stat['responsibility'] ?? 0},
            {'name': '정직함', 'value': stat['honesty'] ?? 0},
            {'name': '창의성', 'value': stat['creativity'] ?? 0},
          ];
        }
      }
    } catch (e) {
      debugPrint(e.toString());
      // 에러 처리
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCoverLetterAnalysis();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 타이틀
            Row(
              children: const [
                Text(
                  '자기소개서 분석',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                // 원하면 로고 등 추가
              ],
            ),
            const SizedBox(height: 16),

            // 차트
            const Text(
              'AI 자기소개서 분석',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (roseData.isEmpty)
              const Text('분석 데이터가 없습니다.')
            else
              CoverLetterRoseChart(roseData: roseData),

            const SizedBox(height: 20),

            // AI 분석 컴포넌트
            CoverLetterAiAnalysisBox(aiAnalysisResult: aiAnalysisResult),

            const SizedBox(height: 20),

            // PDF 뷰어
            const Text(
              '자기소개서 (PDF)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (pdfUrl == null || pdfUrl!.isEmpty)
              const Text('PDF 파일이 없습니다.')
            else
            // PDF 컴포넌트 - flutter_pdfview 사용
              SizedBox(
                height: 500, // 원하는 높이
                child: CoverLetterPdfViewer(pdfUrl: pdfUrl!),
              ),
          ],
        ),
      ),
    );
  }
}
