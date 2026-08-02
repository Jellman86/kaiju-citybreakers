# Decision log

Use [RESEARCH.md](RESEARCH.md) to classify the basis for each decision. For playtest decisions, include the build commit, device, sample size, observed result, and whether players received coaching.

## 2026-08-01 — Core format

Choose a cooperative kaiju rampage roguelite as the first product. Treat competitive territory control as a later mode, not the initial build.

Basis: platform evidence plus project inference. Roblox's design guidance supports social play, while solo support prevents the first prototype from depending on server population. The superiority of this format for our players remains a testable hypothesis.

## 2026-08-01 — Vertical-slice scope

Build one kaiju, one compact district, one enemy, staged destruction, and one complete round before additional content.

Basis: project inference. Combat feel and destruction are the riskiest assumptions and should be tested before content production.

## 2026-08-01 — Original IP only

Use entirely original characters, designs, names, sounds, and branding.

Basis: Roblox intellectual-property requirements plus the zero-cost constraint. Original work gives freedom to publish and iterate without licensing cost or takedown risk.

## 2026-08-01 — Free implementation

Use only free/open-source tools, included Roblox services, original assets, and GitHub Free features.

Basis: explicit project requirement.

## 2026-08-01 — Source ownership

Rojo files own scripts; Studio owns world composition. Use the Studio MCP for world operations and playtesting without independently replacing Rojo-managed scripts.

Basis: engineering inference. One source of truth prevents synchronization conflicts and supports reviewable Git history.

## 2026-08-01 — Authored destruction states

Prefer Intact, Damaged, and Collapsed variants with client cosmetic debris over unrestricted structural physics.

Basis: Roblox performance and security guidance plus a project hypothesis. Staged states make networking, collision, and server authority predictable; client-local bounded debris provides spectacle without making every fragment authoritative.

## 2026-08-01 — Phase 1 dependency and asset audit

Use Roblox-native character, camera, input, tagging, overlap, constraint, and cleanup systems for the Kaiju Feel Lab. Defer general frameworks and adopt no Creator Store character or destruction model.

Basis: the [reuse audit](REUSE_AUDIT.md). Native systems already cover the small slice across devices. Marketplace kaiju results conflict with original-IP constraints, and generic destructible models do not match the authored-state or performance contract. Roblox's official modular city kit remains a Phase 2 candidate pending isolated inspection and profiling.

## 2026-08-01 — Kaiju Feel Lab engineering gate

Keep the current prototype path and proceed to uncoached human testing.

Basis: automated Studio integration at commit `3583660` completed the charge-and-smash loop without runtime errors, but synthetic input is not human evidence. See [PLAYTESTS.md](PLAYTESTS.md). Do not mark hypothesis H1 passed until people unfamiliar with the controls test it.

## 2026-08-01 — Comprehension-first visual blockout

Replace the visible scaled avatar with an original Brontide shell on the native R15 controller, and dress the test lane as a compact city before the first child playtest. Keep both as source-controlled Roblox primitives until their silhouette and layout pass the comprehension test.

Basis: direct stakeholder observation that a human avatar in an abstract arena did not communicate the intended kaiju game. The reuse re-check found no free Creator Store kaiju model that met the originality, provenance, relevance, inspection, and mobile-fit gates. The primitive shell retains proven native locomotion while the city composition supplies scale cues without committing to a production art asset. This is a project hypothesis: an uncoached player should identify the character as a giant monster and the setting as a city within ten seconds.

## 2026-08-01 — One action map across devices

Use Roblox `ContextActionService` to bind each gameplay action once across keyboard/mouse, gamepad, and generated touch buttons. Use `UserInputService.PreferredInput` only to change instructional text, never gameplay authority, and keep interactive HUD content inside `CoreUISafeInsets`.

