package com.gittowork.domain.coverletter.repository;

import com.gittowork.domain.coverletter.entity.CoverLetter;
import com.gittowork.domain.user.entity.User;
import jakarta.validation.constraints.NotNull;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CoverLetterRepository extends JpaRepository<CoverLetter, Integer> {
    List<CoverLetter> findAllByUser_Id(int userId);
}
