package com.gittowork.global.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gittowork.domain.github.entity.GithubAnalysisResult;
import com.gittowork.global.config.GptConfig;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@Service
public class GptService {

    private final String API_URL = "https://api.openai.com/v1/chat/completions";
    private final GptConfig gptConfig;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Autowired
    public GptService(GptConfig gptConfig,
                      RestTemplate restTemplate,
                      ObjectMapper objectMapper) {
        this.gptConfig = gptConfig;
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
    }

    /**
     * 1. 메서드 설명: OpenAI의 ChatGPT API를 호출하여 주어진 프롬프트에 대해 GitHub 데이터를 분석하는 결과를 JSON 문자열로 반환하는 메서드.
     * 2. 로직:
     *    - HTTP 요청 헤더에 인증 및 콘텐츠 타입 정보를 설정한다.
     *    - 프롬프트와 관련된 메시지를 포함한 요청 본문을 구성한 후 API 호출을 수행한다.
     *    - API 호출 결과로 받은 응답의 본문을 반환한다.
     * 3. param:
     *      prompt - GitHub 데이터를 분석하기 위한 사용자 프롬프트.
     *      maxToken - API 호출 시 사용할 최대 토큰 수.
     * 4. return: OpenAI API로부터 받은 응답 JSON 문자열.
     */
    public String githubDataAnalysis(String prompt, int maxToken) throws JsonProcessingException {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(gptConfig.getApiKey());

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("model", gptConfig.getModel());

        Map<String, String> systemMessage = new HashMap<>();
        systemMessage.put("role", "system");
        systemMessage.put("content", "아래 프롬프트의 지침에 따라 GitHub 데이터를 분석하고, 결과를 JSON 형식으로 출력 예시에 맞게 출력해 주세요.");

        Map<String, String> userMessage = new HashMap<>();
        userMessage.put("role", "user");
        userMessage.put("content", prompt);

        requestBody.put("messages", new Object[]{systemMessage, userMessage});
        requestBody.put("temperature", 0.3);
        requestBody.put("max_tokens", maxToken);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);
        try {
            ResponseEntity<String> response = restTemplate.exchange(API_URL, HttpMethod.POST, entity, String.class);
            return response.getBody();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * 1. 메서드 설명: GitHub 분석 결과 객체를 기반으로 OpenAI에게 보낼 프롬프트를 생성하는 메서드.
     * 2. 로직:
     *    - 분석 결과 데이터와 분석 지침, JSON 출력 예시를 포함한 프롬프트 문자열을 생성한다.
     * 3. param:
     *      githubAnalysisResult - GitHub 분석 결과 객체.
     * 4. return: 생성된 프롬프트 문자열.
     */
    public String generateGithubAnalysisPrompt(GithubAnalysisResult githubAnalysisResult) {
        StringBuilder prompt = new StringBuilder();
        prompt.append("## 다음 GitHub 분석 결과 데이터를 바탕으로, 사용자가 선택한 저장소들의 정보를 종합하여 아래 항목들에 대해 분석해주세요.\n\n");
        prompt.append("1. primaryRole: 저장소 데이터를 분석하여 사용자가 가장 적합한 IT 직무(예: Backend, Frontend, Devops Engineer 등)를 도출해주세요.\n");
        prompt.append("2. roleScores: 도출된 primaryRole을 수행할 수 있는 능력을 0에서 100점 사이로 산정해주세요.\n");
        prompt.append("3. aiAnalysis: \n");
        prompt.append("   - analysis_summary: 전체 저장소 분석 결과에 대한 요약을 한글로 작성해주세요.\n");
        prompt.append("   - improvement_suggestions: 개선방안을 한글로 작성해주세요.\n\n");
        prompt.append("### 출력 예시는 다음과 같이 JSON 형태로 작성해주세요.\n\n");
        prompt.append("{\n");
        prompt.append("  \"primaryRole\": \"Backend\",\n");
        prompt.append("  \"roleScores\": 88,\n");
        prompt.append("  \"aiAnalysis\": {\n");
        prompt.append("    \"analysis_summary\": [\n");
        prompt.append("      \"선택된 저장소들은 주로 백엔드 기술(특히 Python과 Django)을 활용한 프로젝트들이 많아 보입니다.\",\n");
        prompt.append("      \"안정적인 코드 관리와 높은 생산성을 보이고 있습니다.\",\n");
        prompt.append("      \"저장소 내 커밋 빈도와 이슈 관리 결과, 백엔드 개발에 적합한 역량을 확인할 수 있습니다.\"\n");
        prompt.append("    ],\n");
        prompt.append("    \"improvement_suggestions\": [\n");
        prompt.append("      \"테스트 커버리지 확장을 통한 코드 안정성 강화가 요구됩니다.\",\n");
        prompt.append("      \"문서화 및 코드 리뷰 프로세스 개선이 필요합니다.\",\n");
        prompt.append("      \"프론트엔드와의 연계성을 고려한 통합적인 시스템 설계가 중요합니다.\"\n");
        prompt.append("    ]\n");
        prompt.append("  }\n");
        prompt.append("}\n");
        prompt.append("## 분석에 사용할 데이터:\n");
        prompt.append(githubAnalysisResult.toString());
        return prompt.toString();
    }

    /**
     * 1. 메서드 설명: JSON 문자열을 파싱하여 GithubAnalysisResult 객체로 변환하는 메서드.
     * 2. 로직:
     *    - ObjectMapper를 사용하여 입력 JSON 문자열을 GithubAnalysisResult 객체로 역직렬화한다.
     * 3. param:
     *      jsonString - 분석 결과를 담은 JSON 문자열.
     * 4. return: 역직렬화된 GithubAnalysisResult 객체.
     */
    public GithubAnalysisResult githubAnalysisResultParser(String jsonString) {
        try {
            return objectMapper.readValue(jsonString, GithubAnalysisResult.class);
        } catch (IOException e) {
            throw new RuntimeException("GithubAnalysisResult JSON 파싱 중 오류 발생", e);
        }
    }
}
