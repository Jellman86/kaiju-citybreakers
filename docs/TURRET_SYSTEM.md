# Capturable turret system

## Purpose and evidence boundary

Turrets are shared territory objectives: a living human or kaiju holds a clearly marked zone to capture a neutral or opposing turret, and an owned turret automatically attacks the other role. The first slice exists to test whether this produces readable movement and counterplay in the mixed-scale game; it is not evidence that a conventional MOBA rule set fits this project.

Roblox provides the platform facts used here:

- The server is the source of truth for game state, and clients should render harmless presentation separately from authoritative outcomes: [client-server runtime](https://create.roblox.com/docs/projects/client-server) and [server authority model](https://create.roblox.com/docs/projects/server-authority).
- Instantaneous ray hits and physically simulated projectiles solve different gameplay requirements. Roblox's weapon guidance uses moving shot effects for visible arrows or rockets and separate explosive-projectile settings: [detect hits](https://create.roblox.com/docs/tutorials/curriculums/gameplay-scripting/detect-hits) and [weapons kit](https://create.roblox.com/docs/resources/weapons-kit).
- `Workspace:Raycast()` and filtering are the native obstruction tools: [raycasting](https://create.roblox.com/docs/workspace/raycasting).
- High-frequency `RunService` work should be bounded and measured on a representative physical device; Studio emulation is not a memory-performance substitute: [design for performance](https://create.roblox.com/docs/performance-optimization/design) and [improve performance](https://create.roblox.com/docs/performance-optimization/improve).
- Creator Store models can contain scripts, and moderation cannot guarantee that every backdoor is removed. Imported models require inspection or sandboxing: [third-party asset vulnerabilities](https://create.roblox.com/docs/scripting/security/third-party-vulnerabilities) and [Creator Store](https://create.roblox.com/docs/production/creator-store).

No source establishes the correct capture time, radius, damage, range, projectile speed, target priority, or team-balance rule for Kaiju Citybreakers. Every numerical value below is a **provisional project threshold** and the fun/fairness claims are **hypotheses**.

## Reuse decision

Use native `CollectionService` tags, attributes, raycasts, anchored collision proxies, `Humanoid:TakeDamage()`, and server-to-client remote events. Do not adopt Roblox's complete weapons kit: it demonstrates supported effect patterns, but its player-weapon framework, camera/input assumptions, and configuration tree are larger than four stationary automated attacks require.

The four user-selected Creator Store models are retained only as sanitized visual shells. All imported scripts, remotes, sounds, effects, movers, values, and seat behaviour were removed before any Play run. Gameplay is supplied exclusively by source-controlled strict Luau. Exact provenance and audit results are recorded in `assets/ASSET_REGISTER.md`.

## Authoring contract

A capturable turret is a `Model` tagged `CapturableTurret` with:

- a unique `TurretId` string;
- a supported `TurretArchetype` string;
- an anchored descendant `Muzzle` part;
- an optional anchored descendant `CaptureZone` presentation part;
- positive `CaptureRadius` and `CaptureSeconds` attributes;
- replicated server-owned state attributes from `TurretContract`.

The map chooses identity, archetype, placement, muzzle, and capture geometry. Source-controlled definitions choose bounded attack behaviour. A malformed, duplicate, unsupported, or over-budget turret is rejected without stopping the server.

Each turret also owns a source-controlled `AimAssembly` with an `AimOrigin`, yaw turntable, one or more archetype-specific barrels, and a muzzle. The server replicates only its validated target position and targeting state at the bounded perception cadence. Each client eases the anchored cosmetic assembly toward that position; client motion never chooses a victim, changes damage, or changes the server ray/projectile. The complete assembly remains visible and editable before Play.

## State machine

```text
Neutral --one role present--> Capturing --uninterrupted hold--> Owned
Owned --opposing role present--> Capturing --uninterrupted hold--> Owned by opponent
any capturable state --both roles present--> Contested
```

- Only living player characters count.
- Capture uses horizontal distance plus a bounded vertical distance so players cannot capture through a mountain, roof, or floor.
- `Contested` pauses progress and disables firing.
- Leaving an incomplete capture currently resets that attempt. This is a hypothesis chosen for a legible first test, not a genre standard.
- Ownership persists until an opposing capture completes or the round resets.
- The capture zone communicates neutral, capturing, contested, and owning-team state through both colour and replicated attributes. A later accessible UI pass must not rely on colour alone.

## Targeting and fairness contract

- Only an owned, uncontested turret may acquire or fire.
- The server selects the nearest living visible opposing player inside the archetype range.
- The server raycasts from the authored muzzle and rejects targets obstructed by world geometry.
- A target change starts a visible lock/wind-up before the first shot. Loss of eligibility, range, or line of sight cancels the lock.
- A turret never accepts a target, hit, damage amount, capture result, or projectile position from a client.
- Target lock time, nearest-target priority, and the absence of friendly fire are provisional rules. Test whether the giant kaiju is unfairly focused and whether human cover creates real counterplay.

## Distinct attack profiles

All profiles share acquisition and team rules, but they must not collapse into one recoloured tracer.

| Archetype | Authoritative hit model | Required presentation | Intended counterplay |
| --- | --- | --- | --- |
| Machine gun | Single server raycast at a moderate cadence | short, medium-width tracer and small impact flash | break line of sight between shots |
| Minigun | Single server raycasts after a longer spin-up, at a rapid bounded cadence | thin rapid tracers and persistent spin-up cue | react during spin-up; use cover |
| Cannon | Fast server-simulated shell with swept segment raycasts and a small impact radius | visible travelling shell, trail, heavy impact ring | move after the firing cue |
| Rocket | Slow server-simulated missile with swept segment raycasts and a larger radial impact | clearly visible missile body, longer trail, warning colour, explosion ring | dodge the travelling missile or use solid cover |

The server owns logical projectile position, collision, lifetime, team filtering, radial damage, and active count. Clients interpolate bounded pooled visuals from launch data and render impact effects from server results. Cosmetic parts are anchored, non-colliding, non-queryable, and do not create damage or physical blast pressure.

## Initial budgets

These are provisional, not Roblox benchmarks:

| Budget | Initial ceiling |
| --- | ---: |
| Registered turrets | `12` |
| Capture/target perception | `5 Hz` |
| Logical projectile simulation | `20 Hz` while projectiles exist |
| Simultaneous logical cannon/missile projectiles | `16` |
| Logical projectile lifetime | `4 seconds` maximum |
| Client projectile/tracer pool | fixed cap; no unbounded creation |
| Unanchored imported turret parts | `0` |
| Imported executable scripts/remotes | `0` |

## Placement guidance

- First expose one neutral turret in a broad open route with nearby hard cover and no simultaneous enemy introduction.
- Keep the capture circle and muzzle visible from both human and kaiju camera heights.
- Do not place the first lethal rocket at a spawn exit or in an unavoidable corridor.
- Use turret silhouettes and effect language consistently; placement may change sightlines but not make a missile look like a bullet.
- Capture objectives should create a route choice or local advantage, not become mandatory busywork for solo completion.

## Required tests before map-wide rollout

1. Static source build proves all four imported shells contain zero scripts, remotes, sounds, movers, and unanchored parts.
2. One-player Studio test captures a neutral turret, leaves and re-enters an incomplete capture, and verifies replicated states.
3. Native two-client test verifies contested pause, ownership transfer, no friendly fire, server-selected targets, obstruction, death, respawn, and capture by both scales.
4. Archetype test proves bullets are instant, minigun cadence/spin-up is distinguishable, cannon shells travel, rockets travel and apply bounded radial damage, and solid cover blocks each attack as specified.
5. Physical-phone test records whether an uncoached player identifies ownership, notices the firing cue, names the projectile type, and dodges at least one cannon or rocket.
6. Representative-device profile records client/server frame time, memory trend, active logical projectiles, raycasts per second, effect-pool cap, and cleanup after a four-turret stress exchange.

Do not duplicate turrets across the city until these tests pass. Failed readability should change cues and placement before damage is increased.
