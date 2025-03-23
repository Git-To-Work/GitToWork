package com.gittowork.domain.github.repository;

import com.gittowork.domain.github.entity.GithubCode;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface GithubCodeRepository extends MongoRepository<GithubCode, String> {
}
