import 'package:flutter/material.dart';
import '../../layouts/appbar_bottom_nav_layout.dart';
import '../../services/user_api.dart'; // 수정: user_api.dart 사용
import '../../widgets/app_bar.dart';

// 실제 DB에서 받아올 때, id/name/logoUrl 형태의 모델
class BusinessField {
  final int fieldId;
  final String fieldName;
  final String? logoUrl; // nullable로 변경
  bool isSelected;

  BusinessField({
    required this.fieldId,
    required this.fieldName,
    this.logoUrl, // 필수 아니도록 변경
    this.isSelected = false,
  });
}

class BusinessInterestScreen extends StatefulWidget {
  /// 회원가입 시나리오 여부
  final bool isSignUp;

  /// 회원가입 시, 이전 화면에서 넘겨받은 회원가입 파라미터
  final Map? signupParams;

  /// 회원정보 수정 시, 이미 선택되어 있는 분야들 (분야명 리스트)
  final List<String> initialSelectedFields;

  /// 회원가입 시나리오용 생성자
  const BusinessInterestScreen({
    super.key,
    required Map signupParams,
  })  : isSignUp = true,
        signupParams = signupParams,
        initialSelectedFields = const [];

  /// 회원정보 수정 시나리오용 named constructor
  const BusinessInterestScreen.edit({
    super.key,
    required List<String> initialSelectedFields,
  })  : isSignUp = false,
        signupParams = null,
        initialSelectedFields = initialSelectedFields;

  @override
  State<BusinessInterestScreen> createState() => _BusinessInterestScreenState();
}

class _BusinessInterestScreenState extends State<BusinessInterestScreen> {
  // 실제로는 백엔드에서 받아온 데이터를 여기에 저장
  List<BusinessField> businessFields = [];

  @override
  void initState() {
    super.initState();
    _fetchBusinessFields();
  }

  Future<void> _fetchBusinessFields() async {
    final fetchedFields = await UserApi.fetchInterestFields();

    for (final field in fetchedFields) {
      if (widget.initialSelectedFields.contains(field.fieldName)) {
        field.isSelected = true;
      }
    }

    setState(() {
      businessFields = fetchedFields;
    });

    if (widget.isSignUp) {
      debugPrint("이전 회원가입 파라미터: ${widget.signupParams}");
    }
  }

  // 아이템을 탭했을 때 선택/해제 로직
  void _toggleSelect(int index) {
    // 현재 이미 선택된 항목 수
    final selectedCount = businessFields.where((field) => field.isSelected).length;

    // 새로 선택하려고 하는데 이미 5개가 선택된 상태면 막기
    if (!businessFields[index].isSelected && selectedCount >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최대 5개까지 선택할 수 있습니다.')),
      );
      return;
    }

    setState(() {
      businessFields[index].isSelected = !businessFields[index].isSelected;
    });
  }

  Future<void> _onComplete() async {
    final selectedFields = businessFields
        .where((field) => field.isSelected)
        .map((f) => f.fieldId)
        .toList();

    if (widget.isSignUp) {
      widget.signupParams?['interestsFields'] = selectedFields;
      final isSignupSuccess = await UserApi.sendSignupData(widget.signupParams!);
      if (isSignupSuccess) {
        final isUpdated = await UserApi.updateInterestFields(selectedFields);
        if (isUpdated) {
          Navigator.pop(context, selectedFields);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('관심 분야 업데이트 실패')),
          );
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AppBarBottomNavLayout()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입에 실패했습니다.')),
        );
      }
    } else {
      final isUpdated = await UserApi.updateInterestFields(selectedFields);
      if (isUpdated) {
        Navigator.pop(context, selectedFields);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('관심 분야 업데이트 실패')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 아직 데이터를 못 받아왔을 경우 로딩 표시
    if (businessFields.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 30.0, bottom: 16.0),
                    child: Text(
                      '관심 비즈니스 분야',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 30.0),
                    child: Wrap(
                      spacing: 30, // 가로 간격
                      runSpacing: 30, // 세로 간격
                      children: List.generate(businessFields.length, (index) {
                        final field = businessFields[index];

                        // logoUrl이 없을 경우에 대한 예외 처리
                        final imageUrl = field.logoUrl;
                        final hasLogo = imageUrl != null && imageUrl.isNotEmpty;

                        return InkWell(
                          onTap: () => _toggleSelect(index),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 이미지와 선택 체크 아이콘은 Stack으로 구현
                              Stack(
                                children: [
                                  // logoUrl이 null이거나 빈 문자열이면 기본 Placeholder 처리
                                  hasLogo
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      imageUrl!,
                                      width: 180,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                      : Container(
                                    width: 180,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text('No Image'),
                                  ),
                                  if (field.isSelected)
                                    const Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 24,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                field.fieldName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF7C7C7C),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // 하단 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Container(
              width: double.infinity,
              height: 70,
              color: const Color(0xFF2C2C2C),
              child: Center(
                child: GestureDetector(
                  onTap: _onComplete,
                  child: const Text(
                    '선택 완료',
                    style: TextStyle(
                      color: Color(0xFFD6D6D6),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 100), // 네비게이션 바 위로 여백
        ],
      ),
    );
  }
}
