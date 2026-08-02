# Production roadmap

This roadmap assumes a small, part-time human team using Codex for implementation support. Calendar estimates are directional; phase gates matter more than dates. The entire implementation uses free tools and original assets.

Every phase begins with the relevant question in [RESEARCH.md](RESEARCH.md) and ends with evidence recorded in [DECISIONS.md](DECISIONS.md). Do not expand a system merely because its implementation is complete.

## Phase 0 — Pre-production and pipeline (week 1)

### Deliverables

- Product pillars, audience, rating, and non-goals agreed.
- Research ledger, hypothesis register, and initial instrumentation events agreed.
- Rojo repository, formatter, linter, Git workflow, and Studio plugin working.
- One-page art direction and scale guide.
- Greybox test place connected to Rojo.
- A thirty-minute design session with the user's son to choose the starter kaiju's silhouette, movement, power, and name.

### Exit gate

A code change can move from Git to Studio, run in a local playtest, and be reverted safely.

## Phase 1 — Kaiju feel prototype (weeks 2–3)

### Deliverables

- Temporary block kaiju with a custom camera.
- Server-validated basic attack, charge, and signature ability.
- Hit reactions, cooldown indicators, and temporary sound effects.
- Keyboard/mouse, gamepad, and mobile control layouts.
- One target dummy and one breakable test wall.

### Tests

- Input latency and readability on mobile emulation.
- Network ownership and exploit-resistant hit validation.
- Camera clipping near buildings.

### Exit gate

Moving, attacking, and breaking the wall is enjoyable for five minutes without progression.

## Phase 2 — Destruction sandbox (weeks 4–5)

### Deliverables

- Three-state building destruction system.
- CollectionService tags and attributes for destructible assets.
- Modular warehouse, substation, and street-kit placeholders.
- Server state with client-only debris and effects.
- Debris pooling and cleanup budgets.

### Tests

- Twenty buildings collapsing in sequence.
- Late-joining client receives the correct collapsed state.
- Collision and navigation remain usable after destruction.

### Exit gate

Destruction is readable, repeatable, synchronized, and maintains the target frame rate.

### Phase 2D — Sustained Beam and destruction spectacle

This focused slice comes before enemy production. It must make the existing city satisfying to destroy before new combatants compete for attention.

**Map ownership:** visual environment composition has moved to a human-authored Studio workflow. The checked-in `KaijuFeelLab` and Terrain models are the editable baseline; procedural generation is fallback and measurement scaffolding, not the art-direction authority. See [MAP_AUTHORING.md](MAP_AUTHORING.md).

#### Deliverables

- Replace arbitrary glowing damage seams with impact-local rupture marks. Every accepted structure hit carries a server-derived attack type and quantized surface zone; replicated zone state reconstructs the same holes for late joiners without replaying transient debris.
- Prove archetype-specific damage first on the Arc Power Plant cooling towers: dark interior breach, torn non-emissive rim, attack-scaled silhouette, and no persistent Neon damage indicator. Retain authored health/collision/collapse states rather than runtime fracture physics.
- Replace the phone-failed small circular mark with an attack-scaled irregular breach: layered dark depth, displaced non-emissive rim pieces, and a strict eight-part-per-mark ceiling. Pair Smash with a visibly measured local wind-up, fast strike, impact response, and eased recovery while the server remains authoritative for the actual hit; phase changes alone are not animation evidence.
- Replace the flat-slab five-zone backdrop with bounded native terrain: real terrain water and sand banks at Azure Lake, clear park mounds outside the combat promenade, a layered rocky massif behind Mount Brontide, and perimeter relief that breaks the horizon without blocking the road grid. Increase central tower-height contrast before adding building count.
- Recompose Arc Power Plant dressing around a functional thermal-plant read: paired cooling basins, large generation/turbine halls, visible coolant/service pipes, a fenced transformer and switchgear yard, busbars, and an outgoing transmission gantry. Remove decorative floor-light channels that make the site read as a generic sci-fi plaza.
- Replace the single-impact Beam with a short hold-to-channel action: wind-up, approximately `1.5` seconds of active sweep, and recovery. Duration is a playtest parameter, not a final balance value.
- Keep a server-owned Beam session with bounded begin, aim-update, and end requests. Resolve damage at a fixed low frequency instead of every rendered frame; validate the living character, direction cone, duration, cadence, range, and cooldown on every session.
- Let the Beam draw a destructive path by damaging successive unique structures as aim moves or earlier structures collapse. Reuse the existing destructible registry, collision group, state machine, and cleared-rubble behaviour; cap targets per sample and per channel.
- Keep the visible Beam attached to Brontide's mouth and eased head aim for the full channel. Pool or reuse its trail, impact, and debris presentation rather than creating new instances every frame.
- Add scalable impact tiers: damage chips and sparks; collapse dust, shock ring, pooled chunks, silhouette transition, sound layers, and a brief local camera response; and one restrained chain finisher when several structures collapse.
- Add Reduced Effects controls that suppress strong shake and flashes, plus an automatic low-effects profile with shorter lifetimes and fewer particles on the representative mobile baseline.

