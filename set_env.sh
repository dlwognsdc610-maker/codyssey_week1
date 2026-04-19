#!/usr/bin/env bash

#local -> global 
GIT_USER_VAL="$(git config --get user.name 2>/dev/null)"
[ -z "$GIT_USER_VAL" ] && GIT_USER_VAL="$(git config --global --get user.name 2>/dev/null)"
[ -z "$GIT_USER_VAL" ] && GIT_USER_VAL="Your Name"

GIT_EMAIL_VAL="$(git config --get user.email 2>/dev/null)"
[ -z "$GIT_EMAIL_VAL" ] && GIT_EMAIL_VAL="$(git config --global --get user.email 2>/dev/null)"
[ -z "$GIT_EMAIL_VAL" ] && GIT_EMAIL_VAL="you@example.com"

GIT_REPO_VAL="$(git remote get-url origin 2>/dev/null)"
[ -z "$GIT_REPO_VAL" ] && GIT_REPO_VAL="https://github.com/username/repo.git"

export GIT_USER="$GIT_USER_VAL"
export GIT_EMAIL="$GIT_EMAIL_VAL"
export GIT_REPO="$GIT_REPO_VAL"

echo "GIT_USER=$GIT_USER"
echo "GIT_EMAIL=$GIT_EMAIL"
echo "GIT_REPO=$GIT_REPO"