Basis: Roblox platform documentation plus the project's mobile-first requirement. Native character controls already supply keyboard, thumbstick, touch joystick, and camera behaviour. The game-specific layer adds `Q`/Shift or left trigger/B for charge, mouse/`E` or right trigger for smash, and labelled touch buttons for both. Mixed-input players receive prompts for their most recently preferred input. Actual comfort, reach, and comprehension remain human playtest questions on representative phone/tablet and gamepad hardware.

## 2026-08-01 — Use camera-facing desktop movement without changing touch or gamepad semantics

On keyboard/mouse, lock the pointer, orbit a third-person camera from mouse delta, and align Brontide's yaw with the camera's horizontal forward direction so the creature's back remains toward the player. Keep movement camera-relative, use scroll-wheel zoom and camera collision, and restore Roblox's native camera and auto-rotation whenever touch or gamepad becomes the preferred input.

Basis: stakeholder feedback clarified that the intended reference is a classic behind-the-character action camera rather than independent cursor-to-world aiming. Roblox documents locked-center mouse delta for relative camera input, `CameraType.Scriptable` for experience-owned camera CFrames, and per-frame `Camera.Focus` updates. Character rotation is yaw-only and attacks remain server-authoritative.

## 2026-08-01 — Lay out touch actions within the live action-frame bounds

Compute `SMASH` and `CHARGE` size and position from Roblox's live `ContextButtonFrame`, rather than fixed screen percentages. Keep targets between 72 and 96 pixels, maintain a proportional gap, and stack them in a column immediately left of Roblox's native Jump control whenever the preferred row is obstructed. Clamp the fallback column against the full viewport, not only its narrower parent frame.

Basis: an iPad A16 reproduction showed the former percentage positions resolving inside Roblox's lower-right action frame, not the full screen, leaving a three-pixel action overlap. The first separated row also intersected Roblox's later-created Jump button. Frame-relative anchors, late native-control detection, and a screen-bounded obstacle fallback keep all three actions separated across resolution and orientation changes.

## 2026-08-01 — Make charge legible at kaiju scale

Increase the validated charge from 44 studs/second for 0.45 seconds to 80 studs/second for 0.6 seconds, producing an unobstructed travel budget of approximately 48 studs. On server acceptance, add a client-only 8-degree FOV kick, a short cyan particle burst, and a fading Brontide highlight; none of these cosmetics affect simulation or authority.

Basis: an actual iPad report said charge appeared to do nothing. Reproduction proved that the touch request was accepted but moved only about 20.7 studs, which read too similarly to the 24 studs/second walk speed on a four-times-scale character and distant camera. A roughly 3.3× walk-speed burst plus three brief feedback channels creates a distinct locomotion verb without adding input blocking, hit-stop, or camera shake.

## 2026-08-01 — Adopt the native, proxy-based destructible contract

Use one strict shared contract for full and objective structures: three authored visual variants, one damage-query hitbox, intact and collapsed collision proxies, stable IDs, and sequenced server state. Replicated attributes reconstruct durable state; a compact server event triggers live client feedback. Make each complete structure an atomic streaming model and keep decorative geometry outside gameplay collision and queries.

Basis: Roblox platform documentation supports tags and attributes, collision filtering and bounded spatial queries, atomic logical groups, server-authoritative outcomes, state-change replication, and client-local effects. The approach retains the already proven native overlap and remote path while eliminating hierarchy-specific variant assumptions and streamed Instance arguments. The claim that three states create enough spectacle remains H6, not a proven result.

The Phase 2A reuse audit adopts no runtime dependency or external asset. The official Modern City kit remains a modular-workflow reference because a wholesale import would introduce thousands of mesh parts and scripts before layout or destruction performance is validated.

## 2026-08-01 — Bound client debris with a purpose-built pool

Replace per-collapse `Part` creation and `Debris` destruction with a client-only pool that prewarms ten fragments, grows only to 100, recycles the oldest active fragment at saturation, and unparents inactive entries. Guard every delayed release with an entry generation so a timer from an earlier use cannot hide a recycled fragment. Keep concrete, metal, and lightweight presentation in data profiles and defer dust particles until the representative district is profiled.

