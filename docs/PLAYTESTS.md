# Playtest log

Automated Studio runs validate integration and instrumentation; they do not count as human playtest evidence. Human sessions record age band only when freely volunteered and necessary, never names, account IDs, or chat.

## 2026-08-02 — Dormant factory, asymmetric turrets, sustained Beam, and vehicle-AI smoke

- Static gate: repository standards, StyLua, Selene, parse validation, Rojo build, and `git diff --check` passed with zero errors or warnings.
- A single freshly restarted Studio process loaded the rebuilt `build/KaijuCitybreakers.rbxlx`; server and client reached `Active`, registered four turrets, spawned the bounded rogue kaiju, and emitted no gameplay-script runtime error.
- An earlier in-memory run was rejected as evidence: Studio reused an already-open place containing three saved runtime vehicle proxies. Startup now deletes a stale `RuntimeReinforcements` folder and resets `SpawnSequence` before registration, preventing an Edit-time artifact from impersonating neutral production.
- After several active minutes the neutral factory still reported `Operational`, spawn sequence `0`, and zero runtime vehicles. A stable server-side human hold then changed it to `Human/Captured` and produced exactly one first vehicle.
- A human hold captured a neutral turret as `Human/Owned`; the same-duration kaiju hold left another turret `Neutral`, with progress `0`.
- One normal client-to-server Beam request kept exactly two reusable local beam segments active, ran for the configured four-second session, and changed the selected turret from `300/Neutral` to `0/Destroyed`.
- The captured factory reached its bounded `2` tank/`1` helicopter cap. When a hostile kaiju was placed at a visible 95-stud test position, a tank entered `Engaging`, replicated a stable `player:` target ID and aim point, fired twice, and applied `180` total damage through normal projectiles.
- The desktop reticle measured `0.555` of viewport width and `0.500` of viewport height after the GUI-inset correction.

This is an engineering smoke, not a human gameplay result. Physical-device and two-player tests must still judge capture readability, Beam steering/comfort, turret destruction feedback, vehicle fairness, and fun after publication.

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

## 2026-08-01 — West park/plaza layout integration

- Build commit: `ea02de3`
- Environment: Roblox Studio iPad A16 landscape simulation, one local client and server.
- Operator: Studio MCP inspection, synthetic navigation, direct client ability requests, camera-clearance probes, SceneAnalysis, and screenshots; **zero human testers**.
- Systems: expanded foundation/crossing, repositioned market shells, park/plaza primitive kit, north connector, district cordons, existing camera, and authoritative gate destruction.

### Results

- The world changed from `274` to `323` descendants, `213` to `251` parts, and `41` to `52` models. Lights remained at `10`. SceneAnalysis changed from `921` to `970` total instances and `309` to `358` 3D objects.
- The `88 × 52` stud plaza and `36` stud warehouse-side turn met their provisional metrics. All decorative geometry was anchored with collision, touch, query, and shadows disabled.
- Synthetic navigation completed crossing → plaza → north connector → spawn and the complete reverse route without jumping or losing health.
- From the plaza centre, all eight radial probes were clear at both 24 and 42 studs, the configured camera-distance range.
- Overhead and player-scale captures showed an open paved centre, green perimeter, trees, entry signals, and west amber/cyan landmark. Four initial parallel paving strips read like parking bays and were replaced with three concentric civic rings before the exact-commit run.
- An explicit working-tree probe found that the old map allowed Brontide to walk around the west gate tower at `x=-90` while the gate remained intact. Two joined district cordons closed both foundation-edge routes. The exact commit stopped the same probe near `z=-23.3` with the gate intact.
- Two normal client attack requests then passed cooldown, spatial hitbox, and server-authoritative damage validation. The gate ended health `0`, `Collapsed`, sequence `2`, and Brontide traversed the central opening to approximately `z=-58.8`.
- The final triangle/draw query returned zero passes and is recorded as unavailable, not as a zero-cost result. No gameplay warnings or runtime errors appeared.

### Decision

Retain the park/plaza, market positions, north loop, and gate cordons. The layout passes automated route, objective-integrity, physics, camera-clearance, and instance-budget gates. Do not add the dense avenue yet until an uncoached player tests branch recognition, route return, perceived scale, and whether the plaza is an enjoyable combat space. Representative-device frame time and memory also remain open.

## 2026-08-01 — Production artifact publishing regression

- Build commit: `9ccbd01`
- Reported environment: physical iPad, one production client; one observed player report.
- Reproduction environment: isolated Rojo-built `.rbxlx` in Roblox Studio, macOS, one local client and server.
- Systems: production publishing boundary, server/client bootstrap, generated world, Brontide character, and HUD.

### Incident

Studio reported production version 6 successfully published from the live Rojo-synced editing session. A fresh iPad session instead showed the template baseplate and default avatar with no city, Brontide shell, round HUD, or gameplay controls. Those simultaneous absences identify a missing production bootstrap rather than an individual world-builder or UI failure.

### Corrective verification

