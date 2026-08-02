# Decision log

Use [RESEARCH.md](RESEARCH.md) to classify the basis for each decision. For playtest decisions, include the build commit, device, sample size, observed result, and whether players received coaching.

## 2026-08-02 — Human-authored map is the visual source of truth

Store `Workspace.KaijuFeelLab` and `Workspace.Terrain` as focused Roblox XML model sources, capture them from an ignored saved Studio place, and preserve them whenever Play starts. Keep the procedural builder only as a fallback for an intentionally empty place and as reusable metric scaffolding.

Basis: direct stakeholder feedback correctly identified that screenshot sampling, instance counts, and procedural coordinates do not provide continuous spatial judgement or convincing art direction. Roblox supplies a native visual Terrain Editor, while Rojo supports model files as project paths but does not reverse-sync Studio edits to the filesystem. Separating the two world roots from Rojo-owned scripts lets a human compose the map visually without introducing a second script source of truth. The solution uses only existing free tools and Git LFS already registered by the project.

Risk and review condition: XML world models are large and visually opaque in code review, so each capture must be rebuilt and inspected in Edit mode, with gameplay and device regression proportional to the change. Revisit asset partitioning if repeated captures materially consume the project's free Git LFS allowance or create merge contention.

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

## 2026-08-01 — Begin a mixed-scale lab before rebuilding the city

Assign the first player as the solo-safe kaiju and later players as humans, with automatic promotion when the kaiju leaves. Prototype Brontide at scale `10`—expected to produce approximately `60–75` studs of actual height—beside an ordinary avatar. Give the roles separate server-owned spawn and movement metrics, separate local cameras, and non-colliding character groups. Keep all attacks kaiju-only and server-authoritative.

Basis: the stakeholder wants human-size and kaiju-size players to coexist without relying on perceived-scale tricks. Roblox supports manual character loading, custom humanoids, model scaling, per-player cameras and collision groups, but does not publish a generally safe maximum in-experience character scale. The scale, role fun and mobile cost therefore remain hypotheses. The existing R15 controller and original primitive shell are reused for the feasibility build; no external rig, character framework or asset is adopted. See [MIXED_SCALE_PLAYERS.md](MIXED_SCALE_PLAYERS.md).

## 2026-08-01 — Make mixed-scale players opposing combatants

Allow humans and Brontide to damage and defeat each other in the feasibility lab. Humans receive one stylized energy blaster resolved by a server raycast; Smash, Charge, Beam and sustained kaiju contact can damage humans. Both roles retain native Humanoid death and the manual role-preserving respawn lifecycle.

Disable Roblox's automatic passive Humanoid regeneration for the lab. It otherwise changes shots-to-defeat during a sustained exchange and makes damage tuning less legible. Any future healing will be an explicit server-owned mechanic with its own evidence gate.

Direct full-rig collision remains disabled because client-owned articulated giant limbs create an avoidable flinging and exploit surface. A single smooth, massless contact hull physically blocks human characters, while a throttled server overlap owns contact damage and clamps knockback. This satisfies the requested physical confrontation while keeping the damaging outcome authoritative. The tuning and the stability of even this bounded proxy remain hypotheses until a physical two-device test.

## 2026-08-01 — Replace glowing damage placeholders with localized authored rupture

Keep the server-owned `Intact`, `Damaged`, and `Collapsed` gameplay states, but add a separate fixed-width surface-zone string updated on every accepted hit. Smash, Charge, and Beam provide only server-derived impact geometry; the server quantizes it and replicates compact durable state. Clients render at most two non-physical rupture marks per damaged structure and reuse the existing debris pool for transient chips.

Basis: direct stakeholder playtest feedback identified the cooling tower's persistent orange Neon `EnergyFracture` slab as unconvincing. Inspection confirmed that repeated hits discarded location and attack type and emitted no new visual event unless the whole structure state changed. Roblox-native attributes, spatial geometry, and local cosmetic instances solve that observed failure without a framework, runtime CSG, EditableMesh permission, or authoritative rubble. Two marks, twenty-four zones, primitive cavity construction, and attack-specific diameters are provisional implementation thresholds pending physical-phone comparison.

## 2026-08-01 — Enlarge rupture depth and animate Smash after the phone gate

