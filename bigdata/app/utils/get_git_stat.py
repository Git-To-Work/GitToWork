from datetime import datetime
from typing import Dict, Any, List, Optional, Tuple
from app.core.mongo import get_mongo_db

"""
주어진 커밋 리스트에서 총 커밋 수, 최초/최종 커밋 날짜 및 일별 커밋 빈도를 계산합니다.
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
단일 레포지토리에 대한 통계 정보를 조회합니다.
MongoDB의 여러 컬렉션에서 정보를 집계하며, 레포지토리가 없을 경우 예외를 발생합니다.
"""
def get_repo_stats(user_id: int, repo_id: str) -> Dict[str, Any]:
    db = get_mongo_db()

    # github_repository 컬렉션에서 레포지토리 정보 조회
    repo_doc = db.github_repository.find_one(
        {"user_id": user_id, "repositories.repo_id": repo_id},
        {"repositories.$": 1}
    )
    if not repo_doc or "repositories" not in repo_doc or not repo_doc["repositories"]:
        raise Exception("Repository not found in github_repository collection")

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
선택된 레포지토리 목록에 대해 각각의 통계 정보를 조회합니다.
"""
def get_selected_repo_stats(selected_repositories_id: str, user_id: int) -> List[Dict[str, Any]]:
    db = get_mongo_db()

    selected_repo_doc = db.selected_repository.find_one({"selected_repositories_id": selected_repositories_id})
    if not selected_repo_doc or "repositories" not in selected_repo_doc:
        raise Exception("Selected repositories document not found.")

    stats_list = []
    for repo_obj in selected_repo_doc["repositories"]:
        repo_id = repo_obj.get("repo_id")
        if repo_id:
            try:
                stats = get_repo_stats(user_id, repo_id)
                stats_list.append(stats)
            except Exception as e:
                print(f"Error processing repo_id {repo_id}: {e}")
    return stats_list


"""
선택된 레포지토리들의 통계 정보를 평균화하여 집계합니다.
하나 이상의 통계 정보가 없을 경우 예외를 발생시킵니다.
"""
def aggregate_selected_repo_stats(selected_repositories_id: str, user_id: int) -> Dict[str, Any]:
    stats_list = get_selected_repo_stats(selected_repositories_id, user_id)
    if not stats_list:
        raise Exception("No repository stats available to aggregate.")

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

