import 'package:flutter/material.dart';

class LuckyInput extends StatelessWidget {
  final TextEditingController birthDateController;
  final String selectedTime;
  final String selectedGender;
  final Function(String) onTimeChanged;
  final Function(String) onGenderChanged;
  final VoidCallback onSubmit;

  const LuckyInput({
    super.key,
    required this.birthDateController,
    required this.selectedTime,
    required this.selectedGender,
    required this.onTimeChanged,
    required this.onGenderChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
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
          // 생년월일 텍스트필드
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _roundedTextField(
              controller: birthDateController,
              label: '생년월일',
              hint: '예: 19990723',
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: 12),
          // 태어난 시간 및 성별 선택 row (태어난 시간 : 성별 = 3:2 비율)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 태어난 시간 BottomPicker (flex: 3)
                Expanded(
                  flex: 3,
                  child: _timeBottomPicker(context),
                ),
                const SizedBox(width: 12),
                // 성별 BottomPicker (flex: 2)
                Expanded(
                  flex: 2,
                  child: _genderBottomPicker(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          // 운세 보기 버튼
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
              onPressed: onSubmit,
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
    TextEditingController? controller,
    required String label,
    String? hint,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _genderBottomPicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '성별',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            // 바텀시트로 남성/여성 선택 (높이를 지정해서 띄움)
            final result = await showModalBottomSheet<String>(
              context: context,
              builder: (BuildContext context) {
                return SafeArea(
                  child: SizedBox(
                    height: 150, // 원하는 높이로 지정 (예: 150)
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('남성'),
                          onTap: () {
                            Navigator.pop(context, '남성');
                          },
                        ),
                        ListTile(
                          title: const Text('여성'),
                          onTap: () {
                            Navigator.pop(context, '여성');
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

            if (result != null) {
              onGenderChanged(result);
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
                  selectedGender.isNotEmpty ? selectedGender : '눌러서 선택',
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


  Widget _timeBottomPicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '태어난 시간',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            // 30분 단위 시간 옵션 생성 (00:00 ~ 23:30)
            List<String> timeOptions = [];
            for (int hour = 0; hour < 24; hour++) {
              timeOptions.add('${hour.toString().padLeft(2, '0')}:00');
              timeOptions.add('${hour.toString().padLeft(2, '0')}:30');
            }

            final result = await showModalBottomSheet<String>(
              context: context,
              builder: (BuildContext context) {
                return SafeArea(
                  child: SizedBox(
                    // 높이를 제한해서 스크롤 가능하도록 함
                    height: 300,
                    child: ListView.builder(
                      itemCount: timeOptions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(timeOptions[index]),
                          onTap: () {
                            Navigator.pop(context, timeOptions[index]);
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            );

            if (result != null) {
              onTimeChanged(result);
            }
          },
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedTime.isNotEmpty ? selectedTime : '눌러서 선택',
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
}