- `rojo build default.project.json` produced an isolated place artifact containing the server and client script trees.
- Playing that artifact printed the world, server, and client startup markers with no gameplay error.
- The server generated `KaijuFeelLab` with exactly `323` descendants and replaced the test player with a Brontide character model containing `371` descendants.
- The exact artifact was published to existing place `137103245194702` in universe `10609698937`; Studio entered `PublishSuccessful` and logged the destination IDs.

### Decision

Production releases now use the clean, exact-commit artifact workflow in `docs/RELEASE.md`, not direct publishing from a live-synced session. The corrective upload is complete, but the physical-iPad production smoke test remains pending until the reporter leaves the old server and joins a fresh one.

### Spawn-lifecycle follow-up

- Implementation commit: `61eaea0`
- Environment: isolated Rojo-built `.rbxlx`, Studio iPad A16 landscape simulation, one local client and server; **zero human testers**.
- Trigger: the next physical-iPad production report showed the player falling through the sky. The built artifact intentionally contains no authored Workspace spawn before the server generates the city, leaving automatic character loading vulnerable to join/bootstrap timing.
- `Players.CharacterAutoLoads` was disabled in both the built DataModel and the first server bootstrap statements. `KaijuService` now loads a character only after `PrototypeWorldService` creates `KaijuSpawn`, computes clearance from the scaled Brontide bounds, places the root over that spawn, and clears linear and angular velocity.
- The initial character settled at approximately `(0, 12.22, 69)` with near-zero velocity and `FloorMaterial = Asphalt`. An iPad-simulator capture showed Brontide, the city, HUD, and touch controls together.
- Two server-side deaths produced distinct replacement character instances after the configured respawn delay. The final replacement settled at approximately `(0, 12.22, 69)` with zero velocity and `FloorMaterial = Asphalt`.
- The world, server, and client bootstrap markers appeared without a gameplay error.

The artifact-level initial-spawn and respawn regressions pass. A fresh physical-iPad production server remains the required final smoke test after publishing this commit.

## 2026-08-01 — Live bootstrap failure and Studio-only boundary fix

- Implementation commit: `cdf9695`
- Reported environment: physical phone in landscape, one production client; one guided human report.
- Reproduction evidence: Creator Hub Error Report for production place `137103245194702`, published versions V6 and V8.
- Corrective environment: clean Rojo-built `.rbxlx`, Roblox Studio iPad A16 landscape emulation, one local client and server; **zero human testers**.

### Incident evidence

- The phone showed Roblox CoreGui and sky, but no character, city, gameplay HUD, or action controls.
- Creator Hub recorded four server and two client occurrences of `'StudioTestService' is not a valid Service name` on V6, followed by server and client module-load failures. V8 recorded the resulting server module-load failure at 1:46 PM.
- Both production entrypoints loaded the Studio-only multiplayer regression at module scope. The server failed before runtime world and character startup; the client failed before HUD and controller startup.

### Corrective verification

- Server and client entrypoints now require the regression only within `RunService:IsStudio()`. The test modules also guard their own service acquisition.
- Repository checks now reject module-scope test imports from either production entrypoint and unguarded `StudioTestService` acquisition.
- `./scripts/check.sh` passed with zero Selene or StyLua errors and produced the place artifact.
- A clean iPad-emulated Play session showed Brontide grounded in the generated city with the objective HUD and touch controls visible together.
- The Studio log contained both `[Kaiju Citybreakers] Kaiju Feel Lab server started` and `[Kaiju Citybreakers] Kaiju Feel Lab client started`; no gameplay bootstrap error appeared.

### Decision

Retain automated `StudioTestService` coverage, but keep it outside the live dependency graph. Add Creator Hub Error Report inspection to every production smoke test. The fix passes isolated artifact testing; a fresh physical-device session remains the final gate after publishing the exact commit-labelled artifact.

### Production publication

- Published source commit: `7c6a100dc2a1667f7662eecf113dec50518bc346`
- Artifact: `KaijuCitybreakers-7c6a100dc2a1.rbxlx`
- SHA-256: `90ac6c5d6cbeb4e9f90f3de2190e8ffde2f0e20ae6d2421f41b5e3307c0e4570`
- Studio returned `PublishSuccessful` for existing place `137103245194702` in universe `10609698937` at 2:03 PM.
- Creator Hub showed one active public V9 server, started at 2:03 PM with one connected player and 60 FPS.
- The Error Report total remained at 12 historical V6/V8 events and contained no V9 bootstrap error immediately after the fresh server started. Analytics may be delayed, so this does not replace the pending physical-device visual smoke test.

## 2026-08-01 — Expanded smashable city, Charge impact, Beam, and iPhone layout

- Implementation: local working tree; deliberately uncommitted, unpushed, and unpublished at stakeholder request.
- Environment: clean Rojo-built `.rbxlx`, Roblox Studio iPhone 16 landscape emulation at `852 × 393`, one local client and server; **zero human testers**.
- Systems: runtime city builder, destructible contract, authoritative CombatService, three touch actions plus native Jump, client-local feedback, and HUD prompts.

### Results

