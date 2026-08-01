# Dependency register

No third-party Luau runtime dependency is currently adopted. Roblox engine services are platform facilities, not vendored dependencies.

Every future dependency entry must include purpose, exact version/commit, source, licence, cost, runtime/development scope, maintenance status, security review, alternatives considered, and removal plan.

## Development tools

| Tool | Version | Scope | Source | Licence | Cost | Adoption reason |
| --- | --- | --- | --- | --- | --- | --- |
| Rokit | `1.2.0` | Development | [rojo-rbx/rokit](https://github.com/rojo-rbx/rokit) | MIT | Free | Pins and installs the Roblox toolchain. |
| Rojo | `7.7.0` | Development | [rojo-rbx/rojo](https://github.com/rojo-rbx/rojo) | MPL-2.0 | Free | Synchronizes reviewable filesystem source with Studio and builds places. |
| StyLua | `2.5.2` | Development/CI | [JohnnyMorganz/StyLua](https://github.com/JohnnyMorganz/StyLua) | MPL-2.0 | Free | Deterministic Luau formatting. |
| Selene | `0.31.0` | Development/CI | [Kampfkarren/selene](https://github.com/Kampfkarren/selene) | MPL-2.0 | Free | Roblox-aware Luau linting. |
| Git LFS | `3.7.1` | Development | [git-lfs/git-lfs](https://github.com/git-lfs/git-lfs) | MIT; bundled components retain their licences | Free within documented GitHub allowance | Versions large binary source assets without bloating normal Git objects. |
| `actions/checkout` | `v5` | CI | [actions/checkout](https://github.com/actions/checkout) | MIT | Free on the standard public runner | Checks out source for validation. Dependabot monitors the reference. |
| Game-development Codex skills (`roblox-luau`, `game-feel`, `game-ui-ux`, `level-design`, `performance-optimization`, `audio-design`) | commit `01b3eb41b359a6386e7d27c8a704baaa2a2fcfd9` | Optional development guidance; user-level installation | [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) | Apache-2.0 | Free | Adds focused Roblox, play-feel, cross-device UI, spatial design, profiling, and audio workflows. The audited packages contain Markdown only and add no game runtime code. |

Versions in `rokit.toml` and `.github/workflows/ci.yml` are authoritative for repository tooling. The optional Codex skills are pinned by commit in this register and installed under the developer's Codex home; they become available in a new Codex turn. Update this register and `CHANGELOG.md` in the same change as a version update.

## Evaluated but not adopted

Reusable candidates and rejection/defer reasons belong in [REUSE_AUDIT.md](REUSE_AUDIT.md), not in the active dependency table.
