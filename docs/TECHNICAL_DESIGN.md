# Technical design

## Architecture principles

- The server owns round phase, damage, objectives, rewards, destructible state, and enemy decisions.
- Clients own input collection, camera, HUD, local animation prediction, cosmetic debris, and non-authoritative effects.
- Remotes express intent rather than outcomes. A client requests an attack; the server determines whether it can happen and what it hits.
- Rojo-managed files are authoritative for scripts. The focused `src/world` model files are authoritative for Studio-authored terrain and map composition; see [MAP_AUTHORING.md](MAP_AUTHORING.md).
- Systems are built for one player first, then tested with two clients before expanding capacity.

## Rojo data model

```text
ReplicatedStorage
├── Shared                 <- src/shared
└── Remotes                <- created/mapped folder

ServerScriptService
└── Server                 <- src/server/init.server.luau
    ├── Builders
    ├── Services
    └── Tests              <- Studio-only multiplayer orchestration

StarterPlayer
└── StarterPlayerScripts
    └── Client             <- src/client/init.client.luau
        ├── Controllers
        ├── Effects
        └── Tests          <- Studio-only client observations

Workspace
├── Terrain                <- src/world/Terrain.rbxmx
└── KaijuFeelLab           <- src/world/KaijuFeelLab.rbxmx
    ├── AuthoringGuides    <- Edit-only map bounds and scale references
    ├── AuthoringInbox     <- sandboxed Edit-only candidate-model handoff
    ├── GameplayMarkers    <- visible movable source markers read by server systems
    └── EnemyTemplates     <- visible replaceable visual templates cloned at runtime
```

## Planned server services

### RoundService

Controls Waiting, Countdown, Active, and Results phases. Publishes timestamps rather than trusting client timers.

### KaijuService

Owns the replicated `Human`/`Kaiju` role, loads characters only after role-specific spawns exist, applies server-owned scale and movement metrics, assigns collision groups, builds the Brontide shell, and promotes a human if the kaiju leaves. The first player is the solo-safe kaiju; later players are humans during the feasibility slice.

### CombatService

Validates role, living state, cooldowns, range, aim, obstruction and target state. Kaiju spatial queries damage structures and humans; the human blaster starts at the server-known character and raycasts the first eligible obstruction or kaiju. A fixed-rate overlap around the smooth kaiju contact hull owns contact damage and clamps knockback independently of client-owned character physics.

### DestructionService

Moves tagged buildings through Intact, Damaged, and Collapsed states. Sends compact state changes while clients produce cosmetic effects.

### ObjectiveService

Tracks district objectives and emits progress. Objectives reference tagged world instances rather than hard-coded paths.

### EnemyService

Runs a modest number of server-owned decisions. Uses simple state machines and throttled sensing rather than expensive per-frame pathfinding.

### RewardService

Calculates round results on the server. Persistence is not implemented until the loop passes the vertical-slice gate.

## Planned client controllers

- InputController: device-independent actions.
- AimController: one bounded reticle ray for both roles, immediate human aim, smoothed kaiju head/Beam aim, camera-forward body facing for keyboard/mouse, and centred gamepad/touch intent.
- CameraController: locked-mouse desktop orbit for both roles, including a human-scale over-the-shoulder offset, scale, obstruction, zoom, shake, and accessibility settings.
- KaijuController: predicted animation and ability feedback.
- RoundController: local round snapshot and timer.
- HudController: objective, energy, health, and abilities.
- EffectsController: pooled debris, particles, sound, and impact feedback.

## World contracts

Use CollectionService tags and attributes so world building does not depend on fragile hierarchy paths.

### Mixed-scale characters

