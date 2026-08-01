# Research and validation ledger

This document keeps design decisions traceable. It prevents precedent, intuition, and internal targets from being presented as proven facts.

## Evidence labels

- **Platform evidence:** guidance or data published by Roblox.
- **Technical requirement:** behaviour required by Roblox's engine, networking, safety, or publishing model.
- **Comparable observation:** a mechanic observed in another game. It can suggest an option but does not prove that it will work here.
- **Inference:** a conclusion drawn from multiple sources and the project's constraints.
- **Hypothesis:** an unproven design belief that needs a prototype and playtest.
- **Provisional threshold:** an internal pass/fail target. It is deliberately adjustable and is not an industry benchmark.

## Research-to-decision matrix

| Decision | Evidence | What the evidence supports | What remains unproven |
| --- | --- | --- | --- |
| Start with cooperative PvE and preserve solo play | Roblox says social play can improve retention, while its genre research identifies interest in social co-opetition and action experiences. | Build social interactions into the loop without requiring a full competitive economy. | That co-op is more fun than solo for this specific combat and audience. |
| Deliver destruction during the first minute | Roblox links day-one retention to the core loop, onboarding, and performance, and recommends reaching the fun quickly—ideally within five minutes. | Do not hide the kaiju fantasy behind menus, exposition, or progression. | Whether sixty seconds is the right target; this is a provisional threshold. |
| Use the loop `break → absorb energy → mutate → face escalation` | Roblox defines the core loop as the most repeated minute-to-minute actions and the engine of progression. | The primary verb should directly feed meaningful choice and escalation. | Whether mutations improve replay intent or interrupt the action. |
| Prototype a five-to-eight-minute round | Short scope lets us test the complete loop before content production; Roblox recommends measuring step completion and drop-off. This is a project inference, not a Roblox benchmark. | Ship a measurable beginning, middle, end, and replay prompt early. | The ideal duration for the target players. |
| Use staged destruction with local cosmetic debris | Roblox performance guidance warns about high assembly counts and expensive precise collisions, and notes that visuals can be local while outcomes remain server-known. | Keep authoritative state small and predictable; use authored collision proxies and bounded effects. | The exact debris and simultaneous-collapse budgets for target devices. |
| Keep combat and rewards server-authoritative | Roblox security guidance requires validation of client intent and context and recommends server-side rate limiting. | Validate range, cadence, player state, targets, and rewards on the server. | Exact latency compensation and rate limits, which require network tests. |
| Aim Beam from the player view but resolve it on the server | Roblox's weapon-targeting guidance allows client aim intent when the server validates origin, direction/context, cadence, and obstruction. Native shape casts provide a bounded forgiving query. | Share a smoothed client aim direction with the head pose, validate it against Brontide's server pose, and let the server choose the hit. | Whether `0.18` seconds of aim lag, the turn limits, and the nine-stud cast radius feel accurate on each input device. |
| Turn Beam into a sustained destructive sweep | Roblox supports native shape casts and spatial queries, recommends event-driven work over unnecessary per-frame logic, and permits outcome-independent visuals to run locally. Its performance guidance warns that particles and transparency can become expensive on mobile. | Use a bounded server session and fixed-rate damage samples, while clients reuse a continuous mouth Beam and capped impact/collapse effects. | Channel duration, sample rate, penetration rule, damage budget, particle caps, comfort, and whether the result is more fun all require profiling and child playtests. |
| Let humans fight and physically confront the kaiju | Roblox Humanoids provide replicated health/death, collision groups provide selective physical blocking, and Roblox's security guidance requires the server to validate weapon origin, direction, obstruction, cadence, role and living state. | Use a server-raycast human blaster, server-owned kaiju attack damage, and one smooth contact proxy instead of making every giant limb collide. | Damage, fire rate, contact damage, knockback, respawn timing, balance and whether asymmetric combat is enjoyable are prototype hypotheses. |
| Start enemies with one scout drone | Native pathfinding is appropriate for ground agents, while Roblox warns that many server-animated Humanoids are expensive. A flying scout can use simpler authored patrol nodes and bounded line-of-sight checks. | Prove one lightweight, readable server-owned combatant before multiplying NPCs or building a boss. | Enemy count, attack cadence, projectile speed, and whether defenders improve rather than distract from destruction. |
| Design visual, mobile-first onboarding | Roblox recommends mobile consideration, rapid onboarding, visual tutorials, and low reliance on text. | Use target highlighting, icons, camera framing, and large touch-safe actions. | The control layout and prompt timing, which require device playtests. |
| Use original kaiju IP | Roblox's intellectual-property guidance requires creators to own or have permission for uploaded content. | Create original names, silhouettes, sounds, environments, and branding. | Which original visual direction has the strongest appeal. |
| Defer monetization | No source proves that monetization helps validate the core fun. The project also has a zero-cost implementation constraint. | Test fun, readability, performance, and replay before adding economy complexity. | A future ethical cosmetic model, if the game ever needs one. |

## Primary sources

