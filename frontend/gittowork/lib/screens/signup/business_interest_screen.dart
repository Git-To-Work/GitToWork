import 'package:flutter/material.dart';
import '../../widgets/app_bar.dart';

// 실제 DB에서 받아올 때, id/name/imageUrl 형태의 모델
class BusinessField {
  final int fieldId;
  final String fieldName;
  final String logoUrl;
  bool isSelected;

  BusinessField({
    required this.fieldId,
    required this.fieldName,
    required this.logoUrl,
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
    Key? key,
    required Map signupParams,
  })  : isSignUp = true,
        signupParams = signupParams,
        initialSelectedFields = const [],
        super(key: key);

  /// 회원정보 수정 시나리오용 named constructor
  const BusinessInterestScreen.edit({
    Key? key,
    required List<String> initialSelectedFields,
  })  : isSignUp = false,
        signupParams = null,
        initialSelectedFields = initialSelectedFields,
        super(key: key);

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

  // 백엔드에서 비즈니스 분야 리스트를 가져오는 로직 (가짜 예시)
  Future<void> _fetchBusinessFields() async {
    // TODO: 실제 ApiService 등을 사용하여 백엔드에서 받아오세요.
    final fetchedFields = [
      BusinessField(fieldId: 1, fieldName: "솔루션 SI", logoUrl: "https://picsum.photos/200/120"),
      BusinessField(fieldId: 2, fieldName: "game", logoUrl: "https://picsum.photos/200/120"),
      BusinessField(fieldId: 3, fieldName: "클라우드", logoUrl: "https://picsum.photos/200/120"),
      BusinessField(fieldId: 4, fieldName: "인프라", logoUrl: "https://picsum.photos/200/120"),
      BusinessField(fieldId: 5, fieldName: "빅데이터", logoUrl: "https://picsum.photos/200/120"),
      BusinessField(fieldId: 6, fieldName: "AI", logoUrl: "https://picsum.photos/200/120"),
      BusinessField(fieldId: 7, fieldName: "블록체인", logoUrl: "https://picsum.photos/200/120"),
      BusinessField(fieldId: 8, fieldName: "IoT", logoUrl: "https://picsum.photos/200/120"),
      BusinessField(fieldId: 9, fieldName: "보안", logoUrl: "https://picsum.photos/200/120"),
      BusinessField(fieldId: 10, fieldName: "로봇", logoUrl: "https://picsum.photos/200/120"),
      BusinessField(fieldId: 11, fieldName: "커머스", logoUrl: "https://picsum.photos/200/120"),
      BusinessField(fieldId: 12, fieldName: "핀테크", logoUrl: "https://picsum.photos/200/120"),
      // ...
    ];

    // 이미 선택된 분야(수정 시나리오)를 반영
    // widget.initialSelectedFields 에 포함된 분야명과 동일하면 isSelected = true
    for (final field in fetchedFields) {
      if (widget.initialSelectedFields.contains(field.fieldName)) {
        field.isSelected = true;
      }
    }

    setState(() {
      businessFields = fetchedFields;
    });

    if (widget.isSignUp) {
      // 디버그용
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

  // 선택 완료 버튼 누르면 호출
  void _onComplete() {
    // 선택된 항목들만 추려내기
    final selectedFields = businessFields.where((field) => field.isSelected).toList();

    // 분야명만 추출 (["빅데이터", "AI", ...])
    final selectedNames = selectedFields.map((f) => f.fieldName).toList();

    if (widget.isSignUp) {
      // 회원가입 시나리오
      widget.signupParams?['interestsFields'] = selectedNames;
      debugPrint("최종 회원가입 정보: ${widget.signupParams}");

      // TODO: 백엔드로 회원가입 정보 전송 etc.
      // 예) ApiService.sendSignupData(widget.signupParams!);

      // 전송 후 다음 화면으로 이동하거나 완료 처리
      // 여기서는 그냥 pop
      Navigator.pop(context);
    } else {
      // 회원정보 수정 시나리오
      // 선택 결과를 MyInfoEditScreen으로 돌려주어 거기서 반영
      Navigator.pop(context, selectedNames);
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
                        return InkWell(
                          onTap: () => _toggleSelect(index),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 이미지와 선택 체크 아이콘은 Stack으로 구현
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      field.logoUrl,
                                      width: 180,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
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
