import 'package:flutter/material.dart';

class TermsServiceScreen extends StatelessWidget {
  const TermsServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 기본 AppBar (뒤로가기 버튼 포함)
      appBar: AppBar(
        title: const Text('서비스 이용 약관'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: const [
          ExpansionTile(
            title: Text('제1조: 서비스 목적'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '본 약관은 서비스 이용에 관한 기본 사항을 간단하게 정리한 것입니다.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('제2조: 이용자 의무'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '이용자는 서비스 이용 시 관련 법령과 본 약관을 준수해야 합니다.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('제3조: 서비스 제공'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '서비스는 회사의 정책에 따라 제공되며, 변경될 수 있습니다.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
