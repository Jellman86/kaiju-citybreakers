#!/usr/bin/env bash

set -euo pipefail

required_files=(
  "CHANGELOG.md"
  "CONTRIBUTING.md"
  "SECURITY.md"
  "docs/PROJECT_STANDARDS.md"
  "docs/DEPENDENCIES.md"
  "docs/RESEARCH.md"
  "docs/REUSE_AUDIT.md"
  "docs/DECISIONS.md"
  "docs/PLAYTESTS.md"
  "assets/ASSET_REGISTER.md"
  ".github/CODEOWNERS"
  ".github/pull_request_template.md"
  ".github/dependabot.yml"
)

for required_file in "${required_files[@]}"; do
  if [[ ! -s "${required_file}" ]]; then
    echo "Required standards file is missing or empty: ${required_file}" >&2
    exit 1
  fi
done

if ! rg --quiet '^## \[Unreleased\]$' CHANGELOG.md; then
  echo "CHANGELOG.md must contain an [Unreleased] section." >&2
  exit 1
fi

while IFS= read -r source_file; do
  if [[ "$(head -n 1 "${source_file}")" != "--!strict" ]]; then
    echo "Luau source must begin with --!strict: ${source_file}" >&2
    exit 1
  fi
done < <(rg --files src -g '*.luau')

tracked_generated="$(git ls-files -- '*.rbxl' '*.rbxlx' '*.rbxm' '*.rbxmx')"
if [[ -n "${tracked_generated}" ]]; then
  echo "Generated Roblox files must not be tracked:" >&2
  echo "${tracked_generated}" >&2
  exit 1
fi

if ! rg --quiet '^\*\.blend filter=lfs ' .gitattributes; then
  echo "Blender sources must remain configured for Git LFS." >&2
  exit 1
fi

git diff --check

echo "Repository standards checks passed."
