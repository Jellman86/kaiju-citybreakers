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
  "docs/FACTORY_OBJECTIVES.md"
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

for factory_source in \
  src/shared/FactoryContract.luau \
  src/shared/VehicleContract.luau \
  src/server/Services/FactoryService.luau; do
  if [[ ! -s "${factory_source}" ]]; then
    echo "Factory objective source is missing or empty: ${factory_source}" >&2
    exit 1
  fi
done

if ! grep --quiet 'factoryService:Start()' src/server/init.server.luau \
  || ! grep --quiet 'factoryService:Stop()' src/server/init.server.luau; then
  echo "FactoryService must remain in the production startup and cleanup lifecycle." >&2
  exit 1
fi

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

if grep --extended-regexp --line-number \
  '<Item class="(Script|LocalScript|ModuleScript)"' src/world/KaijuFeelLab.rbxmx; then
  echo "Captured world models must not contain executable scripts; audit and strip AuthoringInbox candidates first." >&2
  exit 1
fi

for rig_name in TurretRig RigRoot YawMotor PitchMotor VisualMuzzle; do
  rig_count="$(grep -c "<string name=\"Name\">${rig_name}</string>" src/world/KaijuFeelLab.rbxmx || true)"
  if [[ "${rig_count}" -ne 4 ]]; then
    echo "Authored turret contract requires exactly four ${rig_name} instances; found ${rig_count}." >&2
    exit 1
  fi
done

if ! grep --quiet '<string name="Name">Rig_LeftArm</string>' src/world/KaijuFeelLab.rbxmx; then
  echo "The authored rogue-kaiju template must retain its articulated Rig_* motor contract." >&2
  exit 1
fi

for factory_authoring_name in \
  FactoryObjectives \
  TEMP_ArcFactoryObjective \
  TankSpawn \
  HelicopterSpawn \
  GroundRoute \
  AirRoute; do
  factory_authoring_count="$(grep -c "<string name=\"Name\">${factory_authoring_name}</string>" src/world/KaijuFeelLab.rbxmx || true)"
  if [[ "${factory_authoring_count}" -ne 1 ]]; then
    echo "Temporary factory authoring contract requires one ${factory_authoring_name}; found ${factory_authoring_count}." >&2
    exit 1
  fi
done

if grep --extended-regexp --ignore-case --line-number \
  'Mire Goji|Godzilla|Gojira|RigMotionSmoke' src/world/KaijuFeelLab.rbxmx \
  || grep --recursive --include='*.luau' --extended-regexp --ignore-case --line-number \
    'Mire Goji|Godzilla|Gojira|RigMotionSmoke' src; then
  echo "Protected fan-IP candidates and temporary rig-test helpers must not enter source." >&2
  exit 1
fi

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