- The city foundation grew from `350 × 260` to `500 × 380` studs, more than doubling its blockout area. The runtime world contained `723` descendants, `565` parts, `72` direct children, zero unanchored world parts, and the existing ten lights.
- All `17` tagged structures had unique IDs and complete Visuals, Collision, and DamageHitbox packages; the audit found zero invalid structures. This includes the gate, the three earlier archetypes, all five former static shells, and eight new east/south district buildings.
- The generated iPhone controls measured Beam `(386.1, 228, 72 × 72)`, Charge `(470.1, 228, 72 × 72)`, Smash `(554.1, 228, 72 × 72)`, and Jump `(638, 222, 70 × 70)`. The rectangle check reported zero overlaps and a 12-pixel Smash-to-Jump gap.
- A normal Beam request passed the server cooldown, character, round, collision-filter, and raycast path, returned one confirmed hit, and reduced NorthSignalTower health from `4` to `2` with state `Damaged`.
- A normal Charge request returned acceptance followed by a separate confirmed `chargeImpact`, reducing GateTowerEast health from `3` to `1` with state `Damaged`.
- The fresh artifact printed world, server, and client startup markers. No project script error or stack trace appeared; unrelated Studio asset/chat service warnings were excluded from gameplay evidence.

### Decision

Retain the staged city expansion, three-action layout, Charge impact, and Beam for a physical-device playtest. The structural, input-spacing, and authoritative-damage regressions pass in Studio. This does not prove physical-phone comfort, representative-device frame time/memory, Beam balance, or that the larger layout is fun and understandable; those remain human/hardware gates before publication.

### Production publication

- Published source commit: `01b48abbe3ea42f72732f4d874122e866626baaf`
- Artifact: `KaijuCitybreakers-01b48abbe3ea.rbxlx`
- SHA-256: `a9973d8b53571d807a1b1f769829441bf15a46bb8fa0a4bd026002b5023d75ad`
- The exact commit-labelled artifact was opened without Rojo and smoke-tested in Studio's iPhone 16 landscape profile. Brontide, the expanded city, objective HUD, Beam, Charge, Smash, and native Jump rendered together with no action-button overlap.
- The runtime audit found `17` unique tagged destructibles and `0` invalid contracts. Server and client startup markers appeared without a project script error.
- Studio entered `PublishSuccessful` and logged `Published "Kaiju Citybreakers" to Roblox.` for existing place `137103245194702` in universe `10609698937` at 3:03 PM.
- A fresh production-client visual smoke test remains pending because this Mac has Roblox Studio but no Roblox player, and the available browser session is not signed in. Creator Hub Error Report review is also pending authenticated access. Neither pending gate is represented as passed.

## 2026-08-01 — Mega-district structural audit and Beam redesign trigger

- Implementation: local working tree on `agent/beam-and-mega-districts`; not yet published.
- Environment: clean Rojo-built `.rbxlx`, Roblox Studio iPhone 16 landscape emulation at `852 × 393`, one local client and server; **zero human testers in Studio**.
- Human evidence: a physical-device player reported that the published Beam appeared to do nothing and requested cursor-following mouth fire with a lagging head turn.

### Results

- The runtime generated `33` unique valid destructibles across Central City, Titan Park, Arc Power Plant, Mount Brontide, and Azure Lake.
- The generated world contained `1,271` descendants and `962` `BasePart` instances, with `0` invalid destruction contracts, `0` unanchored world parts, and the existing `10` lights.
- The temporary gameplay title, instructions, and timer were absent in the updated phone build. The test then identified and removed a separate gate instruction billboard before release.
- Phone controls remained visible inside the landscape safe area. Short-range zone labels replaced the first oversized labels that obscured the spawn view.
- Static checks passed with zero Selene errors, warnings, or parse errors and produced the place artifact.
- A normal aimed Beam hit the low Titan Park pavilion once and changed health `2 → 0`, `Intact → Collapsed`.
- A normal aimed Beam hit the tall CentralNorthWestTower once and changed health `5 → 3`, `Intact → Damaged`.
- The same request geometry left the deliberately off-axis CentralNorthEastTower at health `5`, `Intact`, with zero confirmed hits.
- Tapping the actual generated iPhone `BEAM` action collapsed the Titan Park conservatory, proving the touch action rather than only a direct remote request.
- Player-scale captures showed the intended open park, cyan-channel power plant, angular mountain ridge, broad lake and marina, and dense central skyline as distinct silhouettes.
- In the final rebuilt artifact, a touch camera drag produced `-76.00°` raw camera-relative yaw; the dedicated `HeadAimMotor` retained `-38.05°` through its `C0` offset after the animation pass, matching the authored head-turn limit.
- The final audit remained at `962` generated-world parts, `33` valid destructibles, `0` invalid contracts, `0` unanchored world parts, and `10` lights. The head pivot is a single character part outside the generated-world count.

### Pending human/device gates

- Complete a physical-phone performance, comfort, and comprehension test across all five districts.
- Judge the `0.18` second Beam tracking response and `38°` head limit during natural play; Studio proves routing and bounds, not subjective feel.

### Decision

Retain the map scale, structure count, lean visual variants, server Beam correction, and dedicated head pivot. The exact-build engineering gate passes. Publish for the requested physical-device iteration while keeping performance, comfort, comprehension, and subjective Beam feel explicitly unverified.

