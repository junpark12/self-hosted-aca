#!/bin/bash
set -e

RUNNER_SCOPE="${RUNNER_SCOPE:-org}"
RUNNER_LABELS="${RUNNER_LABELS:-container-app}"
RUNNER_GROUP="${RUNNER_GROUP:-Default}"

b64url() {
    openssl base64 -e -A | tr '+/' '-_' | tr -d '='
}

echo "GitHub App JWT 생성 중..."
NOW=$(date +%s)
IAT=$((NOW - 60))
EXP=$((NOW + 540))
HEADER=$(printf '{"alg":"RS256","typ":"JWT"}' | b64url)
PAYLOAD=$(printf '{"iat":%s,"exp":%s,"iss":"%s"}' "$IAT" "$EXP" "$GITHUB_APP_ID" | b64url)
UNSIGNED="${HEADER}.${PAYLOAD}"
SIGNATURE=$(printf '%s' "$UNSIGNED" | openssl dgst -sha256 \
    -sign <(printf '%s' "$GITHUB_APP_PRIVATE_KEY") | b64url)
JWT="${UNSIGNED}.${SIGNATURE}"

echo "Installation Access Token 요청 중..."
INSTALL_TOKEN=$(curl -s -X POST \
    -H "Authorization: Bearer ${JWT}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/app/installations/${GITHUB_APP_INSTALLATION_ID}/access_tokens" \
    | jq -r .token)

if [ -z "$INSTALL_TOKEN" ] || [ "$INSTALL_TOKEN" = "null" ]; then
    echo "Installation Token 발급 실패. App ID/Installation ID/Private Key를 확인하세요."
    exit 1
fi

if [ "$RUNNER_SCOPE" = "org" ]; then
    echo "조직 등록 토큰 요청 중: $GITHUB_OWNER"
    REG_TOKEN=$(curl -s -X POST \
        -H "Authorization: token ${INSTALL_TOKEN}" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/orgs/${GITHUB_OWNER}/actions/runners/registration-token" \
        | jq -r .token)
    RUNNER_URL="https://github.com/${GITHUB_OWNER}"
else
    echo "리포지토리 등록 토큰 요청 중: $GITHUB_OWNER/$GITHUB_REPO"
    REG_TOKEN=$(curl -s -X POST \
        -H "Authorization: token ${INSTALL_TOKEN}" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/runners/registration-token" \
        | jq -r .token)
    RUNNER_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}"
fi

if [ -z "$REG_TOKEN" ] || [ "$REG_TOKEN" = "null" ]; then
    echo "등록 토큰 발급 실패. GitHub App 권한을 확인하세요."
    exit 1
fi

echo "등록 토큰 획득 성공"
echo "Runner 구성 중..."
./config.sh --unattended \
    --name "runner-$(hostname)" \
    --url "$RUNNER_URL" \
    --token "$REG_TOKEN" \
    --runnergroup "$RUNNER_GROUP" \
    --ephemeral \
    --labels "$RUNNER_LABELS" \
    --replace

echo "Runner 시작..."
./run.sh
