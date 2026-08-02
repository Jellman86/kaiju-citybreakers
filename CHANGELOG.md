# Changelog

All notable player-facing, developer-facing, security, asset, and production-pipeline changes are recorded here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/2.0.0/). Releases use [Semantic Versioning](https://semver.org/); while the game is experimental, versions remain below `1.0.0`.

## [Unreleased]

### Added

- First server-authoritative reinforcement-factory foundation with generic team/lane/objective contracts, contested capture, destructible shutdown, linked-turret transfer, bounded tank/helicopter waves, authored routes, distinct travelling projectiles, vehicle health/defeat, and integration with existing player attacks and turret targeting.
- Research-led urban-island conquest and factory-objective specification, H14 playtest gate, Edit-visible map-owner handoff, and audited free-commercial-use asset candidate decisions.
- Native `Motor6D` rigs for all four placed turret shells, including moving visual muzzles and client-local traverse/elevation driven by server-selected targets.
- Richer server-authoritative `Riftback` AI with patrol, FOV/line-of-sight vision, hearing, target memory and hysteresis, investigation, blocked/stuck path recovery, swipe/lunge choice, stagger, and enrage.
- Client-local joint posing for the articulated original enemy proxy across locomotion, attacks, stagger, idle, and enrage states.
- Edit-visible full-map authoring guides, truthful Brontide/human scale references, and a sandboxed `AuthoringInbox` that formalize the map-owner/Codex handoff while remaining absent from Play.
- Edit-visible turret aim assemblies, a movable rogue-kaiju spawn marker, and a replaceable enemy template that keep gameplay objects inspectable while server code owns their contracts.
- First server-owned rogue-kaiju AI slice with bounded native pathfinding, chase/telegraph/recovery states, player melee damage, turret target integration, authoritative health, and defeat.
- Research-led capturable-turret specification with sanitized Creator Store shell provenance, server-owned capture/targeting, distinct bullet/minigun/cannon/rocket profiles, bounded projectile/effect budgets, placement guidance, and explicit multiplayer/mobile gates.
- Hand-authored Studio map pipeline with source-controlled Terrain and city models, a focused capture tool, and an Edit-mode authoring guide.
- Native smooth terrain composition with a rocky Mount Brontide massif, park mounds, irregular sand banks, real terrain water, and perimeter relief around the city.
- Procedural Brontide Smash animation with an eased wind-up, fast strike, server-authoritative impact moment, and recovery to the original pose.
- Localized authored building damage with server-derived surface zones, Smash/Charge/Beam-shaped rupture marks, compact late-join reconstruction, and bounded pooled impact chips.
- Initial mixed-scale player foundation with one server-assigned giant Brontide, human-sized later players, role-specific spawns/cameras/metrics, non-flinging collision groups, and a human-scale doorway reference.
- Native multiplayer regression coverage for measured role scale, human combat rejection, role-specific cameras/actions, late-join destruction reconstruction, and automatic kaiju promotion after disconnect.
- Asymmetric mixed-scale combat foundation with a cross-device human energy blaster, damage and death for both roles, role-preserving respawns, kaiju attacks against humans, and controlled physical kaiju contact.
- Research-backed Phase 2D roadmap for a sustained, server-authoritative demolition Beam and tiered, pooled destruction spectacle with mobile and Reduced Effects gates.
- Research specification for genuinely mixed-scale human and kaiju players, including role architecture, truthful level metrics, collision/security rules, mobile constraints, and a two-client feasibility lab.
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
- Studio-only automated multiplayer regression that collapses a structure through one client, adds a late client, and verifies authoritative state, client visual reconstruction, collision proxies, and non-replayed debris.
- West park/plaza greybox with a truthful cross-street branch, broad optional movement loop, low-density primitive dressing, a north reconnect, and district cordons that close the legacy city-gate bypass.
- Eight-building east and south district expansion with a second avenue, southern cross street, longer central route, and staged destruction for every city building.
- Server-authoritative Brontide energy beam with keyboard, gamepad, and touch input, a four-second cooldown, validated raycast damage, and client-local beam feedback.
- Five-zone mega-district blockout across Central City, Titan Park, Arc Power Plant, Mount Brontide, and Azure Lake, with 33 smashable structures and an eight-times-larger foundation.
- Mouse/reticle-aware Beam aiming shared by Brontide's eased head turn, mouth muzzle cue, and server-validated swept hit query.
- Dedicated Brontide visual-head pivot so the skull, eyes, crown, and mouth can visibly track Beam aim without fighting the native avatar animator.

### Changed

- Turret tracers, lock cues, cannon shells, and missiles now originate at each shell's moving visual muzzle while authoritative hit resolution remains server-owned.
- External-asset policy now explicitly requires `£0` commercial use with no royalty, revenue share, subscription, usage fee, or earnings-triggered payment, plus legitimate rights to the underlying IP.
- Runtime world startup now preserves an authored `KaijuFeelLab` and non-empty Terrain instead of destroying the designer's map whenever Play begins.
- Central skyline towers now use materially different heights so Brontide is framed by an urban silhouette instead of a field of similarly low boxes.
- Smash now drives dedicated Brontide visual-shell pivots that Roblox's avatar animation pass cannot erase and uses a deliberately readable `0.87`-second anticipation-to-recovery sequence.
- Arc Power Plant now uses functional industrial grouping—cooling basins and pipes, service lanes, a fenced transformer/switchgear yard, busbars and an outgoing grid gantry—instead of decorative Neon floor channels.
- Localized damage now uses much larger face-clamped irregular breaches with layered dark depth and displaced rims, capped at eight local parts per mark, after the first physical-phone mark read as a small flat bullet hole.
- Damaged cooling towers and other building archetypes now use dark physical splits and impact-local cavities instead of persistent orange Neon crack plates; every accepted hit emits a sequenced localized-damage event even when the structure remains `Damaged`.
- Repository visibility changed from private to public so standard GitHub-hosted CI remains free.
- Production publishing now uses a clean, commit-labelled Rojo place artifact with a SHA-256 digest and mandatory fresh-server smoke test; Rojo sync is reserved for iteration.
- Charge movement now uses a short native `LinearVelocity` constraint after Studio testing showed that a one-frame velocity was neutralized by the Humanoid controller.
- Prototype onboarding now names Brontide and gives a single city-gate objective instead of presenting an abstract feel lab.
- Charge now travels roughly 48 studs with a stronger speed differential, accepted-action FOV kick, cyan energy burst, and brief body highlight so it reads clearly at kaiju scale.
- Destruction events now carry compact stable IDs, state sequences, positions, and material profiles; replicated attributes reconstruct visual state for late joiners and streamed-in structures.
- Destructible visual variants are client-selected and excluded from gameplay collision, touch, and attack queries.
- Collapse fragments are reused instead of created and destroyed for every event; the pool grows only to 100 parts and inactive parts leave the data model.
- Charge now damages up to four structures along its server-measured travel path and produces a distinct impact flash and camera response on a confirmed hit.
- Collapsed structures leave the attack-query collision group until reset, allowing charge, Smash, and Beam to reach intact buildings behind cleared rubble.
- Touch layout now arranges Beam, Charge, and Smash around Roblox's finalized Jump-button rectangle and recomputes when native control geometry changes.
- Beam now uses a forgiving native sphere cast from Brontide's mouth, accepts only a bounded forward aim direction, reaches 240 studs, and displays a thicker confirmed beam for 0.45 seconds.
- New district buildings use lean authored state variants to keep the expanded world below the provisional 1,000-part mobile ceiling.
- Removed the temporary title, instructions, round timer, and gate instruction billboard from the gameplay view; only action controls remain.

### Fixed

- Replaced the internally advancing but visually overwritten Smash tween after a physical-device test showed no visible wind-up or body motion.
- Reflow touch actions after Roblox's native Jump button receives its final phone layout, keeping Smash unobscured on iPhone landscape screens.
- Kept the Studio-only multiplayer regression out of live server and client startup, preventing published sessions from aborting before the city, Brontide, HUD, and controls load.
- Disabled the template spawn and removed the overlapping runtime baseplate in the Kaiju Feel Lab.
- Replaced the live-synced Studio publishing path after it produced a successful-looking upload whose production server contained only the template baseplate.
- Prevented production players from spawning before the runtime city exists by disabling automatic character loading, loading them after world bootstrap, and explicitly placing Brontide on the generated spawn.
- Made repository standards validation portable to the minimal GitHub Actions runner environment.
- Prevented `CHARGE` and `SMASH` touch controls from overlapping or escaping the screen by sizing and arranging them within Roblox's live action-frame bounds, including a stacked narrow-screen fallback.
- Prevented Beam from passing above low buildings by replacing its chest-height horizontal ray with an aimed, nine-stud-radius server sweep.
- Prevented the native avatar animation pass from clearing Brontide's visible head turn by driving the dedicated pivot's persistent joint offset.

### Security

- Quarantined, inspected, and removed a free `Mire Godzilla` fan model rather than shipping protected IP, four embedded scripts/modules, and an unprofiled 119-mesh enemy.
- Turret registration now rejects malformed motor chains and any unanchored visual part outside the expected anchored-root assembly.
- Client ability requests are type-, state-, cooldown-, character-, rate-, and server-hitbox validated.
- Invalid or duplicate destructible packages are rejected by the authoritative registry without crashing the round.

Release links will be added when the first version is tagged.
