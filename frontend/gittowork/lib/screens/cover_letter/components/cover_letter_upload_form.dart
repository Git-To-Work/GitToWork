import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gittowork/services/cover_letter_api.dart';

class CoverLetterUploadForm extends StatefulWidget {
  const CoverLetterUploadForm({Key? key}) : super(key: key);

  @override
  State<CoverLetterUploadForm> createState() => CoverLetterUploadFormState();
}

class CoverLetterUploadFormState extends State<CoverLetterUploadForm> {
  File? selectedFile;
  final titleController = TextEditingController();

  final titleSuggestions = [
    '성장하는 개발자',
    '열정을 가진 엔지니어',
    '협업을 즐기는 개발자',
  ];

  void pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result?.files.single.path != null) {
      setState(() {
        selectedFile = File(result!.files.single.path!);
      });
    }
  }

  /// 부모(스크린)에서 호출할 수 있도록 public 메서드로 만듦
  void submitCoverLetter() async {
    if (selectedFile == null || titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('파일과 제목을 모두 입력해주세요.')),
      );
      return;
    }

    try {
      await CoverLetterApi.createCoverLetter(
        title: titleController.text,
        file: selectedFile!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자기소개서가 성공적으로 업로드되었습니다.')),
      );
      Navigator.pop(context);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 실패: $e')),
      );
    }
  }

  void showSuggestions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: titleSuggestions.map((title) {
          return ListTile(
            title: Text(title),
            onTap: () {
              setState(() => titleController.text = title);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '자기소개서 파일 업로드',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
        ),
        const SizedBox(height: 10),

        // 파일 선택 박스
        GestureDetector(
          onTap: pickFile,
          child: Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey, style: BorderStyle.solid),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.attach_file, size: 30, color: Colors.orange),
                const SizedBox(height: 5),
                selectedFile == null
                    ? RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: '자기소개서',
                        style: TextStyle(
                          color: Color(0xFFFF8C00), // #FF8C00
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' 파일을 선택해주세요',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                    : Text(
                  selectedFile!.path.split('/').last,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'PDF 파일을 업로드해주세요',
          style: TextStyle(fontWeight: FontWeight.w300, fontSize: 15),
        ),
        const SizedBox(height: 30),

        // 자기소개서 제목
        const Text(
          '자기소개서 제목',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: titleController,
          decoration: InputDecoration(
            hintText: '제목을 입력해주세요',
            suffixIconConstraints: const BoxConstraints(
              minWidth: 80,
              minHeight: 40,
            ),
            suffixIcon: GestureDetector(
              onTap: showSuggestions,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Text(
                  '추천 ▼',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}