Basis: Roblox recommends pooling frequently respawned instances and creating non-authoritative visuals on clients. This is an engineering inference to be retained only if the Phase 2B stress run reduces actual created instances while holding active fragments and cleanup within the configured caps. A generic package is not adopted because this lifecycle is small, local, and game-specific.

Result: automated Studio testing of commit `d21eaae` issued 200 overlapping spawn requests and created exactly 100 parts, recycled 100, peaked at 100 active, returned all 100 to the pool, and left no world instances after teardown. Fifty ten-fragment trials averaged `0.101 ms` on the prewarmed path versus `0.113 ms` for fresh creation plus timed cleanup in the same Studio session. Retain the pool for bounded allocation and lifecycle control. These editor microbenchmarks are not representative-mobile frame-time evidence, so particle dust remains deferred and H6 remains open.

## 2026-08-01 — Derive the first archetypes from Brontide metrics

Build a low broad warehouse, a two-kaiju-height signal tower, and a compact energy substation on a 2-stud grid through one strict destructible builder. Place the north pair beside the spawn-to-gate teaching route and the substation beyond the gate as a future energy landmark. Replace three similarly positioned static shells instead of expanding the world bounds.

Basis: live Brontide extents, movement, charge, camera, and attack dimensions; Roblox's modular-pivot, built-in-material, streaming, reuse, and simple-collision guidance; and the level-design introduce/develop/test/release pattern. Exact scale, health, visibility, and fun remain provisional until automated routing plus uncoached human and representative-device tests are recorded.

Result: the exact-commit Studio regression at `ff95af4` registered all four unique atomic structures without diagnostics. The three new archetypes stayed below their part ceilings, collapsed through the real authoritative hit path at their configured health, selected only the correct client visual and collision proxy, and allowed traversal across the substation rubble slab. Retain this blockout, but require a two-client state/late-stream regression before district multiplication; do not infer human readability or mobile performance from the synthetic run.

## 2026-08-01 — Automate the late-join destruction gate with StudioTestService

Use Roblox's native `StudioTestService` to start one client, collapse a representative structure through the real attack path, then add a second client and compare server state with each client's replicated attributes and local visual selection. Gate the harness on Studio plus an exact versioned test argument so ordinary Play and production sessions remain unaffected.

Basis: separate server and client processes are required to test replication; Roblox now provides a native asynchronous multiplayer-test API, player addition, test arguments, and structured completion. A third-party framework would add dependency and maintenance surface without improving this focused integration test.

Result: exact commit `eeaf523` returned a structured pass with two clients. Both reconstructed warehouse health `0`, state `Collapsed`, and sequence `2`; the initial client saw ten live fragments and the late client saw zero historical fragments. An ordinary Play regression created no test remote and produced no errors. The native harness is retained, and the district-multiplication gate is open.

## 2026-08-01 — Add one low-density park loop before dense streets

Extend west from a truthful cross street into one open park/plaza, then reconnect beside the spawn. Preserve the direct avenue as the critical path and keep all branch connections north of the gate. Use a 40-part expansion ceiling, existing built-in materials, no new lights, and no decorative physics.

Basis: Brontide's measured extents, 48-stud charge, and 24–42 stud camera distances; the level-design introduce/build/release/test rhythm; Roblox's greybox playtest questions; and Roblox's guidance on object density, anchored geometry, collision, shadows, and built-in profiling. Production park kits remain deferred because this is a route and density test.

Result: exact commit `ea02de3` added 38 parts and 11 models with no lights, completed the loop in both directions, kept eight camera rays clear at both distance limits, and preserved the authoritative gate path. Testing also found and closed a legacy side bypass with two primitive cordons. Retain this greybox but require an uncoached layout test and representative-device performance evidence before adding the dense avenue.

