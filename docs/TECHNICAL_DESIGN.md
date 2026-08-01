# Technical design

## Architecture principles

- The server owns round phase, damage, objectives, rewards, destructible state, and enemy decisions.
- Clients own input collection, camera, HUD, local animation prediction, cosmetic debris, and non-authoritative effects.
- Remotes express intent rather than outcomes. A client requests an attack; the server determines whether it can happen and what it hits.
- Rojo-managed files are authoritative for scripts. Studio instances, tags, attributes, terrain, lighting, and placement remain in the place.
- Systems are built for one player first, then tested with two clients before expanding capacity.

## Rojo data model

```text
ReplicatedStorage
├── Shared                 <- src/shared
└── Remotes                <- created/mapped folder

ServerScriptService
└── Server                 <- src/server/init.server.luau
    └── Services

StarterPlayer
└── StarterPlayerScripts
    └── Client             <- src/client/init.client.luau
        └── Controllers
```

## Planned server services

### RoundService

Controls Waiting, Countdown, Active, and Results phases. Publishes timestamps rather than trusting client timers.

### KaijuService

Spawns kaiju rigs, applies server-owned stats, validates ability requests, and manages knockout/revival state.

### CombatService

Validates cooldowns, range, arc, line of sight, team rules, and target state. Produces authoritative damage events.

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
- AimController: camera-forward yaw facing for keyboard/mouse, with native auto-facing retained for gamepad and touch.
- CameraController: locked-mouse desktop orbit, scale, obstruction, zoom, shake, and accessibility settings.
- KaijuController: predicted animation and ability feedback.
- RoundController: local round snapshot and timer.
- HudController: objective, energy, health, and abilities.
- EffectsController: pooled debris, particles, sound, and impact feedback.

## World contracts

Use CollectionService tags and attributes so world building does not depend on fragile hierarchy paths.

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

The server switches authoritative health and simple collision proxies. Each client selects the visible authored variant and emits cosmetic fragments, dust, camera impulses, and sound. Cosmetic debris has no gameplay collision and a short lifetime. A fixed-cap pool remains Phase 2B work; Phase 2A retains native timed cleanup.

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
