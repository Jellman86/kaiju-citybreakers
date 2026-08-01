#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Release builds require a clean Git worktree." >&2
  git status --short >&2
  exit 1
fi

head_sha="$(git rev-parse HEAD)"
origin_sha="$(git rev-parse origin/main)"
if [[ "${head_sha}" != "${origin_sha}" ]]; then
  echo "HEAD must exactly match origin/main before building a release." >&2
  echo "HEAD:        ${head_sha}" >&2
  echo "origin/main: ${origin_sha}" >&2
  exit 1
fi

./scripts/check.sh

short_sha="$(git rev-parse --short=12 HEAD)"
artifact="build/KaijuCitybreakers-${short_sha}.rbxlx"
mv build/KaijuCitybreakers.rbxlx "${artifact}"
shasum -a 256 "${artifact}" > "${artifact}.sha256"

echo "Release artifact: ${artifact}"
echo "Source commit: ${head_sha}"
echo "Next: follow docs/RELEASE.md and publish this file to the existing place."
