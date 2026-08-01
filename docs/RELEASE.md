# Release process

Production is place `137103245194702` in universe `10609698937`. Rojo-managed files remain the source of truth; generated place files are disposable release artifacts and stay out of Git.

Rojo documents `rojo build -o build.rbxlx` as the supported way to assemble a complete place file from a project. It separately describes live sync as the faster active-iteration workflow. This project therefore uses live sync for development and a clean, exact-commit build artifact for production publishing:

- [Rojo: Building Your Place](https://rojo.space/docs/v7/getting-started/new-game/#building-your-place)
- [Rojo project place restrictions](https://rojo.space/docs/v7/project-format/)

## Release gate

1. Confirm the intended commit is on `main`, equals `origin/main`, has passing public CI, and has applicable playtest evidence.
2. Run `./scripts/prepare-release.sh`. It refuses dirty or unpushed source, runs the complete check suite, and emits a commit-labelled `.rbxlx` plus SHA-256 digest under ignored `build/`.
3. Open that exact `.rbxlx` in Studio without connecting Rojo. Run one server/client Play test and verify the smoke checks below.
4. Use **File → Publish to Roblox As… → Kaiju Citybreakers → existing Kaiju Citybreakers → Overwrite**. Never add a new place during this flow.
5. Require Studio's explicit success result and record the destination place ID from the Studio publish log.
6. Leave any existing Roblox session, join a fresh production server, and repeat the smoke checks. A Studio-only pass is not evidence that production received the artifact.
7. Open Creator Hub's **Monitoring → Error Report**, filter to the production place and latest version, and verify that the fresh session introduced no bootstrap error.
8. Record source commit, artifact name, place version if shown, device, result, and follow-up in `docs/PLAYTESTS.md`.

Do not use **Publish to Roblox** from a live Rojo-synced editing session as the production release path. That path can appear successful while the live place does not contain the source-controlled bootstrap. The built artifact is the deployable unit and the Git commit is its rollback identity.

## Smoke checks

- The city exists; the player does not spawn on the template baseplate alone.
- The player becomes Brontide rather than retaining the default avatar.
- Brontide is grounded at `KaijuSpawn` with no continuing downward velocity.
- The round HUD and current input prompts appear.
- Camera, movement, charge, and smash work on the test device.
- At least one registered building progresses through its authored destruction states.
- Studio/server output has no bootstrap error and includes the world, server, and client startup markers.
- Creator Hub's Error Report has no new server or client bootstrap error for the published version.

If any check fails, stop testing that version. Use Creator Hub place version history to restore the last known-good version, then diagnose from a clean artifact before publishing again.
