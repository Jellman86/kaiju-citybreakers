# Kaiju Citybreakers

[![CI](https://github.com/Jellman86/kaiju-citybreakers/actions/workflows/ci.yml/badge.svg)](https://github.com/Jellman86/kaiju-citybreakers/actions/workflows/ci.yml)

Working title for a free-to-build, cooperative Roblox kaiju roguelite.

One to four players become original kaiju, break through a modular city, absorb unstable energy, choose mutations, and survive an escalating robotic defence force. The first release target is a short, replayable vertical slice rather than a large open world.

## Current status

Phase 2D mixed-district blockout, following the playable Phase 1 Kaiju Feel Lab. The repository currently contains:

- A scoped game design and sixteen-week roadmap.
- A free/open-source Roblox toolchain managed by Rokit.
- A Rojo project mapping for shared, server, and client code.
- A server-authoritative round state machine and client round controller.
- Art, performance, safety, testing, and original-IP constraints.
- A research ledger connecting major decisions to evidence or measurable hypotheses.
- Codified free-only, reuse-first, security, provenance, changelog, contribution, and release standards.
- A fixed-cap client debris pool with material-specific fragment presets and deterministic cleanup.
- Reusable warehouse, signal-tower, and electrical-substation greyboxes derived from live Brontide movement, camera, attack, and scale metrics.
- A west park/plaza loop with a broad camera-safe movement space, truthful crossing, objective-safe reconnect, and measured primitive budget.

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
| Move / aim / camera | `WASD` / mouse look | Left stick / right stick | Roblox thumbstick / drag |
| Charge | `Q` or Shift | Left trigger or `B` | `CHARGE` button |
| Smash | `E` or click | Right trigger | `SMASH` button |

The HUD follows Roblox's preferred input and changes its prompt when a player switches between keyboard/mouse, gamepad, and touch.
On keyboard and mouse, moving the mouse orbits the third-person camera and Brontide turns with its forward direction, keeping the creature's back toward the camera. The scroll wheel zooms, camera collision prevents wall clipping, and `WASD` remains camera-relative. Gamepad and touchscreen players retain Roblox's native camera and character facing.
Touch actions use a resolution-aware lower-right cluster: `SMASH` and `CHARGE` sit side-by-side when space permits and stack automatically on narrow or portrait screens.
An accepted charge surges Brontide roughly 48 studs over 0.6 seconds and layers a brief camera kick, cyan energy burst, and body highlight so the movement reads clearly at kaiju scale.

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
- [Release process](docs/RELEASE.md)
- [Security policy](SECURITY.md)
- [Game design](docs/GAME_DESIGN.md)
- [Research and validation ledger](docs/RESEARCH.md)
- [Reuse audit](docs/REUSE_AUDIT.md)
- [Dependency register](docs/DEPENDENCIES.md)
- [Asset register](assets/ASSET_REGISTER.md)
- [Playtest log](docs/PLAYTESTS.md)
- [Roadmap](docs/ROADMAP.md)
- [Technical design](docs/TECHNICAL_DESIGN.md)
- [Destruction system specification](docs/DESTRUCTION_SYSTEM.md)
- [District blockout and archetypes](docs/DISTRICT_BLOCKOUT.md)
- [Mixed district park/plaza blockout](docs/MIXED_DISTRICT.md)
- [Mixed-scale human and kaiju feasibility](docs/MIXED_SCALE_PLAYERS.md)
- [Multiplayer Studio regression](docs/MULTIPLAYER_TESTING.md)
- [Art direction](docs/ART_DIRECTION.md)
- [Free toolchain](docs/FREE_TOOLCHAIN.md)
- [Decisions](docs/DECISIONS.md)
