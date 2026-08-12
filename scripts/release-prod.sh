#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/release-prod.sh <version>

Tags the current commit and pushes the tag, which triggers the
release_ios / release_android / release_github workflows.

The release lanes promote the build that is already on TestFlight and the Play
internal track, so run scripts/release-beta.sh for this version first.

The version may be given with or without a leading 'v'.

Examples:
  scripts/release-prod.sh v1.2.0
  scripts/release-prod.sh 1.2.0
EOF
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

version="$1"

if [[ ! "$version" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must be a semantic version, for example v1.2.0 or 1.2.0" >&2
  exit 1
fi

tag="v${version#v}"

echo "Are you sure you want to release $tag to production?"
echo "Commit: $(git rev-parse --short HEAD) ($(git log -1 --pretty=%s))"
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Release cancelled"
  exit 0
fi

git tag -a "$tag" -m "Release $tag"
git push origin "$tag"

echo "Pushed tag $tag — release workflows triggered"