#### Research spike

Compare bounded repeated `Spherecast` traversal with a native swept-volume overlap approach in one five-to-eight-building street. Select the smallest native query that preserves occlusion, supports successive targets, and stays within the server frame budget. Do not introduce a combat or effects framework unless the spike proves the existing service boundaries inadequate.

#### Validation

- Sweep across low, tall, near, distant, and partially occluded buildings with mouse, touch, and gamepad aim.
- Confirm one channel cannot exceed its duration, sample rate, unique-target cap, or damage budget even with malformed or repeated remotes.
- Stress a twenty-building chain while recording client/server frame time, memory trend, network traffic, active fragments, and concurrent emitters on a physical phone.
- Verify that damaged and collapsed states remain visually distinct after effects finish, late joiners reconstruct authoritative states, and two clients cannot double-apply one player's Beam samples.
- Confirm repeated hits create at most the configured persistent marks per structure, no damaged archetype uses placeholder Neon geometry, and reset/collapse removes localized marks without leaving client instances behind.
- Confirm Smash moves named visible Brontide shell parts by at least a provisional six studs, restores every dedicated shell-pivot offset, does not double-play on predicted confirmation, and still produces exactly one server-authoritative hit per accepted request.
- Raycast the generated mountain, park mound, and lake to verify tall Rock terrain, walkable Grass relief, and native Water respectively; record terrain cell count and retain the existing world-part ceiling.
- Check Reduced Effects, photosensitivity-safe flashing, camera comfort, and aim readability with no coaching.
- Ask phone testers to identify Arc Power Plant without reading its sign and name the visual clues they used; treat recognition from the cooling towers alone as insufficient evidence for the whole district.

#### Exit gate

The Beam visibly traces a controllable path through multiple buildings, each confirmed impact feels substantially stronger than the current prototype, all transient effects return to rest, and the representative phone remains at or above the provisional `30 FPS` destruction threshold without unbounded instance, memory, or remote growth.

### Phase 2E — Genuine mixed-scale players

Prove one human-scale player and one physically giant Brontide in the same server before rebuilding the full city or producing human-versus-kaiju progression. See [MIXED_SCALE_PLAYERS.md](MIXED_SCALE_PLAYERS.md).

**Status:** foundation implemented and automated two-client regression passed on 2026-08-01. Physical-device controls/performance and a useful human role remain open exit gates.

#### Deliverables

- Server-owned `Human` and `Kaiju` roles with solo-safe assignment, role-specific spawning and automatic human promotion if the kaiju leaves.
- One provisional `60–75` stud Brontide beside an ordinary `5–6.5` stud R15 human, with actual model bounds maintaining at least a provisional `10:1` standing-height ratio.
- Separate role metrics for movement, camera, spawn clearance, collision and combat reach.
- Non-colliding human/kaiju character groups so the giant cannot fling a human; explicit server spatial queries remain the only source of combat and destruction outcomes.
- A smooth kaiju contact hull that physically blocks humans while server queries apply capped contact damage and knockback; raw limb collision remains disabled.
- A stylized cross-device human blaster, damageable Humanoids for both roles, kaiju attacks that can defeat humans, and role-preserving respawn.
- A small human-scale doorway/approach reference inside the greybox and one useful mixed-role interaction before any production-scale human content.

