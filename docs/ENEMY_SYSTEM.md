# Enemy-system plan

Enemies should make the kaiju fantasy clearer, not turn the game into a crowded humanoid simulator. The original plan began with one readable scout drone. The owner-requested four-turret feasibility slice now runs first because candidate placements already exist; this is a bounded scheduling exception, not permission to populate the map before the turret and later drone pass their own mobile readability and server-cost gates.

## Evidence boundary

Roblox provides native path creation, waypoint traversal, material and region costs, blocked-path handling, and streaming guidance through `PathfindingService` and `PathfindingModifier`. Roblox also recommends avoiding large numbers of server-animated Humanoids, measuring with its profilers, and validating combat intent and outcomes at the client/server boundary. Those are platform facts. The exact enemy counts, reaction times, projectile speeds, and encounter composition below remain project hypotheses.

Primary sources:

- [Pathfinding](https://create.roblox.com/docs/characters/pathfinding)
- [`PathfindingService`](https://create.roblox.com/docs/reference/engine/classes/PathfindingService)
- [`Motor6D`](https://create.roblox.com/docs/reference/engine/classes/Motor6D)
- [PathfindingModifier](https://create.roblox.com/docs/reference/engine/classes/PathfindingModifier)
- [Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- [Securing the client/server boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary)
- [Server authority model](https://create.roblox.com/docs/projects/server-authority)

## Reuse decisions

- Use native `PathfindingService` for ground defenders; do not write a custom navmesh or A* implementation.
- Use authored aerial patrol nodes, line-of-sight raycasts, and bounded steering for scout drones; a flying drone does not benefit from ground navigation.
- Use one shared server enemy state machine and damage/team contract across drones, turrets, and the boss.
- Reuse the existing client-local effect and fixed-budget pooling patterns for projectiles, impacts, and defeat fragments.
- Use simple assemblies or animation-light controllers for crowds; do not multiply full Humanoids without profiler evidence.
- Reuse the turret projectile resolver only where the hit model matches. Bullet rays, cannon shells, and missiles remain distinct profiles rather than one generic visual recolour; see [TURRET_SYSTEM.md](TURRET_SYSTEM.md).

## First rogue-kaiju integration slice

The first target is one smaller original `Riftback` rogue kaiju so the capturable turrets have a non-player opponent. The map owner controls its visible template and spawn marker in Edit mode. The server clones the reviewed template, strips executable descendants and authoring helpers, exposes health/state attributes, accepts authoritative turret damage, and owns every decision and hit. The actual proxy limbs, head and tail are connected by native `Motor6D` joints; a client controller poses those joints for locomotion, wind-up, stagger and enrage without affecting outcomes.

The bounded decision loop runs at `5 Hz` and uses this observable state flow:

```text
Patrol --vision/hearing--> Chase --in range--> Swipe or Lunge
Chase --loses target--> Investigate last-known position --memory expires--> Patrol
any living state --damage threshold--> Staggered --> previous decision loop
health below threshold --> Enraged (faster movement and recovery)
health reaches zero --> Defeated
```

- Vision requires a wide forward field of view plus server line of sight; nearby movement can be heard even outside that cone.
- Target scores use distance and a current-target hysteresis margin so the actor does not rapidly switch between equally good targets.
- It remembers the last seen/heard position briefly and investigates it instead of becoming instantly idle.
- Native paths are recomputed only after the target moves materially, a forward waypoint is blocked, the actor is sampled as stuck, or the normal throttle expires.
- A close target receives a readable swipe; a suitable farther target can trigger a longer lunge wind-up and bounded server movement. Both attacks revalidate range and obstruction at impact.
- Accumulated authoritative damage can stagger the actor. Low health enters an explicit enraged phase.

All ranges, angles, timings, target weights, attack choices and enrage/stagger thresholds are provisional. The checked-in creature remains deliberately labelled as a replaceable original proxy, not final art. A Creator Store or user-imported model may replace it only after the commercial licence, underlying-IP, script, provenance, and mobile geometry gates pass. The inspected `Mire Godzilla` candidate was removed because a free listing cannot grant rights to protected fan IP.

## Later scout-drone slice

The drone patrols a short authored loop, acquires the nearest living kaiju inside a bounded radius, turns visibly, shows a clear wind-up, fires one slow projectile, recovers, and returns to patrol when the target is lost. The server owns acquisition, cadence, projectile collision, damage, defeat, and rewards. Clients may immediately show non-authoritative wind-up, trail, impact, and sound feedback.

Provisional first-test limits:

| Budget | Initial contract |
| --- | ---: |
| Simultaneously active scout drones | `4` solo, `6` with two players |
| Server perception checks | no faster than `5 Hz` per drone |
| Projectile lifetime | at most `4` seconds |
| Attack telegraph | at least `0.65` seconds |
| Unpooled defeat fragments | `0` |
| Required attacks | patrol, telegraphed shot, stagger, defeat |

These values are not Roblox benchmarks. Change them from profiler and playtest evidence.

## District roles

- **Central City:** tutorial drone sightline and open dodge lane.
- **Titan Park:** wide patrol arcs and room to learn projectile avoidance.
- **Arc Power Plant:** later turret introduction and energy objective.
- **Mount Brontide:** later ground defender route test using slopes and cost modifiers.
- **Azure Lake:** later aerial encounter over shoreline; no underwater navigation in the slice.

## Gates before map-wide population

- A first-time player notices the wind-up, understands the source of damage, and dodges at least one shot without verbal coaching.
- Solo and two-player target selection is stable; enemies never damage allies or defeated targets.
- A player can distinguish patrol, investigation, swipe, lunge, stagger and enrage without reading developer attributes; target selection does not visibly thrash.
- Server validation rejects malformed attack or reward requests and clients cannot nominate an arbitrary victim.
- Four drones plus simultaneous building collapse stay within measured server/client frame and memory budgets on the representative mobile baseline.
- Streaming, destruction state changes, and route blockers do not trap or permanently idle ground defenders.
- Defeating drones supports the break/absorb/mutate loop; it does not become a disconnected score activity.
