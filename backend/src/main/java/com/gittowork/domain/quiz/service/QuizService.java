package com.gittowork.domain.quiz.service;

import com.gittowork.domain.quiz.dto.response.QuizResponse;
import com.gittowork.domain.quiz.entity.Quiz;
import com.gittowork.domain.quiz.repository.QuizRepository;
import com.gittowork.global.exception.WrongQuizTypeException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Random;

@Service
@RequiredArgsConstructor
public class QuizService {

    private final QuizRepository quizRepository;

    /**
     * 1. 메서드 설명:
     *    - 지정한 퀴즈 형식(type)에 해당하는 퀴즈 문제 중 하나를 무작위로 반환합니다.
     * 2. 로직:
     *    - MongoDB에서 type에 해당하는 모든 퀴즈를 조회합니다.
     *    - 조회된 리스트가 비어있으면 WrongQuizTypeException을 발생시킵니다.
     *    - 리스트에서 하나의 퀴즈를 무작위로 선택합니다.
     *    - QuizResponse 형태로 가공하여 반환합니다.
     * 3. param:
     *    - type: 퀴즈 형식 문자열 (예: "ox", "2choice")
     * 4. return:
     *    - QuizResponse 객체 (type, questionId, questionText, choices, correctAnswerIndex, feedback 포함)
     * 5. 예외:
     *    - WrongQuizTypeException: 주어진 타입에 해당하는 퀴즈가 없을 경우
     */
    public QuizResponse getDeveloperQuiz(String type){
        List<Quiz> quiz = quizRepository.findByType(type);

        if(quiz.isEmpty()){
            throw new WrongQuizTypeException("Wrong quiz type");
        }

        Quiz selected = quiz.get(new Random().nextInt(quiz.size()));

        return QuizResponse.builder()
                .type(selected.getType())
                .questionId(selected.getQuestionId())
                .questionText(selected.getQuestionText())
                .choices(selected.getChoices())
                .correctAnswerIndex(selected.getCorrectAnswerIndex())
                .feedback(selected.getFeedback())
                .build();
    }
}
