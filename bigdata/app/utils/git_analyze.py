# app/utils/git_analyze.py

from datetime import datetime
import os
import re
import subprocess
import tempfile
from collections import defaultdict
from zoneinfo import ZoneInfo

import lizard
from bson import ObjectId
from dotenv import load_dotenv
from github import Github
from pymongo import MongoClient

now_utc = datetime.now(tz=ZoneInfo("UTC"))
now_kst = now_utc.astimezone(ZoneInfo("Asia/Seoul")).isoformat()


#############################
# Helper Functions (공통)
#############################

def get_language(filename, ext_to_lang):
    """
    파일의 basename(파일명만)을 기준으로 확장자에 따라 언어(또는 파일 유형)를 반환.
    ext_to_lang에 없는 경우 "Unknown" 반환.
    """
    base = os.path.basename(filename).lower()
    if base in ext_to_lang:
        return ext_to_lang[base]
    _, ext = os.path.splitext(base)
    return ext_to_lang.get(ext.lower(), "Unknown") if ext else "Unknown"

def simple_syllable_count(word):
    """
    굉장히 단순한 모음 기반 syllable count 함수 (영어 기준)
    """
    word = word.lower()
    vowels = "aeiouy"
    count = 0
    prev_char_was_vowel = False
    for char in word:
        is_vowel = char in vowels
        if is_vowel and not prev_char_was_vowel:
            count += 1
        prev_char_was_vowel = is_vowel
    return count if count > 0 else 1

def flesch_reading_ease(text):
    """
    간단하게 Flesch Reading Ease score를 계산.
    FRE = 206.835 - 1.015*(words/sentences) - 84.6*(syllables/words)
    """
    sentences = re.split(r'[.!?]+', text)
    sentences = [s for s in sentences if s.strip()]
    words = re.findall(r'\w+', text)
    if not sentences or not words:
        return None
    total_syllables = sum(simple_syllable_count(word) for word in words)
    words_per_sentence = len(words) / len(sentences)
    syllables_per_word = total_syllables / len(words)
    score = 206.835 - 1.015 * words_per_sentence - 84.6 * syllables_per_word
    return round(score, 2)

#############################
# Configuration Section
#############################

load_dotenv()

ext_to_lang = {
    ".py": "Python",
    ".js": "JavaScript",
    ".ts": "TypeScript",
    ".java": "Java",
    ".cpp": "C++",
    ".c": "C",
    ".cs": "C#",
    ".go": "Go",
    ".kt": "Kotlin",
    ".php": "PHP",
    ".gitignore": "Git 설정",
    ".gitattributes": "Git 설정"
}

#############################
# GitHub 및 MongoDB 관련 함수
#############################

def get_github_client(user_github_access_token: str) -> Github:
    """Github API 클라이언트를 생성합니다."""
    return Github(user_github_access_token)

def get_repo_full_names(selected_repositories_id):
    """
    MongoDB에서 selected_repository_id로 문서를 조회하여,
    repositories 배열 내 fullName 값을 리스트로 추출하는 함수.
    """
    mongodb_url = os.getenv("MONGODB_URL")
    if not mongodb_url:
        raise ValueError("MONGODB_URL 환경 변수가 설정되지 않았습니다.")
    client = MongoClient(mongodb_url)
    db = client.get_default_database()
    collection = db["selected_repository"]
    document = collection.find_one({"_id": ObjectId(selected_repositories_id)})
    if not document:
        raise ValueError(f"해당 _id({selected_repositories_id})로 문서를 찾을 수 없습니다.")
    if "repositories" not in document:
        raise KeyError("문서에 'repositories' 필드가 없습니다.")
    repo_full_names = [repo["fullName"] for repo in document["repositories"] if "fullName" in repo]
    return repo_full_names

#############################
# 분석 관련 헬퍼 함수들
#############################

