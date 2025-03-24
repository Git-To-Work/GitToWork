package com.gittowork.domain.github.repository;

import com.gittowork.domain.github.entity.GithubEvent;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.Optional;

@Repository
public interface GithubEventRepository extends MongoRepository<GithubEvent, String> {
    Optional<GithubEvent> findTopByUserIdOrderByEventsCreatedAtDesc(int userId);

    Collection<GithubEvent> findAllByUserId(int userId);
}
