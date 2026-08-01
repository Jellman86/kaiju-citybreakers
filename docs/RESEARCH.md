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
| Three authored states provide enough spectacle for the kaiju fantasy. | Hypothesis H6. | Human readability and replay evidence plus the twenty-collapse device stress scene. |
| Charge should damage structures along its travel path. | Unregistered hypothesis; deferred. | Define expected role, use rate, collision behaviour, and a test before implementation. |
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