## 2026-08-01 — Publish production from a clean Rojo artifact

Treat a commit-labelled `.rbxlx` produced by `rojo build` as the production deployable. Keep live Rojo sync for iteration, restrict it to place `137103245194702`, and publish the tested artifact to that existing place through **Publish to Roblox As**. Require an explicit Studio success result followed by a fresh live-server smoke test.

Basis: Rojo documents built place files and live sync as separate supported workflows. Production version 6 was reported as blank on an iPad even though Studio logged a successful publish from a live-synced session; the server showed the template avatar and baseplate with no city, HUD, or gameplay bootstrap. The same commit built into an isolated place artifact started the server and client, generated all 323 world descendants, and created the Brontide character. Publishing that artifact directly to the existing place returned Studio's explicit success result and destination place ID. Retain artifact publishing so the tested source state and the uploaded DataModel are the same unit.

Follow-up: the artifact removed the Studio template spawn, exposing a join/bootstrap race in production. Commit `61eaea0` disables automatic character loading, builds the world first, and makes the server explicitly load and ground each scaled Kaiju at the generated spawn. Initial spawn and two forced respawns settled on asphalt with zero downward velocity in the isolated release artifact. This ordering is retained because it makes the runtime-generated world's readiness a server-owned precondition for character creation.

Second follow-up: a real phone session on the subsequently published artifact showed only CoreGui and sky. Creator Hub's live Error Report confirmed server and client errors stating `'StudioTestService' is not a valid Service name`, followed by module-load failures. Both production entrypoints were unconditionally requiring the multiplayer regression module, whose module scope acquired that Studio-only service. The server therefore stopped before creating the runtime world and character, while the client stopped before creating the HUD. Production entrypoints now require that harness only inside `RunService:IsStudio()`, the modules defensively guard service acquisition, and repository checks reject module-scope test imports from either entrypoint. Studio automation remains available without being a production bootstrap dependency.

## 2026-08-01 — Expand through the existing staged-destruction contract

Convert the five remaining decorative building shells to the same atomic three-state contract as the warehouse, tower, and substation, then add eight buildings across east and south districts. Extend the foundation and streets with anchored built-in-material primitives; keep one damage hitbox and two simple collision proxies per building, and keep collapse spectacle client-local and bounded. End the permanent gate cordons at the outer faces of the two now-destructible gate towers so a collapsed tower never leaves an invisible wall and can become an earned alternate breach.

Basis: the stakeholder requested that every building be smashable and the map become materially larger. Roblox recommends designing for mobile limits, reusing built-in materials, simple collision geometry, client-local outcome-independent visuals, and instance streaming for larger places. A bespoke physics-collapse system or imported city package would violate the project's validated destruction contract and add unmeasured mobile cost. Exact representative-device frame time, memory, and route comprehension remain open gates.

## 2026-08-01 — Give Charge impact and add a server-owned Beam

During the existing 0.6-second Charge, run a bounded server overlap query against only destructible damage hitboxes, damage each unique structure once, and cap the action at four affected structures. Add Beam as a server raycast along Brontide's validated facing direction with a 180-stud range, two damage, and a four-second cooldown. Send only confirmed origin, endpoint, and hit count to the requesting client for short local visuals.

Basis: Roblox's client-server security guidance requires combat outcomes, cadence, player state, and targets to be validated by the server. `WorldRoot:GetPartBoundsInBox()` matches a moving volume and `WorldRoot:Raycast()` returns the first filtered line target. Charge and Beam therefore reuse the existing collision group, damage service, cooldown/rate gates, and destruction states instead of introducing parallel combat logic. Damage values, action preference, and whether Beam improves the child's play experience remain playtest hypotheses.

## 2026-08-01 — Treat Roblox Jump geometry as live phone layout state

Watch the native Jump button's final absolute position, size, and visibility, then arrange Beam, Charge, and Smash outside that rectangle with proportional gaps. Prefer a horizontal row to the left of Jump and fall back to a bounded vertical column only when the available width is insufficient.

