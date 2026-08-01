# Playtest log

Automated Studio runs validate integration and instrumentation; they do not count as human playtest evidence. Human sessions record age band only when freely volunteered and necessary, never names, account IDs, or chat.

## 2026-08-01 — Kaiju Feel Lab integration

- Build commit: `3583660`
- Environment: Roblox Studio desktop, macOS, one local client and server.
- Operator: Studio MCP synthetic navigation and input; **zero human testers**.
- Systems: generated greybox, scaled R15 placeholder, camera, round state, charge, server-authoritative smash, three-state wall, local debris, H1 timestamps.

### Run A — first vertical path

- Character scale reported `4` and wall began `Intact` with health `2`.
- Synthetic navigation approached the target; two `E` inputs changed the wall to `Collapsed`, health `0`.
- Instrumentation: first hit `39.59s`; first collapse `40.66s`.
- No runtime errors appeared in server or client output.
- Issue found: the template baseplate spawn competed with the lab spawn.

### Run B — charge path after corrections

- Disabled the template spawn and removed the overlapping runtime baseplate.
- Replaced a one-frame velocity assignment with a short native `LinearVelocity` constraint because the Humanoid controller immediately neutralized the former.
- Spawn position was near the intended `z=38` start.
- First charge moved the root from approximately `z=32.20` to `z=11.50`; the constraint self-removed after its `0.45s` budget.
- A second charge followed by two validated smash inputs collapsed the wall.
- Instrumentation: first hit `32.76s`; first collapse `33.69s`.
- No runtime errors appeared in server or client output.

### Decision

The engineering path passes: the full action-to-server-to-destruction-to-client-effect loop works. H1 does **not** pass yet because synthetic input cannot establish usability or enjoyment. The next evidence step is an uncoached human test measuring time to first collapse, confusion points, control comprehension, and voluntary replay.

## 2026-08-01 — Brontide city readability integration

- Build commit: `98ab84f`
- Environment: Roblox Studio desktop, macOS, one local client and server.
- Operator: Studio MCP inspection, navigation, and direct client ability requests; **zero human testers**.
- Systems: original primitive Brontide shell, late-loading avatar concealment, low-poly city dressing, existing charge/smash/destruction loop.

### Results

- Brontide spawned with `32` visible shell parts and `0` visible avatar parts, including after the character appearance load path.
- The generated city contained `197` descendants; the gate began `Intact` with health `2`.
- Two client ability requests passed the real server validation and hitbox path, changing the gate to `Collapsed` with health `0`.
- Charge moved the root from approximately `(0.58, 12.53, -7.26)` to `(-9.70, 16.38, -25.20)` while facing the gate.
- No runtime errors appeared in server or client output.
- Studio's synthetic keyboard tool did not activate the `ContextActionService` bindings in this session, despite reporting success. This is a test-harness limitation; keyboard, touch, and gamepad input still require the planned human test.

### Decision

The visual integration and existing server-authoritative loop pass automated regression. The ten-second kaiju/city recognition target remains unproven until an uncoached player sees the build. Do not treat primitive detail or synthetic traversal as evidence of art appeal, control comprehension, or fun.

## 2026-08-01 — Cross-device input integration

- Build commit: `2080617`
- Environment: Roblox Studio desktop, macOS, one local client and server.
- Operator: Studio MCP binding inspection and synthetic gamepad input; **zero human testers**.
- Systems: shared action bindings, gamepad triggers, generated touch actions, preferred-input prompts, and safe-area HUD.

### Results

- The live charge action exposed `Q`, left Shift, left trigger, and `B`; the smash action exposed mouse click, `E`, and right trigger.
- Both actions reported `createTouchButton = true` with the expected `CHARGE` and `SMASH` labels and descriptions.
- A synthetic left-trigger press moved Brontide approximately `20` studs through the real validated charge path.
- After navigation into range, two synthetic right-trigger presses changed the gate from `Intact` to `Collapsed` through the real server hitbox and destruction path.
- The HUD reported `CoreUISafeInsets`, clipping to the device safe area, and the keyboard/mouse prompt for the desktop session.
- No runtime errors appeared in server or client output.

### Unverified

The desktop Studio session reported no touch hardware, so button appearance, thumb reach, camera drag coexistence, and touch prompt switching were not physically tested. These require Studio phone/tablet emulation and then at least one representative touchscreen device. A controller user must also verify comfort and glyph comprehension; synthetic input proves routing, not usability.

## 2026-08-01 — Cursor-facing desktop movement integration

