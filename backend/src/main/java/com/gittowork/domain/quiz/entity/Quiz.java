package com.gittowork.domain.quiz.entity;

import lombok.*;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.util.List;

@Document(collection = "developer_quiz")
@Getter
@Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class Quiz {

    @Id
    private String id;

    private String type;

    private int questionId;

    private String questionText;

    private List<String> choices;

    private int correctAnswerIndex;

    private String feedback;

}
