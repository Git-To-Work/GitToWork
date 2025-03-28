package com.gittowork.domain.coverletter.sevice;

import com.gittowork.domain.coverletter.entity.CoverLetter;
import com.gittowork.domain.coverletter.entity.CoverLetterAnalysis;
import com.gittowork.domain.coverletter.repository.CoverLetterAnalysisRepository;
import com.gittowork.domain.user.entity.User;
import com.gittowork.global.exception.EmptyFileException;
import com.gittowork.global.service.GptService;
import lombok.RequiredArgsConstructor;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;

@Service
@RequiredArgsConstructor
public class CoverLetterAnalysisService {

    private final CoverLetterAnalysisRepository coverLetterAnalysisRepository;
    private final GptService gptService;

    /**
     * 1. 메서드 설명: 비동기적으로 전달받은 자기소개서 PDF 파일을 분석하여,
     *    PDFBox를 사용해 텍스트를 추출한 후, GPT 서비스를 호출하여 분석 결과를 도출하고,
     *    해당 결과를 CoverLetterAnalysis 엔티티에 저장합니다.
     * 2. 로직:
     *    - 파일 유효성을 검사하고, MultipartFile을 임시 파일로 저장합니다.
     *    - try-with-resources 구문을 사용해 PDDocument를 로드하고 PDFTextStripper로 텍스트를 추출합니다.
     *    - 추출한 텍스트를 기반으로 GPT 서비스를 호출하여 분석 결과를 생성합니다.
     *    - 생성된 분석 결과에 CoverLetter와 User 정보를 설정하고 DB에 저장합니다.
     * 3. param:
     *      - file: 사용자가 업로드한 자기소개서 PDF 파일.
     *      - coverLetter: 파일과 연결된 CoverLetter 엔티티.
     *      - user: 분석 요청을 수행하는 사용자 엔티티.
     * 4. return: 없음 (비동기 작업으로 처리되며, 분석 결과는 DB에 저장됩니다).
     */
    @Async
    @Transactional
    public void coverLetterAnalysis(MultipartFile file, CoverLetter coverLetter, User user) {
        if (file == null || file.isEmpty() || file.getOriginalFilename() == null) {
            throw new EmptyFileException("Empty file input");
        }
        try {
            File tempFile = File.createTempFile(file.getOriginalFilename(), ".pdf");
            file.transferTo(tempFile);

            String content;
            try (PDDocument document = PDDocument.load(tempFile)) {
                content = new PDFTextStripper().getText(document);
            }

            CoverLetterAnalysis analysisResult = gptService.coverLetterAnalysis(content, 500);
            analysisResult.setFile(coverLetter);
            analysisResult.setUser(user);
            coverLetterAnalysisRepository.save(analysisResult);
        } catch (IOException e) {
            throw new EmptyFileException("Empty file input");
        }
    }
}
