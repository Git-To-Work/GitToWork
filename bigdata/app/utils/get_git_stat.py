import logging
from datetime import datetime
from typing import Dict, Any, List, Optional, Tuple
from app.core.mongo import get_mongo_db

"""
/**
 * 1. 메서드 설명: 주어진 커밋 리스트로부터 총 커밋 수, 최초/최종 커밋 날짜, 일평균 커밋 빈도를 계산한다.
 *
 * 2. 로직:
 *    - ISO 포맷의 커밋 날짜 문자열을 datetime 객체로 변환한다.
 *    - 최초 커밋일과 최종 커밋일 사이의 일 수를 구해 커밋 빈도(일별 평균 커밋 수)를 계산한다.
 *    - 커밋이 없을 경우 None 및 0.0 빈도로 반환한다.
 *
 * 3. param:
 *    - commits: 커밋 정보를 담은 딕셔너리 리스트
 *
 * 4. return:
 *    - (총 커밋 수, 최초 커밋일, 최종 커밋일, 일평균 커밋 수)의 튜플
 */
"""
def parse_commit_dates(commits: List[Dict[str, Any]]) -> Tuple[int, Optional[datetime], Optional[datetime], float]:
    commit_dates = [
        datetime.fromisoformat(commit["commit_date"].replace("Z", "+00:00"))
        for commit in commits if commit.get("commit_date")
    ]
    total_commits = len(commits)
    if commit_dates:
        first_date = min(commit_dates)
        last_date = max(commit_dates)
        delta_days = (last_date - first_date).days or 1  # 0일인 경우 1로 처리
        frequency = total_commits / delta_days
        return total_commits, first_date, last_date, frequency
    return total_commits, None, None, 0.0

"""
/**
 * 1. 메서드 설명: 단일 GitHub 레포지토리에 대한 다양한 통계 정보를 MongoDB에서 조회 및 구성한다.
 *
 * 2. 로직:
 *    - github_repository 컬렉션에서 레포지토리의 기본 정보(별 개수, 포크 수 등)를 조회한다.
 *    - github_issue, github_pull_request 컬렉션에서 열린 이슈와 PR 개수를 센다.
 *    - github_commit 컬렉션에서 커밋 활동 정보를 조회하고, 커밋 수 및 커밋 빈도를 계산한다.
 *    - 모든 데이터를 하나의 딕셔너리로 구성하여 반환한다.
 *
 * 3. param:
 *    - user_id: 사용자 고유 ID
 *    - repo_id: 조회할 레포지토리 ID
 *
 * 4. return:
 *    - repository: 레포지토리 이름
 *    - stars, forks: 별 개수 및 포크 수
 *    - open_issues, open_pull_requests: 열린 이슈 및 PR 개수
 *    - commit_activity: 커밋 수, 최초/최종 커밋일, 커밋 빈도 등 커밋 관련 정보
 */
"""
def get_repo_stats(user_id: int, repo_id: str) -> Dict[str, Any]:
    db = get_mongo_db()

    # github_repository 컬렉션에서 레포지토리 정보 조회
    repo_doc = db.github_repository.find_one(
        {"user_id": user_id, "repositories.repo_id": repo_id},
        {"repositories.$": 1}
    )
    if not repo_doc or "repositories" not in repo_doc or not repo_doc["repositories"]:
        raise ValueError("Repository not found in github_repository collection")

    repo_info = repo_doc["repositories"][0]
    repository_name = repo_info.get("full_name", "")
    stars = repo_info.get("stargazers_count", 0)
    forks = repo_info.get("forks_count", 0)

    # open 이슈 및 PR 수 조회
    open_issues = db.github_issue.count_documents({"repo_id": repo_id})
    open_pull_requests = db.github_pull_request.count_documents({"repo_id": repo_id})

    # 커밋 활동 조회
    commit_doc = db.github_commit.find_one({"user_id": user_id, "repo_id": repo_id})
    if commit_doc and "commits" in commit_doc:
        total_commits, first_commit_date, last_commit_date, commit_frequency = parse_commit_dates(commit_doc["commits"])
    else:
        total_commits, first_commit_date, last_commit_date, commit_frequency = 0, None, None, 0.0

    commit_activity = {
        "total_commits": total_commits,
        "first_commit_date": first_commit_date.isoformat() if first_commit_date else None,
        "last_commit_date": last_commit_date.isoformat() if last_commit_date else None,
        "commit_frequency_per_day": commit_frequency
    }

    return {
        "repository": repository_name,
        "stars": stars,
        "forks": forks,
        "open_issues": open_issues,
        "open_pull_requests": open_pull_requests,
        "commit_activity": commit_activity
    }

