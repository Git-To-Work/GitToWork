package com.gittowork.domain.github.repository;

import com.gittowork.domain.github.entity.GithubAnalysisResult;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface GithubAnalysisResultRepository extends MongoRepository<GithubAnalysisResult, String> {
}
