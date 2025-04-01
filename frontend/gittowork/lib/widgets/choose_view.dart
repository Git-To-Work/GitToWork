import 'package:flutter/material.dart';
import 'package:gittowork/services/company_api.dart';

class ChooseView extends StatefulWidget {
  final int companyId;
  final bool initialLiked;
  final bool initialBlacklisted;

  const ChooseView({
    super.key,
    required this.companyId,
    required this.initialLiked,
    this.initialBlacklisted = false,
  });

  @override
  State<ChooseView> createState() => _ChooseViewState();
}

class _ChooseViewState extends State<ChooseView> {
  late bool isLiked;
  late bool isBlacklisted;

  @override
  void initState() {
    super.initState();
    isLiked = widget.initialLiked;
    isBlacklisted = widget.initialBlacklisted;
  }

  Future<void> _toggleLike() async {
    try {
      if (isLiked) {
        await CompanyApi.unlikeCompany(widget.companyId);
      } else {
        await CompanyApi.likeCompany(widget.companyId);
      }
      setState(() {
        isLiked = !isLiked;
      });
    } catch (e) {
      debugPrint("❌ 좋아요 요청 실패: $e");
    }
  }

  Future<void> _toggleBlacklist() async {
    try {
      if (isBlacklisted) {
        await CompanyApi.removeCompanyFromBlacklist(widget.companyId);
        setState(() {
          isBlacklisted = false;
        });
      } else {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("차단 확인"),
            content: const Text("해당 기업을 차단하시겠습니까?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("취소"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("확인"),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await CompanyApi.addCompanyToBlacklist(widget.companyId);
          setState(() {
            isBlacklisted = true;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ 차단 요청 실패: $e");
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
                            isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                            color: const Color(0xFF1976D2),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '좋아요',
                            style: TextStyle(
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
              // 차단 버튼
              Expanded(
                child: Material(
                  color: const Color(0xFFFFF2F0),
                  child: InkWell(
                    onTap: _toggleBlacklist,
                    splashColor: const Color(0xFFFFCDD2),
                    highlightColor: const Color(0xFFFFCDD2),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isBlacklisted ? Icons.block : Icons.block_outlined,
                            color: const Color(0xFFD32F2F),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isBlacklisted ? '차단 해제' : '차단',
                            style: const TextStyle(
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
