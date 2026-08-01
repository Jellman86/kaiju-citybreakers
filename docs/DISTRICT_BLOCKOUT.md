# District blockout and destructible archetypes

This document fixes the Phase 2C greybox scale and route before the district expands. It applies the reusable destruction contract to three distinct silhouettes while the geometry remains cheap to change.

## Evidence boundary

Roblox's modular-environment workflow recommends a small reusable kit, consistent pivots, and repeatable grid increments. Roblox's performance guidance recommends built-in materials, reuse, streaming, anchored static geometry, and simple custom collision rather than unnecessary mesh fidelity. See [Assemble modular environments](https://create.roblox.com/docs/tutorials/use-case-tutorials/modeling/assemble-modular-environments), [Design for performance](https://create.roblox.com/docs/performance-optimization/design), and [Improve performance](https://create.roblox.com/docs/performance-optimization/improve).

The exact footprints, health values, routes, colours, and part ceilings below are **provisional project thresholds**. They are derived from the live prototype and must be revised when navigation, readability, or device evidence disagrees.

## Live player metrics

Measured in Studio on 2026-08-01 before the Phase 2C change:

| Metric | Value | Blockout consequence |
| --- | ---: | --- |
| Brontide extents | `15.6 × 24.7 × 28.1` studs | Required approaches stay at least 34 studs wide; 40 studs is preferred where the camera must turn. |
| Walk speed | `24` studs/second | A 48-stud frontage takes about two seconds to pass at full walk speed. |
| Charge budget | approximately `48` studs | The north pair frames the route without putting a solid obstacle directly across one charge. |
| Basic attack box | `30 × 24 × 26` studs | Damage hitboxes reach the edge of the plaza but do not trigger from the avenue centre accidentally. |
| Configured camera arm | `24–42` studs | Required routes avoid tight interiors and preserve broad exterior sightlines. |

Use a 2-stud structural grid and repeat façade details at 6–8 stud intervals. Every archetype uses a ground-centred origin and aligned `Intact`, `Damaged`, and `Collapsed` variants so a later Blender replacement can keep the same pivot and contract.

## North-to-south teaching route

```text
spawn / safe read at z=69
      warehouse west  ←  34-stud avenue  →  signal tower east
                         market crossing
                       objective city gate
                 harbour shell  ←→  energy substation
```

- **Introduce:** the low warehouse and tall tower present two breakable silhouettes beside the starting route without blocking it.
- **Develop:** static market buildings and the crossing preserve scale cues while the player approaches the gate.
- **Test:** the gate remains the explicit two-smash objective across the avenue.
- **Release/vista:** the cyan substation behind the gate gives a visible destination and future energy-reward anchor.

No new hard gate or reward logic is introduced. Whether players understand that all four structures can break remains an uncoached readability question.

## Archetype briefs and budgets

| Archetype | Position | Footprint / height | Health | Profile | Authored parts | Role |
| --- | --- | --- | ---: | --- | ---: | --- |
| North warehouse | `(-58, 0, 55)` | `48 × 30 / 16` | 3 | Metal | 28 | Low, broad teaching target with loading doors and roof slabs. |
| North signal tower | `(57, 0, 55)` | `28 × 28 / 53` | 4 | Concrete | 31 | Two-kaiju-height orientation landmark and tougher target. |
| Harbour substation | `(57, 0, -68)` | `40 × 32 / 16` | 3 | Metal | 27 | Cyan energy landmark and future objective/reward anchor. |

The part counts include all three visual variants, both collision proxies, and the damage hitbox. The provisional ceiling is 35 `BasePart` instances per full archetype, one queryable damage hitbox, and one active collision proxy. Decorative geometry is anchored and excluded from collision, touch, and queries.

## State readability

- `Intact` uses clean silhouette edges and regular repeated details.
- `Damaged` changes the main value group, breaks alignment, and adds a small amber damage seam.
- `Collapsed` lies below Brontide's body mass as a low chunk field; gameplay uses a single 1.5-stud collision slab rather than decorative rubble.
- Concrete, metal, and lightweight effects are selected by the existing material-profile table. No state adds authoritative loose physics.

## Reuse and replacement

Phase 2C uses Roblox primitives and built-in materials through one source-controlled builder. The official Modern City kit remains a composition and pivot reference; importing its thousands of mesh parts and scripts would not help answer the current scale, route, and state-readability questions.

If these footprints pass, their ground-centred origins, names, hierarchy, proxy dimensions, and effect profiles become the handoff contract for original Blender meshes. Art replaces visual descendants only; gameplay hitboxes, collision proxies, attributes, tags, and server state remain stable.

## Verification gates

- Four unique destructibles register without diagnostics.
- Each new structure advances through its configured health to `Collapsed` using the real server hitbox path.
- Only one visual variant is visible on the client at a time.
- Every decorative part remains non-colliding, non-touching, and non-queryable.
- The main avenue remains unobstructed before and after all three structures collapse.
- The world-instance and 3D-object increase is recorded; render-pass numbers are recorded only when SceneAnalysisService returns valid non-zero data.
- A later two-client test confirms state agreement and late-stream reconstruction before multiplying these archetypes into a district.