- Build commit: `78604c2`
- Environment: Roblox Studio desktop, macOS, one local client and server.
- Operator: Studio MCP synthetic mouse, held keyboard movement, and gamepad attack input; **zero human testers**.
- Systems: cursor-to-world raycasting, yaw-only character facing, camera-relative movement, preferred-input auto-rotation, and the existing authoritative smash path.

### Results

- Keyboard/mouse mode reported `Humanoid.AutoRotate = false` and loaded the new `AimController` without runtime errors.
- Moving the cursor to the right changed the root look vector to approximately `(0.93, 0, -0.38)`; moving it left changed the vector to approximately `(-0.94, 0, -0.35)`. Root position remained fixed during both observations.
- Holding `W` for about `1.5` seconds moved Brontide approximately `37` studs camera-forward while the creature continued facing diagonally toward the right-side cursor, confirming that movement and facing are independent.
- From attack range, two synthetic right-trigger smashes followed the real remote, server hitbox, and destruction path, changing the gate from `Intact` with health `2` to `Collapsed` with health `0`.

### Unverified

Studio's mouse-click automation intersected CoreGui rather than the game viewport, so the click binding itself was not re-proven in this run. The cursor-facing behaviour, independent movement, and downstream authoritative attack direction passed; natural mouse feel and preferred-input transitions still require a human desktop playtest. Gamepad and touch retain native auto-facing by code and still require the representative-device checks recorded above.

## 2026-08-01 — Behind-kaiju mouse camera integration

- Build commit: `7431b64`
- Environment: Roblox Studio desktop, macOS, one local client and server.
- Operator: Studio MCP synthetic relative mouse movement, wheel input, obstruction probe, keyboard movement, and gamepad attack input; **zero human testers**.
- Systems: locked-center mouse input, scriptable orbit camera, camera-forward creature facing, zoom, camera collision, and the existing authoritative smash path.

### Results

- Desktop mode reported a `Scriptable` camera, `LockCenter` mouse behaviour, hidden cursor, and `Humanoid.AutoRotate = false`.
- Repeated rightward mouse movement rotated the camera and Brontide from straight ahead to a horizontal direction of approximately `(-0.67, 0, -0.74)`. Their normalized horizontal look vectors maintained a dot product of exactly `1`, confirming that the creature's back remained toward the camera.
- Two wheel-up inputs reduced the camera arm from `42` to `36` studs.
- A temporary client-only obstruction placed behind Brontide shortened the visible camera arm from the configured `36` studs to approximately `9.25` studs, confirming that the collision ray prevents wall clipping. The probe was destroyed immediately after measurement.
- From attack range, two synthetic right-trigger smashes followed the real remote, server hitbox, and destruction path, changing the gate from `Intact` with health `2` to `Collapsed` with health `0`.
- No gameplay runtime errors appeared in client or server output.

### Unverified

Synthetic pointer movement proves camera routing and alignment, not comfort. A human desktop player must still judge sensitivity, pitch limits, zoom range, motion comfort, and whether locked-center smash clicking feels natural. Studio's automation cannot send Escape because Roblox reserves it for CoreGui, so the coded menu-open cursor release also needs a manual check. Gamepad and touchscreen keep Roblox's native camera/facing path and retain the representative-device checks recorded above.

## 2026-08-01 — Responsive iPad action controls

- Build commit: `8a11eb3`
- Environment: Roblox Studio device simulator, one local client and server.
- Operator: Studio MCP device configuration, runtime rectangle inspection, and screenshots; **zero human testers**.
- Systems: ContextActionService touch buttons, resolution-aware sizing, orientation reflow, native Jump avoidance, and screen-bound checks.

### Reproduction

- On iPad A16 landscape (`1179×819` runtime viewport), the former 96 px `CHARGE` rectangle ended at x=`951` while `SMASH` began at x=`948`, producing a three-pixel overlap.
- After separating the pair, both still intersected the lower edge of Roblox's native 120 px Jump button because that control is created later than `ContextActionGui`.

### Results

- iPad A16 landscape (`1179×819`): 95×95 px action targets, 15 px gaps, no action/action or action/Jump overlap, and both rectangles fully inside the viewport.
- iPad A16 portrait (`819×1179`): 96×96 px targets stacked left of Jump, 15 px horizontal and vertical separation, no overlaps, and both rectangles fully inside the viewport even though their positions extend beyond the narrower action frame.
- iPad 6th Generation landscape (`1023×768`): 89×89 px targets, 14 px gaps, no action/action or action/Jump overlap, and both rectangles fully inside the viewport.
- Screenshots confirmed circular outlines, readable labels, and clear separation from the native movement and Jump controls.
- No runtime errors appeared in client or server output.

