import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/lucky_provider.dart';
import '../../services/lucky_api.dart';

class LuckyInput extends StatefulWidget {
  final VoidCallback onSubmit;

  const LuckyInput({super.key, required this.onSubmit});

  @override
  State<LuckyInput> createState() => _LuckyInputState();
}

class _LuckyInputState extends State<LuckyInput> {
  final TextEditingController _birthDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint("열림");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final luckyProvider = Provider.of<LuckyProvider>(context, listen: false);
      _birthDateController.text = luckyProvider.birthDate;
      LuckyService.getFortuneUserInfoWithProvider(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final luckyProvider = Provider.of<LuckyProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _roundedTextField(
              controller: _birthDateController,
              label: '생년월일',
              hint: '예: 1999-07-23',
              keyboardType: TextInputType.number,
              onChanged: (val) => luckyProvider.setBirthDate(val),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _timeBottomPicker(context, luckyProvider),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _genderBottomPicker(context, luckyProvider),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
              ),
              onPressed: () async {
                final luckyProvider = Provider.of<LuckyProvider>(context, listen: false);
                luckyProvider.setAll(
                  birthDate: _birthDateController.text,
                  gender: luckyProvider.gender,
                  birthTime: luckyProvider.birthTime,
                );

                luckyProvider.setLoading();

                try {
                  await LuckyService.saveFortuneUserInfo(context);
                } catch (e) {
                  debugPrint('❌ 유저 정보 저장 실패: $e');
                }

                try {
                  await LuckyService.getTodayFortune(context);
                } catch (e) {
                  debugPrint('❌ 운세 조회 실패: $e');
                }
              },

              child: const Text(
                '운세 보기',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundedTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _genderBottomPicker(BuildContext context, LuckyProvider luckyProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('성별', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final result = await showModalBottomSheet<String>(
              context: context,
              builder: (context) => SafeArea(
                child: SizedBox(
                  height: 150,
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('남성'),
                        onTap: () => Navigator.pop(context, '남성'),
                      ),
                      ListTile(
                        title: const Text('여성'),
                        onTap: () => Navigator.pop(context, '여성'),
                      ),
                    ],
                  ),
                ),
              ),
            );
            if (result != null) {
              luckyProvider.setGender(result);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  luckyProvider.gender.isNotEmpty ? luckyProvider.gender : '눌러서 선택',
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeBottomPicker(BuildContext context, LuckyProvider luckyProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('태어난 시간', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            List<String> timeOptions = [];

            for (int hour = 0; hour < 24; hour++) {
              for (int minute = 0; minute < 60; minute += 30) {
                final startHour = hour;
                final startMinute = minute;

                int endHour = hour;
                int endMinute = minute + 30;

                if (endMinute >= 60) {
                  endMinute = 0;
                  endHour = (hour + 1) % 24; // 23:30 → 00:00
                }

                final start = '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
                final end = '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

                timeOptions.add('$start ~ $end');
              }
            }


            final result = await showModalBottomSheet<String>(
              context: context,
              builder: (context) => SafeArea(
                child: SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: timeOptions.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(timeOptions[index]),
                      onTap: () => Navigator.pop(context, timeOptions[index]),
                    ),
                  ),
                ),
              ),
            );

            if (result != null) {
              luckyProvider.setBirthTime(result);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatTimeRange(luckyProvider.birthTime),
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 🔹 "11:00" -> "11:00 ~ 11:30"
  String formatTimeRange(String time) {
    if (time.isEmpty) return '눌러서 선택';

    // '11:00 ~ 11:30' 형식에서 시작 시간만 추출
    final start = time.split(' ~ ')[0];

    final parts = start.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    int nextHour = hour;
    int nextMinute = minute + 30;
    if (nextMinute >= 60) {
      nextMinute -= 60;
      nextHour = (nextHour + 1) % 24;
    }

    final end = '${nextHour.toString().padLeft(2, '0')}:${nextMinute.toString().padLeft(2, '0')}';
    return '$start ~ $end';
  }

}
