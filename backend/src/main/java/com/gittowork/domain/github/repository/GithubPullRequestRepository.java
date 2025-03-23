package com.gittowork.domain.github.repository;

import com.gittowork.domain.github.entity.GithubPullRequest;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface GithubPullRequestRepository extends MongoRepository<GithubPullRequest, String> {
}
