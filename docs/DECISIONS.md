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
