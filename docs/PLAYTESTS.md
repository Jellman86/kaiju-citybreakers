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
