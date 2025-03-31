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

    /**
     * 1. 메서드 설명: 선택된 Repository의 Github 분석 결과를 조회하여,
     *    각 Repository의 분석 정보(전체 점수, 언어 수준, 활동 지표, AI 분석 결과 등)를 기반으로
     *    최종 분석 결과 DTO(GetGithubAnalysisByRepositoryResponse)를 생성하여 반환하는 API.
     * 2. 로직:
     *    - selectedRepositoryId를 기반으로 GithubAnalysisResult를 조회한다.
     *    - 전체 점수를 기준으로 overallScore(문자 등급)를 산출한다.
     *    - 각 RepositoryResult의 languageLevel 맵의 엔트리들을 병합하여, 키별 평균값을 계산한다.
     *    - 각 언어의 평균값을 기준으로 1~10 점수로 변환한 languageScore 맵을 생성한다.
     *    - Repository 이름 리스트, 분석 날짜, 언어 비율, 활동 지표, AI 분석 결과 등을 포함하여
     *      최종 응답 DTO를 빌더 패턴으로 생성한다.
     * 3. param: int selectedRepositoryId - 분석 대상 Repository의 식별자.
     * 4. return: GetGithubAnalysisByRepositoryResponse - 분석 결과 정보를 담은 DTO.
     */
    @Transactional(readOnly = true)
    public GetGithubAnalysisByRepositoryResponse getGithubAnalysisByRepository(String selectedRepositoryId) {
        GithubAnalysisResult githubAnalysisResult = githubAnalysisResultRepository
                .findBySelectedRepositoriesId(selectedRepositoryId)
                .orElseThrow(() -> new GithubAnalysisNotFoundException("Github Analysis Result not found"));

        int overallScoreValue = githubAnalysisResult.getOverallScore();
        String overallScore = overallScoreValue > 90 ? "A+"
                : overallScoreValue > 80 ? "A"
                : overallScoreValue > 70 ? "B+"
                : overallScoreValue > 60 ? "B" : "C";

        Map<String, Double> averageLanguageScore = githubAnalysisResult.getRepositories().stream()
                .flatMap(repositoryResult -> repositoryResult.getLanguageLevel().entrySet().stream())
                .collect(Collectors.groupingBy(Map.Entry::getKey, Collectors.averagingDouble(Map.Entry::getValue)));

        Map<String, Integer> languageScore = averageLanguageScore.entrySet().stream()
                .collect(Collectors.toMap(
                        Map.Entry::getKey,
                        entry -> {
                            double avg = entry.getValue();
                            if (avg > 90) return 10;
                            else if (avg > 80) return 9;
                            else if (avg > 70) return 8;
                            else if (avg > 60) return 7;
                            else if (avg > 50) return 6;
                            else if (avg > 40) return 5;
                            else if (avg > 30) return 4;
                            else if (avg > 20) return 3;
                            else if (avg > 10) return 2;
                            else if (avg > 0)  return 1;
                            else return 0;
                        }
                ));

        return GetGithubAnalysisByRepositoryResponse.builder()
                .analysisDate(githubAnalysisResult.getAnalysisDate().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")))
                .languageRatios(githubAnalysisResult.getLanguageRatios())
                .languageLevel(languageScore)
                .selectedRepositories(githubAnalysisResult.getSelectedRepositories().stream()
                        .map(Repository::getRepoName)
                        .collect(Collectors.toList()))
                .overallScore(overallScore)
                .activityMetrics(githubAnalysisResult.getActivityMetrics())
                .aiAnalysis(githubAnalysisResult.getAiAnalysis())
                .build();
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

        List<Integer> repositoryList = Arrays.stream(repositories)
                .boxed()
                .toList();
        List<String> repositoryNames = userRepositories.stream()
                .filter(repository -> repositoryList.contains(repository.getRepoId()))
                .map(Repository::getRepoName)
                .collect(Collectors.toList());

        boolean analysisStarted = githubRestApiService.checkNewGithubEvents(githubAccessToken, userName, userId, repositoryNames);
        if (analysisStarted) {
            githubAnalysisService.githubAnalysisByRepository(repositories, userName);
        }
        return CreateGithubAnalysisByRepositoryResponse.builder()
                .analysisStarted(analysisStarted)
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
    public MessageOnlyResponse saveSelectedGithubRepository(int[] selectedGithubRepositoryIds) {
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

        selectedRepoRepository.save(selectedRepository);
        return MessageOnlyResponse.builder()
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
