package com.gittowork.domain.jobnotice.repository;

import com.gittowork.domain.jobnotice.entity.JobNotice;
import org.springframework.data.jpa.repository.JpaRepository;

public interface JobNoticeRepository extends JpaRepository<JobNotice, Integer> {
}