def get_commit_activity(repo):
    """저장소의 커밋 활동 정보를 계산합니다."""
    all_commits = list(repo.get_commits())
    total_commits = len(all_commits)
    if total_commits > 0:
        first_commit_date = all_commits[-1].commit.author.date
        last_commit_date = all_commits[0].commit.author.date
        period_days = (last_commit_date - first_commit_date).days or 1
        commit_frequency = round(total_commits / period_days, 2)
    else:
        first_commit_date = None
        last_commit_date = None
        commit_frequency = 0
    return {
        "total_commits": total_commits,
        "first_commit_date": first_commit_date.isoformat() if first_commit_date else None,
        "last_commit_date": last_commit_date.isoformat() if last_commit_date else None,
        "commit_frequency_per_day": commit_frequency
    }

def get_language_commit_metrics(repo, ext_to_lang):
    """저장소의 트리에서 언어별 커밋 수를 누적하여 계산합니다."""
    language_metrics = defaultdict(lambda: {"commit_count": 0})
    default_branch = repo.default_branch
    tree = repo.get_git_tree(default_branch, recursive=True)
    for element in tree.tree:
        if element.type != "blob":
            continue
        file_path = element.path
        lang = get_language(file_path, ext_to_lang)
        if lang == "Unknown":
            continue
        commits_for_file = repo.get_commits(path=file_path)
        language_metrics[lang]["commit_count"] += commits_for_file.totalCount
    return dict(language_metrics)

def collect_file_list(clone_dir, ext_to_lang):
    """clone_dir 내에서 ext_to_lang에 해당하는 파일 목록을 수집합니다."""
    file_list = []
    for root, dirs, files in os.walk(clone_dir):
        for file in files:
            base = file.lower()
            _, ext = os.path.splitext(base)
            if base in ext_to_lang or ext in ext_to_lang:
                file_list.append(os.path.join(root, file))
    return file_list

def update_metrics_for_file(file_info, ext_to_lang, complexity_metrics):
    """하나의 파일(file_info)에 대해 복잡도 메트릭을 누적합니다."""
    lang = get_language(file_info.filename, ext_to_lang)
    if lang == "Unknown":
        return
    metrics = complexity_metrics[lang]
    metrics["total_files"] += 1
    metrics["total_cyclomatic_complexity"] += file_info.average_cyclomatic_complexity
    metrics["total_nloc"] += file_info.nloc
    metrics["total_token_count"] += file_info.token_count
    param_count = sum(func.parameter_count for func in file_info.function_list)
    metrics["total_parameter_count"] += param_count

def finalize_metrics(complexity_metrics):
    """누적된 복잡도 메트릭을 기반으로 평균 값을 계산합니다."""
    for lang, metrics in complexity_metrics.items():
        if metrics["total_files"] > 0:
            metrics["average_cyclomatic_complexity"] = round(
                metrics["total_cyclomatic_complexity"] / metrics["total_files"], 2
            )
            metrics["average_nloc"] = round(
                metrics["total_nloc"] / metrics["total_files"], 2
            )
            metrics["average_token_count"] = round(
                metrics["total_token_count"] / metrics["total_files"], 2
            )
            metrics["average_parameter_count"] = round(
                metrics["total_parameter_count"] / metrics["total_files"], 2
            )
    return dict(complexity_metrics)

