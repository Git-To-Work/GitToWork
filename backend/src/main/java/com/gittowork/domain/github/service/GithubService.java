package com.gittowork.domain.github.service;

import com.gittowork.domain.github.dto.response.*;
import com.gittowork.domain.github.entity.*;
import com.gittowork.domain.github.model.repository.Repository;
import com.gittowork.domain.github.repository.*;
import com.gittowork.domain.user.entity.User;
import com.gittowork.domain.user.repository.UserRepository;
import com.gittowork.global.exception.*;
import com.gittowork.global.response.MessageOnlyResponse;
import com.gittowork.global.service.GithubRestApiService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor()
public class GithubService {

    private final GithubAnalysisResultRepository githubAnalysisResultRepository;
    private final GithubRepoRepository githubRepoRepository;
    private final UserRepository userRepository;
    private final SelectedRepoRepository selectedRepoRepository;
    private final GithubRestApiService githubRestApiService;
    private final GithubAnalysisService githubAnalysisService;
    private final AnalysisStatusRepository analysisStatusRepository;

    /**
     * 1. 메서드 설명: 선택된 Repository의 Github 분석 결과를 조회하여,
     *    분석 상태가 complete인 경우 각 Repository의 분석 정보(전체 점수, 언어 수준, 활동 지표, AI 분석 결과 등)를 기반으로
     *    최종 분석 결과 DTO(GetGithubAnalysisByRepositoryResponse)를 생성하여 반환하며,
     *    complete가 아닌 경우 현재 분석 상태와 적절한 메시지를 담은 DTO(GetGithubAnalysisStatusResponse)를 반환하는 API.
     * 2. 로직:
     *    - selectedRepositoryId를 기반으로 AnalysisStatus를 조회한다.
     *    - AnalysisStatus가 complete인 경우:
     *         - 해당 selectedRepositoryId의 최신 GithubAnalysisResult를 조회한다.
     *         - 전체 점수를 기준으로 overallScore(문자 등급)를 산출한다.
     *         - 분석 날짜, 언어 비율, Repository 이름 리스트, 활동 지표, AI 분석 결과 등을 포함하여
     *           최종 응답 DTO(GetGithubAnalysisByRepositoryResponse)를 빌더 패턴으로 생성하여 반환한다.
     *    - AnalysisStatus가 pending, analyzing, fail 등 complete가 아닌 경우:
     *         - 현재 분석 상태에 따른 적절한 메시지를 생성하고,
     *           상태와 메시지를 담은 DTO(GetGithubAnalysisStatusResponse)를 빌더 패턴으로 생성하여 반환한다.
     * 3. param: String selectedRepositoryId - 분석 대상 Repository의 식별자.
     * 4. return:
     *         - AnalysisStatus가 complete인 경우: GetGithubAnalysisByRepositoryResponse (분석 결과 정보를 담은 DTO)
     *         - 그 외 경우: GetGithubAnalysisStatusResponse (분석 상태와 메시지를 담은 DTO)
     */
    @Transactional(readOnly = true)
    public Object getGithubAnalysisByRepository(String selectedRepositoryId) {
        AnalysisStatus analysisStatus = analysisStatusRepository
                .findBySelectedRepositoriesId(selectedRepositoryId)
                .orElseThrow(() -> new GithubAnalysisNotFoundException("Github analysis status not found"));

        if (analysisStatus.getStatus() == AnalysisStatus.Status.complete) {
            GithubAnalysisResult githubAnalysisResult = githubAnalysisResultRepository
                    .findFirstBySelectedRepositoriesIdOrderByAnalysisDateDesc(selectedRepositoryId)
                    .orElseThrow(() -> new GithubAnalysisNotFoundException("Github Analysis Result not found"));

            int overallScoreValue = githubAnalysisResult.getOverallScore();
            String overallScore = overallScoreValue > 90 ? "A+"
                    : overallScoreValue > 80 ? "A"
                    : overallScoreValue > 70 ? "B+"
                    : overallScoreValue > 60 ? "B"
                    : overallScoreValue > 50 ? "C+"
                    : overallScoreValue > 40 ? "C" : "D";

            return GetGithubAnalysisByRepositoryResponse.builder()
                    .status(analysisStatus.getStatus().name())
                    .selectedRepositoryId(selectedRepositoryId)
                    .analysisDate(githubAnalysisResult.getAnalysisDate().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")))
                    .languageRatios(githubAnalysisResult.getLanguageRatios())
                    .selectedRepositories(githubAnalysisResult.getSelectedRepositories().stream()
                            .map(Repository::getRepoName)
                            .collect(Collectors.toList()))
                    .overallScore(overallScore)
                    .activityMetrics(githubAnalysisResult.getActivityMetrics())
                    .aiAnalysis(githubAnalysisResult.getAiAnalysis())
                    .build();
        } else {
            String message = switch (analysisStatus.getStatus()) {
                case pending -> "분석이 아직 시작되지 않았습니다.";
                case analyzing -> "분석이 진행 중입니다.";
                case fail -> "분석에 실패하였습니다.";
                default -> "분석 상태를 확인할 수 없습니다.";
            };

            SelectedRepository selectedRepository = selectedRepoRepository.findById(selectedRepositoryId)
                    .orElseThrow(() -> new GithubRepositoryNotFoundException("Selected repository not found"));

            return GetGithubAnalysisStatusResponse.builder()
                    .status(analysisStatus.getStatus().name())
                    .selectedRepositoryId(selectedRepositoryId)
                    .selectedRepositories(selectedRepository.getRepositories().stream()
                            .map(Repository::getRepoName)
                            .collect(Collectors.toList()))
                    .message(message)
                    .build();
        }
    }

    /**
     * 1. 메서드 설명: 현재 인증된 사용자의 GitHub 분석을 위한 Repository 리스트를 필터링하여,
     *    신규 이벤트가 있는지 확인한 후, 분석을 시작하거나 메시지를 반환하는 API.
     * 2. 로직:
     *    - 현재 인증된 사용자의 username을 조회한다.
     *    - username을 기반으로 User 엔티티를 검색하여 userId와 GitHub Access Token을 확보한다.
     *    - userId를 사용하여 GithubRepository를 조회하고, 사용자의 Repository 리스트를 확보한다.
     *    - 파라미터로 전달된 repositories 배열과 사용자의 Repository repoId를 비교하여,
     *      해당하는 repository 이름 리스트를 구성한다.
     *    - 구성된 repository 이름 리스트를 이용하여, 신규 GitHub 이벤트가 있는지 체크한다.
     *    - 신규 이벤트가 존재하면, 비동기로 GitHub 분석을 시작하고, 분석 시작 메시지를 반환한다.
     * 3. param: int[] repositories - 분석 대상 repository의 repoId 배열.
     * 4. return: CreateGithubAnalysisByRepositoryResponse - 분석 시작 여부와 메시지를 담은 DTO.
     */
    @Transactional
    public CreateGithubAnalysisByRepositoryResponse createGithubAnalysisByRepositoryResponse(int[] repositories) {
        String userName = getUserName();
        User user = userRepository.findByGithubName(userName)
                .orElseThrow(() -> new UserNotFoundException("User not found"));
        int userId = user.getId();
        String githubAccessToken = user.getGithubAccessToken();

        GithubRepository userGithubRepository = githubRepoRepository.findByUserId(userId)
                .orElseThrow(() -> new GithubRepositoryNotFoundException("Github Repository not found"));
        List<Repository> userRepositories = userGithubRepository.getRepositories();

        List<Integer> selectedRepoIds = Arrays.stream(repositories)
                .boxed()
                .toList();

        List<String> selectedRepoNames = userRepositories.stream()
                .filter(repo -> selectedRepoIds.contains(repo.getRepoId()))
                .map(Repository::getRepoName)
                .collect(Collectors.toList());

        boolean analysisStarted = githubRestApiService.checkNewGithubEvents(githubAccessToken, userName, userId, selectedRepoNames);
        String selectedRepositoryId = null;
        if (analysisStarted) {
            githubAnalysisService.saveUserGithubRepositoryInfo(githubAccessToken, userName, userId);
            githubAnalysisService.githubAnalysisByRepository(repositories, userName);

            List<Repository> selectedRepositories = userRepositories.stream()
                    .filter(repo -> selectedRepoIds.contains(repo.getRepoId()))
                    .collect(Collectors.toList());

            SelectedRepository selectedRepository = selectedRepoRepository.findByUserIdAndRepositories(userId, selectedRepositories)
                    .orElseThrow(() -> new GithubRepositoryNotFoundException("Github Repository Combination Not Found"));

            AnalysisStatus analysisStatus = analysisStatusRepository.findByUserAndSelectedRepositoriesId(user, selectedRepository.getSelectedRepositoryId())
                    .orElseThrow(() -> new GithubAnalysisNotFoundException("Github Analysis Status Not Found"));

            analysisStatus.setStatus(AnalysisStatus.Status.analyzing);

            selectedRepositoryId = analysisStatus.getSelectedRepositoriesId();

            analysisStatusRepository.save(analysisStatus);
        }

        return CreateGithubAnalysisByRepositoryResponse.builder()
                .analysisStarted(analysisStarted)
                .selectedRepositoryId(selectedRepositoryId)
                .selectedRepositories(selectedRepoNames)
                .message(analysisStarted ? "분석이 시작되었습니다." : "마지막 분석 이후로 추가 이벤트가 없습니다.")
                .build();
    }

    /**
     * 1. 메서드 설명: 선택된 GitHub repository 정보를 저장하는 API.
     * 2. 로직:
     *    - SecurityContext에서 현재 인증된 사용자의 username을 조회한다.
     *    - username을 이용해 User 엔티티를 검색하여 사용자 정보를 가져온다.
     *    - 조회된 User 엔티티의 id를 사용해 GithubRepository 엔티티를 조회한다.
     *    - 전달받은 repository ID 배열을 Set으로 변환한 후, GithubRepository에 저장된 repository 목록 중 선택된 항목을 필터링한다.
     *    - findByUserIdAndRepositories를 통해 userId와 선택된 repository 조합이 이미 존재하는지 확인한다.
     *      - 이미 존재하면 SelectedRepositoryDuplicatedException 예외를 발생시킨다.
     *      - 존재하지 않으면, findMatchingSelectedRepository를 통해 기존 SelectedRepository 엔티티가 있으면 업데이트하지 않고
     *        새로 저장하는 방식으로 신규 SelectedRepository 엔티티를 생성하여 저장한다.
     * 3. param: selectedGithubRepositoryIds - 사용자가 선택한 repository의 ID 배열.
     * 4. return: 성공 시 "레포지토리 선택 저장 요청 처리 완료" 메시지를 포함한 MessageOnlyResponse 객체.
     */
    @Transactional
    public SaveSelectedRepositoriesResponse saveSelectedGithubRepository(int[] selectedGithubRepositoryIds) {
        String username = getUserName();
        User user = userRepository.findByGithubName(username)
                .orElseThrow(() -> new UserNotFoundException("User not found"));
        int userId = user.getId();
        GithubRepository githubRepository = githubRepoRepository.findByUserId(userId)
                .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"));

        Set<Integer> selectedIds = Arrays.stream(selectedGithubRepositoryIds)
                .boxed()
                .collect(Collectors.toSet());
        List<Repository> selectedRepositories = githubRepository.getRepositories().stream()
                .filter(repo -> selectedIds.contains(repo.getRepoId()))
                .collect(Collectors.toList());

        Optional<SelectedRepository> existSelectedRepository = selectedRepoRepository.findByUserIdAndRepositories(userId, selectedRepositories);

        if (existSelectedRepository.isPresent()) {
            throw new SelectedRepositoryDuplicatedException("Selected repository already exists");
        }

        SelectedRepository selectedRepository = findMatchingSelectedRepository(userId, selectedRepositories)
                .map(existing -> {
                    existing.setRepositories(selectedRepositories);
                    return existing;
                })
                .orElseGet(() -> SelectedRepository.builder()
                        .userId(userId)
                        .repositories(selectedRepositories)
                        .build());

        String selectedRepositoryId = selectedRepoRepository.save(selectedRepository).getSelectedRepositoryId();

        analysisStatusRepository.save(
                AnalysisStatus.builder()
                        .user(user)
                        .selectedRepositoriesId(selectedRepositoryId)
                        .status(AnalysisStatus.Status.pending)
                        .build()
        );

        return SaveSelectedRepositoriesResponse.builder()
                .selectedRepositoryId(selectedRepositoryId)
                .message("레포지토리 선택 저장 요청 처리 완료")
                .build();
    }

    /**
     * 1. 메서드 설명: 지정된 userId와 선택된 repository 리스트를 기반으로 기존에 저장된 SelectedRepository 엔티티 중 동일한 것을 찾는 메서드.
     * 2. 로직:
     *    - userId를 기준으로 해당 사용자의 모든 SelectedRepository 엔티티를 조회한다.
     *    - 각 SelectedRepository 엔티티에 대해, 저장된 repository 리스트의 크기가 선택된 repository 리스트와 동일하며,
     *      저장된 repository 집합이 선택된 repository 집합을 모두 포함하는지 검사한다.
     * 3. param:
     *      - userId: 사용자 식별자.
     *      - selectedRepositories: 필터링된 선택 repository 리스트.
     * 4. return: 동일한 repository 정보가 존재하면 Optional로 해당 SelectedRepository를 반환, 그렇지 않으면 Optional.empty() 반환.
     */
    private Optional<SelectedRepository> findMatchingSelectedRepository(int userId, List<Repository> selectedRepositories) {
        return selectedRepoRepository.findAllByUserId(userId).stream()
                .filter(existing -> existing.getRepositories().size() == selectedRepositories.size()
                        && new HashSet<>(existing.getRepositories()).containsAll(selectedRepositories))
                .findFirst();
    }

    /**
     * 1. 메서드 설명: 현재 인증된 사용자의 GitHub 저장소 정보를 조회하여, 해당 정보를 GetMyRepositoryResponse DTO로 반환하는 API.
     * 2. 로직:
     *    - 현재 인증된 사용자의 username을 조회한다.
     *    - username을 기반으로 User 엔티티를 검색한다.
     *    - User 엔티티의 id를 사용하여 GithubRepository 엔티티를 조회한다.
     *    - 조회된 GithubRepository의 repositories 리스트를 Repo DTO로 변환한다.
     *    - 변환된 Repo DTO 리스트를 포함하는 GetMyRepositoryResponse 객체를 반환한다.
     * 3. param: 없음.
     * 4. return: 사용자의 GitHub 저장소 정보를 담은 GetMyRepositoryResponse 객체.
     */
    @Transactional(readOnly = true)
    public GetMyRepositoryResponse getMyRepository() {
        String username = getUserName();
        User user = userRepository.findByGithubName(username)
                .orElseThrow(() -> new UserNotFoundException("User not found"));
        int userId = user.getId();
        GithubRepository githubRepository = githubRepoRepository.findByUserId(userId)
                .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"));

        List<Repo> repos = githubRepository.getRepositories().stream()
                .map(repo -> Repo.builder()
                        .repoId(repo.getRepoId())
                        .repoName(repo.getRepoName())
                        .build())
                .collect(Collectors.toList());
        return GetMyRepositoryResponse.builder()
                .repositories(repos)
                .build();
    }

    /**
     * 1. 메서드 설명: 현재 인증된 사용자의 SelectedRepository 목록을 조회하여,
     *    각 SelectedRepository 내의 repository 이름 리스트를 추출하고,
     *    이를 조합하여 GetMyRepositoryCombinationResponse DTO로 반환하는 API.
     * 2. 로직:
     *    - 현재 인증된 사용자의 username을 조회한다.
     *    - username을 기반으로 User 엔티티를 검색하여 userId를 확보한다.
     *    - userId를 사용하여 SelectedRepository 리스트를 조회한다.
     *    - 각 SelectedRepository 객체의 repositories 리스트에서 repository 이름을 추출하여
     *      RepositoryCombination 객체를 생성한다.
     *    - RepositoryCombination 객체들을 조합한 후, GetMyRepositoryCombinationResponse 객체를 빌더 패턴으로 생성하여 반환한다.
     * 3. param: 없음.
     * 4. return: 변환된 repository 조합 정보를 담은 GetMyRepositoryCombinationResponse 객체.
     */
    @Transactional(readOnly = true)
    public GetMyRepositoryCombinationResponse getMyRepositoryCombination() {
        String username = getUserName();
        User user = userRepository.findByGithubName(username)
                .orElseThrow(() -> new UserNotFoundException("User not found"));
        int userId = user.getId();

        List<RepositoryCombination> repoComb = selectedRepoRepository.findAllByUserId(userId)
                .stream()
                .map(selectedRepository -> RepositoryCombination.builder()
                        .selectedRepositoryId(selectedRepository.getSelectedRepositoryId())
                        .repositoryNames(selectedRepository.getRepositories()
                                .stream()
                                .map(Repository::getRepoName)
                                .collect(Collectors.toList()))
                        .build())
                .collect(Collectors.toList());

        return GetMyRepositoryCombinationResponse.builder()
                .repositoryCombinations(repoComb)
                .build();
    }

    /**
     * 1. 메서드 설명: 현재 인증된 사용자의 선택된 GitHub repository 조합과 해당 분석 결과를 삭제하는 API.
     * 2. 로직:
     *    - SecurityContext에서 현재 인증된 사용자의 username을 조회한다.
     *    - username을 기반으로 User 엔티티를 검색하여 userId를 확보한다.
     *    - 전달받은 selectedGithubRepositoryIds를 문자열로 변환한다.
     *    - userId와 변환된 식별자를 이용하여 해당 SelectedRepository를 조회한다.
     *    - 동일한 식별자로 GithubAnalysisResult를 조회한다.
     *    - 조회된 SelectedRepository와 GithubAnalysisResult를 삭제한다.
     * 3. param: int selectedGithubRepositoryIds - 삭제할 repository 조합의 식별자.
     * 4. return: 삭제 완료 메시지를 담은 MessageOnlyResponse 객체.
     */
    @Transactional
    public MessageOnlyResponse deleteSelectedGithubRepository(String selectedGithubRepositoryIds) {
        int userId = userRepository.findByGithubName(getUserName())
                .orElseThrow(() -> new UserNotFoundException("User not found"))
                .getId();

        SelectedRepository selectedRepository = selectedRepoRepository.findByUserIdAndSelectedRepositoryId(userId, selectedGithubRepositoryIds)
                .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository combination not found"));

        Optional<GithubAnalysisResult> githubAnalysisResult = githubAnalysisResultRepository
                .findBySelectedRepositoriesId(selectedGithubRepositoryIds);

        selectedRepoRepository.delete(selectedRepository);
        githubAnalysisResult.ifPresent(githubAnalysisResultRepository::delete);

        return MessageOnlyResponse.builder()
                .message("레포지토리 조합과 분석 결과가 삭제되었습니다.")
                .build();
    }

    @Transactional
    public MessageOnlyResponse updateGithubData() {
        User user = userRepository.findByGithubName(getUserName())
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        String githubAccessToken = user.getGithubAccessToken();
        String userName = getUserName();
        int userId = user.getId();

        boolean isNewRepositoryCreated = githubRestApiService.checkNewRepositoryCreationEvents(githubAccessToken, userName, userId);

        String message = "";
        if (isNewRepositoryCreated) {
            githubAnalysisService.saveUserGithubRepositoryInfo(githubAccessToken, userName, userId);
            message = "새로운 Github Repository가 감지되었습니다. 데이터를 업데이트합니다.";
        } else {
            message = "감지된 새로운 Github Repository가 없습니다.";
        }

        return MessageOnlyResponse.builder()
                .message(message)
                .build();
    }

    /**
     * 1. 메서드 설명: 현재 SecurityContextHolder에서 username을 추출하는 헬퍼 메서드.
     * 2. 로직:
     *    - SecurityContextHolder에서 현재 인증 정보를 조회하여 username을 반환한다.
     * 3. param: 없음.
     * 4. return: 현재 인증된 사용자의 username 문자열.
     */
    private String getUserName() {
        return SecurityContextHolder.getContext().getAuthentication().getName();
    }
}
