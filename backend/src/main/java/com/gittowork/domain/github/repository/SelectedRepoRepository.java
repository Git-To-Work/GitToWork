package com.gittowork.domain.github.repository;

import com.gittowork.domain.github.entity.SelectedRepository;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SelectedRepoRepository extends MongoRepository<SelectedRepository, Integer> {
    List<SelectedRepository> findAllByUserId(int userId);
}
