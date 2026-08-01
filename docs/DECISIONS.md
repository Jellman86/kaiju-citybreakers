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