#### Validation

- Run the native two-client Studio regression with one kaiju and one human, including role replication, actual bounds, respawn/promotion, collision filtering and human rejection from kaiju-only remotes.
- Extend the regression through human fire damaging the kaiju, a kaiju attack defeating the human, role-preserving human respawn, and contact-hull collision/damage checks.
- Verify both cameras, touch controls, human-scale navigation and kaiju-scale traversal on a physical phone.
- Measure client/server frame time, memory, moving character parts and streaming behaviour with both roles present.
- Conduct an uncoached two-player test in which both roles complete a useful task and can explain their contribution.

#### Exit gate

The size difference exists in replicated model bounds rather than camera presentation alone; both roles remain controllable and useful; contact cannot fling either player; server authority and solo play remain intact; and the representative phone passes the provisional performance gate.

## Phase 3 — Complete round loop (weeks 6–7)

### Deliverables

- Waiting, countdown, active, and results states.
- Two district objectives and one route-changing event.
- Energy collection and three mutation choices.
- Solo scaling and two-player scaling.
- Win, loss, restart, and disconnect recovery.

### Exit gate

One complete five-to-eight-minute run works from join to replay with no manual intervention.

## Phase 4 — Defenders and boss (weeks 8–9)

### Deliverables

- Bounded capturable-turret feasibility slice using four sanitized shells, distinct bullet/minigun/cannon/rocket attacks, and native two-client validation.
- One smaller original rogue-kaiju target from an Edit-visible articulated template, with server-owned patrol/perception/memory/investigation, bounded pathfinding, swipe and lunge attacks, stagger, enrage, turret targeting, health, and defeat.
- Scout-drone navigation and attack behaviour after the turret and rogue-kaiju integration gates.
- Greybox defence-mech boss with telegraphed attacks and phases.
- Difficulty director based on player count and round performance.
- Server-side reward calculation.

### Enemy implementation order

1. Complete the owner-requested turret feasibility slice: sanitized assets, server-owned capture/targeting, actual-shell traverse/elevation and moving muzzle, first-shot wind-up, four distinct attack profiles, bounded projectile simulation, fixed-cap cosmetics, cover, and two-client tests. The rig and synthetic motion gate are implemented; physical-device orientation and multiplayer gates remain. Do not multiply it across the map yet; see [TURRET_SYSTEM.md](TURRET_SYSTEM.md).
2. Maintain the shared server-owned enemy contract and bounded state machine: patrol, acquire, chase, investigate, telegraph, attack, recover, stagger, enrage, and defeated.
3. Validate the articulated original `Riftback` rogue kaiju from the visible `EnemyTemplates` contract. Replace only after the map owner supplies a commercially royalty-free, underlying-IP-authorised model that passes security and mobile review.
4. Add one scout drone using authored aerial patrol nodes and line-of-sight checks; it fires a slow, dodgeable projectile and never needs ground pathfinding.
5. Consolidate the proven turret and enemy damage, team, telegraph, projectile, and pooling contracts without changing their distinct presentations.
6. Add another ground defence unit only after the rogue-kaiju path and mobile budget are proven.
7. Build the defence-mech boss only after the drone and turret are readable and performant on mobile.

Enemy decisions, health, damage, targeting, and rewards remain server-owned. Clients predict only harmless presentation such as wind-up effects and projectile trails. Active counts, perception frequency, path recomputation, projectiles, and effects receive explicit budgets before content multiplication; see [ENEMY_SYSTEM.md](ENEMY_SYSTEM.md).

### Exit gate

Solo and two-player teams can win through readable play rather than damage racing or exploits.

## Phase 5 — Original art production (weeks 10–11)

### Blender deliverables

