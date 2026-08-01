# Reuse audit

Before implementing a material system or producing a substantial asset, check whether a vetted free platform feature, package, or asset already solves it better. Reuse is a means to reduce risk and work, not a goal by itself.

## Acceptance checklist

A candidate must pass all applicable checks:

- Solves the current requirement without imposing a larger framework or content scope.
- Free to use and compatible with the repository's eventual code/asset licensing decision.
- Actively maintained, or stable and small enough to vendor safely.
- Has inspectable source and no unnecessary scripts, remotes, analytics, monetization, or network access.
- Keeps authoritative gameplay on the server and supports mobile performance targets.
- Does not contain protected entertainment IP or an imitation likely to create publishing risk.
- Can be pinned, attributed, replaced, and reviewed in Git.
- Is measurably cheaper or safer than the purpose-built alternative.

## 2026-08-01 — Phase 1 audit

| Need | Candidate | Decision | Reason |
| --- | --- | --- | --- |
| Character locomotion | Roblox R15 `Humanoid` character and default controls | **Use now** | Already cross-device, replicated, and integrated with Roblox camera and spawning. The prototype only scales and tunes it. |
| Camera | Roblox default character camera | **Use now** | Retains tested orbit, zoom, touch, mouse, and gamepad behaviour. The prototype adjusts zoom, offset, and field of view rather than replacing it. |
| Cross-device attack input | `ContextActionService` | **Use now** | One binding supports mouse, keyboard, gamepad, and an automatic touch action. |
| World contracts | `CollectionService` tags and instance attributes | **Use now** | Native, inspectable, and sufficient for the first destructible contract. |
| Attack overlap | `Workspace:GetPartBoundsInBox()` and `OverlapParams` | **Use now** | Native broad-phase query; the server controls the hitbox and result. |
| Cosmetic cleanup | Roblox `Debris` service | **Use now** | Bounded cleanup without adding a utility dependency. Pooling remains a later optimization if profiling justifies it. |
| Remote abstraction | RbxUtil `Comm`, `Net`, or `TypedRemote` | **Defer** | The slice has four simple remotes. A wrapper would currently add more API surface than it removes. Reassess when contracts multiply. |
| Cleanup utility | RbxUtil `Trove` | **Defer** | Current services own only a few connections and cleanup is explicit. Reassess if lifecycle bugs or nested resources appear. |
| UI framework | Roblox React-Luau | **Defer** | A three-label prototype HUD does not justify a component runtime and dependency tree. Reassess for the production hub/loadout UI. |
| Entity component system | Matter | **Reject current candidate** | The original repository is archived and the slice has too few dynamic entities to benefit. Research maintained alternatives only if enemy/destruction scale makes data-oriented iteration valuable. |
| Greybox city art | Roblox primitives | **Use now** | Fastest, safest, source-controlled way to test scale, collision, and destruction without prejudging the art direction. |
| Production modular city | Roblox's free `Modular Building Kit - Modern City`, asset `13168370735` | **Candidate for Phase 2** | It is published by Roblox and includes a documented modular workflow. Inspect scripts, instance count, collisions, textures, and modification rights in a disposable place before adopting it. Do not insert it into the game place until that review passes. |
| Destructible marketplace buildings | Community Creator Store results | **Do not use now** | Unknown scripts, structural-physics cost, inconsistent state contracts, and unclear fit. Our authored three-state requirement is small and game-specific. |
| Kaiju marketplace rigs | Creator Store results | **Reject** | Search results are dominated by Godzilla, MonsterVerse, and other protected properties, conflicting with original-IP requirements. |
| Original monster rig search | Free Creator Store models from verified-only search on 2026-08-01 | **Reject** | The results were unrelated or low-context community uploads and did not provide a clearly original, inspectable, mobile-ready rig. A lightweight original shell on the native R15 controller is lower risk for the comprehension prototype. |
| First city readability pass | Roblox primitives and materials | **Use now** | Roads, windows, rooftops, vehicles, lights, and the breakable gate are small game-specific compositions. They remain reviewable in Git, match the staged-destruction contract, and avoid importing a large unknown scene before the layout is validated. |

## Sources reviewed

