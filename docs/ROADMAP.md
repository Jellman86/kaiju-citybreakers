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

- Scout-drone navigation and attack behaviour.
- Turret area denial if schedule permits.
- Greybox defence-mech boss with telegraphed attacks and phases.
- Difficulty director based on player count and round performance.
- Server-side reward calculation.

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
