# Free implementation toolchain

The project has a hard implementation budget of £0. Every required tool and dependency must be free to use for this project.

## Installed and pinned

- Rokit 1.2.0 — toolchain manager.
- Rojo 7.7.0 — filesystem-to-Studio synchronization.
- StyLua 2.5.2 — formatter.
- Selene 0.31.0 — linter.
- Git LFS 3.7.1 — versioning for production Blender, model, and audio binaries.

Versions are pinned in `rokit.toml` for reproducible setup.

## Included platform tools

- Roblox Studio, Studio MCP, Team Create, packages, version history, testing, device emulation, and Creator Hub analytics.
- Blender and BlenderMCP.
- Git and GitHub Free.

The source repository is public. [Standard GitHub-hosted Actions runners are free for public repositories](https://docs.github.com/en/billing/concepts/product-billing/github-actions) and therefore do not consume the private-repository minutes allowance. Do not select paid larger runners. The current workflow does not upload build artifacts or use a dependency cache.

[Git LFS has its own GitHub Free allowance](https://docs.github.com/en/billing/reference/product-usage-included) (currently 10 GB storage and 10 GB monthly bandwidth), including for this public repository. Keep `.blend`, model, and audio history deliberate; do not commit generated Roblox place files or renders.

## Optional free tools

- Krita or GIMP for textures and icons.
- Audacity for editing original or permissively licensed audio.
- Wally only after an external Luau dependency is justified.

## Dependency policy

- Prefer no dependency over a small dependency.
- Dependencies must have a compatible open-source licence and an active source repository.
- Record the reason and licence before adding a dependency.
- Do not use a hosted service that becomes required for local development or normal gameplay unless Roblox includes it at no additional cost.
- Do not use paid asset packs, paid plugins, subscription APIs, premium AI generation services, or licensed entertainment IP.

## Asset policy

- Primary visual assets are original Blender work.
- Placeholder assets may use Roblox primitives.
- Free external assets require provenance and licence records before inclusion.
- Audio must be original, Roblox-provided with valid usage rights, or permissively licensed with attribution tracked where required.