- `CharacterRole` is server-authored on both `Player` and character and is either `Kaiju` or `Human`.
- The provisional Brontide uses real model scale `10`; the human retains the ordinary Roblox avatar scale. Automated acceptance measures the resulting bounds and requires at least a `10:1` standing-height ratio.
- `KaijuCharacters`, `HumanCharacters`, and `HumanScaleGeometry` are registered collision groups. Character-to-character contact is non-colliding, while tagged human-scale geometry can block humans without trapping or flinging the kaiju.
- Combat remotes reject human characters before cooldown or spatial work. Collision groups improve physical stability but never grant damage authority.
- Both roles use the custom scale-aware keyboard/mouse camera and retain native gamepad/touch camera behavior. Humans receive no kaiju actions.
- The human instead receives one cross-device `FIRE` action. Both roles share the same visible reticle: keyboard/mouse moves it within safe viewport bounds while touch/gamepad keep it centred. Both roles use native Humanoid health/death, have passive regeneration disabled, and respawn through the server's manual role-preserving lifecycle.
- `KaijuSpawn`, `HumanSpawn`, and the tagged doorway reference are a feasibility lab, not final production level design.

### `Destructible`

Required attributes:

- `StructureId: string`
- `MaxHealth: number`
- `EnergyValue: number`
- `MaterialProfile: string`

Server-owned runtime attributes:

- `CurrentHealth: number`
- `DestructionState: Intact | Damaged | Collapsed`
- `DestructionStateSequence: number`
- `DamageImpactSequence: number`
- `DamageZoneState: string` — fixed-width compact zone encoding; `-`, `S`, `C`, and `B` mean empty, Smash, Charge, and Beam.
- `DamageSurfaceProfile: Box | Cylinder`

The full hierarchy, collision/query rules, evidence basis, and provisional gates are defined in [DESTRUCTION_SYSTEM.md](DESTRUCTION_SYSTEM.md).

### `ObjectiveTarget`

Required attributes:

- `ObjectiveId: string`
- `ObjectiveType: string`
- `RequiredProgress: number`

### `EnemySpawn`

Required attributes:

- `SpawnGroup: string`
- `MinimumDefenceLevel: number`
- `Weight: number`

## Remote contract

Initial remote:

- `RoundState`: server-to-client snapshot containing phase, server timestamp, phase end timestamp, and sequence number.

Later remotes:

- `AbilityRequest`: client-to-server intent with ability ID and input sequence; the server evaluates the replicated character facing and authoritative hitbox.
- `AbilityResult`: server-to-client confirmation/rejection and authoritative targets.
- `DestructionState`: server-to-client live transition feedback containing a stable structure ID, state, sequence, effect position, and material profile. Replicated attributes remain the durable late-join source of truth.
- `ObjectiveState`: server-to-client objective progress.

Every client-to-server payload has type, rate, ownership, state, and spatial validation.

## Destruction implementation

Avoid unrestricted fracture simulation. Each building package contains authored variants with aligned pivots:

