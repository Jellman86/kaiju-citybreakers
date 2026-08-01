# Project guidance

Read and follow `docs/PROJECT_STANDARDS.md`. It is the normative project policy; the rules below are its short operational summary.

## Product constraints

- Keep the project free to implement. Do not add paid services, paid assets, premium APIs, or dependencies that require commercial licences.
- Use original kaiju, names, silhouettes, sounds, environments, and branding. Do not reproduce Godzilla, MonsterVerse, Pacific Rim, Ultraman, Gamera, or other protected IP.
- Target a Minimal or Mild Roblox content maturity label: stylized destruction, robots as enemies, no gore, and no realistic civilian harm.
- Preserve solo play. Multiplayer may improve the experience, but an empty server must not make the core loop unplayable.
- Design mobile-first, then verify keyboard/mouse and gamepad controls.

## Source of truth

- Rojo-managed Luau in `src/` is the source of truth for scripts.
- Use Roblox Studio MCP for inspection, world building, attributes, tags, playtests, and screenshots. Do not overwrite Rojo-managed scripts directly in Studio.
- Use Blender files in `assets/blender/` as the source for 3D models. Export game-ready assets to `exports/`.

## Engineering conventions

- Use `--!strict` in production Luau modules.
- Keep combat, rewards, destructible state, and round outcomes server-authoritative.
- Treat every client request as untrusted and validate ownership, range, cooldown, and state on the server.
- Prefer small services and controllers with explicit dependencies over global state.
- Run `./scripts/check.sh` before handing off changes.
- Keep `CHANGELOG.md` current under `Unreleased` for notable changes and use Conventional Commit subjects.
- Update `docs/DEPENDENCIES.md` or `assets/ASSET_REGISTER.md` in the same change that adopts a dependency or asset.
- Do not add persistence until the vertical-slice loop is enjoyable and stable.

## Evidence discipline

- Read `docs/RESEARCH.md` before changing a core mechanic, onboarding flow, networking rule, progression system, performance budget, or audience assumption.
- Cite primary platform or research sources where they apply. A comparable game's feature is an observation, not proof of causation.
- Label unsourced design beliefs as hypotheses and give them an observable playtest or analytics measure.
- Label numerical design gates as provisional project thresholds unless a cited source establishes them.
- Record the result, sample size, build commit, and resulting decision in `docs/DECISIONS.md` before expanding a tested system.

## Reuse discipline

- Read `docs/REUSE_AUDIT.md` before adding a framework, utility package, Creator Store asset, controller, or substantial new asset pipeline.
- Prefer Roblox-native functionality and vetted, pinned open-source code when it is simpler and safer than custom work.
- Inspect external models in a disposable place before adoption; remove unknown scripts, record provenance, and profile the result.
- Do not add a dependency or asset merely because it is free. It must pass the reuse acceptance checklist and solve the current requirement better.

## Scope discipline

- The vertical slice includes one kaiju, one district, one enemy, and one complete round.
- Extra kaiju, open-world traversal, competitive Dominion mode, trading, quests, and monetization belong after the vertical-slice gate.
- Prefer staged building damage models over unrestricted physics destruction for predictable performance.
