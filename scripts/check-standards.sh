#!/usr/bin/env bash

set -euo pipefail

required_files=(
  "CHANGELOG.md"
  "CONTRIBUTING.md"
  "SECURITY.md"
  "docs/PROJECT_STANDARDS.md"
  "docs/RELEASE.md"
  "docs/DEPENDENCIES.md"
  "docs/RESEARCH.md"
  "docs/REUSE_AUDIT.md"
  "docs/DECISIONS.md"
  "docs/PLAYTESTS.md"
  "docs/MAP_AUTHORING.md"
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

if ! grep --quiet '"servePlaceIds": \[137103245194702\]' default.project.json; then
  echo "Rojo must remain restricted to the Kaiju Citybreakers production place." >&2
  exit 1
fi

if ! grep --quiet '^## \[Unreleased\]$' CHANGELOG.md; then
  echo "CHANGELOG.md must contain an [Unreleased] section." >&2
  exit 1
fi

while IFS= read -r source_file; do
  if [[ "$(head -n 1 "${source_file}")" != "--!strict" ]]; then
    echo "Luau source must begin with --!strict: ${source_file}" >&2
    exit 1
  fi
done < <(find src -type f -name '*.luau' -print)

production_entrypoints=(
  "src/server/init.server.luau"
  "src/client/init.client.luau"
)

if grep --extended-regexp --line-number '^local .*require\(script\.Tests\.' "${production_entrypoints[@]}"; then
  echo "Production entrypoints must not load Studio-only tests at module scope." >&2
  exit 1
fi

if grep --recursive --include='*.luau' --extended-regexp --line-number \
  '^local StudioTestService = game:GetService\("StudioTestService"\)' src; then
  echo "StudioTestService acquisition must be guarded by RunService:IsStudio()." >&2
  exit 1
fi

for authored_world_source in src/world/Terrain.rbxmx src/world/KaijuFeelLab.rbxmx; do
  if [[ ! -s "${authored_world_source}" ]]; then
    echo "Canonical authored world source is missing or empty: ${authored_world_source}" >&2
    exit 1
  fi
done

tracked_generated="$(git ls-files -- '*.rbxl' '*.rbxlx' '*.rbxm' '*.rbxmx' \
  | grep -Ev '^src/world/(Terrain|KaijuFeelLab)\.rbxmx$' || true)"
if [[ -n "${tracked_generated}" ]]; then
  echo "Generated Roblox files must not be tracked:" >&2
  echo "${tracked_generated}" >&2
  exit 1
fi

if ! grep --quiet '^src/world/\*\.rbxmx filter=lfs ' .gitattributes; then
  echo "Authored Roblox world sources must remain configured for Git LFS." >&2
  exit 1
fi

if ! grep --quiet '^          lfs: true$' .github/workflows/ci.yml; then
  echo "CI must fetch Git LFS map sources before running Rojo." >&2
  exit 1
fi

if ! grep --quiet '^\*\.blend filter=lfs ' .gitattributes; then
  echo "Blender sources must remain configured for Git LFS." >&2
  exit 1
fi

git diff --check

echo "Repository standards checks passed."