### Production publication

- Published source commit: `252faec2405f399184bc6afb6819e46fa3cc6c12`
- Artifact: `KaijuCitybreakers-252faec2405f.rbxlx`
- SHA-256: `30860464a2154f9a159d4a265db65a6eb15c063427c39d5d44b21cb33afacd06`
- The exact commit-labelled artifact was opened without Rojo and smoke-tested in Studio's iPhone 16 landscape profile. Brontide spawned at y=`12.22`, settled on Asphalt with approximately zero vertical velocity, and rendered with the expanded city and three safe-area action controls but no temporary title, instructions, or timer.
- Tapping the exact artifact's `BEAM` control returned `accepted=true`, `hits=1`, and collapsed a registered structure. The generated `CHARGE` and `SMASH` controls separately returned accepted `charge` and `basic` results through the normal client/server path.
- World, server, and client startup markers appeared without a project script error. Studio displayed `Successfully published!` and logged `Published "Kaiju Citybreakers" to Roblox.` for existing place `137103245194702` in universe `10609698937` at 4:41 PM BST.
- A fresh physical-phone production join and Creator Hub Error Report review remain pending. This Mac has Roblox Studio but no Roblox player, so neither production-side gate is represented as passed.

## 2026-08-01 — Genuine mixed-scale player foundation

- Implementation commit: `641e84d6ac27409ded201362759df8dbddb0423e`
- Environment: the existing Roblox Studio editor, one iPhone 16 landscape simulation run, then a native `StudioTestService` server with one initial and one late client; **zero human testers**.
- Systems: server-owned roles, actual character scale, role-specific spawns/metrics/cameras/actions, collision groups, human-scale doorway reference, human combat rejection, late-join destruction reconstruction, and disconnect promotion.

### One-client integration

- The first player received the replicated `Kaiju` role and spawned as the real scaled Brontide in the generated city.
- Measured character bounds were approximately `39.12 × 61.93 × 70.06` studs. The root spawned at approximately y=`30.36` in collision group `KaijuCharacters`.
- The kaiju camera range was `58–105` studs. Brontide and the surrounding city rendered together in the iPhone 16 simulator, and no project runtime error appeared.

### Native two-client regression

- The original player was `Kaiju`; the late player was `Human`. Measured standing heights were `61.37` and `5.50` studs, an actual `11.17:1` model-bounds ratio rather than a camera-only illusion.
- The human client retained `CameraType.Custom` with a `6–18` stud zoom range and had no Smash touch action.
- A direct human basic-attack request left the intact target's health unchanged, exercising the server's role rejection rather than relying on the hidden client button.
- The initial kaiju collapsed `north_warehouse` through normal cooldown and spatial validation. The existing client observed `10` live fragments; the late human reconstructed `Collapsed` state and observed `0` historical fragments.
- The kaiju client then left through the native Studio test lifecycle. The remaining human was promoted and reloaded as `Kaiju`, measuring `61.71` studs tall. The regression returned `passed = true` with one player remaining.

### Decision

Retain scale `10` as the feasibility baseline: it produced a measured ratio above the provisional `10:1` gate while preserving the existing server-authoritative destruction path. This is not evidence that either role is fun, that touch controls are comfortable on hardware, or that two differently scaled moving characters meet the phone performance budget. Do not rebuild the city around this scale until a fresh physical-phone check and an uncoached two-person test validate scale readability, contact stability, navigation, and one useful human contribution.

## 2026-08-01 — Asymmetric mixed-scale combat regression

- Implementation commit: `7073cbc10f137afd7ec0c6f238f6ba95f388595c`
- Environment: existing Roblox Studio editor with native `StudioTestService`, one server, one initial client and one late client; **zero human testers**.
- Systems: human blaster, role-specific combat actions, Humanoid health/death, disabled passive regeneration, role-preserving respawn, kaiju-to-human damage, smooth contact hull, capped contact knockback, late-join destruction reconstruction and disconnect promotion.

### Exact-commit results

- The measured Brontide/human standing heights were `61.37` and `5.51` studs, an actual `11.15:1` ratio.
- The human client had `FIRE`, the centre aim reticle and native `6–18` camera, but no Smash action. The kaiju client had no human Fire action or reticle.
- A normal human request originated at the server-known character, raycast Brontide and reduced kaiju health `1000 → 960`. Continued cooldown-respecting fire defeated Brontide; the same player respawned at `1000` health with the `Kaiju` role and rebuilt contact hull.
- The full character groups remained non-colliding while the smooth contact hull was physically collidable with humans. The authoritative proximity check damaged the human, and the sampled post-contact velocity remained below the configured `28` stud/second cap.
- A human request for the kaiju-only basic attack left the structure unchanged. A normal kaiju Smash defeated the human; the same player respawned at `100` health with the `Human` role.
- The initial client retained `10` live collapse fragments while the late client reconstructed the collapsed warehouse with `0` historical fragments.
- After the original kaiju client left, the remaining human was promoted and rebuilt as a `61.59`-stud kaiju. The structured result returned `passed = true` with one player remaining.

### Harness discovery

