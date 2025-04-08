import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../layouts/appbar_bottom_nav_layout.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_api.dart';
import '../../widgets/app_bar.dart';

// ────────────────────────────────────────────────────────────
// 모델
// ────────────────────────────────────────────────────────────
class BusinessField {
  final int fieldId;
  final String fieldName;
  final String? logoUrl;
  bool isSelected;

  BusinessField({
    required this.fieldId,
    required this.fieldName,
    this.logoUrl,
    this.isSelected = false,
  });
}

// ────────────────────────────────────────────────────────────
// 화면
// ────────────────────────────────────────────────────────────
class BusinessInterestScreen extends StatefulWidget {
  final bool isSignUp;
  final Map? signupParams;
  final List<String> initialSelectedFields;

  const BusinessInterestScreen({
    super.key,
    required Map signupParams,
  })  : isSignUp = true,
        signupParams = signupParams,
        initialSelectedFields = const [];

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
  List<BusinessField> businessFields = [];

  @override
  void initState() {
    super.initState();
    _fetchBusinessFields();
  }

  Future<void> _fetchBusinessFields() async {
    final fetchedFields = await UserApi.fetchInterestFields();

    // "분류없음" 제거
    fetchedFields.removeWhere((field) => field.fieldName == "분류없음");

    for (final field in fetchedFields) {
      if (widget.initialSelectedFields.contains(field.fieldName)) {
        field.isSelected = true;
      }
    }

    setState(() => businessFields = fetchedFields);
  }

  void _toggleSelect(int index) {
    final selectedCount =
        businessFields.where((field) => field.isSelected).length;

    if (!businessFields[index].isSelected && selectedCount >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최대 5개까지 선택할 수 있습니다.')),
      );
      return;
    }

    setState(() => businessFields[index].isSelected =
    !businessFields[index].isSelected);
  }

  Future<void> _onComplete() async {
    final selectedFieldIds = businessFields
        .where((f) => f.isSelected)
        .map((f) => f.fieldId)
        .toList();

    final selectedFieldNames =
    businessFields.where((f) => f.isSelected).map((f) => f.fieldName).toList();

    if (widget.isSignUp) {
      widget.signupParams?['interestsFields'] = selectedFieldIds;
      final ok = await UserApi.sendSignupData(widget.signupParams!);
      if (!ok) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('회원가입에 실패했습니다.')));
        return;
      }

      try {
        final profile = await UserApi.fetchUserProfile();
        context.read<AuthProvider>().setUserProfile(profile);
      } catch (_) {}

      if (widget.signupParams?['notificationAgreed'] == true) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) await UserApi.updateFcmToken(token);
      }

      await UserApi.updateInterestFields(selectedFieldIds);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppBarBottomNavLayout()),
            (_) => false,
      );
    } else {
      final ok = await UserApi.updateInterestFields(selectedFieldIds);
      if (ok) {
        Navigator.pop(context, {
          'fieldNames': selectedFieldNames,
          'fieldIds': selectedFieldIds,
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('관심 분야 업데이트 실패')));
      }
    }
  }

  // ──────────────────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (businessFields.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool hasOdd = businessFields.length.isOdd;
    final int gridCount =
    hasOdd ? businessFields.length - 1 : businessFields.length;
    final int? lastIndex = hasOdd ? businessFields.length - 1 : null;

    return Scaffold(
      appBar: const CustomAppBar(),
      // ① 스크롤 가능한 본문
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 15, bottom: 16),
              child: Text(
                '관심 비즈니스 분야',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
              ),
            ),

            // 2열 Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gridCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1.3,
              ),
              itemBuilder: (_, idx) => _buildFieldItem(idx),
            ),

            // 남은 1개
            if (hasOdd) ...[
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width/2,
                  child: _buildFieldItem(lastIndex!),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),

      // ② 하단 고정 버튼 (SafeArea로 overflow 방지)
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 30),
        child: SizedBox(
          height: 70,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C2C2C),
            ),
            onPressed: _onComplete,
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
    );
  }

  // ──────────────────────────────────────────────────────────
  // 공통 아이템 위젯
  // ──────────────────────────────────────────────────────────
  Widget _buildFieldItem(int index) {
    final field = businessFields[index];
    final imageUrl = field.logoUrl;
    final hasLogo = imageUrl != null && imageUrl.isNotEmpty;

    return InkWell(
      onTap: () => _toggleSelect(index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              hasLogo
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl!,
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              )
                  : Container(
                width: double.infinity,
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
                  child: Icon(Icons.check_circle,
                      color: Colors.green, size: 24),
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
  }
}
