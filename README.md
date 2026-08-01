# Kaiju Citybreakers

[![CI](https://github.com/Jellman86/kaiju-citybreakers/actions/workflows/ci.yml/badge.svg)](https://github.com/Jellman86/kaiju-citybreakers/actions/workflows/ci.yml)

Working title for a free-to-build, cooperative Roblox kaiju roguelite.

One to four players become original kaiju, break through a modular city, absorb unstable energy, choose mutations, and survive an escalating robotic defence force. The first release target is a short, replayable vertical slice rather than a large open world.

## Current status

Phase 1 Kaiju Feel Lab and technical foundation. The repository currently contains:

- A scoped game design and sixteen-week roadmap.
- A free/open-source Roblox toolchain managed by Rokit.
- A Rojo project mapping for shared, server, and client code.
- A server-authoritative round state machine and client round controller.
- Art, performance, safety, testing, and original-IP constraints.
- A research ledger connecting major decisions to evidence or measurable hypotheses.
- Codified free-only, reuse-first, security, provenance, changelog, contribution, and release standards.

## First playable target

- One greybox city district.
- One original kaiju.
- One basic attack and one signature ability.
- Three destructible building states.
- One defence-drone enemy.
- One five-to-eight-minute round.
- Solo play plus two-client Studio testing.

The first gate is simple: moving and breaking buildings must feel good before progression, cosmetics, persistence, or extra kaiju are added.

## Prototype controls

| Action | Keyboard and mouse | Gamepad | Touchscreen |
| --- | --- | --- | --- |
| Move / camera | `WASD` / mouse | Left stick / right stick | Roblox thumbstick / drag |
| Charge | `Q` or Shift | Left trigger or `B` | `CHARGE` button |
| Smash | `E` or click | Right trigger | `SMASH` button |

The HUD follows Roblox's preferred input and changes its prompt when a player switches between keyboard/mouse, gamepad, and touch.

## Free toolchain

- Roblox Studio and its built-in MCP server.
- Blender and BlenderMCP.
- Git and GitHub Free.
- Rokit, Rojo, StyLua, and Selene.
- Krita/GIMP and Audacity if texture or audio editing is needed.

No paid assets, premium APIs, licensed character IP, or paid development dependencies are required.
The repository is public so its standard GitHub-hosted CI runs do not consume the private-repository minutes allowance.

## Local setup

```bash
git lfs install
rokit install
rojo plugin install
./scripts/check.sh
rojo serve
```

Then open Roblox Studio, open the Rojo plugin, and connect it to the local server shown by `rojo serve`.

## Documentation

- [Changelog](CHANGELOG.md)
- [Contributing](CONTRIBUTING.md)
- [Project standards](docs/PROJECT_STANDARDS.md)
- [Security policy](SECURITY.md)
- [Game design](docs/GAME_DESIGN.md)
- [Research and validation ledger](docs/RESEARCH.md)
- [Reuse audit](docs/REUSE_AUDIT.md)
- [Dependency register](docs/DEPENDENCIES.md)
- [Asset register](assets/ASSET_REGISTER.md)
- [Playtest log](docs/PLAYTESTS.md)
- [Roadmap](docs/ROADMAP.md)
- [Technical design](docs/TECHNICAL_DESIGN.md)
- [Art direction](docs/ART_DIRECTION.md)
- [Free toolchain](docs/FREE_TOOLCHAIN.md)
- [Decisions](docs/DECISIONS.md)