One exact-commit attempt stalled inside Studio before adding its late client and returned `null` only after the editor's native **End Session** command. No project-script error appeared, and the temporary test processes were closed. A clean retry from the same single editor completed with the pass above. Treat a `null` native result as no evidence and always confirm that only the editor process remains after an interrupted run.

### Decision

Retain the asymmetric combat foundation for a physical two-device test. The engineering path proves authoritative damage, death, respawn, actions and configured contact filtering; it does not prove that `40` blaster damage, `25` contact damage, instant Smash/Charge/Beam human damage, the collision feel or either role's balance is enjoyable. Do not expand the weapon roster or rebuild the city around combat until two people test natural aiming, collision stability, deaths, rematches and role preference on representative hardware.

### Production publication

- Published source commit: `fe005119e0e803d56f0a4adba7638ad8513a9565`
- Artifact: `build/KaijuCitybreakers.rbxlx`
- SHA-256: `8950083b7bfc7f4aab1392dd6aa541c50198f0b830dc6bb90d25b7ed9252fea5`
- The exact generated artifact was opened in the sole Studio editor and used to overwrite the existing `Kaiju Citybreakers` place. Studio displayed `Successfully published!` and logged `Published "Kaiju Citybreakers" to Roblox.` at 18:06 BST.
- No additional local play session was run after publication because the Mac may be locked. A fresh owner-device join and a physical two-device combat test remain the release validation gates.

## 2026-08-01 — Localized rupture and late-join reconstruction

- Implementation commit: `9e6cf7ebba40fa03d303c7f49c05febd92dd24b4` (localized-damage implementation `defbcb4`).
- Environment: the sole existing Roblox Studio editor, native `StudioTestService`, one server, one initial client and one late client; **zero human testers**.
- Systems: server-owned surface zones, attack-specific rupture marks, bounded client-local impact fragments, durable late-join reconstruction, non-emissive damaged variants, and all existing asymmetric combat/lifecycle gates.

### Exact-commit results

- A normal client Smash damaged `arc_cooling_tower_west` to health `4`, advanced its impact sequence to `1`, and persisted exactly one `Smash` surface zone.
- The original client rendered exactly one dark rupture with four torn-rim pieces (`5` visible localized parts total). The damaged cooling-tower variant contained `0` visible Neon parts.
- The late human client reconstructed the same single rupture from replicated attributes and observed `0` historical impact fragments.
- The warehouse collapse, role-specific controls, `11.16:1` kaiju/human height ratio, human fire, kaiju and human death/respawn, contact-damage velocity cap, and disconnect promotion gates all passed.
- The first run reached and passed both localized-damage observations, then exposed a physics-dependent legacy test placement before the kaiju-to-human Smash. Anchoring both test characters and placing the human at the configured server hitbox centre removed that nondeterminism; the clean rerun returned `passed = true`.

### Decision

Retain the localized rupture system and its two-mark-per-structure budget. This engineering gate proves authoritative placement, bounded rendering, non-emissive state art and late-join durability; it does not yet prove the rupture silhouette or debris spectacle is convincing on a physical phone. Publish for the requested owner-device visual test and keep that human/device judgement explicitly pending.

### Production publication

- Published source commit: `9e6cf7ebba40fa03d303c7f49c05febd92dd24b4`.
- Generated artifact: `build/KaijuCitybreakers.rbxlx`.
- SHA-256: `958a1f64777fb79b82c5956864c562b8f389b3c3681866680d574c220ace2620`.
- The synchronized sole Studio editor published the exact project source to existing place `137103245194702` in universe `10609698937` at 19:45 BST. Studio logged `Published new changes in "Kaiju Citybreakers" to Roblox.` and identified the release as `v13`.
- A fresh physical-phone visual test remains pending; this release is intended for that owner-device check and the subjective rupture quality is not represented as passed.

## 2026-08-01 — Smash animation, rupture scale, and functional power-plant pass

- Implementation commit: `ae7a061d532a2d71ffef0b143595b0850836efdd`.
- Environment: the sole existing Roblox Studio editor with native `StudioTestService`, one server, one initial client and one late client; **zero human testers**.
- Systems: procedural Smash pose, current and legacy avatar-joint compatibility, larger layered surface rupture, Arc Power Plant functional dressing, asymmetric combat/lifecycle coverage, and late-join destruction reconstruction.

### Exact-commit results

- A normal client Smash reached the authoritative server path, damaged `arc_cooling_tower_west`, and rendered one eight-part non-emissive rupture. Its measured client bounding span was `36.11` studs, above the provisional `22`-stud phone-readability gate.
- The client played the Smash windup/strike/recovery sequence and returned `ClientSmashAnimationPhase` to `Idle`. The initial Motor6D-only attempt exposed current `AnimationConstraint` avatar joints; the retained implementation supports both joint types and filters out Brontide shell parts that share shoulder names.
- Arc Power Plant contained `33` dressing parts and the required cooling-water header, steam-service header, transformer/switchgear yard, high-voltage busbar, and transmission gantry. No decorative `EnergyChannel` floor strips remained.
- Human fire, kaiju and human death/respawn, controlled contact damage, role-specific controls, an actual `11.16:1` character height ratio, warehouse collapse, late-join reconstruction, and disconnect promotion all passed in the same structured run.
- The final structured result returned `passed = true`, `localizedExistingHoles = 1`, `localizedLateHoles = 1`, `localizedDamagedNeon = 0`, and `smashAnimationPhase = "Idle"`.

