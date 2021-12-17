#!/bin/bash

case "$JOB_STATUS" in
  success) STATUS_COLOR=$((0x448844)) ;;
  failure) STATUS_COLOR=$((0xD82828)) ;;
  cancelled) STATUS_COLOR=$((0x606060)) ;;
  *) printf '[WARN] Unknown status "%s"\n' "$JOB_STATUS"
esac

: "${GITHUB_BASE_REF:-$GITHUB_REF}"; REPO_BRANCH="${_##*/}"

REPO_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/commit/$GITHUB_SHA"
REPO_TREE="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/tree/$REPO_BRANCH"

COMMIT_SUBJECT="$(git -C "$GITHUB_WORKSPACE" \
                  log -1 "$GITHUB_SHA" --pretty='%s')"
COMMIT_MESSAGE="$(git -C "$GITHUB_WORKSPACE" \
                  log -1 "$GITHUB_SHA" --pretty='%b')"
COMMITTER_NAME="$(git -C "$GITHUB_WORKSPACE" \
                  log -1 "$GITHUB_SHA" --pretty='%cN')"

: "${COMMIT_MESSAGE//$'\r'/}"; : "${_//\"/\\\"}"; COMMIT_MESSAGE="${_//$'\n'/$'\\n'}"

ACTION_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"

AVATAR="https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png"

WEBHOOK_DATA=$'{
  "username": "GitHub",
  "avatar_url": "'$AVATAR'",
  "embeds": [{
    "color": '${STATUS_COLOR:-$((0xFFFFFF))}',
    "author": {
      "name": "'$GITHUB_REPOSITORY' #'$GITHUB_RUN_NUMBER$RUN_SUFFIX'",
      "url": "'$ACTION_URL'",
      "icon_url": "'$GITHUB_SERVER_URL/$GITHUB_ACTOR'.png?s=40"
    },
    "title": "'$COMMIT_SUBJECT'",
    "url": "'$REPO_URL'",
    "description": "'$COMMIT_MESSAGE'",
    "footer": {
      "text": "'$COMMITTER_NAME'",
      "icon_url": "'$GITHUB_SERVER_URL/$COMMITTER_NAME'.png?s=40"
    },
    "fields": [{
      "name": "Status",
      "value": "'$JOB_STATUS'",
      "inline": true
    }, {
      "name": "Branch",
      "value": "[`'$REPO_BRANCH'`]('$REPO_TREE')",
      "inline": true
    }, {
      "name": "'${LANG_NAME:=Bash}'",
      "value": "'${LANG_VERSION:=$BASH_VERSION}'",
      "inline": true
    }],
    "timestamp": "'$(date --utc +%FT%TZ)'"
  }]
}'

SELF_URL='https://github.com/mangadventure/discord-webhook'

printf '[INFO] Sending webhook to Discord...\n'
if curl -Ssf "$WEBHOOK_URL" -d "$WEBHOOK_DATA" \
    -A "Discord-Webhook ($SELF_URL, v0.1)" \
    -H 'Content-Type: application/json'; then
  printf '[INFO] Successfully sent the webhook.\n'
else
  ecode=$?
  printf '[ERROR] Failed to send the webhook.\n'
  exit $ecode
fi
