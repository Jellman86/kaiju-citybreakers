# Security policy

## Supported versions

The game is pre-release. Only the latest commit on `main` receives security fixes.

## Reporting a vulnerability

Do not open a public issue for an exploitable vulnerability. Use GitHub's [private vulnerability report](https://github.com/Jellman86/kaiju-citybreakers/security/advisories/new) and include:

- A concise description and likely impact.
- The affected commit, script, remote, or asset.
- Reproduction steps or a minimal proof of concept.
- Any suggested mitigation.
- Whether the issue may already have been disclosed elsewhere.

Reports are handled on a best-effort basis. This project does not currently operate a paid bug-bounty program.

## Security invariants

- The client sends intent; the server decides outcomes.
- Every client-triggered action is validated for type, finite numeric values where applicable, identity/ownership, game state, range, cadence, cooldown, and target validity.
- Client-to-server remotes are rate-limited and reject unknown fields or identifiers when practical.
- Rewards, progression, inventory, saves, purchases, and destruction never trust client-supplied outcomes or amounts.
- Replicated code and assets contain no secrets. Credentials and private keys never enter Roblox place files, source, logs, commits, or screenshots.
- External models and packages are isolated and inspected for scripts, remotes, network access, monetization, and unexpected assets before adoption.

Roblox's [client-server security guidance](https://create.roblox.com/docs/scripting/security/client-server-boundary) is the baseline for gameplay networking.
