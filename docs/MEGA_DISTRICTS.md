# Mega-district blockout

This blockout turns the current city strip into a free-roam kaiju test map with five visually distinct zones. It remains primitive, source-controlled, free-only, and cheap to revise before original Blender art replaces the accepted silhouettes.

## Evidence boundary

Roblox's current guidance recommends greybox playtesting before art production, instance streaming for large worlds, spatially coherent models, anchored static scenery, simple collision, built-in material reuse, and client-local transient effects. Server raycasts and shape casts can use `RaycastParams` collision groups to consider only authorized target parts. These platform facts guide the implementation; the exact scale, density, routes, Beam radius, and landmark choices below are project hypotheses that still require physical-device and uncoached-player evidence.

Sources:

- [Raycasting](https://create.roblox.com/docs/workspace/raycasting)
- [WorldRoot shape casts](https://create.roblox.com/docs/reference/engine/classes/WorldRoot)
- [Instance streaming](https://create.roblox.com/docs/workspace/streaming)
- [Streaming techniques](https://create.roblox.com/docs/workspace/streaming/techniques)
- [Design for performance](https://create.roblox.com/docs/performance-optimization/design)
- [Improve performance](https://create.roblox.com/docs/performance-optimization/improve)

## World and movement metrics

| Metric | Contract |
| --- | ---: |
| World foundation | `1400 × 1100` studs, about `8.1×` the previous `500 × 380` area |
| Brontide extents | approximately `15.6 × 24.7 × 28.1` studs |
| Required roads and zone entries | at least `40` studs clear |
| Walk speed | `24` studs/second |
| Charge travel | approximately `48` studs |
| Camera arm | `24–42` studs |
| Destructible target | at least `28` unique structures, all authored building silhouettes smashable |
| World-part soft ceiling | `1000` `BasePart` instances before representative-device profiling |
| New dynamic lights | `0`; landmarks use emissive material within the existing light budget |

## Zone graph

```text
                         MOUNT BRONTIDE
                         ridge + overlook
                                |
TITAN PARK -------- CENTRAL CITY + -------- ARC POWER PLANT
open lawns            spawn / gate          industrial yard
      |                    |
      +---------- AZURE LAKE ---------- south ring road
                 shoreline + marina
```

- **Central City:** dense, vertical destruction playground and the shortest route to the existing gate objective.
- **Titan Park:** low-density rest/combat space with broad lawns, tree lines, a civic monument, and multiple camera-safe routes.
- **Arc Power Plant:** high-tension industrial zone, readable through charcoal ground, cyan energy channels, cooling towers, and smashable plant buildings.
- **Mount Brontide:** non-building terrain landmark and overlook with a wide approach; its observatory and ranger station remain smashable.
- **Azure Lake:** broad blue water landmark, pale shoreline, island, boardwalk, and smashable marina/waterworks buildings.

Every zone connects back to the central road graph without a jump, one-way drop, or ability gate. Roads and large color/material fields provide leading lines; zone labels are short-range orientation aids rather than mission logic.

## Beam correction contract

- Input produces a short client-local muzzle cue immediately.
- The server continues to own cooldown, round state, character validation, target selection, and damage.
- Keyboard/mouse uses the pointer ray; touch and gamepad use the camera-centre ray. One exponentially smoothed direction drives both the local head pose and the request, creating approximately `0.18` seconds of readable aim lag.
- Brontide's head is limited to a `38°` yaw and `24°` pitch turn. The muzzle cue and confirmed beam begin at the mouth, not the torso.
- A bounded sphere cast follows the server-validated aim direction and queries only `DestructibleQuery` hitboxes. The server rejects malformed, non-finite, near-vertical, and more-than-`75°` backward-divergent aim before using a safe facing fallback.
- The nine-stud radius must forgive small cursor, animation, and building-height differences without hitting through an entire street.
- The server returns only confirmed origin, endpoint, and hit count.
- The client renders a thicker `0.45` second beam, muzzle flash, and a distinct hit/miss endpoint. Cosmetic parts remain non-colliding, non-queryable, and automatically cleaned up.

## Validation gates

- Beam visibly fires on touch, keyboard, and gamepad requests; from a normal ground pose it damages both a low building and a tall tower while still missing a deliberately off-axis target.
- All authored buildings register unique destruction contracts and change `Intact → Damaged → Collapsed` through the normal server path.
- Each named zone is recognizable in overhead and player-scale captures without reading its label.
- The complete road graph is traversable, retains camera clearance, and has no fall-through edges.
- Instance counts, anchored state, light count, runtime errors, mobile control geometry, and representative-device performance are recorded. Studio evidence cannot replace the final physical-device frame-time, memory, comfort, and comprehension test.

## Working-tree audit

The final iPhone 16 Studio run registered `33` unique valid destructibles, `962` generated-world `BasePart` instances, `0` invalid contracts, `0` unanchored world parts, and the existing `10` lights. The structural and provisional part-count gates pass; the one-part visual head pivot belongs to Brontide's character rather than the generated world.

The authoritative Beam path damaged both the low Titan Park pavilion and a tall Central City tower, while a deliberately off-axis tower remained intact. The actual generated iPhone Beam button also collapsed the park conservatory through the normal action, remote, cooldown, server cast, and destruction path. Player-scale captures distinguished all five zones.

After a touch camera drag produced a raw `-76°` camera-relative yaw, the final dedicated `HeadAimMotor` held a visible `-38.05°` joint offset, matching its authored limit after the native animation pass. Exact-build engineering gates pass; physical-device performance, comfort, and comprehension remain human validation gates.
