# Changelog

All notable player-facing, developer-facing, security, asset, and production-pipeline changes are recorded here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/2.0.0/). Releases use [Semantic Versioning](https://semver.org/); while the game is experimental, versions remain below `1.0.0`.

## [Unreleased]

### Added

- Research-led game design, technical architecture, roadmap, art direction, and validation ledger.
- Free Rojo/Rokit/StyLua/Selene/Git LFS toolchain with public GitHub Actions validation.
- Server-authoritative round state, charge, smash, and three-state destruction foundations.
- Kaiju Feel Lab with a scaled R15 placeholder, native cross-device controls, greybox arena, local cosmetic debris, HUD, and H1 playtest timestamps.
- Original Brontide kaiju shell with a mineral crown, energy seams, heavy limbs, and tail, built on the native R15 controller.
- Readable low-poly city block with roads, sidewalks, lit buildings, scale-reference vehicles, streetlights, and an integrated breakable gate.
- Reuse audit for Roblox-native features, open-source packages, and Creator Store assets.
- Repository standards, contribution and security policies, dependency and asset registers, CODEOWNERS, pull-request checklist, and automated standards checks.
- Pinned, audited game-development Codex guidance for Roblox Luau, game feel, UI/UX, level design, performance profiling, and audio design.
- Deliberate keyboard/mouse, gamepad, and touchscreen controls with device-aware prompts, labelled touch actions, and safe-area HUD layout.
- Classic third-person mouse camera on desktop: mouse movement orbits behind Brontide, the creature follows the view direction, scroll controls zoom, and camera collision protects visibility; gamepad and touch retain native camera controls.
- Research-backed destruction specification with explicit evidence labels, reusable structure hierarchy, feature tiers, reuse decisions, and provisional Phase 2 test gates.
- Strict shared destructible contract with validated unique IDs, server-owned health and sequenced state, atomic streaming, dedicated damage hitboxes, and separate intact/collapsed collision proxies.
- Fixed-cap client debris pool with one-collapse prewarming, oldest-active recycling, generation-safe delayed cleanup, observable statistics, and concrete, metal, and lightweight fragment presets.
- Reusable source-controlled destructible builder plus warehouse, signal-tower, and electrical-substation greyboxes with aligned state variants, stable pivots, simple proxies, and distinct silhouettes.

### Changed

- Repository visibility changed from private to public so standard GitHub-hosted CI remains free.
- Charge movement now uses a short native `LinearVelocity` constraint after Studio testing showed that a one-frame velocity was neutralized by the Humanoid controller.
- Prototype onboarding now names Brontide and gives a single city-gate objective instead of presenting an abstract feel lab.
- Charge now travels roughly 48 studs with a stronger speed differential, accepted-action FOV kick, cyan energy burst, and brief body highlight so it reads clearly at kaiju scale.
- Destruction events now carry compact stable IDs, state sequences, positions, and material profiles; replicated attributes reconstruct visual state for late joiners and streamed-in structures.
- Destructible visual variants are client-selected and excluded from gameplay collision, touch, and attack queries.
- Collapse fragments are reused instead of created and destroyed for every event; the pool grows only to 100 parts and inactive parts leave the data model.

### Fixed

- Disabled the template spawn and removed the overlapping runtime baseplate in the Kaiju Feel Lab.
- Made repository standards validation portable to the minimal GitHub Actions runner environment.
- Prevented `CHARGE` and `SMASH` touch controls from overlapping or escaping the screen by sizing and arranging them within Roblox's live action-frame bounds, including a stacked narrow-screen fallback.

### Security

- Client ability requests are type-, state-, cooldown-, character-, rate-, and server-hitbox validated.
- Invalid or duplicate destructible packages are rejected by the authoritative registry without crashing the round.

Release links will be added when the first version is tagged.