def get_complexity_metrics(repo, ext_to_lang):
    """
    Lizard를 사용해 저장소의 코드 복잡도 메트릭을 계산합니다.
    파일 목록 수집, 각 파일별 메트릭 업데이트, 평균 계산을 헬퍼 함수로 분리하여
    인지 복잡도를 낮춥니다.
    """
    complexity_metrics = defaultdict(lambda: {
        "total_files": 0,
        "total_cyclomatic_complexity": 0.0,
        "total_nloc": 0,
        "total_token_count": 0,
        "total_parameter_count": 0,
        "average_cyclomatic_complexity": 0.0,
        "average_nloc": 0.0,
        "average_token_count": 0.0,
        "average_parameter_count": 0.0
    })
    with tempfile.TemporaryDirectory() as tmpdirname:
        clone_dir = os.path.join(tmpdirname, "repo")
        subprocess.run(
            ["git", "clone", repo.clone_url, clone_dir],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        file_list = collect_file_list(clone_dir, ext_to_lang)
        analysis_result = lizard.analyze_files(file_list)
        for file_info in analysis_result:
            update_metrics_for_file(file_info, ext_to_lang, complexity_metrics)
        return finalize_metrics(complexity_metrics)

def get_readme_analysis(repo):
    """README 파일의 내용 및 Flesch Reading Ease 점수를 계산합니다."""
    try:
        readme = repo.get_readme()
        content = readme.decoded_content.decode("utf-8")
        word_count = len(re.findall(r'\w+', content))
        reading_ease = flesch_reading_ease(content)
    except Exception:
        content = ""
        word_count = 0
        reading_ease = None
    return {
        "word_count": word_count,
        "content_preview": content[:200],
        "flesch_reading_ease": reading_ease
    }

def analyze_repo(repo_full_name, github_client: Github):
    """
    주어진 저장소의 fullName과 Github 클라이언트를 사용해, 해당 저장소의
    다양한 메트릭(기본 통계, 커밋 활동, 코드 복잡도, README 분석 등)을 분석하고
    결과 보고서를 구성하여 반환합니다.
    """
    repo = github_client.get_repo(repo_full_name)

    # 기본 통계
    stars = repo.stargazers_count
    forks = repo.forks_count
    open_issues = repo.get_issues(state="open").totalCount
    open_pulls = repo.get_pulls(state="open").totalCount

    # 커밋 활동 분석
    commit_activity = get_commit_activity(repo)
    # 언어별 커밋 지표
    language_commit_metrics = get_language_commit_metrics(repo, ext_to_lang)
    # 코드 복잡도 분석
    complexity_metrics = get_complexity_metrics(repo, ext_to_lang)
    # README 분석
    readme_analysis = get_readme_analysis(repo)

    report = {
        "repository": repo_full_name,
        "stars": stars,
        "forks": forks,
        "open_issues": open_issues,
        "open_pull_requests": open_pulls,
        "commit_activity": commit_activity,
        "language_commit_metrics": dict(language_commit_metrics),
        "complexity_metrics": dict(complexity_metrics),
        "readme_analysis": readme_analysis
    }
    return report

#############################
# run_full_analysis 및 관련 헬퍼 함수
#############################

def process_all_repositories(repo_full_names, github_client):
    """모든 저장소에 대해 분석 보고서를 생성합니다."""
    reports = []
    for repo_name in repo_full_names:
        try:
            report = analyze_repo(repo_name, github_client)
            reports.append(report)
        except Exception as e:
            print(f"{repo_name} 분석 중 오류 발생: {e}")
    return reports

def save_analysis_result_to_mongo(user_id, selected_repositories_id, all_reports):
    """MongoDB에 분석 결과를 저장합니다."""
    mongodb_url = os.getenv("MONGODB_URL")
    if not mongodb_url:
        raise ValueError("MONGODB_URL 환경 변수가 설정되지 않았습니다.")
    from pymongo import MongoClient
    client = MongoClient(mongodb_url)
    mongo_db = client.get_default_database()
    collection = mongo_db["github_analysis_result_for_recommend"]
    record = {
        "user_id": user_id,
        "selected_repositories_id": selected_repositories_id,
        "repositories": all_reports,
        "analysis_dttm": now_kst
    }
    collection.update_one(
        {"user_id": user_id, "selected_repositories_id": selected_repositories_id},
        {"$set": record},
        upsert=True
    )

def run_full_analysis(user_github_access_token, selected_repositories_id, user_id):
    """
    전체 분석 프로세스를 수행하여 분석 결과를 MongoDB에 저장합니다.
    """
    github_client = get_github_client(user_github_access_token)
    repo_full_names = get_repo_full_names(selected_repositories_id)
    all_reports = process_all_repositories(repo_full_names, github_client)
    save_analysis_result_to_mongo(user_id, selected_repositories_id, all_reports)
