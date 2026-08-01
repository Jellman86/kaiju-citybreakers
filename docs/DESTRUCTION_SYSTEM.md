# Destruction system specification

This is the implementation contract for the Phase 2 destruction sandbox. It translates the evidence in [RESEARCH.md](RESEARCH.md) into a small system that can be disproved through profiling and human playtests before the city expands.

## Decision boundary

Use authored `Intact`, `Damaged`, and `Collapsed` states for gameplay structures. The server owns health, state, collision, rewards, and objective consequences. Clients select the visible authored state and create bounded cosmetic effects.

Do not use unrestricted fracture, joint-breaking explosions, voxel destruction, or authoritative physical rubble for the vertical slice. Roblox documents that additional simulated assemblies and precise collision increase physics cost, while state changes and effects that do not affect outcomes can be handled with compact replication and client-local visuals. See [Improve performance](https://create.roblox.com/docs/performance-optimization/improve) and [Securing the client-server boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary).

This establishes technical feasibility, not fun. H1 and H6 in [RESEARCH.md](RESEARCH.md) remain open until uncoached human and representative-device evidence exists.

## Reusable model contract

Every model tagged `Destructible` must be an atomic streaming unit and conform to this hierarchy:

```text
DestructibleBuilding
├── Visuals
│   ├── Intact
│   ├── Damaged
│   └── Collapsed
├── Collision
│   ├── IntactProxy
│   └── CollapsedProxy
└── DamageHitbox
    └── FxOrigin
```

Required authoring attributes:

| Attribute | Type | Rule |
| --- | --- | --- |
| `StructureId` | string | Non-empty and unique within the server. |
| `MaxHealth` | number | Finite and greater than zero. |
| `EnergyValue` | number | Finite and non-negative; the reward system will consume it later. |
| `MaterialProfile` | string | Non-empty feedback profile such as `Concrete`, `Metal`, or `Lightweight`. |

Runtime attributes owned by the server:

- `CurrentHealth`
- `DestructionState`
- `DestructionStateSequence`
- `DamageImpactSequence`
- `DamageZoneState`

`DamageZoneState` is a fixed-width, compact surface map. The server derives a zone from the validated attack geometry rather than accepting a client-selected building coordinate. Box structures use four faces, two columns, and three height bands; cylindrical structures use eight angular sectors and three height bands. Each zone stores `-`, `S`, `C`, or `B` for empty, Smash, Charge, or Beam. The configured per-structure mark cap bounds the client instance cost.

The shared `DestructibleContract` module is the source of truth for names and validation. Invalid or duplicate structures are ignored with a diagnostic rather than crashing the round.

Roblox tags and attributes are native, saved with the place, and replicated. `CollectionService` also supplies added and removed signals, allowing the same service to register authored and dynamically added packages without hierarchy-specific paths. See [Properties, tags, and attributes](https://create.roblox.com/docs/studio/properties) and [CollectionService](https://create.roblox.com/docs/reference/engine/classes/CollectionService).

## State and replication rules

The allowed forward path is:

```text
Intact → Damaged → Collapsed
```

- Positive finite server damage reduces `CurrentHealth` within `[0, MaxHealth]`.
- Any positive loss that leaves health above zero produces `Damaged`.
- Zero health produces `Collapsed`.
- A collapsed structure rejects further damage.
- Reset restores maximum health and `Intact`; round reset batching is deferred until the round service consumes it.
- The state sequence increases only when the state changes; the impact sequence increases for every accepted hit, including repeated hits while already damaged.

The replicated event contains stable IDs, state and impact sequences, server-derived attack type, zone index, impact position/normal, zone state, and material profile. It triggers live feedback; it is not the source of truth. Replicated attributes reconstruct durable state and localized rupture marks for late joiners or structures that stream in after their transition. Clients tolerate either arrival order.

## Rendering, collision, and hit detection

- Authored visual parts are anchored and have gameplay collision, touch, and query disabled.
- Clients use `LocalTransparencyModifier` to select one visible variant without changing authoritative state.
- `IntactProxy` is the only blocking collision in `Intact` and `Damaged`.
- `CollapsedProxy` is the only blocking collision in `Collapsed`; it must preserve an intentionally usable route.
- `DamageHitbox` is invisible, non-colliding, and the only queryable part in the package.
- The server places damage hitboxes in `DestructibleQuery`. Attack overlaps use `KaijuAttackQuery`, which ignores ordinary world geometry and returns a bounded number of candidates.

This follows Roblox's native collision filtering and `OverlapParams` facilities. See [Collisions and collision groups](https://create.roblox.com/docs/workspace/collisions) and [OverlapParams](https://create.roblox.com/docs/reference/engine/datatypes/OverlapParams).

Set a destructible root to `ModelStreamingMode.Atomic` because the client needs its complete variant package when it becomes eligible to stream. Do not use `Persistent` to bypass streaming. Roblox explicitly recommends atomic models for logical groups and minimizing persistent models. See [Instance streaming](https://create.roblox.com/docs/workspace/streaming).

## Feature tiers

| Tier | Examples | Contract |
| --- | --- | --- |
| Full destructible | Warehouse, tower, substation | Three authored states and gameplay collision proxies. |
| Objective destructible | Gate, generator, defence tower | Full contract plus an objective listener. |
| Lightweight reactive | Cars, lamps, trees, kiosks | One cheap reaction; separate contract after the full structure gate. |
| Static | Roads, terrain, distant shells | No destruction registration. |

The city should communicate what can break through consistent visual treatment. Whether this is understood without coaching is a hypothesis measured by time to first hit and collapse, not an assumption.

## Reuse and asset policy

Use Roblox-native tags, attributes, packages, spatial queries, collision groups, streaming, remotes, MicroProfiler, and SceneAnalysisService. No runtime dependency is adopted.

Roblox's free Modern City kit is a modular-workflow reference, not a wholesale Phase 2 import. Its current listing reports 3,025 mesh parts, 796,055 triangles, and eight scripts. Selective pieces may be inspected later in a disposable place, with scripts disabled and performance measured. The system and first three archetypes remain source-controlled primitives until their scale, routes, and state transitions pass. See the [official kit](https://create.roblox.com/store/asset/13168370735) and [modular environment workflow](https://create.roblox.com/docs/tutorials/use-case-tutorials/modeling/assemble-modular-environments).

A general destruction framework or third-party part-cache package would add more maintenance and security surface than it removes. Phase 2B uses a small purpose-built client pool: it prewarms one ten-fragment collapse, grows only as demanded to a hard 100-part maximum, and recycles the oldest active fragment at saturation. Inactive parts are unparented; controller teardown destroys them. Generation tokens make delayed releases harmless after an entry has been reused.

Roblox explicitly recommends pooling frequently respawned instances and creating outcome-independent visuals locally. Applying that advice to fragments is an engineering inference, so the implementation records spawned, created, active, peak-active, and recycled counts. It is retained only if the stress test reduces created instances and respects the configured cap. See [Improve performance](https://create.roblox.com/docs/performance-optimization/improve).

Concrete, metal, and lightweight profiles vary only fragment colour, native material, size, and speed. A separate dust layer is deferred: Roblox notes that particles do not batch well and that emitter property changes can have a dramatic performance impact. Add `ParticleEmitter:Emit()` presets only after the Phase 2C archetype scene establishes render headroom. See [ParticleEmitter](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter).

Persistent localized marks use a dark circular cavity plus a small non-emissive torn rim built from anchored, non-queryable client parts. They are rebuilt only when the replicated zone string changes, hidden outside `Damaged`, and destroyed with the streamed structure/controller. Transient impact chips reuse the existing fixed-cap debris pool. Runtime CSG and `EditableMesh` are deliberately not used in this slice because their yielding/permission/device-memory paths do not improve the bounded visual hypothesis enough to justify the risk.

## Provisional Phase 2 gates

These are project thresholds, not Roblox benchmarks:

- Twenty structures can collapse in sequence without incorrect states or unbounded debris growth.
- A late-joining client and a structure that streams in late display the authoritative state without replaying old collapse effects.
- The player can traverse the intended collapsed route without snagging on decorative geometry.
- The client never displays more than 100 cosmetic debris parts and cleans every effect within its configured lifetime.
- A 200-spawn overlapping stress run creates at most 100 fragment instances, records at least 100 oldest-active recycles, and returns all entries to the available pool after the final lifetime.
- A representative lower-end mobile profile maintains at least 30 FPS in the stress scene, with client and server frame-time spikes inspected separately.
- One local server and two clients agree on state, health, sequence, and collision.

The pre-Phase-2 Studio baseline, captured from one current camera view on 2026-08-01, was 805 runtime instances, 236 3D objects, 18,738 triangles, and 12 draw calls. It is a comparison point only; view-dependent Studio data is not representative-device proof. Roblox recommends maintaining a real baseline device because Studio emulation is not accurate for device memory. See [Design for performance](https://create.roblox.com/docs/performance-optimization/design) and [MicroProfiler](https://create.roblox.com/docs/performance-optimization/microprofiler).

## Next implementation slices

1. **Phase 2A — contract:** strict validation, registration, state machine, collision/query proxies, compact events, late-stream state selection.
2. **Phase 2B — bounded spectacle:** fixed-cap debris pool, material response presets, cleanup and distance limits. Dust is deliberately gated on Phase 2C profiling.
3. **Phase 2C — archetypes:** metric-derived warehouse, signal tower, and substation built through a reusable strict builder; see [DISTRICT_BLOCKOUT.md](DISTRICT_BLOCKOUT.md).
4. **Phase 2D — mixed district:** measured Brontide metrics, warehouse lane, optional park/plaza loop, objective-safe reconnect, then a separately measured dense avenue greybox; see [MIXED_DISTRICT.md](MIXED_DISTRICT.md).
5. **Phase 2E — evidence:** twenty-collapse stress test, two-client and late-join tests, SceneAnalysis/MicroProfiler capture, real-iPad run, and uncoached human playtest.

The representative two-client late-join reconstruction gate passed at commit `eeaf523`. The twenty-collapse sequence, explicit stream-out/stream-in movement, representative-device profiling, and human readability evidence remain open.

Charge damaging structures and immediate energy absorption are deliberately deferred. Each must be added to [RESEARCH.md](RESEARCH.md) as a testable feature hypothesis before implementation.
