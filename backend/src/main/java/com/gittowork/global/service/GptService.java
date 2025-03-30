package com.gittowork.global.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gittowork.domain.coverletter.entity.CoverLetterAnalysis;
import com.gittowork.domain.github.entity.GithubAnalysisResult;
import com.gittowork.global.config.GptConfig;
import com.gittowork.global.exception.CoverLetterAnalysisException;
import com.gittowork.global.exception.JsonParsingException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@Slf4j
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
     * 1. 메서드 설명: OpenAI의 ChatGPT API를 호출하여 GitHub 데이터를 분석하는 결과를 JSON 문자열로 받고,
     *    이를 GithubAnalysisResult 객체로 파싱하여 반환하는 메서드.
     * 2. 로직:
     *    - GitHub 분석에 필요한 프롬프트를 generateGithubAnalysisPrompt()를 통해 생성한다.
     *    - 시스템 메시지와 사용자 메시지를 포함하여 GPT API 요청을 구성한 후 callGptApi()를 호출한다.
     *    - GPT API 응답 JSON 문자열을 githubAnalysisResultParser()를 이용해 역직렬화한다.
     * 3. param:
     *      githubAnalysisResult - 분석할 GitHub 데이터가 담긴 객체 (분석 지침 참조).
     *      maxToken - API 호출 시 사용할 최대 토큰 수.
     * 4. return: 분석 결과를 담은 GithubAnalysisResult 객체.
     */
    public GithubAnalysisResult githubDataAnalysis(GithubAnalysisResult githubAnalysisResult, int maxToken) throws JsonProcessingException {
        String prompt = generateGithubAnalysisPrompt(githubAnalysisResult);
        String systemMsg = "아래 프롬프트의 지침에 따라 GitHub 데이터를 분석하고, 결과를 JSON 형식으로 출력 예시에 맞게 출력해 주세요.";
        String responseBody = callGptApi(systemMsg, prompt, maxToken);
        return githubAnalysisResultParser(responseBody);
    }

    /**
     * 1. 메서드 설명: GPT API에 커버레터 분석 요청을 보내고, 응답 JSON을 CoverLetterAnalysis 객체로 파싱하여 반환하는 메서드.
     * 2. 로직:
     *    - 분석에 사용할 커버레터 텍스트와 분석 지침을 포함한 프롬프트를 generateCoverLetterAnalysisPrompt()로 생성한다.
     *    - 시스템 메시지와 사용자 메시지를 포함한 GPT API 요청을 callGptApi()를 통해 전송한다.
     *    - 응답 JSON 문자열을 coverLetterAnalysisResultParser()를 사용해 CoverLetterAnalysis 객체로 역직렬화한다.
     * 3. param:
     *      content - 분석에 사용할 커버레터 텍스트.
     *      maxToken - API 호출 시 사용할 최대 토큰 수.
     * 4. return: 분석 결과를 담은 CoverLetterAnalysis 객체.
     */
    public CoverLetterAnalysis coverLetterAnalysis(String content, int maxToken) {
        String prompt = generateCoverLetterAnalysisPrompt(content);
        String systemMsg = "당신은 자기소개서 분석 전문가입니다. 아래에 PDF에서 추출된 자기소개서 텍스트가 제공될 것입니다. "
                + "단, PDF 추출 과정에서 일부 내용이 누락되거나 불완전할 수 있습니다. 이런 경우, 문맥에 맞게 누락된 부분을 보완하여 "
                + "전체 자기소개서의 내용을 분석해 주세요. 분석 시에는 출력 예시의 8가지 역량에 대한 점수와 전반적인 강점 및 약점을 포괄적으로 평가해 주시기 바랍니다.";
        String responseBody = callGptApi(systemMsg, prompt, maxToken);
        return coverLetterAnalysisResultParser(responseBody);
    }

    /**
     * 1. 메서드 설명: 시스템 메시지와 사용자 메시지를 포함한 GPT API 요청을 구성하여 호출하고,
     *    응답 JSON 문자열을 반환하는 공통 메서드.
     * 2. 로직:
     *    - HTTP 헤더에 Content-Type과 Bearer 인증 정보를 설정한다.
     *    - 모델, 온도, 최대 토큰 수 등의 정보를 포함하여 요청 본문(Map<String, Object>)을 구성한다.
     *    - messages 필드에는 시스템 메시지와 사용자 메시지를 순서대로 배열로 포함시킨다.
     *    - restTemplate을 사용하여 GPT API에 POST 요청을 전송하고, 응답 본문을 반환한다.
     * 3. param:
     *      systemMessageContent - 시스템 메시지 내용.
     *      prompt - 사용자 메시지 내용 (분석에 사용할 텍스트와 지침 포함).
     *      maxToken - API 호출 시 사용할 최대 토큰 수.
     * 4. return: GPT API 응답으로 받은 JSON 문자열.
     */
    private String callGptApi(String systemMessageContent, String prompt, int maxToken) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(gptConfig.getApiKey());

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("model", gptConfig.getModel());

        Map<String, String> systemMessage = new HashMap<>();
        systemMessage.put("role", "system");
        systemMessage.put("content", systemMessageContent);

        Map<String, String> userMessage = new HashMap<>();
        userMessage.put("role", "user");
        userMessage.put("content", prompt);

        requestBody.put("messages", new Object[]{systemMessage, userMessage});
        requestBody.put("temperature", 0.3);
        requestBody.put("max_tokens", maxToken);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);
        try {
            ResponseEntity<String> response = restTemplate.exchange(API_URL, HttpMethod.POST, entity, String.class);
            String responseBody = response.getBody();
            log.info("GPT API response: {}", responseBody);

            // JSON 파싱하여 choices -> message -> content 추출
            ObjectMapper objectMapper = new ObjectMapper();
            JsonNode rootNode = objectMapper.readTree(responseBody);
            JsonNode contentNode = rootNode.path("choices").get(0).path("message").path("content");
            String content = contentNode.asText();
            log.info("Extracted GPT Content: {}", content);

            return content;
        } catch (Exception e) {
            throw new CoverLetterAnalysisException("Error calling GPT API");
        }
    }

    /**
     * 1. 메서드 설명: GitHub 분석 결과 객체를 기반으로 GPT API에 보낼 프롬프트를 생성하는 메서드.
     * 2. 로직:
     *    - GitHub 데이터 분석에 필요한 지침과 출력 예시를 포함한 프롬프트 문자열을 구성한다.
     * 3. param:
     *      githubAnalysisResult - 분석에 사용할 GitHub 데이터가 담긴 객체.
     * 4. return: 생성된 프롬프트 문자열.
     */
    private String generateGithubAnalysisPrompt(GithubAnalysisResult githubAnalysisResult) {
        StringBuilder prompt = new StringBuilder();
        prompt.append("## 다음 GitHub 분석 결과 데이터를 바탕으로, 사용자가 선택한 저장소들의 정보를 종합하여 아래 항목들에 대해 분석해주세요.\n\n");
        prompt.append("1. primaryRole: 저장소 데이터를 분석하여 사용자가 가장 적합한 IT 직무(예: Backend, Frontend, Devops Engineer 등)를 도출해주세요.\n");
        prompt.append("2. roleScores: 도출된 primaryRole을 수행할 수 있는 능력을 0에서 100점 사이로 산정해주세요.\n");
        prompt.append("3. aiAnalysis:\n");
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
     * 1. 메서드 설명: 커버레터 분석에 사용할 프롬프트를 생성하는 메서드.
     * 2. 로직:
     *    - 자기소개서 텍스트를 기반으로 분석 지침과 출력 예시를 포함한 프롬프트 문자열을 구성한다.
     * 3. param:
     *      content - 분석에 사용할 커버레터 텍스트.
     * 4. return: 생성된 프롬프트 문자열.
     */
    private String generateCoverLetterAnalysisPrompt(String content) {
        StringBuilder prompt = new StringBuilder();
        prompt.append("\n");
        prompt.append("분석 결과는 다음 두 가지 부분으로 구성되어야 합니다:\n");
        prompt.append("1. 8가지 역량의 각 항목(globalCapability, challengeSpirit, sincerity, communicationSkill, ");
        prompt.append("achievementOrientation, responsibility, honesty, creativity)은 1부터 10까지의 정수로 평가합니다.\n");
        prompt.append("2. 전반적인 분석은 'analysisResult' 문자열으로 작성되어야 하며, ");
        prompt.append("강점, 약점 및 개선방안을 포함한 분석 결과를 문장으로 요약해 주세요.\n");
        prompt.append("\n");
        prompt.append("출력 형식은 아래 JSON 예시와 정확히 일치해야 하며, 추가적인 설명이나 텍스트는 포함하지 않아야 합니다.\n");
        prompt.append("\n");
        prompt.append("## 출력 예시\n");
        prompt.append("{\n");
        prompt.append("    \"analysisResult\": ");
        prompt.append("      \"분석 결과 요약 1\",\n");
        prompt.append("    \"globalCapability\": 8,\n");
        prompt.append("    \"challengeSpirit\": 9,\n");
        prompt.append("    \"sincerity\": 7,\n");
        prompt.append("    \"communicationSkill\": 8,\n");
        prompt.append("    \"achievementOrientation\": 6,\n");
        prompt.append("    \"responsibility\": 9,\n");
        prompt.append("    \"honesty\": 8,\n");
        prompt.append("    \"creativity\": 9,\n");
        prompt.append("}\n");
        prompt.append("\n");
        prompt.append("## 분석에 사용할 자기소개서 텍스트:\n");
        prompt.append(content);
        return prompt.toString();
    }

    /**
     * 1. 메서드 설명: JSON 문자열을 파싱하여 GithubAnalysisResult 객체로 변환하는 메서드.
     * 2. 로직:
     *    - ObjectMapper를 사용하여 입력받은 JSON 문자열을 GithubAnalysisResult 객체로 역직렬화한다.
     * 3. param:
     *      jsonString - 분석 결과를 담은 JSON 문자열.
     * 4. return: 역직렬화된 GithubAnalysisResult 객체.
     */
    private GithubAnalysisResult githubAnalysisResultParser(String jsonString) {
        try {
            return objectMapper.readValue(jsonString, GithubAnalysisResult.class);
        } catch (IOException e) {
            throw new JsonParsingException("GithubAnalysisResult JSON 파싱 중 오류 발생");
        }
    }

    /**
     * 1. 메서드 설명: JSON 문자열을 파싱하여 CoverLetterAnalysis 객체로 변환하는 메서드.
     * 2. 로직:
     *    - ObjectMapper를 사용하여 입력받은 JSON 문자열을 CoverLetterAnalysis 객체로 역직렬화한다.
     * 3. param:
     *      jsonString - 분석 결과를 담은 JSON 문자열.
     * 4. return: 역직렬화된 CoverLetterAnalysis 객체.
     */
    private CoverLetterAnalysis coverLetterAnalysisResultParser(String jsonString) {
        try {
            return objectMapper.readValue(jsonString, CoverLetterAnalysis.class);
        } catch (IOException e) {
            throw new JsonParsingException("CoverLetterAnalysis JSON 파싱 중 오류 발생");
        }
    }
}
