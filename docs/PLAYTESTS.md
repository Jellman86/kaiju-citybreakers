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
