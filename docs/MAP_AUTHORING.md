# Hand-authored map workflow

The playable environment is authored visually in Roblox Studio. `Workspace.KaijuFeelLab` owns roads, buildings, props, landmarks, tags, attributes, and destruction packages; `Workspace.Terrain` owns sculpted land and water. Rojo-managed scripts remain owned by `src/` and must not be edited in Studio.

The canonical map sources are:

- `src/world/KaijuFeelLab.rbxmx`
- `src/world/Terrain.rbxmx`

They are Roblox XML model sources tracked through Git LFS. A generated `build/KaijuCitybreakers.rbxlx` is still disposable.

## Ownership and visible authoring helpers

- The human map owner owns Terrain sculpting, visual composition, prop/model placement, and playtesting.
- Codex owns all gameplay code, AI, networking, security cleanup, tags, attributes, collision/query contracts, and source integration.
- `Workspace.Terrain` contains the complete editable `BrontideTerrainV1` terrain. The captured baseline contains about `1.14 million` occupied cells; the runtime must never regenerate over non-empty authored terrain.
- `Workspace.KaijuFeelLab.AuthoringGuides` is deliberately visible only in Edit mode. Select it and press `F` to frame the full `1520 × 1220` terrain boundary. It also contains an approximately 70-stud Brontide reference and a six-stud human reference for truthful scale decisions.
- `Workspace.KaijuFeelLab.AuthoringInbox` is the handoff location for models the map owner imports or positions for Codex. It is saved as a sandboxed model and removed when Play starts. Codex audits provenance, licence, scripts, remotes, audio, physics, collisions, and performance before moving accepted geometry into a gameplay folder.
- `Workspace.KaijuFeelLab.GameplayMarkers` contains visible, movable source objects used by code. Move `RogueKaijuSpawn` to choose the first enemy's start position; do not rename it or remove its `EnemySpawn` tag.
- `Workspace.KaijuFeelLab.EnemyTemplates.RogueKaijuTemplate` is an Edit-visible, articulated original proxy. Its `EnemyRoot` is the anchored assembly root and its named `Rig_*` motors drive limbs, head and tail. Imported visual geometry may replace its body only after Codex audits and adapts the rig; preserve the containing template and spawn contract.
- Each model under `Workspace.KaijuFeelLab.Turrets` contains a `TurretRig` built from the actual shell. `RigRoot`, `YawMotor`, `PitchMotor`, their welded visual groups and `VisualMuzzle` are one validated anchored-root assembly. Move or rotate the complete top-level turret model; do not move individual rig parts, change joint names, or anchor/unanchor descendants. The hidden `AimAssembly` is a technical authoritative reference, not the visible weapon.
- Factory objectives remain Edit-visible top-level models tagged `ReinforcementFactory`. The map owner chooses the building and city, then positions `CaptureZone`, `TankSpawn`, `HelicopterSpawn`, `GroundRoute/Node01...`, and `AirRoute/Node01...`. Codex owns the tag, attributes, linked destructible ID, query parts, security audit, and code integration. See [FACTORY_OBJECTIVES.md](FACTORY_OBJECTIVES.md).

Terrain, templates, markers, and accepted gameplay objects are intentionally unlocked. The runtime reads or clones them; it must not procedurally replace the saved authored world.

Do not press Play after inserting a new third-party model until Codex has inspected it. Sandboxing reduces the capability of embedded scripts but does not make unknown code trusted. Repository checks reject executable scripts inside the captured world.

## Editing

1. Run `./scripts/check.sh` and open `build/KaijuCitybreakers.rbxlx` in exactly one Roblox Studio instance.
2. Do not connect Rojo while moving or sculpting the map. Rojo cannot write Studio changes back to these model files.
3. Work only in Edit mode. Use **Home → Terrain → Editor** for terrain and select descendants of `Workspace.KaijuFeelLab` for object work. Select `AuthoringGuides` and press `F` whenever you need the full-world overview.
4. Roblox's Terrain Editor provides Select, Transform, Draw, Sculpt, Smooth, Paint, Flatten, Fill, Sea Level, and Replace tools. Prefer broad low-frequency forms first, then smooth and paint; preserve clear kaiju routes and human cover at their measured scales.
5. Use anchored geometry for static scenery. Keep gameplay buildings inside the existing destructible hierarchy and preserve their tags, IDs, hitboxes, collision proxies, and Intact/Damaged/Collapsed variants.
6. Put new third-party candidate models under `AuthoringInbox`, position them where you want, save, and hand the place back to Codex before Play. Do not add or edit gameplay scripts in Studio.
7. To give Codex a placed object to integrate, use a descriptive name, leave it under `AuthoringInbox`, and position/scale it in the intended location. Codex preserves that transform while auditing and adding tags, attributes, collision/query parts, and code contracts.
8. For the first factory, place one candidate factory building plus tank and helicopter candidates in `AuthoringInbox`, and place simple marker Parts where each vehicle should spawn and travel. Do not insert gameplay scripts; Codex will convert the accepted hierarchy to the factory contract without changing your chosen transforms.
9. Choose **File → Save to File**. Save the open place at its existing ignored path under `build/`.
10. From the repository root, run:

   ```sh
   python3 scripts/capture-map.py build/KaijuCitybreakers.rbxlx
   ./scripts/check.sh
   ```

11. Reopen the newly generated place and verify the map in Edit mode before committing. Codex prepares the testable build; the map owner performs the requested device/gameplay test and reports observations.

Use `--world-only` when only objects under `KaijuFeelLab` changed, or `--terrain-only` when only Terrain changed. This avoids rewriting the other large source unnecessarily.

The capture command extracts only `Workspace.Terrain` and `Workspace.KaijuFeelLab`; it deliberately ignores Studio copies of scripts and all other services. Play mode preserves an authored map. The procedural generator runs only as a fallback when those sources are absent from an intentionally empty place.

## Visual ownership

The human map designer owns composition, sightlines, skyline, zone identity, terrain silhouette, prop placement, and whether a place feels convincing. Codex may provide measured checks, technical constraints, implementation support, and screenshot-based feedback, but must not treat object counts or procedural coordinates as proof of visual quality.

## Sources

- [Roblox Terrain Editor](https://create.roblox.com/docs/studio/terrain-editor)
- [Roblox environmental terrain](https://create.roblox.com/docs/environment/terrain)
- [Rojo project format and model paths](https://rojo.space/docs/v7/project-format/)
- [Rojo sync details](https://rojo.space/docs/v7/sync-details/)