"""
/**
 * 1. 메서드 설명: 선택된 복수 개의 GitHub 레포지토리에 대한 통계를 평균 내어 하나의 집계 정보로 반환한다.
 *
 * 2. 로직:
 *    - 선택된 레포지토리 ID를 통해 각 레포지토리에 대한 통계를 조회한다.
 *    - stars, forks, open_issues, open_pull_requests 등 수치형 데이터를 평균 계산한다.
 *    - commit_activity(총 커밋 수, 커밋 빈도)도 개별 통계에서 평균을 구한다.
 *    - 집계된 평균값들을 딕셔너리로 구성하여 반환한다.
 *
 * 3. param:
 *    - selected_repositories_id: 선택된 레포지토리 그룹의 식별자
 *    - user_id: 사용자 고유 ID
 *
 * 4. return:
 *    - stars, forks, open_issues, open_pull_requests: 평균 수치
 *    - commit_activity: 평균 커밋 수 및 평균 커밋 빈도
 */
"""
def get_selected_repo_stats(selected_repositories_id: str, user_id: int) -> List[Dict[str, Any]]:
    db = get_mongo_db()

    selected_repo_doc = db.selected_repository.find_one({"selected_repositories_id": selected_repositories_id})
    if not selected_repo_doc or "repositories" not in selected_repo_doc:
        raise ValueError("Selected repositories document not found.")

    stats_list = []
    for repo_obj in selected_repo_doc["repositories"]:
        repo_id = repo_obj.get("repo_id")
        if repo_id:
            try:
                stats = get_repo_stats(user_id, repo_id)
                stats_list.append(stats)
            except Exception as e:
                logging.error(f"Error processing repo_id {repo_id}: {e}")
    return stats_list


"""
선택된 레포지토리들의 통계 정보를 평균화하여 집계합니다.
하나 이상의 통계 정보가 없을 경우 예외를 발생시킵니다.
"""
def aggregate_selected_repo_stats(selected_repositories_id: str, user_id: int) -> Dict[str, Any]:
    stats_list = get_selected_repo_stats(selected_repositories_id, user_id)
    if not stats_list:
        raise ValueError("No repository stats available to aggregate.")

    count = len(stats_list)
    total_stars = sum(stats.get("stars", 0) for stats in stats_list)
    total_forks = sum(stats.get("forks", 0) for stats in stats_list)
    total_open_issues = sum(stats.get("open_issues", 0) for stats in stats_list)
    total_open_pull_requests = sum(stats.get("open_pull_requests", 0) for stats in stats_list)

    total_commits = sum(stats.get("commit_activity", {}).get("total_commits", 0) for stats in stats_list)
    total_commit_freq = sum(stats.get("commit_activity", {}).get("commit_frequency_per_day", 0) for stats in stats_list)

    aggregated_commit_activity = {
        "total_commits": total_commits / count,
        "commit_frequency_per_day": total_commit_freq / count
    }

    return {
        "stars": total_stars / count,
        "forks": total_forks / count,
        "open_issues": total_open_issues / count,
        "open_pull_requests": total_open_pull_requests / count,
        "commit_activity": aggregated_commit_activity
    }