Keep the authoritative surface-zone contract, but replace each small five-part mark with at most eight client-local parts: three overlapping dark cavity layers and five displaced non-emissive rim pieces. Clamp the authored attack shape against the struck face so small buildings do not receive oversized geometry. Increase the provisional Smash diameter and give Charge and Beam distinct wide-tear and narrow-scar proportions.

Add a dependency-free procedural Smash pose on the existing R15 shoulder and waist motors: brief eased anticipation, fast downstroke, one impact callback, and eased recovery to the captured joint offsets. The client may predict this presentation for responsiveness, but it sends only the existing ability request at the strike moment; the server retains cooldown, role, round, character, spatial-query, damage, and result authority. A matching result sequence suppresses duplicate local playback, while non-predicted Studio requests still exercise the animation path.

Basis: the first physical-phone screenshot proved location correctness but showed that the twelve-stud circular mark read as a small flat bullet hole relative to Brontide and the cooling tower. The enlarged eight-part ceiling and animation timings are provisional H7/H10 parameters. If the second phone comparison still reads as decoration, preserve the server metadata and replace only the renderer with original archetype-specific breakaway meshes rather than adding runtime CSG or an external destruction framework.

## 2026-08-01 — Recompose Arc Power Plant around functional visual grammar

Remove the cyan floor-light grid and organise the district as an original stylized thermal plant: two cooling towers and basins feed visible coolant/service pipes toward the generation halls; a separate fenced switchyard contains repeated transformer bodies, insulators, breakers and elevated busbars; an outgoing gantry points toward the grid; concrete service lanes retain traversal space.

Basis: a physical-phone screenshot showed that the current district read as generic box buildings on a glowing plaza with one visible cooling tower. DOE, National Grid and EDF sources consistently tie recognizable power generation to grouped turbine/generator or heat-recovery buildings, cooling infrastructure, dense pipes/cables, voltage step-up equipment, switchgear/busbars, site control and transmission connections. The blockout uses original native primitives, no real operator branding, no external asset, and no claim of engineering-scale fidelity. Uncoached child recognition and phone performance remain the gates.

## 2026-08-01 — Supersede the overwritten Smash tween with dedicated visual-shell pivots

The previous regression counted animation starts and phase recovery, but a physical-device tester saw no wind-up or body motion. Roblox's avatar animation pass overwrote the tweened shoulder and waist transforms before display. Attach Brontide's visual shell through dedicated `Motor6D` pivots, animate their persistent `C0` offsets through a bounded `0.87`-second wind-up/strike/hold/recovery sequence, and measure displacement of named shell parts rather than treating internal phase changes as visual proof.

The client still sends the existing basic-attack intent only at the authored impact moment. Cooldown, role, round state, hitbox, targets, damage, and result remain server-authoritative. Six studs of visible shell displacement is a provisional engineering gate, not evidence that the timing feels powerful.

## 2026-08-01 — Replace the flat backdrop with bounded native terrain and skyline contrast

Use Roblox smooth Terrain for broad relief rather than adding hundreds of Parts or importing a terrain plugin/heightmap. Keep roads, spawn areas, the park promenade, and destructible foundations on the validated flat movement plane; place park mounds at open-space edges, native Water and overlapping Sand banks under Azure Lake, a tall layered Rock/Grass massif behind Mount Brontide, and low relief around the city perimeter. Increase selected central tower heights, add four bounded destructible infill buildings, and replace one giant city slab with separate urban pads so native grass breaks up the built area.

Basis: player-height iPhone inspection showed a continuous level slab and many roofs near Brontide's own height, so labels—not landform or skyline—carried district recognition. Roblox documents native smooth-terrain fill operations and recommends built-in materials, streaming, instance reuse, and representative-device profiling for large mobile worlds. The automated blockout now contains `37` destructibles and `1,064` world Parts beneath a provisional `1,250`-Part ceiling; the operation count, six-stud Smash displacement, mountain height, park-mound height, terrain cell count, skyline proportions, traversal, and subjective city credibility remain provisional test gates.

## 2026-08-02 — Pull a bounded capturable-turret feasibility slice ahead of the scout drone

