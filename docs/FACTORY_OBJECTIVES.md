# Factory objectives and reinforcement lanes

This specification adds MOBA-compatible territory structure to the current cooperative destruction prototype without committing the whole game to a competitive MOBA. A factory is an objective, a bounded reinforcement producer, and a link between a city district and its defensive network.

## Intended map shape

The map is a chain of dense urban islands separated by broad traversal land. Each island contains a short readable objective sequence; open land provides anticipation, route choice, enemy encounters, and recovery space. The golden path ends at an enemy base, while cross-routes and optional objectives can later support lanes, flanking, allied waves, or opposing teams.

```text
Start island -> open-land encounter -> factory city -> recovery route -> power/park city -> enemy base
                                      |             |
                                      + optional turret / resource branches
```

Greybox and test one island-to-island sequence before increasing map size. The map owner decides terrain, city composition, sightlines, landmarks, and exact placement; code reads visible authored markers and never procedurally replaces the saved map.

## Objective contract

Tag the top-level factory model `ReinforcementFactory` and set these attributes:

| Attribute | Required | Meaning |
| --- | --- | --- |
| `FactoryId` | yes | Stable unique ID used by turrets, vehicles, and objectives. |
| `OwnerTeam` | yes | `Enemy`, `Neutral`, `Human`, or `Kaiju`; the first asymmetric slice starts as `Neutral`. |
| `SpawnProfile` | yes | `Tank`, `Helicopter`, or `Mixed`. |
| `LaneId` | recommended | Authored route/lane identity for later MOBA waves. |
| `LinkedStructureId` | recommended | `StructureId` of the destructible factory building; collapse makes the objective `Destroyed`. |
| `ObjectiveId` | recommended | Stable campaign/objective-graph node. |
| `SpawnInterval` | optional | Server-clamped wave interval; minimum five seconds. |
| `CaptureRadius` | optional | Horizontal capture radius. |
| `CaptureSeconds` | optional | Uncontested time required to capture. |

The model uses visible, movable authoring children:

- `CaptureZone`: capture centre and Edit-mode footprint.
- `TankSpawn`: ground-vehicle origin.
- `HelicopterSpawn`: air-vehicle origin and altitude.
- `GroundRoute/Node01`, `Node02`, …: ordered road route.
- `AirRoute/Node01`, `Node02`, …: ordered aerial patrol route.

Route markers are level-design data. Keep ground nodes on roads with enough clearance for the proxy and final audited tank. Keep air nodes above nearby collision and away from spawn cameras. Names sort lexically, so use zero-padded numbers.

## Server-owned lifecycle

`Operational -> Capturing -> Captured` or `Operational -> Destroyed`.

- A neutral operational factory is dormant and emits no vehicles.
- Only living human players advance capture; kaiju cannot capture or contest the zone.
- Human capture starts bounded allied production and transfers factory-linked turrets to the Human side.
- Collapsing the linked destructible stops production permanently for that round.
- Human-owned vehicles ignore humans and engage opposing kaiju/rogue targets using server line-of-sight, sticky target selection, velocity-based projectile lead, short target memory, and route-stuck recovery.
- Existing defenders remain after destruction in the first slice; playtesting decides whether they should clear or retreat.

All capture, ownership, spawn timing, movement, target selection, projectile travel, damage, health, and defeat are authoritative on the server. Replicated attributes drive presentation and diagnostics. There is no client remote that can request a spawn, capture, hit, or ownership change.

## First feasibility slice

Build and test exactly one factory with:

- maximum two active tanks and one active helicopter;
- one authored ground route and one authored air route;
- physically distinct cannon shells and helicopter bullets;
- player attacks and captured turrets able to damage vehicles;
- human capture starting the bounded allied wave, or kaiju destruction preventing production;
- one or two factory-linked turrets changing allegiance on capture;
- primitive original proxy vehicles until replacements pass the commercial-use, IP, security, assembly, collision, and mobile-cost audit.

The proxy is an engineering presentation, not production art. An accepted imported model replaces visual descendants while preserving `VehicleRoot`, stable attributes, route behaviour, query geometry, and server authority.

## Pacing and encounter test

Use a sawtooth sequence: quiet approach, first visible wave, short pressure spike, capture/demolition choice, then a safe overlook toward the next island. Teach the factory in isolation before combining it with an elite kaiju, multiple turrets, or the enemy-base shield.

Record:

- whether the tester identifies the factory as the source of reinforcements without coaching;
- first-wave arrival, time to disable/capture, contested time, deaths, and idle/confused time;
- whether tanks remain on understandable roads and helicopters remain visible and avoid scenery;
- whether cannon and helicopter fire are named or dodged differently;
- active factories, vehicles, projectiles, server/client frame time, memory, and phone thermal behaviour;
- whether capture, destruction, or bypass feels like a meaningful route decision.

Do not multiply factories until the representative phone remains above the provisional `30 FPS` floor, every runtime count stays bounded, and a child tester can explain why enemies stopped spawning.

## Asset boundary

Creator Store candidates are leads, not approved assets. Nothing enters `assets/ASSET_REGISTER.md` or the authored map until the listing, uploader rights, terms, contents, scripts, remotes, sounds, textures/decals, mesh complexity, pivots, collisions, and commercial-use requirements have been inspected. Free fan-IP models are rejected even when a listing claims broad reuse.

## Research basis

- [Roblox greyboxing](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/greybox-your-environment)
- [Roblox pathfinding](https://create.roblox.com/docs/characters/pathfinding)
- [Roblox instance streaming](https://create.roblox.com/docs/workspace/streaming)
- [Roblox performance design](https://create.roblox.com/docs/performance-optimization/design)
- [Roblox server-side security](https://create.roblox.com/docs/scripting/security/server-side-detection)
- [Creator Store Terms](https://en.help.roblox.com/hc/en-us/articles/21308223046932-Creator-Store-Terms)
- [Roblox asset intellectual property](https://create.roblox.com/docs/marketplace/intellectual-property)
