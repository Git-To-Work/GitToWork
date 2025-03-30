import 'package:flutter/material.dart';
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
      appBar: AppBar(
        title: const Text('자기소개서 상세보기'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI 자기소개서 분석',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  roseData.isEmpty
                      ? const Text('분석 데이터가 없습니다.')
                      : CoverLetterRoseChart(roseData: roseData),
                  const SizedBox(height: 20),
                  CoverLetterAiAnalysisBox(aiAnalysisResult: aiAnalysisResult),
                  const SizedBox(height: 20),
                  const Text(
                    '자기소개서 (PDF)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (pdfUrl == null || pdfUrl!.isEmpty)
                    const Text('PDF 파일이 없습니다.'),
                  if (pdfUrl != null && pdfUrl!.isNotEmpty)
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: CoverLetterPdfViewer(pdfUrl: pdfUrl!),
                    ),
                  // cover_letter_detail_screen.dart의 PDF 뷰어 하단에 추가
                  ElevatedButton.icon(
                    icon: const Icon(Icons.fullscreen),
                    label: const Text('PDF 전체 화면 보기'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => Scaffold(
                            appBar: AppBar(title: const Text('PDF 전체 보기')),
                            body: CoverLetterPdfViewer(pdfUrl: pdfUrl!),
                          ),
                        ),
                      );
                    },
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
