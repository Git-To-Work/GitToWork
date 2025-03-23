package com.gittowork.domain.github.repository;

import com.gittowork.domain.github.entity.GithubIssue;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface GithubIssueRepository extends MongoRepository<GithubIssue, String> {
}
