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
