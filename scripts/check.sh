#!/usr/bin/env bash

set -euo pipefail

mkdir -p build

stylua --check src
selene src
rojo build default.project.json --output build/KaijuCitybreakers.rbxlx

echo "Checks passed and build/KaijuCitybreakers.rbxlx was generated."

