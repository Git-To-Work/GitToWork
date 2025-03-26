package com.gittowork.domain.coverletter.sevice;

import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.model.CannedAccessControlList;
import com.amazonaws.services.s3.model.DeleteObjectRequest;
import com.amazonaws.services.s3.model.ObjectMetadata;
import com.amazonaws.services.s3.model.PutObjectRequest;
import com.gittowork.domain.coverletter.dto.response.GetMyCoverLetterListResponse.FileInfo;
import com.gittowork.domain.coverletter.dto.response.GetMyCoverLetterListResponse;
import com.gittowork.domain.coverletter.dto.response.UploadCoverLetterResponse;
import com.gittowork.domain.coverletter.entity.CoverLetter;
import com.gittowork.domain.coverletter.repository.CoverLetterAnalysisRepository;
import com.gittowork.domain.coverletter.repository.CoverLetterRepository;
import com.gittowork.domain.user.entity.User;
import com.gittowork.domain.user.repository.UserRepository;
import com.gittowork.global.exception.*;
import com.gittowork.global.response.MessageOnlyResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class CoverLetterService {
    private final CoverLetterRepository coverLetterRepository;
    private final CoverLetterAnalysisRepository coverLetterAnalysisRepository;
    private final UserRepository userRepository;

    private final AmazonS3 amazonS3;

    @Value("${cloud.aws.s3.bucketName}")
    private String bucketName;

    /**
     * 1. 메서드 설명: 전달받은 MultipartFile과 제목 정보를 기반으로 현재 인증된 사용자의 커버레터를 업로드하는 서비스 메서드.
     *    업로드된 파일은 Amazon S3에 저장되며, 저장 후 DB에 CoverLetter 엔티티로 기록하고 업로드 결과 DTO를 반환한다.
     * 2. 로직:
     *    - SecurityContext에서 현재 인증된 사용자의 username을 조회한다.
     *    - username으로 User 엔티티를 검색하여 사용자 정보를 확보한다.
     *    - 파일이 비어 있거나 원본 파일명이 없는 경우 예외를 발생시킨다.
     *    - 파일 확장자가 "pdf"인지 검증한다.
     *    - S3에 파일을 업로드하고 파일 URL을 획득한다.
     *    - CoverLetter 엔티티를 DB에 저장한다.
     *    - 업로드 결과 메시지와 저장된 CoverLetter의 식별자를 포함한 DTO를 반환한다.
     * 3. param:
     *      - file: 업로드할 MultipartFile 객체.
     *      - title: 커버레터와 연관된 제목.
     * 4. return: 업로드 결과 메시지와 저장된 CoverLetter 식별자를 담은 UploadCoverLetterResponse DTO.
     */
    @Transactional
    public UploadCoverLetterResponse uploadCoverLetter(MultipartFile file, String title) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByGithubName(username)
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        if (file == null || file.isEmpty() || file.getOriginalFilename() == null) {
            throw new EmptyFileException("Empty file input");
        }
        validatePdfFileExtension(file.getOriginalFilename());

        String fileUrl = uploadFileToS3(file);

        CoverLetter coverLetter = coverLetterRepository.save(
                CoverLetter.builder()
                        .user(user)
                        .originName(file.getOriginalFilename())
                        .fileUrl(fileUrl)
                        .createDttm(LocalDateTime.now())
                        .title(title)
                        .build()
        );

        return UploadCoverLetterResponse.builder()
                .message("파일 업로드가 성공적으로 완료되었습니다.")
                .coverLetterId(coverLetter.getId())
                .build();
    }

    /**
     * 1. 메서드 설명: 전달받은 파일 이름의 확장자가 pdf인지 검증하는 메서드.
     * 2. 로직:
     *    - 파일 이름에서 마지막 점(.) 이후의 문자열을 추출하여 소문자로 변환한다.
     *    - 추출된 확장자가 "pdf"와 일치하지 않으면 예외를 발생시킨다.
     * 3. param:
     *      - filename: 검증할 파일의 원본 이름.
     * 4. return: 없음 (조건 미충족 시 예외 발생).
     */
    private void validatePdfFileExtension(String filename) {
        int lastDotIndex = filename.lastIndexOf(".");
        if (lastDotIndex == -1) {
            throw new FileExtensionException("File extension not supported");
        }
        String extension = filename.substring(lastDotIndex + 1).toLowerCase();
        if (!"pdf".equals(extension)) {
            throw new FileExtensionException("File extension not supported: " + extension);
        }
    }

    /**
     * 1. 메서드 설명: 전달받은 MultipartFile을 Amazon S3에 업로드하고, 업로드된 파일의 URL을 반환하는 메서드.
     * 2. 로직:
     *    - 원본 파일명으로부터 파일 확장자를 추출하여 고유한 S3 파일 이름을 생성한다.
     *    - 파일 메타데이터(Content-Type, Content-Length 등)를 설정한다.
     *    - S3 PutObjectRequest를 통해 파일을 업로드하고 PublicRead 권한을 부여한다.
     *    - 업로드된 파일의 URL을 획득하여 반환한다.
     * 3. param:
     *      - file: 업로드할 MultipartFile 객체.
     * 4. return: 업로드된 파일의 URL (String).
     */
    private String uploadFileToS3(MultipartFile file) {
        String originalFilename = file.getOriginalFilename();
        String fileExtension = Optional.ofNullable(originalFilename)
                .filter(name -> name.contains("."))
                .map(name -> name.substring(name.lastIndexOf(".")))
                .orElse("");
        String s3FileName = UUID.randomUUID().toString().substring(0, 10) + fileExtension;

        ObjectMetadata metadata = new ObjectMetadata();
        metadata.setContentType(file.getContentType());
        metadata.setContentLength(file.getSize());

        try {
            PutObjectRequest putObjectRequest = new PutObjectRequest(bucketName, s3FileName, file.getInputStream(), metadata)
                    .withCannedAcl(CannedAccessControlList.PublicRead);
            amazonS3.putObject(putObjectRequest);
        } catch (IOException e) {
            throw new S3UploadException("S3 upload failed");
        }
        return amazonS3.getUrl(bucketName, s3FileName).toString();
    }

    /**
     * 1. 메서드 설명: 현재 인증된 사용자의 CoverLetter 목록을 조회하여,
     *    각 CoverLetter 엔티티를 FileInfo DTO로 변환한 후,
     *    이를 포함하는 GetMyCoverLetterListResponse DTO를 반환하는 API.
     * 2. 로직:
     *    - SecurityContext에서 현재 인증된 사용자의 username을 조회한다.
     *    - username을 기반으로 User 엔티티를 검색하여 userId를 확보한다.
     *    - userId를 이용해 CoverLetter 목록을 조회한다.
     *    - 조회된 CoverLetter 목록을 FileInfo DTO로 매핑한 후, 리스트로 수집한다.
     *    - FileInfo 리스트를 포함하는 GetMyCoverLetterListResponse DTO를 빌더 패턴으로 생성하여 반환한다.
     * 3. param: 없음.
     * 4. return: 사용자의 CoverLetter 정보를 담은 GetMyCoverLetterListResponse DTO.
     */
    public GetMyCoverLetterListResponse getMyCoverLetterList() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String username = auth.getName();

        User user = userRepository.findByGithubName(username)
                .orElseThrow(() -> new UserNotFoundException("User not found"));
        int userId = user.getId();

        List<CoverLetter> coverLetters = coverLetterRepository.findAllByUser_Id(userId);

        List<FileInfo> fileInfos = coverLetters.stream()
                .map(coverLetter -> FileInfo.builder()
                        .fileId(coverLetter.getId())
                        .fileName(coverLetter.getOriginName())
                        .fileUrl(coverLetter.getFileUrl())
                        .title(coverLetter.getTitle())
                        .build()
                )
                .toList();

        return GetMyCoverLetterListResponse.builder()
                .files(fileInfos)
                .build();
    }

    /**
     * 1. 메서드 설명: 전달받은 CoverLetter ID를 기반으로 DB에서 CoverLetter 엔티티를 삭제하고,
     *    해당 CoverLetter에 연결된 파일을 Amazon S3에서 삭제한 후, 삭제 결과 메시지를 반환하는 API.
     * 2. 로직:
     *    - coverLetterId로 CoverLetter 엔티티를 조회하고, 존재하지 않으면 예외를 발생시킨다.
     *    - 조회된 CoverLetter 엔티티를 DB에서 삭제한다.
     *    - CoverLetter의 파일 URL에서 S3 키를 추출한 후, 해당 파일을 S3에서 삭제한다.
     *    - 삭제 완료 메시지를 포함하는 MessageOnlyResponse DTO를 빌더 패턴으로 생성하여 반환한다.
     * 3. param: int coverLetterId - 삭제할 CoverLetter의 식별자.
     * 4. return: 삭제 완료 메시지를 담은 MessageOnlyResponse DTO.
     */
    public MessageOnlyResponse deleteCoverLetter(int coverLetterId) {
        CoverLetter coverLetter = coverLetterRepository.findById(coverLetterId)
                .orElseThrow(() -> new CoverLetterNotFoundException("CoverLetter not found"));

        coverLetterRepository.delete(coverLetter);

        deleteCoverLetterFromS3(coverLetter.getFileUrl());

        return MessageOnlyResponse.builder()
                .message("파일 삭제 요청 처리 완료")
                .build();
    }

    /**
     * 1. 메서드 설명: 주어진 파일 URL로부터 S3 객체 키를 추출하여 해당 파일을 S3에서 삭제하는 메서드.
     * 2. 로직:
     *    - 파일 URL에서 S3 객체 키를 추출한다.
     *    - 추출된 키를 기반으로 S3에서 파일을 삭제한다.
     *    - 삭제 과정 중 오류 발생 시 S3DeleteException 예외를 발생시킨다.
     * 3. param: String fileUrl - 삭제할 파일의 URL.
     * 4. return: 없음.
     */
    private void deleteCoverLetterFromS3(String fileUrl){
        String key = getKeyFromCoverLetterAddress(fileUrl);
        try {
            amazonS3.deleteObject(new DeleteObjectRequest(bucketName, key));
        } catch (Exception e) {
            throw new S3DeleteException("S3 delete failed");
        }
    }

    /**
     * 1. 메서드 설명: 주어진 파일 URL에서 S3 객체 키를 추출하는 메서드.
     * 2. 로직:
     *    - URL을 파싱하여 경로 정보를 추출한 후, UTF-8로 디코딩한다.
     *    - 경로의 선행 슬래시('/')를 제거하여 S3 객체 키를 반환한다.
     *    - URL 파싱에 실패하면 S3DeleteException 예외를 발생시킨다.
     * 3. param: String fileUrl - 파일 URL.
     * 4. return: 추출된 S3 객체 키 (String).
     */
    private String getKeyFromCoverLetterAddress(String fileUrl){
        try {
            URL url = new URL(fileUrl);
            String decodedPath = URLDecoder.decode(url.getPath(), StandardCharsets.UTF_8);
            return decodedPath.startsWith("/") ? decodedPath.substring(1) : decodedPath;
        } catch (MalformedURLException e) {
            throw new S3DeleteException("S3 delete failed");
        }
    }
}
