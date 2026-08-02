# Project standards

This is the normative engineering and production policy for Kaiju Citybreakers. `AGENTS.md` summarizes agent-specific instructions; this document applies to every contributor and tool.

`MUST`, `MUST NOT`, `SHOULD`, and `MAY` indicate requirement strength. An exception requires a written entry in `docs/DECISIONS.md` with its owner, reason, risk, and removal or review condition.

## 1. Product invariants

- The project **MUST** be implementable for £0 using free tools, standard public-repository GitHub runners, included Roblox facilities, original work, and compatible free/open-source dependencies.
- The game **MUST** use original names, characters, silhouettes, audio, settings, and branding. Protected entertainment IP and confusingly similar imitation are prohibited.
- The target **MUST** remain Minimal or Mild: stylized destruction and robot combat, no gore or realistic civilian harm.
- The normal loop **MUST** remain completable solo. Multiplayer may enrich it but cannot be a prerequisite for the vertical slice.
- Interaction and UI **MUST** be designed mobile-first and verified on keyboard/mouse and gamepad.

## 2. Evidence before expansion

- A material mechanic or progression decision **MUST** cite applicable primary evidence or be labelled a hypothesis in `docs/RESEARCH.md`.
- Internal numerical gates **MUST** be labelled provisional unless a source establishes them.
- A prototype **MUST** measure the riskiest assumption before its content is expanded.
- Synthetic, developer, guided, and uncoached human tests **MUST** be distinguished in `docs/PLAYTESTS.md`.
- A tested decision **MUST** record build commit, device, player count, coaching, sample size, result, and consequence.

## 3. Reuse before custom work

For any non-trivial system or asset, evaluate candidates in this order:

1. Roblox-native service or engine feature.
2. Roblox-published package, template, or asset.
3. Maintained licence-compatible open-source package.
4. Original implementation or asset.

A candidate **MUST** pass the checklist in `docs/REUSE_AUDIT.md`. Adoption decisions **MUST** record source, version/asset ID, owner, licence or permission, cost, maintenance state, security inspection, performance impact, and replacement plan.

“Free” alone is insufficient. Do not import unknown scripts, unnecessary frameworks, telemetry, monetization, hosted runtime dependencies, protected IP, or physically expensive models. Roblox warns that unfamiliar packages can contain malicious scripts; inspect them in a disposable place before they approach the game source.

Custom code is appropriate when the requirement is small or game-specific and the candidate introduces more surface area, coupling, risk, or cost than it removes.

## 4. Dependencies and assets

- Runtime Luau dependencies **SHOULD** remain at zero until repetition or risk justifies one.
- Every adopted dependency **MUST** be pinned and entered in `docs/DEPENDENCIES.md` before merge.
- Every external or generated asset **MUST** be entered in `assets/ASSET_REGISTER.md` before merge.
- Unknown, custom, non-commercial-only, or incompatible licences **MUST NOT** be adopted.
- Adopted assets and dependencies **MUST** be commercially usable in a monetised Roblox experience for `£0`: no purchase fee, subscription, trial expiry, revenue share, royalty, usage fee, or payment triggered by future earnings. Required attribution or share-alike terms **MUST** be recorded and compatible with the intended distribution.
- The uploader **MUST** own the underlying work or have permission to license it. A free listing does not make protected fan IP safe to use.
- Paid, trial-limited, account-locked, quota-dependent, royalty-bearing, or revenue-share production requirements **MUST NOT** be adopted.
- Large Blender, model, and audio sources **MUST** use Git LFS. The two canonical hand-authored map models under `src/world/` are source assets and **MUST** use Git LFS. Generated places, arbitrary model exports, and renders **MUST NOT** be committed unless a written release process requires them.
- Blender source in `assets/blender/` owns original 3D work; reviewed exports go to `exports/`.

Public repository visibility does not itself grant a reuse licence. A project-wide code and asset licence requires an explicit owner decision; do not infer one.

## 5. Architecture and Roblox security

- Rojo-managed Luau in `src/` **MUST** remain the source of truth for scripts.
- Studio **MAY** own world composition, tags, attributes, terrain, lighting, and playtest state, but **MUST NOT** become an independent fork of Rojo scripts. Authored map changes **MUST** follow `docs/MAP_AUTHORING.md`; runtime bootstrap **MUST NOT** erase a pre-existing authored map.
- Production Luau modules **MUST** use `--!strict`.
- Combat, rewards, objectives, mutations, persistence, purchases, and destruction **MUST** be server-authoritative.
- Every client payload **MUST** be treated as hostile and validated against the rules in `SECURITY.md`.
- Cosmetic effects **SHOULD** run locally when they do not affect gameplay.
- New per-frame work, physics assemblies, collision fidelity, textures, particles, and network traffic **MUST** be justified against the performance budget.

## 6. Git and review

- `main` **MUST** remain buildable. Use short-lived branches for reviewed work once more than one contributor is active.
- Commit subjects **MUST** follow Conventional Commits: `type(optional-scope): description`.
- Commits **SHOULD** be small, intentional, and free of unrelated formatting or generated output.
- Pull requests **MUST** use `.github/pull_request_template.md`, pass CI, identify research/reuse implications, and disclose cost, licence, IP, security, and performance effects.
- `CHANGELOG.md` **MUST** receive an `Unreleased` entry for notable player behaviour, developer workflow, dependency, asset, compatibility, or security changes.
- Direct commits to `main` are tolerated during owner-only pre-alpha work. Enable required CI and pull-request protection before granting another contributor write access.

## 7. Versioning and releases

- Use Semantic Versioning tags in the form `vMAJOR.MINOR.PATCH` with optional prerelease identifiers.
- Versions below `1.0.0` represent initial development and may change contracts.
- Do not tag a version merely because code builds. A release requires a named scope, passing CI, a clean changelog section, recorded playtest evidence appropriate to the release, and a rollback point.
- Production publishing **MUST** use the clean, exact-commit Rojo artifact and live-server smoke test in `docs/RELEASE.md`; a live-synced Studio session is not a release artifact.
- Move `Unreleased` entries into a dated version section when tagging. Never rewrite a published version's changelog entry.

## 8. Definition of done

A change is done only when all applicable items are true:

- The requested behaviour works in the relevant Studio modes and device classes.
- Server/client trust boundaries and cleanup paths are verified.
- Formatting, lint, standards checks, and Rojo build pass through `./scripts/check.sh`.
- Versioned native Studio multiplayer regressions run before replicated gameplay content is multiplied, with results recorded against the exact implementation commit.
- Research, decision, reuse, playtest, dependency, asset, and changelog records are updated where applicable.
- No paid requirement, protected IP, secret, unreviewed external script, generated place, or unrelated change is introduced.
- Git contains a focused Conventional Commit and public CI passes.

## 9. Source basis

- [Keep a Changelog](https://keepachangelog.com/en/2.0.0/)
- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
- [Semantic Versioning 2.0.0](https://semver.org/)
- [GitHub contribution guidelines](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/setting-guidelines-for-repository-contributors)
- [GitHub CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
- [GitHub private vulnerability reporting](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/configure-for-a-repository)
- [Roblox packages](https://create.roblox.com/docs/projects/assets/packages)
- [Roblox client-server boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary)