### Decision

Retain the joint-compatible Smash pose, eight-part rupture, and functional plant silhouette for the next physical-phone judgement. The engineering gate proves bounded construction, recovery, replication, and regression compatibility; it does not prove the animation timing feels powerful or that an unprompted player identifies the district as a power station. Those remain human/device gates.

### Production publication

- Published source commit: `64e77e4241c5ccf81e4576f821ea08403dae6c9b` (gameplay implementation `ae7a061d532a2d71ffef0b143595b0850836efdd`).
- Generated artifact: `build/KaijuCitybreakers.rbxlx`.
- SHA-256: `70c945d00038e46e379cf25830131dc6ed442e74391088b48038930076306333`.
- The sole Studio editor discarded its synchronized in-memory place, reopened the committed build from disk, and overwrote the existing `Kaiju Citybreakers` place at 20:39 BST. Studio displayed `Successfully published!` and logged `Published "Kaiju Citybreakers" to Roblox.`
- A fresh physical-phone check of Smash feel, rupture readability, and unprompted power-station recognition remains pending.

## 2026-08-01 — Visible Smash and native-terrain city pass

- Implementation commit: `06fd0629ba0b369fafc09c249f40a2fcff982bb8`.
- Environment: the sole existing Roblox Studio editor in iPhone 16 simulation, plus native `StudioTestService` with one server, one initial client and one late client; **zero human testers**.
- Systems: dedicated Brontide visual-shell pivots, measured Smash displacement, native smooth terrain, true terrain water, park/mountain relief, separated urban pads, stepped skyline buildings, four additional destructible infill buildings, and the complete asymmetric-combat/lifecycle regression.

### Results

- The first run correctly failed because the lake fill competed with the grass base. Carving the lake voxel volume before filling Water made the Azure Lake ray report `Enum.Material.Water`.
- The next run correctly rejected the previous post-animation body-joint pose: internal phases completed, but visible shell displacement was only `0.85` studs. Dedicated shell motors increased the exact final measurement to `14.01` studs and restored every pivot to `Idle`, above the provisional six-stud gate.
- Terrain-only rays measured Mount Brontide's Rock surface at `161.98` studs and the Titan Park Grass mound at `12.86` studs. The generated terrain occupied `1,142,194` cells through a bounded operation list and added no Part instances.
- The expanded blockout registered `37` destructible structures and `1,064` world Parts, below its provisional `1,250`-Part ceiling. Arc Power Plant retained its `33`-Part dressing budget.
- The same final structured run passed warehouse collapse, localized eight-part rupture, late-join reconstruction, human fire, kaiju and human death/respawn, capped contact damage, role-specific controls, an `11.15:1` character-height ratio, and disconnect promotion.
- One intervening exact-source run reported `late client did not join` before reaching its two-client assertions. Clearing the native Studio session and retrying the unchanged source produced the complete pass above; the failed harness launch is recorded as no gameplay evidence.

### Decision

Retain the dedicated shell pivots, terrain profile, skyline hierarchy and four infill buildings for publication. The engineering gate now measures what is displayed rather than merely counting animation phases. Simulator inspection shows stronger height contrast, native ground and perimeter relief, but neither synthetic tests nor the editor simulator prove that the city looks convincing, Smash feels powerful, district routes remain clear, or the published phone stays above the provisional frame-rate floor. Those remain owner-device and uncoached-child tests.

### Production publication

- Published source commit: `06fd0629ba0b369fafc09c249f40a2fcff982bb8`.
- Generated artifact: `build/KaijuCitybreakers.rbxlx`.
- SHA-256: `c70a7969e3514c1756ba542b4f5d8a1da5119df6bc5d8e9844ba7e40b883d64e`.
- The exact artifact was opened in the sole existing Studio editor and used to overwrite the existing `Kaiju Citybreakers` place. Studio displayed `Successfully published!` and logged `Published new changes in "Kaiju Citybreakers" to Roblox.` at 21:26 BST.
- A fresh owner-phone check of the terrain, skyline, Smash motion, lake, traversal and frame rate remains the release-validation gate; automated Studio evidence does not replace that physical-device judgement.

## 2026-08-02 — Articulated-turret and richer-enemy boot smoke

- Implementation commit: `1c29eaae080b74d2bd87cae9c702ca2db0affee1`.
- Environment: the sole Roblox Studio editor, one local server and one client; **zero human testers**.
- Scope: exact-commit Rojo artifact startup, authored-world preservation, four articulated turret registrations, original articulated rogue-kaiju spawn, server/client initialization, and active-round transition.

### Exact-commit results

