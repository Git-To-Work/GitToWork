import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// flutter_pdfview는 로컬 파일 경로(String)를 넣어줘야 합니다.
/// 따라서 URL로부터 PDF 파일을 다운로드 후 임시 디렉토리에 저장하고
/// 그 파일 경로를 PDFView에 넘겨주는 방식입니다.

class CoverLetterPdfViewer extends StatefulWidget {
  final String pdfUrl;

  const CoverLetterPdfViewer({
    super.key,
    required this.pdfUrl,
  });

  @override
  State<CoverLetterPdfViewer> createState() => _CoverLetterPdfViewerState();
}

class _CoverLetterPdfViewerState extends State<CoverLetterPdfViewer> {
  String? localPdfPath;
  bool isReady = false;
  int totalPages = 0;
  int currentPage = 0;
  late PDFViewController pdfViewController;

  @override
  void initState() {
    super.initState();
    _downloadAndSavePdf();
  }

  Future<void> _downloadAndSavePdf() async {
    try {
      final url = Uri.parse(widget.pdfUrl);
      final response = await http.get(url);
      final bytes = response.bodyBytes;

      // 임시 디렉토리
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/temp_view.pdf');
      await file.writeAsBytes(bytes, flush: true);

      setState(() {
        localPdfPath = file.path;
      });
    } catch (e) {
      debugPrint('PDF 다운로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (localPdfPath == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        PDFView(
          filePath: localPdfPath,
          swipeHorizontal: false,
          autoSpacing: true,
          pageSnap: true,
          pageFling: true,
          onRender: (_pages) {
            setState(() {
              totalPages = _pages!;
              isReady = true;
            });
          },
          onViewCreated: (PDFViewController vc) {
            pdfViewController = vc;
          },
          onPageChanged: (index, _) {
            setState(() {
              currentPage = index!;
            });
          },
          onError: (error) {
            debugPrint(error.toString());
          },
          onPageError: (page, error) {
            debugPrint('$page 페이지 에러: $error');
          },
        ),
        if (!isReady)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
