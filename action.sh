#!/bin/bash

set -o pipefail

case "$JOB_STATUS" in
  success) STATUS_COLOR=$((0x448844)) ;;
  failure) STATUS_COLOR=$((0xD82828)) ;;
  cancelled) STATUS_COLOR=$((0x606060)) ;;
  *) printf '[WARN] Unknown status "%s"\n' "$JOB_STATUS"
esac

REPO_BRANCH="${GITHUB_BASE_REF:-$GITHUB_REF_NAME}"
REPO_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/commit/$GITHUB_SHA"
REPO_TREE="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/tree/$REPO_BRANCH"

COMMIT_SUBJECT="$(git -C "$GITHUB_WORKSPACE" log -1 "$GITHUB_SHA" --pretty='%s')"
COMMIT_MESSAGE="$(git -C "$GITHUB_WORKSPACE" log -1 "$GITHUB_SHA" --pretty='%b')"
COMMITTER_NAME="$(git -C "$GITHUB_WORKSPACE" log -1 "$GITHUB_SHA" --pretty='%cN')"

ACTION_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"

AVATAR="https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png"

export AVATAR ACTION_URL COMMIT_SUBJECT REPO_URL COMMIT_MESSAGE COMMITTER_NAME JOB_STATUS

WEBHOOK_DATA=$'{
  username: "GitHub",
  avatar: $ENV.AVATAR,
  embeds: [{
    color: $color|tonumber,
    author: {
      url: $ENV.ACTION_URL,
      name: $author,
      icon: $icon
    },
    title: $ENV.COMMIT_SUBJECT,
    url: $ENV.REPO_URL,
    description: $ENV.COMMIT_MESSAGE,
    footer: {
      text: $ENV.COMMITTER_NAME,
      icon_url: $icon
    },
    fields: [{
      name: "Status",
      value: $ENV.JOB_STATUS,
      inline: true
    }, {
      name: "Branch",
      value: $branch,
      inline: true
    }, {
      name: $lang_name,
      value: $lang_version,
      inline: true
    }],
    timestamp: $date
  }]
}'

SELF_URL='https://github.com/mangadventure/discord-webhook'

printf '[INFO] Sending webhook to Discord...\n'
jq -Mn "$WEBHOOK_DATA" \
  --arg color "${STATUS_COLOR:-$((0xFFFFFF))}" \
  --arg author "$GITHUB_REPOSITORY #$GITHUB_RUN_NUMBER$RUN_SUFFIX" \
  --arg icon "$GITHUB_SERVER_URL/$GITHUB_ACTOR.png?s=40" \
  --arg branch "[$REPO_BRANCH]($REPO_TREE)" \
  --arg lang_name "${LANG_NAME:-Bash}" \
  --arg lang_version "${LANG_VERSION:-$BASH_VERSION}" \
  --arg date "$(date --utc +%FT%TZ)" \
  | curl "$WEBHOOK_URL" -H 'Content-Type: application/json' \
     -Ssf -d@- -A "Discord-Webhook ($SELF_URL, v0.5)"
ecode=$?
if ((ecode == 0)); then
  printf '[INFO] Successfully sent the webhook.\n'
else
  printf '[ERROR] Failed to send the webhook.\n'
  exit $ecode
fi
