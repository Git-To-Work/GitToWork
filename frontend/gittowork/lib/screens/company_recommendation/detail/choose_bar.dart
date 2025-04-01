import 'package:flutter/material.dart';
import 'package:gittowork/services/company_api.dart';

class ChooseView extends StatefulWidget {
  final int companyId;
  final bool initialLiked;

  const ChooseView({
    super.key,
    required this.companyId,
    required this.initialLiked,
  });

  @override
  State<ChooseView> createState() => _ChooseViewState();
}

class _ChooseViewState extends State<ChooseView> {
  late bool isLiked;

  @override
  void initState() {
    super.initState();
    isLiked = widget.initialLiked;
  }

  Future<void> _toggleLike() async {
    try {
      String message;
      if (isLiked) {
        await CompanyApi.unlikeCompany(widget.companyId);
      } else {
        await CompanyApi.likeCompany(widget.companyId);
      }

      setState(() {
        isLiked = !isLiked;
      });

    } catch (e) {
      debugPrint("❌좋아요 요청 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 60,
          child: Row(
            children: [
              // 좋아요 버튼
              Expanded(
                child: Material(
                  color: const Color(0xFFF0F5FF),
                  child: InkWell(
                    onTap: _toggleLike,
                    splashColor: const Color(0xFFBBDEFB),
                    highlightColor: const Color(0xFFBBDEFB),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLiked
                                ? Icons.thumb_up_alt
                                : Icons.thumb_up_alt_outlined,
                            color: const Color(0xFF1976D2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '좋아요',
                            style: const TextStyle(
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 차단 버튼 (추후 구현 가능)
              Expanded(
                child: Material(
                  color: const Color(0xFFFFF2F0),
                  child: InkWell(
                    onTap: () {
                      // TODO: 차단 기능 연결 시 구현
                    },
                    splashColor: const Color(0xFFFFCDD2),
                    highlightColor: const Color(0xFFFFCDD2),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.block, color: Color(0xFFD32F2F)),
                          SizedBox(width: 8),
                          Text(
                            '차단',
                            style: TextStyle(
                              color: Color(0xFFD32F2F),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