- The authored city and terrain remained present; runtime bootstrap logged `Preserved hand-authored Brontide world`.
- `EnemyService` spawned one articulated rogue kaiju at initial startup and again at countdown reset.
- `TurretService` registered all four capturable turrets with the anchored-root assembly validation enabled.
- Server and client initialized, the round reached `Active`, and Studio Output contained no project-script error during the smoke window.
- A separate synthetic motor probe on the same captured authored world measured visible-shell displacement on all four models (`2.319`, `3.693`, `0.984`, and `3.613` studs). That probe establishes moving geometry, not correct art direction, aim alignment, feel, multiplayer behaviour, or mobile performance.

### Decision

The build is safe to publish for owner-device testing. Retain the four rig contracts and richer single-enemy state machine, but do not multiply either system yet. A human must confirm that each complete turret visibly turns and elevates toward its target, its projectile starts at the barrel, and `Riftback` visibly patrols, investigates, telegraphs swipe versus lunge, staggers, and enrages without getting stuck or rapidly switching targets.

### Production publication

- Published source commit: `d9ecd457dc0007c539fe23e0b6fb4301645b1eab` (implementation commit `1c29eaae080b74d2bd87cae9c702ca2db0affee1`).
- Exact artifact: `build/KaijuCitybreakers-d9ecd457dc00.rbxlx`.
- SHA-256: `00167ce99e9ff26ac92324b29245a4c5842894da591c39fdf91ad2c2619cc76d`.
- The commit-labelled artifact was opened in the sole Studio process, passed a fresh one-server/one-client boot smoke, and overwrote the existing `Kaiju Citybreakers` place. Studio displayed `Successfully published!` and logged `Published "Kaiju Citybreakers" to Roblox.` at 11:44 BST.
- Roblox granted the destination experience access to the nine referenced asset IDs reported by Studio (`5590111085`, `5590111156`, `5590111209`, `5590112509`, `5590111661`, `5590112408`, `5590111714`, `5590112161`, and `5590112319`) before the upload completed.
- A fresh owner-phone session remains required for visual aim alignment, enemy-state readability, live-server bootstrap, and representative-device performance; no human or production-client result is inferred from the Studio pass.

## 2026-08-02 — Temporary factory objective boot smoke

- Implementation commit: `596ed87` (factory foundation `41498f7`).
- Environment: one clean Roblox Studio process, one local server and one client; **zero human testers**.
- Scope: exact Rojo artifact startup, source-captured Edit-visible factory contract, route markers, bounded mixed wave, vehicle attributes, projectile presence, and project-script error inspection.

### Results

- The rebuilt place contained one tagged `TEMP_ArcFactoryObjective`, the production `FactoryService`, five ground-route nodes, and five air-route nodes.
- The authored objective linked Arc Power Plant's destructible `arc_turbine_hall`, retained movable Edit-mode markers, and hid spawn/route authoring markers when runtime registration began.
- The round reached `Active`; the factory's replicated `SpawnSequence` reached `3` and `RuntimeReinforcements` contained `Tank_1`, `Tank_2`, and `Helicopter_3`.
- Both tanks replicated `VehicleArchetype = Tank`, health `180`, and state `Engaging`. The helicopter replicated `VehicleArchetype = Helicopter`, health `120`, and state `Engaging`.
- A separate `HelicopterBullet` travelling projectile was present during inspection, establishing a distinct projectile instance from the combat vehicle. This does not yet prove visual clarity, collision fairness, or damage balance.
- Studio Output contained no factory or project-script error during the smoke window. The test was stopped normally, and only one Studio process remained.

### Decision

Retain the temporary Arc factory as the first integration fixture. It proves registration, caps, spawning, replicated combat state, and basic projectile activity—not route quality, capture/destruction shutdown, linked-turret transfer, vehicle model quality, mobile performance, or fun. The map owner may move the complete objective and its markers while expanding the generated terrain; the next evidence gate is an owner playtest followed by the two-client capture/destruction regression.

### Production publication

- Published source commit: `941ccb6c65aa8efa737f1fdf34448c92f1d68cc1` (factory implementation `596ed87`, factory foundation `41498f7`).
- Exact artifact: `build/KaijuCitybreakers-941ccb6c65aa.rbxlx`.
- SHA-256: `84a99fa5ee3fe3e1f8e8b1a188f69f83c09a8ba55678e96cc9f0fb0f295be079`.
- The commit-labelled artifact passed a fresh one-server/one-client smoke in the sole Studio process. Its factory reached `SpawnSequence = 3` with two tanks and one helicopter, and Studio Output contained no project-script errors.
- The owner confirmed publication to Roblox at 12:54 BST. One Studio process remained open; no second editor was launched.
- A fresh owner-device session remains required for factory visibility, spawn pacing, vehicle movement, projectile readability, combat balance, and representative-device performance; no production playtest result is inferred from publication.

## 2026-08-02 — Asymmetric factory capture and shared-aim smoke

- Implementation commit: `26a0a7898718519c07ec52c837d76282c773fe2e`.
- Environment: one clean Roblox Studio process, one local server and one client; **zero human testers**.
- Scope: neutral startup, bounded wave, synthetic human-only capture, active-vehicle allegiance transfer, shared reticle presence, human desktop camera mode, and client-streaming objective feedback registration.

### Results

