package com.gittowork.domain.user.service;

import com.gittowork.domain.fields.entity.Fields;
import com.gittowork.domain.fields.repository.FieldsRepository;
import com.gittowork.domain.user.dto.request.InsertProfileRequest;
import com.gittowork.domain.user.dto.response.GetMyProfileResponse;
import com.gittowork.domain.user.dto.response.MessageOnlyResponse;
import com.gittowork.domain.user.entity.User;
import com.gittowork.domain.user.entity.UserGitInfo;
import com.gittowork.domain.user.repository.UserGitInfoRepository;
import com.gittowork.domain.user.repository.UserRepository;
import com.gittowork.global.exception.UserNotFoundException;
import com.gittowork.global.service.RedisService;
import jakarta.transaction.Transactional;
import lombok.AllArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@AllArgsConstructor(onConstructor = @__(@Autowired))
public class UserService {

    private final UserRepository userRepository;
    private final UserGitInfoRepository userGitInfoRepository;
    private final RedisService redisService;
    private final FieldsRepository fieldsRepository;

    /**
     * 1. 메서드 설명: 프로필 추가 정보를 저장하는 API.
     * 2. 로직:
     *    - 현재 인증 정보에서 username을 조회하고, Redis에서 사용자 기본 정보와 GitHub 추가 정보를 가져온다.
     *    - 조회한 데이터를 바탕으로 User 엔티티를 생성 및 저장하여 auto increment된 id를 확보한다.
     *    - 해당 id를 기반으로 UserGitInfo 엔티티를 생성하고, User와 양방향 연관관계를 설정한 후 저장한다.
     * 3. param: insertProfileRequest - 프로필 추가 정보를 담은 DTO.
     * 4. return: 성공 시 "추가 정보가 성공적으로 업데이트되었습니다." 메시지를 포함한 MessageOnlyResponse 객체.
     */
    @Transactional
    public MessageOnlyResponse insertProfile(InsertProfileRequest insertProfileRequest) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();

        Map<String, Object> userCaching = redisService.getUser("user:" + username);
        Integer githubId = (Integer) userCaching.get("githubId");

        User user = User.builder()
                .githubId(githubId)
                .githubName(userCaching.get("githubName").toString())
                .name(insertProfileRequest.getName())
                .githubEmail(userCaching.get("githubEmail").toString())
                .phone(insertProfileRequest.getPhone())
                .birthDt(LocalDate.parse(insertProfileRequest.getBirthDt()))
                .experience(insertProfileRequest.getExperience())
                .createDttm(LocalDateTime.now())
                .updateDttm(LocalDateTime.now())
                .privacyConsentDttm(insertProfileRequest.isPrivacyPolicyAgreed() ? LocalDateTime.now() : null)
                .githubAccessToken(userCaching.get("githubAccessToken").toString())
                .notificationAgreeDttm(insertProfileRequest.isNotificationAgreed() ? LocalDateTime.now() : null)
                .build();

        user = userRepository.save(user);

        Map<String, Object> userGitInfoCaching = redisService.getUserGitInfo("userGitInfo:" + username);

        UserGitInfo userGitInfo = UserGitInfo.builder()
                .avatarUrl(userGitInfoCaching.get("githubAvatarUrl").toString())
                .publicRepositories((Integer) userGitInfoCaching.get("publicRepositories"))
                .followers((Integer) userGitInfoCaching.get("followers"))
                .followings((Integer) userGitInfoCaching.get("following"))
                .createDttm(LocalDateTime.now())
                .updateDttm(LocalDateTime.now())
                .build();

        userGitInfo.setUser(user);
        user.setUserGitInfo(userGitInfo);

        userGitInfoRepository.save(userGitInfo);

        return MessageOnlyResponse.builder()
                .message("추가 정보가 성공적으로 업데이트되었습니다.")
                .build();
    }

    /**
     * 1. 메서드 설명: 내 프로필 정보를 조회하는 API.
     * 2. 로직:
     *    - 현재 인증 정보에서 username을 조회한다.
     *    - username으로 DB에서 User 엔티티를 찾는다. (없으면 예외 발생)
     *    - user.getInterestFields()에서 대괄호를 제거하고 ','로 split하여 interestFieldsNumbers(List<Integer>)로 변환한다.
     *    - fieldsRepository.findAllById(interestFieldsNumbers)를 통해 해당하는 Fields 목록을 조회한다.
     *    - 조회된 필드 목록에서 fieldName만 추출하여 String[]로 만든다.
     *    - User 정보와 GitHub 프로필 정보를 바탕으로 GetMyProfileResponse를 생성해 반환한다.
     * 3. param: 없음
     * 4. return: 내 프로필 정보를 담은 GetMyProfileResponse 객체.
     */
    @Transactional
    public GetMyProfileResponse getMyProfile() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();


        User user = userRepository.findByGithubName(username)
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        List<Integer> interestFieldsNumbers = Arrays.stream(
                        user.getInterestFields()
                                .replaceAll("[\\[\\]]", "")
                                .split(","))
                .map(String::trim)
                .map(Integer::parseInt)
                .collect(Collectors.toList());

        List<Fields> interestFields = fieldsRepository.findAllById(interestFieldsNumbers);

        String[] fieldsNames = interestFields.stream()
                .map(Fields::getFieldName)
                .toArray(String[]::new);

        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

        return GetMyProfileResponse.builder()
                .userId(user.getId())
                .email(user.getGithubEmail())
                .name(user.getName())
                .nickname(user.getGithubName())
                .phone(user.getPhone())
                .birthDt(user.getBirthDt().format(formatter))
                .experience(user.getExperience())
                .avatarUrl(user.getUserGitInfo().getAvatarUrl())
                .interestFields(fieldsNames)
                .build();
    }

}
