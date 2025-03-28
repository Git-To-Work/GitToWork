package com.gittowork.domain.coverletter.repository;

import com.gittowork.domain.coverletter.entity.CoverLetterAnalysis;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CoverLetterAnalysisRepository extends JpaRepository<CoverLetterAnalysis, Integer> {
}