These are the starting sources for systems and production decisions. Prefer official Roblox documentation and first-party reports for platform claims.

1. [Design for Roblox](https://create.roblox.com/docs/production/game-design/design-for-roblox) — onboarding, social play, audience, mobile, and visual communication.
2. [Core loops](https://create.roblox.com/docs/production/game-design/core-loops) — repeated actions and progression structure.
3. [Retention](https://create.roblox.com/docs/production/analytics/retention) — first-session experience, core-loop completion, and progression framing.
4. [Analytics](https://create.roblox.com/docs/production/analytics) — event measurement and metric sequencing.
5. [Client-server boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary) — input validation, combat validation, and rate limiting.
6. [Server-side detection](https://create.roblox.com/docs/scripting/security/server-side-detection) — server authority and harm prevention.
7. [Instance streaming](https://create.roblox.com/docs/workspace/streaming) — streaming benefits and large-place configuration.
8. [Performance improvement](https://create.roblox.com/docs/performance-optimization/improve) — frame work, physics assemblies, collision fidelity, and client visuals.
9. [Content maturity labels](https://en.help.roblox.com/hc/en-us/articles/8862768451604-Content-Maturity-Labels) — violence and fear boundaries.
10. [Intellectual property](https://create.roblox.com/docs/marketplace/intellectual-property) — ownership and permission requirements.
11. [Roblox genre insights](https://about.roblox.com/newsroom/2024/07/roblox-genre-insights-what-will-you-create-next) — first-party search and genre observations, including social co-opetition.
12. [2026 creator-program announcement](https://about.roblox.com/newsroom/2026/03/roblox-announces-incubator-jumpstart-creator-programs) — first-party emphasis on genre mashups, deep mechanics, and cross-platform play.
13. [Pathfinding](https://create.roblox.com/docs/characters/pathfinding) — native agent parameters, costs, modifiers, blocked paths, streaming compatibility, and computation limits.
14. [Server authority model](https://create.roblox.com/docs/projects/server-authority) — server-owned state with harmless client-side prediction for responsiveness.
15. [Particle emitters](https://create.roblox.com/docs/effects/particle-emitters) — burst emission, attachment placement, fade behaviour, quality testing, and particle fill-rate considerations.
16. [Design for performance](https://create.roblox.com/docs/performance-optimization/design) — baseline-device selection, frame-time budgets, event-driven work, built-in materials, streaming, and transparency overdraw.
17. [Test on hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware) — profiling on representative physical devices rather than treating emulation as final evidence.

## Hypothesis register

The thresholds below are **provisional project targets**, not published Roblox benchmarks. Record the device, build commit, player count, and whether coaching occurred for every test.

| ID | Hypothesis | Prototype measurement | Provisional pass signal | If it fails |
| --- | --- | --- | --- | --- |
| H1 | Immediate destruction sells the kaiju fantasy. | Time from character control to first building collapse; post-run replay choice. | At least 80% of first-time testers collapse a building within 60 seconds without verbal coaching; at least 60% voluntarily choose replay. | Simplify the route and controls; improve scale feedback before adding content. |
| H2 | Cooperative play adds coordination without making solo feel incomplete. | Solo and two-player completion, incapacitations, objective time, and short interview notes. | Both configurations finish; pairs show at least one observed cooperative behaviour; neither mode feels trivially easy. | Rework scaling, revive, and combo incentives independently. |
| H3 | A five-to-eight-minute slice is enough for escalation and replay. | Round completion time, quit point, idle/confused time, and replay choice. | At least 70% of guided-alpha runs finish; fewer than 20% contain a confusion stall longer than 20 seconds. | Shorten objectives or improve direction before changing the target duration. |
| H4 | A three-choice mutation creates meaningful variety without stopping momentum. | Time to choose, choice distribution, and ability to explain the chosen effect. | At least 80% choose within 10 seconds and can describe the effect after the round. | Reduce wording, strengthen visual previews, or offer two choices. |
| H5 | The action set is readable and usable on touch. | Mis-taps, missed cooldown feedback, camera corrections, and task completion on phone emulation and a real device. | Testers can use every core action without help and no single UI issue repeatedly blocks play. | Re-space controls, reduce simultaneous actions, or add context-sensitive input. |
| H6 | Authored destruction can create spectacle within a mobile budget. | Client and server frame time, memory trend, active physics assemblies, network traffic, and cleanup. | Representative lower-end profile remains at or above 30 FPS during the stress scene, with no unbounded memory or debris growth. | Lower debris lifetime/count, simplify collision, pool effects, and reduce simultaneous collapses. |
| H7 | The starter kaiju's weight comes from presentation as well as size. | Preference test across animation timing, camera, audio, hit-stop, and environmental reaction variants. | A clear majority describes the improved variant as heavier or more powerful without being told the intent. | Iterate presentation layers before increasing model size or damage. |
| H8 | A sustained Beam that traces successive collapses is more satisfying than one brief impact. | Compare current and channelled variants using successful targets per use, aim corrections, voluntary reuse, comfort reports, and preference. | Testers understand that holding/sweeping controls the path, intentionally destroy at least three structures in one valid opportunity, and prefer the sustained version without repeated discomfort. | Shorten the channel, strengthen path feedback, lower visual intensity, or restore discrete fire while retaining better collapse feedback. |
| H9 | Human weapons and dangerous kaiju contact make the scale difference interactive rather than cosmetic. | Two-client damage, deaths, respawns, contact stability, shots-to-defeat, role preference and voluntary rematches. | Both roles can damage and defeat the other through readable actions; contact blocks without uncontrolled launching; both players request another round. | Reduce damage asymmetry, improve cover/telegraphs, replace physical blocking with a server-owned boundary, or return humans to cooperative objectives. |

## Phase 2 destruction evidence specification

The implementation contract and source links are consolidated in [DESTRUCTION_SYSTEM.md](DESTRUCTION_SYSTEM.md). Its current feature claims are classified as follows:

| Claim | Classification | Evidence or measurement |
| --- | --- | --- |
| Authoritative state with client-local cosmetic effects reduces unnecessary replication and keeps outcomes secure. | Platform evidence and technical requirement. | Roblox performance and client-server security guidance. |
| One query hitbox and simple collision proxies are preferable to querying or colliding with decorative geometry. | Platform evidence plus engineering inference. | Roblox collision-fidelity, collision-group, and spatial-query documentation; verify query counts and route traversal. |
| Atomic streaming is appropriate for the complete authored state package. | Platform evidence plus engineering inference. | Roblox streaming documentation; verify late stream-in and memory before expanding package complexity. |
| Reusing a fixed set of short-lived client fragments reduces repeated instance allocation while preserving local-only spectacle. | Platform evidence plus measured engineering inference. | Roblox recommends pooling frequently respawned instances and creating outcome-independent visuals locally; compare created instances and cap behaviour under a 200-spawn synthetic stress run. |
| A particle dust layer is affordable in the representative district. | Unproven performance hypothesis; deferred. | Roblox warns that particles add draw calls and that emitter property changes can be expensive; inspect rendering and frame time after Phase 2C archetypes exist. |
| Three metric-derived archetypes can teach destructibility and orient the player without enlarging the district. | Level-design inference and hypothesis H6. | Compare uncoached target choice, route obstruction, state readability, instance composition, and collapse cost for the warehouse, tower, and substation. |
| A low-density west park/plaza loop improves orientation and combat-camera freedom without weakening the gate route. | Level-design inference and project hypothesis. | Verify both routes, gate non-bypass, camera clearance, scene composition, and uncoached branch comprehension before adding dense streets. |
| Three authored states provide enough spectacle for the kaiju fantasy. | Hypothesis H6. | Human readability and replay evidence plus the twenty-collapse device stress scene. |
| Charge should damage structures along its travel path. | Platform-supported engineering inference; implemented for testing. | Roblox's bounded spatial-query APIs support server-owned path impacts. Confirm that two damage, four unique targets, and the current hitbox make Charge useful without replacing Smash in child playtests. |
| A straight-line energy beam can add ranged expression without weakening server authority. | Platform-supported engineering inference; implemented for testing. | Roblox raycasts and collision filtering allow the server to select the first valid destructible while clients render transient visuals. Range, damage, cooldown, readability, and control comfort remain unproven. |
| A larger city can remain mobile-friendly with anchored authored states and streaming-ready atomic models. | Platform evidence plus performance hypothesis. | Roblox recommends designing for low-end devices, built-in materials, instance streaming for larger worlds, and profiling representative hardware. Editor validation cannot substitute for a real-device frame-time and memory capture. |
| Direct energy absorption improves the break loop. | Unregistered hypothesis; deferred. | Define comprehension and momentum measures before implementing the reward presentation. |

Small samples are for finding problems, not proving broad market demand. We will record sample size beside every result and avoid percentages when fewer than five people have tested a version.

## Instrumentation plan

Use Roblox's included analytics facilities; no paid analytics service is required.

Initial events:

- `ftue_control_granted`
- `first_structure_hit`
- `first_structure_collapsed`
- `first_energy_collected`
- `mutation_presented`
- `mutation_selected`
- `objective_started`
- `objective_completed`
- `player_incapacitated`
- `round_completed`
- `replay_selected`
- `round_abandoned`

Every event schema must be reviewed for privacy, cardinality, and usefulness before implementation. Do not collect free-form chat, names, or unnecessary personal data.

## Research workflow

For each material system:

1. Write the design question.
2. Find the strongest applicable source, preferring primary platform or research sources.
3. Label the conclusion as evidence, inference, or hypothesis.
4. Build the smallest prototype that can disprove it.
5. Add only the instrumentation needed to make the decision.
6. Playtest on the relevant devices and player counts.
7. Record results and sample size in the decision log.
8. Keep, revise, or remove the system before expanding its content.

Comparable games may inspire mechanic inventories and UX questions, but their revenue, popularity, or use of a feature does not establish causation. We will not clone their protected characters, branding, maps, audio, or distinctive expression.