- Brontide production model, efficient rig, and animation set.
- Idle, locomotion, combo, charge, tail slam, hit, knockdown, victory, and defeat animations.
- Modular city kit with intact, damaged, and collapsed variants.
- Defence drone and boss silhouette pass.

### Studio deliverables

- Import scale and naming validation.
- Materials, effects, lighting, LOD strategy, and collision proxies.
- Server-synchronized day/night cycle with authored dawn, day, dusk, and night presets; gradual transitions; and no gameplay logic that depends on a client's local clock.
- Night readability pass for Brontide, destructible states, roads, objectives, attacks, and touch controls, using a fixed light/shadow budget instead of multiplying dynamic lights across the city.
- Animation event integration.

### Day/night validation

- Measure client frame time, memory, shadow cost, and visible-light count at every preset on the representative mobile baseline before enabling continuous cycling.
- Verify that a late-joining client receives the current phase and that all clients remain visually synchronized without per-frame remote traffic.
- Run uncoached visibility tests for navigation, building-state recognition, Beam/Charge telegraphs, objective markers, and accessibility settings at the darkest approved night value.
- Keep the cycle cosmetic during the vertical slice; weather, defender behaviour, spawn rates, and night-specific rewards require separate research and playtest gates.

### Exit gate

The production kaiju and complete day/night lighting range communicate scale and power without reducing mobile performance below budget or obscuring gameplay information.

## Phase 6 — UX, audio, and accessibility (weeks 12–13)

### Deliverables

- Mobile-first HUD and ability controls.
- Visual onboarding and objective guidance.
- Original or properly licensed free sound effects, edited in Audacity.
- Colour-blind-safe objective and team indicators.
- Camera shake, flashing, motion, and volume controls.
- Minimal/Mild content maturity review.

### Exit gate

A first-time tester can join, understand the goal, complete a round, and start another without developer help.

## Phase 7 — Alpha hardening (weeks 14–15)

### Deliverables

- Multi-client, device, latency, and reconnect test matrix.
- Performance and memory profiling.
- Security review of remotes, rewards, damage, and state changes.
- Crash/error logging through Roblox's included facilities.
- Private alpha with a small trusted group.
- Prioritized fixes based on observed play, not requested feature volume.

### Exit gate

Three consecutive group sessions complete without data loss, blocking defects, or critical performance regressions.

## Phase 8 — Private beta and launch decision (week 16+)

### Deliverables

- Original title, icon, thumbnails, description, and content questionnaire.
- Creator Hub analytics and funnel events.
- Private beta release with feedback form.
- Decision based on D1 intent signals, completion rate, replay rate, and qualitative fun.

### Launch decision

- Continue toward public release if destruction and replay intent are strong.
- Rework the core feel if users complete the round but do not replay.
- Stop or radically rescope before adding content if the first minute is not enjoyable.

## Post-slice backlog

Ordered only after the vertical-slice gate:

1. Second kaiju with a genuinely different movement and combat role.
2. Additional district event and boss modifier.
3. Lightweight mastery and cosmetic saves.
4. Social harbour improvements and party flow.
5. Third kaiju and second district.
6. Dominion competitive prototype.
7. Optional atmospheric human-survival event.

## Immediate implementation sequence

1. Validate the implemented `61.37`-stud Brontide and `5.50`-stud human foundation on a physical phone; retain, reduce or reject the measured `11.17:1` scale from evidence.
2. Give the human one small, useful interaction and run an uncoached two-player navigation/destruction session before adding production human content.
3. Implement Phase 2D's sustained Beam and tiered collapse presentation against the retained physical scale in one five-to-eight-building Central City street.
4. Tune on a physical phone, then run the twenty-building destruction/performance and full-round reset gates before rolling the presentation across all structures.
5. Revise mixed-scale routes from the two-player evidence before rebuilding scenery.
6. Prototype exactly one scout drone only after mixed scale, Beam and destruction spectacle pass their mobile and readability gates; do not populate the whole map yet.
7. Add energy collection and mutation choice only after both roles, Beam, Charge, Smash and the scout are readable together on phone.