### Unverified

Simulator geometry validates layout but not thumb comfort. A person using a physical iPad should still judge reach, accidental presses, camera-drag coexistence, and whether the vertical action order feels natural. Studio was reset to its default desktop viewport after testing.

## 2026-08-01 — Touch charge legibility regression

- Build commit: `00808ff`
- Environment: Roblox Studio iPad A16 landscape simulation, one local client and server.
- Operator: Studio MCP touch-button input, remote-result instrumentation, transform measurement, and cosmetic-event observation; **zero human testers**.
- Systems: touch charge binding, server-authoritative LinearVelocity, charge tuning, cooldown UI, FOV feedback, particles, and highlight.

### Reproduction

- The original touch button sent a valid charge request and received `accepted = true`, so input routing was not broken.
- It moved Brontide approximately `20.7` studs, matching the former 44 studs/second × 0.45 second budget. At four-times character scale with a distant camera, this read too similarly to ordinary movement.
- Repeated taps during the 2.5-second cooldown were silently ignored by the local cooldown guard.

### Results

- The updated touch charge received `accepted = true` and moved the root from approximately z=`73.82` to z=`23.89`: `49.93` studs through the real server constraint path.
- Client observation recorded both `ChargeEnergyBurst` and `ChargeEnergyHighlight` being created after acceptance.
- Camera FieldOfView peaked at `75`, an 8-degree kick from the configured resting value of `67`, then returned to rest.
- The touch title progressed from `2.5` through `0.1` while the button was dimmed, then restored `CHARGE` and full opacity at cooldown completion.
- No gameplay runtime errors appeared in client or server output.

### Unverified

The engineering and feedback paths pass, but a physical-device player must confirm that the revised distance, effect strength, cooldown communication, and repeat-use rhythm feel satisfying rather than excessive. Studio was reset to its default desktop viewport after testing.

## 2026-08-01 — Reusable destruction contract integration

- Build commit: `6704fbc`
- Environment: Roblox Studio desktop, macOS, one local client and server.
- Operator: Studio MCP contract inspection and direct client ability requests; **zero human testers**.
- Systems: tagged structure validation, atomic streaming, state sequencing, dedicated damage queries, collision proxies, client-local variants, and collapse debris.

### Results

- The feel-lab gate registered as exactly one valid destructible with health `2`, state `Intact`, sequence `0`, and atomic model streaming.
- Every visual part had collision, touch, and query disabled. The dedicated `DamageHitbox` was queryable in `DestructibleQuery`; `KaijuAttackQuery` collided with that group and not `Default`.
- Two basic attacks followed the real client remote, server cooldown, bounded hitbox, and authoritative damage path. The server ended at health `0`, state `Collapsed`, sequence `2`.
- Authoritative collision changed from the intact proxy to the collapsed proxy. The client showed `7` collapsed-variant parts and hid every intact and damaged part.
- The collapse event emitted exactly `10` non-colliding client-local debris fragments.
- Instrumentation recorded first hit at `26.70s` and first collapse at `28.06s`; no gameplay runtime errors appeared in client or server output.

### Unverified

This one-client regression does not prove late-join or stream-out/stream-in reconciliation. Those require a two-client streaming test before the city contains enough destructible structures for ordering failures to become difficult to isolate. Performance budgets also need re-measurement after the first representative warehouse, tower, and utility structure set is added.

## 2026-08-01 — Bounded client debris integration

- Build commit: `d21eaae`
- Environment: Roblox Studio desktop, macOS, one local client and server.
- Operator: Studio MCP synthetic stress, lifecycle inspection, microbenchmark, and direct client ability requests; **zero human testers**.
- Systems: prewarmed fixed-cap fragment pool, oldest-active overflow, generation-safe delayed release, material profiles, authoritative collapse, and effect cleanup.

### Results

- A 200-spawn overlapping stress run created exactly `100` parts, peaked at `100` active, recycled `100`, then settled to `0` active and `100` available. Pool destruction left zero test parts in the world.
- The 200-request scheduling block took approximately `3.71 ms` in this Studio session. This is an editor observation, not a target-device frame-time result.
- Across 50 ten-fragment trials, the prewarmed path averaged approximately `0.101 ms`; fresh part creation plus native timed cleanup averaged `0.113 ms`. The observed hot-path reduction was `10.8%` in this session.
- A one-slot adversarial test immediately recycled a part, then allowed the old timer to fire. The newer generation remained active and parented until its own lifetime expired.
- Two real basic attacks left the server gate at health `0`, state `Collapsed`, sequence `2`, with the collapsed collision proxy active.
- The client displayed exactly `10` concrete fragments. Every fragment had collision, touch, query, and shadows disabled; all were unparented after the configured five-second lifetime.
- No gameplay runtime errors appeared in client or server output.

