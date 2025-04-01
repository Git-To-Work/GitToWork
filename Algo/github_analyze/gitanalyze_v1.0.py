import os
import re
import json
import subprocess
import tempfile
from collections import defaultdict
from datetime import datetime
from github import Github
from dotenv import load_dotenv
import lizard
import datetime

#####################
# Helper Functions  #
#####################

def get_language(filename):
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

#########################
# Configuration Section #
#########################

load_dotenv()
access_token = os.getenv("GITHUB_ACCESS_TOKEN")
if not access_token:
    raise ValueError("GITHUB_ACCESS_TOKEN 환경 변수가 설정되지 않았습니다.")

# 분석 대상 레포지토리 (형식: "사용자이름/레포지토리이름")
repo_full_name = "chanhoan/chanhoan_Github"  # 수정 가능

# 분석 대상 개발 언어 확장자 매핑 (HTML, CSS, Markdown 등 제외)
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

##############################
# GitHub Data Collection     #
##############################

g = Github(access_token)
repo = g.get_repo(repo_full_name)

stars = repo.stargazers_count
forks = repo.forks_count
open_issues = repo.get_issues(state="open").totalCount
open_pulls = repo.get_pulls(state="open").totalCount

# -------------------------
# 프로젝트 커밋 활동 분석
# -------------------------
all_commits = list(repo.get_commits())
total_commits = len(all_commits)
if total_commits > 0:
    # GitHub API returns commits in descending order (최신이 첫 번째)
    first_commit_date = all_commits[-1].commit.author.date
    last_commit_date = all_commits[0].commit.author.date
    # 기간(일수) 계산
    period_days = (last_commit_date - first_commit_date).days or 1  # 0이면 1로 처리
    commit_frequency_per_day = round(total_commits / period_days, 2)
else:
    first_commit_date = None
    last_commit_date = None
    commit_frequency_per_day = 0

commit_activity = {
    "total_commits": total_commits,
    "first_commit_date": first_commit_date.isoformat() if first_commit_date else None,
    "last_commit_date": last_commit_date.isoformat() if last_commit_date else None,
    "commit_frequency_per_day": commit_frequency_per_day
}

############################################
# 1. 언어별 커밋 빈도 및 변경 규모 분석     #
############################################

language_commit_metrics = defaultdict(lambda: {"commit_count": 0})
default_branch = repo.default_branch
tree = repo.get_git_tree(default_branch, recursive=True)
for element in tree.tree:
    if element.type == "blob":
        file_path = element.path
        lang = get_language(file_path)
        if lang == "Unknown":
            continue
        commits_for_file = repo.get_commits(path=file_path)
        language_commit_metrics[lang]["commit_count"] += commits_for_file.totalCount

####################################################
# 2. 코드 복잡도 분석 (Lizard의 확장된 메트릭 활용) #
####################################################

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
    file_list = []
    for root, dirs, files in os.walk(clone_dir):
        for file in files:
            base = file.lower()
            _, ext = os.path.splitext(base)
            if base in ext_to_lang or ext in ext_to_lang:
                file_list.append(os.path.join(root, file))
    analysis_result = lizard.analyze_files(file_list)
    for file_info in analysis_result:
        lang = get_language(file_info.filename)
        if lang == "Unknown":
            continue
        complexity_metrics[lang]["total_files"] += 1
        complexity_metrics[lang]["total_cyclomatic_complexity"] += file_info.average_cyclomatic_complexity
        complexity_metrics[lang]["total_nloc"] += file_info.nloc
        complexity_metrics[lang]["total_token_count"] += file_info.token_count
        # 파일 내 함수별 파라미터 수 합산
        param_count = sum(func.parameter_count for func in file_info.function_list)
        complexity_metrics[lang]["total_parameter_count"] += param_count
    for lang, metrics in complexity_metrics.items():
        if metrics["total_files"] > 0:
            metrics["average_cyclomatic_complexity"] = round(metrics["total_cyclomatic_complexity"] / metrics["total_files"], 2)
            metrics["average_nloc"] = round(metrics["total_nloc"] / metrics["total_files"], 2)
            metrics["average_token_count"] = round(metrics["total_token_count"] / metrics["total_files"], 2)
            metrics["average_parameter_count"] = round(metrics["total_parameter_count"] / metrics["total_files"], 2)

#################################
# 3. README 분석 (NLP 기반)    #
#################################

try:
    readme = repo.get_readme()
    readme_content = readme.decoded_content.decode("utf-8")
    readme_word_count = len(re.findall(r'\w+', readme_content))
    reading_ease = flesch_reading_ease(readme_content)
except Exception:
    readme_content = ""
    readme_word_count = 0
    reading_ease = None

readme_analysis = {
    "word_count": readme_word_count,
    "content_preview": readme_content[:200],
    "flesch_reading_ease": reading_ease
}

#######################################
# 종합 보고서 구성 및 인기 지표 추가   #
#######################################

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

report_json = json.dumps(report, indent=4, ensure_ascii=False)

# 현재 날짜-시간을 "YYYYMMDD-HHMMSS" 형식으로 생성
current_time_str = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
# 파일 이름 구성: {현재날짜-시간}_{레포지토리이름}.json
file_name = f"{current_time_str}_{repo.name}.json"

# 사용자 폴더 경로: ./user/{userName}
# repo.owner.login 은 GitHub 레포지토리 소유자(사용자)의 이름입니다.
output_dir = os.path.join(".", "user", repo.owner.login)
os.makedirs(output_dir, exist_ok=True)

# 최종 파일 경로
output_path = os.path.join(output_dir, file_name)

# JSON 파일로 저장
with open(output_path, "w", encoding="utf-8") as f:
    f.write(report_json)

print(f"보고서가 저장되었습니다: {output_path}")