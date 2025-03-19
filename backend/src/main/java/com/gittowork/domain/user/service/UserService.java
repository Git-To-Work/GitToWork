package com.gittowork.domain.user.service;

import com.gittowork.domain.fields.entity.Fields;
import com.gittowork.domain.fields.repository.FieldsRepository;
import com.gittowork.domain.user.dto.request.InsertProfileRequest;
import com.gittowork.domain.user.dto.request.SelectInterestsFieldRequest;
import com.gittowork.domain.user.dto.request.UpdateProfileRequest;
import com.gittowork.domain.user.dto.response.GetInterestFieldsResponse;
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

    /**
     * 1. 메서드 설명: 프로필 추가 정보를 수정하는 API.
     * 2. 로직:
     *    - 전달받은 updateProfileRequest에서 사용자 id를 사용해 DB에서 User 엔티티를 조회한다. (없으면 예외 발생)
     *    - 조회한 User 엔티티의 이름, 생년월일, 경력, 전화번호, 관심 분야 정보를 updateProfileRequest의 값으로 업데이트한다.
     *    - 업데이트된 User 엔티티를 저장하고, 성공 메시지를 포함한 MessageOnlyResponse를 반환한다.
     * 3. param: updateProfileRequest - 프로필 수정 정보를 담은 DTO.
     * 4. return: 성공 시 "추가 정보 수정 요청 처리 완료" 메시지를 포함한 MessageOnlyResponse 객체.
     */
    @Transactional
    public MessageOnlyResponse updateProfile(UpdateProfileRequest updateProfileRequest) {
        User user = userRepository.findById(updateProfileRequest.getUserId())
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        user.setName(updateProfileRequest.getName());
        user.setBirthDt(LocalDate.parse(updateProfileRequest.getBirthDt()));
        user.setExperience(updateProfileRequest.getExperience());
        user.setPhone(updateProfileRequest.getPhone());
        user.setInterestFields(
                Arrays.toString(updateProfileRequest.getInterestsFields()).replaceAll(" ", "")
        );

        userRepository.save(user);

        return MessageOnlyResponse.builder()
                .message("추가 정보 수정 요청 처리 완료")
                .build();
    }

    /**
     * 1. 메서드 설명: 모든 관심 분야(Fields) 목록을 조회하여 GetInterestFieldsResponse 객체로 반환하는 API.
     * 2. 로직:
     *    - fieldsRepository.findAll()을 통해 DB에서 모든 Fields 엔티티를 조회한다.
     *    - 조회한 결과를 GetInterestFieldsResponse 빌더를 사용해 Response 객체로 변환하여 반환한다.
     * 3. param: 없음.
     * 4. return: 모든 관심 분야 목록을 포함하는 GetInterestFieldsResponse 객체.
     */
    public GetInterestFieldsResponse getInterestFields() {
        List<Fields> interestFields = fieldsRepository.findAll();

        return GetInterestFieldsResponse.builder()
                .fields(interestFields)
                .build();
    }

    /**
     * 1. 메서드 설명: 현재 인증된 사용자의 관심 비즈니스 분야 정보를 업데이트하는 API.
     * 2. 로직:
     *    - 현재 인증 정보에서 username을 조회하고, 해당 사용자를 DB에서 조회한다. (없으면 예외 발생)
     *    - 전달받은 SelectInterestsFieldRequest의 interestsFields 배열을 문자열로 변환한 후, 공백을 제거하여 User 엔티티의 관심 분야 정보에 설정한다.
     *    - 변경된 User 엔티티를 저장하고, 성공 메시지를 포함한 MessageOnlyResponse를 반환한다.
     * 3. param: selectInterestsFieldRequest - 관심 분야 정보를 담은 DTO.
     * 4. return: 성공 메시지를 포함한 MessageOnlyResponse 객체.
     */
    public MessageOnlyResponse selectInterestFields(SelectInterestsFieldRequest selectInterestsFieldRequest) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();

        User user = userRepository.findByGithubName(username)
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        String interestFields = Arrays.toString(selectInterestsFieldRequest.getInterestsFields()).replaceAll(" ", "");
        user.setInterestFields(interestFields);

        userRepository.save(user);

        return MessageOnlyResponse.builder()
                .message("관심 비즈니스 분야 입력 처리 성공")
                .build();
    }

}