### Decision

Retain the pool because it reduces the representative collapse hot path in this Studio test and, more importantly, makes allocation, active count, overflow, and cleanup explicitly bounded. Do not generalize the microbenchmark to physical mobile performance. Dust particles remain deferred until the Phase 2C archetype scene can be profiled for draw calls and frame time on a representative lower-end device.

## 2026-08-01 — Destructible city archetype integration

- Build commit: `ff95af4`
- Environment: Roblox Studio iPad A16 landscape simulation, one local client and server.
- Operator: Studio MCP inspection, direct client ability requests, and synthetic navigation; **zero human testers**.
- Systems: reusable structure builder, warehouse, signal tower, substation, authored state variants, simple collision proxies, material profiles, and existing server-authoritative combat.

### Results

- Exactly four destructibles registered with unique IDs and atomic streaming: the existing gate plus `north_warehouse`, `north_tower`, and `harbour_substation`.
- The full world changed from the pre-Phase-2C baseline of `203` descendants, `160` `BasePart` instances, and `26` models to `274`, `213`, and `41` respectively. The corresponding SceneAnalysis capture changed from `845` to `916` total instances and from `241` to `309` 3D objects. The triangle/render-pass query returned no valid pass data in this view, so no render-cost claim is made.
- The warehouse, tower, and substation used `28`, `31`, and `27` authored `BasePart` instances respectively, below the provisional ceiling of `35`. All decorative parts were anchored and excluded from collision, touch, and queries.
- Each structure began `Intact` at its configured health. Client ability requests passed the real remote, cooldown, spatial hitbox, and authoritative damage path; one request immediately after a synthetic relocation missed spatially and a normal retry landed. The structures ended at health `0`, state `Collapsed`, and sequence `2` after `3`, `4`, and `3` landed hits.
- Client and server state agreed. Only the collapsed variant was visible; the intact proxy was disabled, the low collapsed proxy was enabled, and the dedicated damage hitbox remained queryable in `DestructibleQuery`.
- Synthetic navigation crossed the collapsed substation from west to east and ended near `(83.2, 12.0, -68.7)` with health `1000` and concrete floor contact.
- No gameplay warnings or runtime errors appeared in client or server output.

### Decision

Retain the builder and all three footprints for the next test slice. They meet the automated contract, budget, authority, and traversal gates without increasing the world bounds or adding an external asset or dependency. Before multiplying them into the mixed district, run a two-client state/late-stream regression. Human target choice, silhouette readability, route comprehension, and representative-device frame and memory cost remain unproven.

## 2026-08-01 — Destruction late-join reconstruction

- Build commit: `eeaf523`
- Environment: Roblox Studio native multiplayer test, one server process, one initial client, then one late client.
- Operator: `StudioTestService` automated orchestration and client observations; **zero human testers**.
- Systems: normal round activation, server-positioned attack setup, client ability requests, authoritative warehouse destruction, replicated attributes, local variant selection, collision proxies, and collapse debris.

### Discovery

The first working-tree run added the second client successfully, but the client did not report within an assumed `350 ms` after joining. The model and its `CollectionService` tag had not necessarily streamed by that deadline. The harness was corrected to wait for the tagged atomic model and its collapsed attributes with bounded 15-second timeouts, matching the production streaming contract rather than assuming instant replication.

### Exact-commit results

- The initial client issued three cooldown-respecting requests through the normal ability remote and spatial hitbox path.
- Server state ended at health `0`, `Collapsed`, sequence `2`; the intact proxy was disabled, collapsed proxy enabled, and damage hitbox remained queryable.
- Both clients independently reported health `0`, `Collapsed`, sequence `2`, no intact or damaged visual parts, and a visible collapsed variant.
- The initial client observed exactly `10` active collapse fragments. The client added after collapse observed `0`, confirming that durable state reconstructed without replaying the historical cosmetic event.
- The harness returned `{ passed = true, players = 2, structureId = "north_warehouse" }` and ended both clients automatically.
- A separate ordinary one-client Play session created no test remote, left the warehouse at its normal health `3`/`Intact` state, and produced no gameplay warnings or runtime errors.

### Decision

The Phase 2 late-join state gate passes for one representative destructible. The corrected bounded wait becomes the regression contract for streamed client observations. District multiplication may proceed, but the later twenty-collapse sequence, stream-out/stream-in movement test, representative-device profiling, and human readability test remain open.