```text
Building
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

The server switches authoritative health and simple collision proxies. Each client selects the visible authored variant and emits non-authoritative effects. Cosmetic fragments have no gameplay collision, no shadows, and a short lifetime. A client-only pool prewarms one collapse, grows to a hard 100-part cap, and recycles the oldest active fragment on overflow. Per-entry generations prevent an earlier delayed cleanup from deactivating a reused fragment. Inactive fragments are unparented, and controller destruction destroys the complete pool.

`DestructibleStructureBuilder` owns the repeated hierarchy, authoring attributes, atomic streaming mode, damage hitbox, effect origin, proxies, tag, and build-time visual safety assertions. Archetype functions supply only aligned visual variants and dimensions. The gate remains the legacy reference package until its objective label is separated from its variant visuals.

`DistrictDressingBuilder` owns the west park/plaza's reusable primitive scale cues. Its trees, planters, rings, pylons, and landmark are anchored local scenery with collision, touch, query, and shadows disabled; only the two broad ground surfaces participate in character collision. Road, sidewalk, and gate-cordon surfaces remain owned by `PrototypeWorldService` because they define the district route and objective boundary.

The same builder owns Arc Power Plant's low-cost functional silhouette: paired cooling basins and towers, generation halls, coolant and steam headers, a fenced transformer/switchgear yard, busbars, and an outgoing transmission gantry. These are original anchored primitives rather than a copied facility or imported pack. Decorative floor-light channels are prohibited because they weaken the industrial read without explaining how power leaves the site.

`SmashAnimator` gives the local player a measured windup, strike, impact hold, and eased recovery while `CombatService` remains authoritative for hit timing and damage. Each Brontide shell attachment uses a dedicated `Motor6D`; the six arm/forearm/claw pivots animate persistent `C0` offsets because Roblox's avatar animation pass overwrote ordinary body-joint transforms before display. The controller records actual displacement of those visible shell parts and restores every pivot after recovery. Confirmed, non-predicted Smash results can replay the pose for Studio coverage without granting the client damage authority.

The human-authored `Workspace.Terrain` and `Workspace.KaijuFeelLab` models own the shipped environment. `PrototypeWorldService` preserves those instances during Play and only runs the procedural composition when the map root is absent. `TerrainBuilder.Ensure` likewise preserves any non-empty terrain; its destructive `Build` path remains an explicit empty-place fallback. The captured baseline retains the original bounded Grass, Rock, Sand, and Water profile, while future skyline, route, and terrain-quality decisions are made visually in Studio and captured through [MAP_AUTHORING.md](MAP_AUTHORING.md).

`AuthoringGuides` and the sandboxed `AuthoringInbox` are source-controlled inside that world so the map owner can see full terrain bounds, compare human/kaiju scale, and place candidate assets in context. `PrototypeWorldService` destroys both before gameplay begins. They never become targets, collisions, objectives, AI, or production visuals. A candidate leaves the inbox only after the asset/reuse audit and removal of all imported executable behaviour.

Gameplay markers, turret aim assemblies, and enemy templates are also source-controlled and remain visible in Edit mode. Unlike the two authoring-only folders, server systems read or clone them at Play. Names, tags, and contract parts are code-owned; their world transforms and reviewed visual descendants are map/model-owner authored.

The versioned `StudioTestService` regression starts with one client, drives the real authoritative attack path, then adds a late client and compares server state with both clients' replicated attributes and locally selected variants. Test modules are inert outside Studio and unless their exact test argument is present; see [MULTIPLAYER_TESTING.md](MULTIPLAYER_TESTING.md).

Concrete, metal, and lightweight material profiles vary fragment material, colour, size, and speed without changing gameplay. Dust particles, camera impulses, and sound remain separate evidence-gated layers; Roblox warns that particles add draw calls and that emitter property changes can be expensive.

## Performance budgets

Initial targets, adjusted after device testing:

- 30 FPS minimum on a representative lower-end mobile profile.
- 60 FPS target on desktop.
- At most 100 visible cosmetic debris parts per client.
- Cosmetic debris lifetime of roughly 4–6 seconds.
- At most 20 simultaneously active simple enemies in the slice.
- No per-frame server raycasts for every enemy.
- Streamed city districts and simple collision proxies.
- Texture sizes normally 1024 or lower for reusable environment assets.

## Testing strategy

### Automated/free checks

- StyLua formatting check.
- Selene lint.
- Rojo build validation.
- Pure-module tests when combat math and mutation selection exist.

### Studio tests

- Solo local server.
- Two-client simulation after every networking milestone.
- Mobile and tablet emulation for every HUD/input change.
- Artificial latency during combat milestones.
- Late join during Active state.
- Player disconnect during objectives and results.

## Security checklist

- Never accept client-supplied damage, reward amount, cooldown completion, or target ownership.
- Rate-limit every client-to-server remote.
- Clamp positions, vectors, IDs, and numeric values.
- Confirm the player controls the requesting kaiju.
- Confirm round and knockout state before abilities.
- Calculate hits on the server using server-observed state.
- Keep mutation and unlock definitions in server-readable shared configuration, with ownership validated server-side.
