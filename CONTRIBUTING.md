# Contributing

Thanks for helping with Kaiju Citybreakers. This is a research-led, original-IP Roblox project with a hard implementation budget of £0.

Read [PROJECT_STANDARDS.md](docs/PROJECT_STANDARDS.md), [RESEARCH.md](docs/RESEARCH.md), and [REUSE_AUDIT.md](docs/REUSE_AUDIT.md) before changing a core system or adopting an asset or dependency.

## Setup

```bash
git lfs install
rokit install
rojo plugin install
./scripts/check.sh
```

Use `rojo serve` for live Studio work. Files under `src/` own Luau source; do not independently fork those scripts inside Studio.

## Before implementing

1. State the current requirement and its success measure.
2. Search Roblox-native services and documented platform features.
3. Search Roblox-published packages or assets where relevant.
4. Search maintained, licence-compatible open-source packages.
5. Check [REUSE_AUDIT.md](docs/REUSE_AUDIT.md) for an existing decision.
6. Implement custom functionality only when the alternatives fail the current requirement, security, performance, IP, maintenance, or cost checks.

Record a material adoption or rejection in the reuse audit. Record design evidence or a testable hypothesis in the research ledger.

## Change workflow

1. Create a short branch such as `feat/destruction-feedback` or `fix/charge-cooldown` when work will be reviewed through a pull request.
2. Keep each change focused and preserve unrelated work.
3. Add or update tests and playtest instrumentation in proportion to risk.
4. Update `CHANGELOG.md` under `Unreleased` for notable behaviour, security, workflow, dependency, or asset changes.
5. Update the dependency or asset register when applicable.
6. Run `./scripts/check.sh`.
7. Complete the pull-request checklist with evidence, not only assertions.

## Commit messages

Use [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):

```text
type(optional-scope): concise imperative description
```

Accepted types are `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, and `chore`. Use `!` and a `BREAKING CHANGE:` footer for an incompatible contract change.

Examples:

```text
feat(combat): validate charge requests on the server
fix(destruction): ignore already-collapsed structures
docs(research): record first-minute onboarding evidence
```

## Non-negotiable contribution rules

- No paid dependency, paid service, paid asset, subscription requirement, or larger GitHub runner.
- No protected kaiju, entertainment franchise, copied branding, or inadequately licensed asset.
- No client authority over combat outcomes, rewards, progression, persistence, or destructible state.
- No unreviewed Creator Store scripts or opaque vendored code.
- No production change that bypasses the research, reuse, provenance, changelog, or verification requirements.

## Human testing

Protect player privacy. Record build, device class, player count, whether coaching occurred, observable results, and sample size. Do not record names, account IDs, chat, or unnecessary personal information. Synthetic tests validate engineering only and must not be presented as human evidence.
