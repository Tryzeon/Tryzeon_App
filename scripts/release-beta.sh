#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/release-beta.sh <version> [--ios | --android]

The version may be given with or without a leading 'v'.

Examples:
  scripts/release-beta.sh v1.2.0
  scripts/release-beta.sh 1.2.0
  scripts/release-beta.sh v1.2.0 --ios
  scripts/release-beta.sh 1.2.0 --android
EOF
}

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required." >&2
  exit 1
fi

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 1
fi

version="$1"
platform="${2:-all}"

if [[ ! "$version" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must be a semantic version, for example v1.2.0 or 1.2.0" >&2
  exit 1
fi

version="${version#v}"

current_branch=$(git branch --show-current)
if [[ "$current_branch" != "main" ]]; then
  echo "Error: releases must be run from 'main' (current branch: '$current_branch')" >&2
  exit 1
fi

# Check for unpushed commits
if [[ -n $(git log "origin/$current_branch..HEAD") ]]; then
  echo "Error: You have unpushed commits" >&2
  exit 1
fi

run_ios=false
run_android=false

case "$platform" in
  all)
    run_ios=true
    run_android=true
    ;;
  --ios)
    run_ios=true
    ;;
  --android)
    run_android=true
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

# Confirmation prompt
echo "Are you sure you want to release version $version?"
if [[ "$run_ios" == true && "$run_android" == true ]]; then
  echo "Platform: iOS and Android"
elif [[ "$run_ios" == true ]]; then
  echo "Platform: iOS"
elif [[ "$run_android" == true ]]; then
  echo "Platform: Android"
fi
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Release cancelled"
  exit 0
fi

if [[ "$run_ios" == true ]]; then
  gh workflow run beta_ios.yml -f version="$version"
  echo "Triggered iOS beta workflow for version $version"
fi

if [[ "$run_android" == true ]]; then
  gh workflow run beta_android.yml -f version="$version"
  echo "Triggered Android beta workflow for version $version"
fi