- The exact Rojo artifact reached `Active` with no project-script error. The authored factory reported `Neutral / Operational`, `SpawnSequence = 3`, and three live vehicles plus one transient projectile in `RuntimeReinforcements`.
- The kaiju client visibly rendered the shared reticle. After a server-side test changed the sole test player's role to `Human` and held its root five studs from `CaptureZone`, the eight-second authoritative capture completed as `Human / Captured`; all three active vehicles reported `OwnerTeam = Human`.
- The human client reported `Enum.CameraType.Scriptable` and a live `AimReticle`, establishing role rebinding and the shared desktop camera/reticle path. This synthetic role swap retained the kaiju body and therefore does not prove natural human-avatar aiming, animation, or comfort.
- The first objective-feedback query correctly exposed a streaming-order defect: the factory tag could replicate before `CaptureZone`, leaving no billboard or ring. The committed controller now waits for the streamed zone, closes the lookup/connection race, and re-registers after zone stream-out. The rebuilt corrected artifact passes repository, StyLua, Selene, parse, and Rojo checks, but the Mac locked before a second Studio visual run; the corrected billboard/ring is therefore **not yet runtime-verified**.
- One initial synthetic capture attempt returned the player to its spawn because the client still owned and simulated the test character root. Anchoring the root for the server-only objective probe isolated capture logic and produced the successful result; this is harness behavior, not evidence about ordinary walking capture.

### Decision

Retain the neutral factory, human-only capture, three-of-three allegiance transfer, human custom camera, and shared reticle for owner-device testing. The exact merged artifact passed a fresh one-server/one-client boot smoke before publication, but that smoke did not close the remaining human gates: observe the streaming-safe factory ring/billboard, complete capture with a natural human avatar, confirm kaiju presence does not advance capture, and confirm human/kaiju shots land at the visible reticle on representative controls. Physical-device feel and performance remain owner tests.

### Production publication

- Published source commit: `368653074de279aaa618e9f39f6503ece7bf6a79` (implementation commit `26a0a7898718519c07ec52c837d76282c773fe2e`).
- Exact artifact: `build/KaijuCitybreakers-368653074de2.rbxlx`.
- SHA-256: `9afa14a55c75b43726457fe8e9d6db03cac95c741b3c3b69eaaae709f96a5dc9`.
- The commit-labelled artifact was opened in the sole Studio process and passed a fresh one-server/one-client boot smoke. Studio logged preservation of the hand-authored world, one articulated rogue-kaiju spawn, four capturable-turret registrations, server/client startup, and transition to `Active` with no project-script error.
- The destination experience was granted access to the nine asset IDs requested by Studio (`5590111085`, `5590111156`, `5590111209`, `5590112509`, `5590111661`, `5590112408`, `5590111714`, `5590112161`, and `5590112319`) with the owner's explicit confirmation.
- The exact artifact overwrote the existing `Kaiju Citybreakers` place at 14:01 BST. Studio displayed `Successfully published!`; one Studio process remained open and no second editor was launched.
- A fresh owner-device session remains required for the factory capture split, transferred-unit allegiance, objective feedback, human crosshair aiming, kaiju beam aiming, touch/gamepad behavior, and representative-device performance.

## 2026-08-02 — Neutral-factory, combat-targeting, and vehicle-AI release smoke

- Published source commit: `9a10630e73b545444bb06b56b8e9558f2b5f30e1`.
- Exact artifact: `build/KaijuCitybreakers-9a10630e73b5.rbxlx`.
- SHA-256: `07251361edb268a2e3945267948acc8430d3f4f9cded66c2c08cd8cf5dca4275`.
- Environment: the sole Roblox Studio editor, one local server and one client; **zero human testers**.

### Results

- The exact commit-labelled artifact preserved the hand-authored world, spawned one articulated rogue kaiju, registered all four turrets, started server and client, and reached `Active` without a project-script error.
- The factory remained `Neutral / Operational` with `SpawnSequence = 0` and zero children in `RuntimeReinforcements`, confirming that neutral factories are dormant until a human capture.
- The client loaded a four-second beam and placed the desktop reticle at approximately `(0.5550, 0.4995)` of the viewport, just right of centre with the top inset accounted for.
- Earlier same-source system probes completed human-only factory capture and vehicle spawning, human-only turret capture, kaiju turret destruction, a complete server-owned beam session that destroyed its target, and tank target acquisition/damage with a replicated aim point. The rejected harness attempts and their operator causes remain documented in the preceding implementation record; no rejected attempt is counted as gameplay evidence.

### Production publication

- The exact artifact overwrote the existing `Kaiju Citybreakers` place (`137103245194702`) at 15:17 BST. Studio displayed `Successfully published!`.
- Studio granted the destination experience access to the nine requested asset IDs (`5590111085`, `5590111156`, `5590111209`, `5590112509`, `5590111661`, `5590112408`, `5590111714`, `5590112161`, and `5590112319`) before completing the upload.
- The experience remains private. An unauthenticated production-page check therefore returned `Content not accessible`, and the Mac locked before an authenticated Roblox-client smoke could begin. A fresh owner-device session remains required for live-server bootstrap, aim feel, capture interaction, vehicle behavior, beam impact, and representative-device performance.