Use the four user-placed turret models as sanitized visual shells only. Remove every imported script, remote, sound, effect, mover, value, and seat behaviour; anchor their parts; register exact provenance and audit results; and supply gameplay through one strict source-controlled server service. Turrets use neutral/capturing/contested/owned state, pause while contested, require an uninterrupted opposing capture, select only living visible opposing players, and stop firing unless owned and uncontested.

Do not implement all attacks as the same recoloured ray. Machine-gun and minigun shots use server raycasts with different wind-up/cadence presentation. Cannon shells and rockets are bounded logical projectiles using fixed-rate swept server raycasts; cannon impacts are smaller and faster, while rockets are slower, more visible, and apply a larger server-owned radius. Clients render only fixed-cap non-physical trails, projectile bodies, lock cues, and impacts.

Basis: the stakeholder already placed turret candidates and requested MOBA-like capture plus distinct projectile behaviour. Roblox's official weapon guidance distinguishes instantaneous and physically simulated hit checks and separately documents moving rocket effects and exploding projectiles. Roblox also requires authoritative gameplay state and warns that Creator Store models are a common backdoor source even after moderation. Exact capture, lock, range, cadence, speed, damage, radial falloff, targeting priority, visual treatment, and whether the mechanic improves this game are H12 hypotheses. The exception to the former drone-first order is limited to one four-turret feasibility scene; neither system may be populated map-wide before its readability, multiplayer, security, and device-performance gates pass. See [TURRET_SYSTEM.md](TURRET_SYSTEM.md).

## 2026-08-02 — Separate the first rogue-kaiju AI from its replaceable visual

Build one server-owned rogue-kaiju actor before the scout drone so the complete turret system has a non-player target. Clone its visual from the Edit-visible `EnemyTemplates` folder at a movable tagged spawn. Keep target acquisition, bounded native pathfinding, telegraphed melee, health, damage, and defeat in strict source code; use an original primitive proxy until the map owner imports a model that passes the reuse audit.

Basis: the stakeholder owns map composition, model importing, and testing while Codex owns code and model contracts. Separating `EnemyRoot` and stable template/spawn names from visual descendants lets either side iterate without overwriting the other. Exact movement and combat numbers remain untested hypotheses, and the actor cannot be multiplied before physical-device and multiplayer evidence.

## 2026-08-02 — Rig the visible turret shells and deepen the first enemy before multiplication

Convert each of the four sanitized turret shells into an anchored-root assembly with native yaw and pitch `Motor6D`s. Weld the real body and weapon geometry to those carriers, place a moving visual muzzle at the barrel, and have clients ease the presentation toward the target position selected by the server. Retain the hidden anchored aim reference for deterministic authoritative hit resolution, and reject any rig whose motors or assembly root do not match the contract.

Expand the single `Riftback` actor from nearest-player chase into a bounded server-owned behaviour loop: patrol, FOV/line-of-sight vision, hearing, target hysteresis and memory, last-known-position investigation, blocked/stuck path recovery, swipe/lunge selection, cumulative-damage stagger, low-health enrage, and defeat. Animate its original jointed proxy locally from replicated state while leaving target selection, movement, hits, health and defeat authoritative.

Basis: the visible shell—not a proxy overlay—must aim for the placed model to communicate turret intent. Roblox assemblies and `Motor6D` solve two mechanical pivots without a Blender round trip, while native pathfinding and `Path.Blocked` avoid a custom navigation implementation. A Studio smoke test measured non-zero displacement of visible shell geometry on all four turrets (`2.319`, `3.693`, `0.984`, and `3.613` studs), but orientation, state readability, mobile performance and multiplayer fairness remain H12/H13 human-test gates.

## 2026-08-02 — Require royalty-free commercial use and legitimate underlying IP separately

An adopted external asset must cost `£0` and permit use and necessary modification in a monetised Roblox experience without purchase, subscription, revenue share, royalties, usage fees, or later payment triggered by earnings. Separately, the uploader must own the work or have authority to license every protected element. A free or permissive fan upload cannot grant rights to someone else's character.

Basis: Creator Store terms govern use on Roblox services, but Roblox's IP rules still require ownership or permission for underlying content. The quarantined `Mire Godzilla` candidate was therefore removed despite being listed free; it also contained four scripts/modules and an unprofiled 119-mesh visual. Original work or a demonstrably authorised commercial asset remains the replacement route.
