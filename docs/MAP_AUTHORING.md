# Hand-authored map workflow

The playable environment is authored visually in Roblox Studio. `Workspace.KaijuFeelLab` owns roads, buildings, props, landmarks, tags, attributes, and destruction packages; `Workspace.Terrain` owns sculpted land and water. Rojo-managed scripts remain owned by `src/` and must not be edited in Studio.

The canonical map sources are:

- `src/world/KaijuFeelLab.rbxmx`
- `src/world/Terrain.rbxmx`

They are Roblox XML model sources tracked through Git LFS. A generated `build/KaijuCitybreakers.rbxlx` is still disposable.

## Editing

1. Run `./scripts/check.sh` and open `build/KaijuCitybreakers.rbxlx` in exactly one Roblox Studio instance.
2. Do not connect Rojo while moving or sculpting the map. Rojo cannot write Studio changes back to these model files.
3. Work only in Edit mode. Use **Home → Terrain → Editor** for terrain and select descendants of `Workspace.KaijuFeelLab` for object work.
4. Roblox's Terrain Editor provides Select, Transform, Draw, Sculpt, Smooth, Paint, Flatten, Fill, Sea Level, and Replace tools. Prefer broad low-frequency forms first, then smooth and paint; preserve clear kaiju routes and human cover at their measured scales.
5. Use anchored geometry for static scenery. Keep gameplay buildings inside the existing destructible hierarchy and preserve their tags, IDs, hitboxes, collision proxies, and Intact/Damaged/Collapsed variants.
6. Choose **File → Save to File**. Save the open place at its existing ignored path under `build/`.
7. From the repository root, run:

   ```sh
   python3 scripts/capture-map.py build/KaijuCitybreakers.rbxlx
   ./scripts/check.sh
   ```

8. Reopen the newly generated place and verify the map in Edit mode before committing. For risky layout changes, also test Play, phone emulation, one physical phone, and two-client destruction state.

The capture command extracts only `Workspace.Terrain` and `Workspace.KaijuFeelLab`; it deliberately ignores Studio copies of scripts and all other services. Play mode preserves an authored map. The procedural generator runs only as a fallback when those sources are absent from an intentionally empty place.

## Visual ownership

The human map designer owns composition, sightlines, skyline, zone identity, terrain silhouette, prop placement, and whether a place feels convincing. Codex may provide measured checks, technical constraints, implementation support, and screenshot-based feedback, but must not treat object counts or procedural coordinates as proof of visual quality.

## Sources

- [Roblox Terrain Editor](https://create.roblox.com/docs/studio/terrain-editor)
- [Roblox environmental terrain](https://create.roblox.com/docs/environment/terrain)
- [Rojo project format and model paths](https://rojo.space/docs/v7/project-format/)
- [Rojo sync details](https://rojo.space/docs/v7/sync-details/)
