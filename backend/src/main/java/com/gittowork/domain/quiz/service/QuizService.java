package com.gittowork.domain.quiz.service;

import com.gittowork.domain.quiz.dto.response.QuizResponse;
import com.gittowork.domain.quiz.entity.Quiz;
import com.gittowork.domain.quiz.repository.QuizRepository;
import com.gittowork.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Random;

@Service
@RequiredArgsConstructor
public class QuizService {

    private final QuizRepository quizRepository;
    private final UserRepository userRepository;


    public QuizResponse getDeveloperQuiz(String type){
//        String username = SecurityContextHolder.getContext().getAuthentication().getName();
//        User user = userRepository.findByGithubName(username).orElseThrow(()-> new UserNotFoundException("User Not Found"));

        List<Quiz> quiz = quizRepository.findByType(type);

        if(quiz.isEmpty()){
            throw new RuntimeException("wrong type");
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