- [Roblox asset system](https://create.roblox.com/docs/projects/assets)
- [Roblox packages](https://create.roblox.com/docs/projects/assets/packages)
- [Roblox Creator Store](https://create.roblox.com/docs/production/creator-store)
- [Roblox RbxUtil repository](https://github.com/Sleitnick/RbxUtil)
- [Roblox React-Luau repository](https://github.com/Roblox/react-luau)
- [Archived Matter repository](https://github.com/evaera/matter)
- [Official Modular Building Kit - Modern City](https://create.roblox.com/store/asset/13168370735)

Roblox warns that unfamiliar packages can contain malicious scripts and recommends saving and inspecting them before use. Accordingly, third-party models are reviewed in a disposable place and never inserted directly into the source place as an experiment.

The 2026-08-01 Creator Store re-check used free, verified-creator-only searches for an original monster rig and a low-poly city. No character result passed the originality, provenance, relevance, and inspection threshold. Community city packs were not adopted because the source-controlled primitive city solves the current readability test with less security and performance risk. The official Roblox modular kit remains the strongest later candidate.

## 2026-08-01 — Game-development skill audit

| Candidate | Decision | Reason |
| --- | --- | --- |
| Official OpenAI curated and experimental catalogues | **No game-design skill available** | The curated catalogue contained general development/design tools but no dedicated game-design or Roblox package; the former experimental path was unavailable. |
| `gamedev-skills/awesome-gamedev-agent-skills` | **Adopt six pinned skills** | Active Apache-2.0 repository with portable Codex support. The selected packages are concise Markdown plus references, contain no executable scripts, and directly cover current gaps: Roblox Luau, feel, UI/UX, levels, performance, and audio. |
| `brockmartin/roblox-game-skill` | **Reject** | Broad and potentially useful, but no repository licence was declared and the package includes a large amount of monetisation material outside current scope. |
| `rhino-ty/game-architect` | **Reject** | MIT licensed but strongly Steam/console/marketing oriented, with broad automatic triggering and unsourced persona assumptions that conflict with this project's evidence discipline and Roblox audience focus. |

The adopted skills are development guidance, not proof. Numerical recommendations remain provisional until supported by Roblox documentation, research, profiling, or project playtests. They add no runtime code or player data collection.

## 2026-08-01 — Phase 2A destruction audit

| Need | Candidate | Decision | Reason |
| --- | --- | --- | --- |
| Structure discovery and configuration | Native `CollectionService` tags and attributes | **Use** | Saved, replicated, inspectable, and already used by the prototype. Added/removed signals support packages without a framework. |
| Damage candidate filtering | Native collision groups plus `OverlapParams` | **Use** | One queryable hitbox per structure removes decorative geometry from authoritative overlaps and provides a bounded native query. |
| Durable late-join state | Replicated server-owned attributes | **Use** | Avoids a bespoke snapshot service for the current state count; live events remain cosmetic triggers only. |
| Complete streamed package | Native atomic model streaming | **Use provisionally** | Ensures the variant hierarchy arrives as a unit. Reassess memory after the twenty-structure stress scene; do not use persistent streaming as a shortcut. |
| State-machine/destruction framework | Creator Store and open-source destruction packages | **Reject for Phase 2A** | The required forward-only three-state machine is small and game-specific. General frameworks add unknown remotes, scripts, physics, or lifecycle surface. |
| Cosmetic object pool | Public PartCache copies and generic pools | **Defer** | No current candidate offered a clearly maintained canonical source and a better fit than a small fixed-cap local pool. Native timed cleanup remains until Phase 2B measures the stress path. |
| City content | Roblox Modern City kit `13168370735` | **Reference; do not import wholesale** | Roblox publishes it and its pivot workflow is reusable, but the listing reports 3,025 MeshParts, 796,055 triangles, and eight scripts. Inspect selected pieces only after the contract and blockout pass. |

No dependency or external asset was added by Phase 2A. Replacement plan: the shared contract is intentionally small; remove it if a future measured native or vetted package solves the same requirement with less code and equivalent security.

## 2026-08-01 — Phase 2B bounded-effects audit

| Need | Candidate | Decision | Reason |
| --- | --- | --- | --- |
| Repeated cosmetic fragments | Purpose-built client pool using native `Part` and `task.delay` | **Use** | The requirement is one small fixed-shape lifecycle: prewarm, acquire, deactivate, recycle oldest at the cap, and destroy with the controller. It remains local, inspectable, and dependency-free. |
| Generic pool or PartCache copy | Public Creator Store and open-source variants | **Reject for current scope** | No canonical candidate is needed for one effect type; importing a package would add licence, update, API, and security surface without reducing this game-specific code. |
| Timed destruction through native `Debris` | Existing Phase 2A path | **Replace for fragments** | It guarantees cleanup but still creates and destroys every fragment. The fixed pool measures created instances directly and keeps a hard live-object ceiling. |
| Dust burst | Native `ParticleEmitter:Emit()` | **Defer pending archetype profiling** | Native manual bursts are the preferred candidate, but Roblox warns that particles add draw calls and emitter property changes can have a dramatic performance impact. Establish Phase 2C render headroom before adding them. |

No dependency, external asset, texture, or paid service is added. Replacement plan: keep the pool only if the recorded stress run reduces created instances and respects cleanup/cap invariants; otherwise return to the simpler native cleanup path.

## 2026-08-01 — Phase 2C archetype audit

| Need | Candidate | Decision | Reason |
| --- | --- | --- | --- |
| Modular greybox archetypes | Roblox primitives, built-in materials, and one contract builder | **Use** | Directly tests footprint, silhouette, routing, state alignment, and budgets with reviewable source and no import pipeline. |
| Production city modules | Roblox Modern City kit `13168370735` | **Reference only** | Its consistent-pivot and modular-composition workflow informs the builder, but importing thousands of mesh parts and scripts cannot answer the current blockout questions more safely or cheaply. |
| Community warehouse, tower, or substation models | Creator Store results | **Do not use** | Unknown scripts, provenance, collision, pivots, and state variants would require more audit and conversion than the small metric-driven placeholders. |
| Original Blender buildings | Custom low-poly meshes | **Defer to art replacement** | Blender becomes valuable after footprints and state readability pass. The builder fixes pivots and gameplay proxies so visuals can later be replaced without rewriting systems. |

No dependency or external asset is adopted. Replacement plan: preserve structure IDs, pivots, attributes, hierarchy, proxies, and profiles while replacing only visual descendants with original optimized meshes after the blockout gate.

## 2026-08-01 — Phase 2D park/plaza audit

| Need | Candidate | Decision | Reason |
| --- | --- | --- | --- |
| Park/plaza greybox | Existing source-controlled primitive helpers and built-in materials | **Use** | The current question is route, scale, density, and camera clearance; native parts remain the smallest reviewable test. |
| Foliage and civic props | Small reusable primitive kit | **Use provisionally** | A trunk/canopy pair, planter, paving ring, and landmark provide scale cues without scripts, textures, imports, or gameplay physics. |
| Roblox Modern City kit `13168370735` | Selected road/park modules | **Reference only** | The kit's modular workflow is relevant, but importing production meshes cannot improve this greybox decision and would obscure the measured part delta. |
| Creator Store park packs | Community assets | **Do not use** | Unknown scripts, collisions, textures, provenance, and inconsistent scale cost more to audit than the bounded primitive composition. |
| Blender park assets | Original meshes | **Defer** | Replace the approved blockout kit only after route comprehension and target-device evidence justify production art. |

No dependency, external asset, texture, or paid service is added. Replacement plan: keep the layout coordinates and gameplay surfaces stable while later replacing only decorative descendants with original optimized assets.

## 2026-08-01 — Mixed-scale player audit

| Need | Candidate | Decision | Reason |
| --- | --- | --- | --- |
| Two physical character scales | Existing R15 `Humanoid`, `Model:ScaleTo()`, manual character loading and Brontide shell | **Use for feasibility** | Preserves native cross-device locomotion and tests actual replicated bounds without importing a rig or framework. |
| Per-role camera | Existing camera controller plus Roblox's local `Camera` and player zoom properties | **Extend** | The client already owns camera presentation; selecting metrics by replicated server role is smaller than introducing another controller package. |
| Contact filtering | Native `PhysicsService` collision groups | **Use** | Prevents human/kaiju flinging while leaving server spatial queries responsible for combat. |
| Human/kaiju framework or marketplace character | Creator Store and general character frameworks | **Do not use** | The feasibility question needs two roles, native characters and one original shell. External models add provenance, IP, scripts and performance risk without answering it better. |
| Character health, death and respawn | Native `Humanoid`, `Humanoid.Died`, and existing manual loading | **Use** | Already replicated and integrated with both character roles; a combat framework would add unnecessary state and remotes. |
| Human ranged weapon | Native `ContextActionService`, `RemoteEvent`, and server `Workspace:Raycast()` | **Use** | The first weapon has one firing mode. Roblox's native path supports every target device and the required server validation without an inventory or weapon framework. |
| Human/kaiju physical contact | One native smooth welded contact proxy plus collision groups and a throttled server overlap | **Use provisionally** | Full-rig collision is unstable at the measured scale difference. One inspectable proxy provides physical blocking while explicit server logic owns damage and bounded knockback. |

No dependency, external asset, paid service or new production art is adopted. Replace the enlarged R15 proxy with an original Blender custom humanoid only after actual bounds, role fun, camera comfort and mobile performance pass.

## 2026-08-01 — Localized authored-damage audit

| Need | Candidate | Decision | Reason |
| --- | --- | --- | --- |
| Durable impact-local damage | Native attributes plus a shared fixed-zone codec | **Use** | A compact server-owned string reconstructs hit location and attack type for late joiners without replicating arbitrary geometry or trusting client coordinates. |
| Persistent rupture presentation | Small client-authored primitive cavity and torn rim | **Use provisionally** | It directly replaces the observed Neon placeholder, uses built-in materials, remains non-physical, and is capped per structure. Retain only if phone playtests find it more convincing. |
| Runtime `SubtractAsync`/CSG | Native CSG operation | **Reject for this slice** | It yields and would create changing complex geometry on the authoritative path; the current hypothesis does not require arbitrary topology. |
| Runtime `EditableMesh` cutting | Native mesh API | **Defer** | Published use requires the Mesh/Image API setting and eligible account verification, and creation can fail against device-specific editable-memory budgets. Reassess only if authored zones cannot meet the visual gate. |
| Marketplace destruction framework | Creator Store/community packages | **Reject** | The existing strict registry, state machine, queries, late-join attributes, and debris pool already cover the requirement with less security, licence, and performance surface. |

No dependency, external asset, texture, paid service, or new permission is added. Replacement plan: preserve the impact metadata and replace only the primitive client renderer with original archetype-specific Blender breakaway meshes if H10 passes.