Basis: a physical iPhone screenshot showed Smash sharing the native Jump button's footprint even though the initial Studio layout appeared valid. Roblox creates and settles native controls asynchronously. A one-time descendant callback observed the button before its final geometry; property-driven relayout addresses the observed timing fault and remains subject to a final physical-phone check.

## 2026-08-01 — Expand into five performance-bounded greybox zones

Use a `1400 × 1100` foundation and five distinct material, density, silhouette, and landmark zones: Central City, Titan Park, Arc Power Plant, Mount Brontide, and Azure Lake. Keep all authored building silhouettes inside the existing atomic three-state destruction contract, keep terrain-like dressing non-queryable, use lean state variants for new buildings, and retain instance streaming.

Basis: the stakeholder requested a much larger city with clear places rather than more repeated blocks. Roblox recommends greybox testing, spatially coherent streaming models, anchored static scenery, built-in materials, simple collision, and measuring before optimization. A new imported city kit or unrestricted physics system would discard the validated destruction contract and introduce unmeasured mobile cost. The working-tree audit records 33 valid destructibles and 962 world parts, below the provisional 1,000-part ceiling; zone comprehension and physical-device performance remain unproven.

## 2026-08-01 — Supersede the horizontal Beam ray with shared aimed mouth fire

Use one exponentially smoothed client aim direction for Brontide's head pose and Beam request. Keyboard/mouse derives it from the pointer ray; touch and gamepad use the camera centre. Fire immediate harmless muzzle feedback from the mouth, while the server validates the request against the living character, cooldown, round, finite vector bounds, vertical limits, and a 75-degree forward cone before running a nine-stud-radius native sphere cast against only destructible hitboxes.

Basis: a physical-device report said Beam did nothing. The prior synthetic test hit a tall tower, but the horizontal cast originated above many low roofs, making a valid request appear broken. Roblox's weapon-targeting guidance permits client aim intent only when the server validates origin/context/cadence and resolves the actual hit. The smoothed pose is presentation; server cooldown, cast, target, and damage remain authoritative. The exact lag, turn limits, radius, and visual duration remain playtest parameters.

## 2026-08-01 — Prototype one lightweight scout before a defender army

The first enemy slice contains one server-owned scout-drone archetype with authored air patrol nodes, bounded line-of-sight acquisition, a long telegraph, a slow projectile, stagger, and defeat. Ground units later reuse native `PathfindingService` and modifiers; the boss is deferred until the drone and turret pass readability and performance gates.

Basis: Roblox provides native ground pathfinding and warns that many server-animated Humanoids can be expensive. A flying scout does not need a custom navmesh or ground-path computation. One shared state, team, damage, pooling, and authority contract avoids multiplying parallel AI systems before their contribution to the destruction loop is proven. See [ENEMY_SYSTEM.md](ENEMY_SYSTEM.md).

## 2026-08-01 — Prove a sustained demolition Beam before adding enemies

Insert a focused Phase 2D slice ahead of the scout-drone prototype. Replace the brief one-hit presentation with a bounded server-owned Beam session that accepts rate-limited aim intent, resolves damage at fixed samples, and can advance through successive destructibles as the player sweeps or rubble clears. Keep the mouth/head presentation and tiered impact spectacle client-local, transient, pooled, and scalable through Reduced Effects.

Basis: the stakeholder reports that the Beam needs to last longer, draw a destructive line across targets, and make destruction more spectacular. Roblox's security model still requires the server to validate combat context and cadence, while its performance guidance supports local outcome-independent visuals but warns that particle fill rate, transparency, property churn, and per-frame work can be expensive. A native-query spike against five to eight buildings and a physical-phone stress test therefore precede content rollout. The approximately `1.5`-second channel, sampling cadence, caps, feedback layers, and player preference remain explicit hypotheses rather than settled balance.
