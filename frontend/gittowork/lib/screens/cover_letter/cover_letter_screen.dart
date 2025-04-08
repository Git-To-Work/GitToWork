import 'package:flutter/material.dart';
import '../entertainment/quiz_screen.dart';
import 'cover_letter_create_screen.dart';
import 'package:gittowork/widgets/app_bar.dart';
import 'components/cover_letter_list.dart';

class CoverLetterScreen extends StatelessWidget {
  const CoverLetterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      // 이미 NavigationBar를 따로 구성하셨다면 Scaffold의 bottomNavigationBar 등으로 추가
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '자기소개서',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            // 1) 퀴즈 페이지 이동 버튼
            InkWell(
              onTap: () {
                // TODO: 개발자 퀴즈 페이지 이동 로직 추가
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuizScreen()),
                );
              },
              child:  Container(
                width: double.infinity,
                height: 90,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("assets/images/skycolor.png"),
                      fit: BoxFit.cover),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '자소서 이렇게 작성하면 된다!',
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFF488EE3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.blue,
                      size: 48,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // 2) 자기소개서 등록 버튼
            InkWell(
              onTap: () {
                // 자기소개서 등록 페이지 이동 로직
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CoverLetterCreateScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '+자기소개서 등록',
                  style: TextStyle(
                    fontSize: 22,
                    color: Color(0xFFD6D6D6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),

            const Text(
              '자기소개서 관리',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 15),

            // 3) 자기소개서 리스트
            CoverLetterList(),
          ],
        ),
      ),
    );
  }
}
