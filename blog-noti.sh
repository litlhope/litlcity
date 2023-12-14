#!/bin/bash

# 슬랙 웹훅 URL 설정
slack_webhook_url="https://hooks.slack.com/services/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"

# 인자 확인
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <git-repo-path>"
    exit 1
fi

git_repo_path=$1

# Git 저장소로 이동
cd "$git_repo_path" || exit

# 마지막 커밋 메시지 추출
last_commit_message=$(git log -1 --pretty=%B)

# 슬랙 메시지 포맷
slack_message="블로그에 새로운 게시글이 등록되었습니다.\n${last_commit_message}"

# 슬랙 웹훅을 통해 메시지 전송
curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"${slack_message}\"}" $slack_webhook_url
