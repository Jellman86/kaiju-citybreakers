# Mixed district park/plaza blockout

Phase 2D begins with one optional west-side loop and a broad combat-release space. It deliberately does not multiply dense streets yet: the layout must first prove orientation, traversal, camera clearance, and scene-cost headroom.

## Evidence boundary

Roblox recommends continuously playtesting greybox layouts for orientation, choice overload, unintended bypasses, and intended feeling before replacing them with art. Its performance guidance recommends measuring object density, anchoring static geometry, disabling unnecessary collision/query/touch and small-part shadows, reusing assets, and avoiding layered transparency. See [Greybox your environment](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/greybox-your-environment), [Design for performance](https://create.roblox.com/docs/performance-optimization/design), and [Improve performance](https://create.roblox.com/docs/performance-optimization/improve).

The route and budgets below are project inferences and provisional thresholds. Synthetic navigation can disprove a blocked route but cannot prove that a player notices, understands, or enjoys the branch.

## Pre-change evidence

Captured in Studio at commit `dbf9b3e` on 2026-08-01:

| Measure | Baseline |
| --- | ---: |
| World descendants | `274` |
| World `BasePart` instances | `213` |
| World models | `41` |
| World lights | `10` |
| SceneAnalysis total instances | `921` |
| SceneAnalysis 3D objects | `309` |
| Authored world bounds | `x -110…110`, `z -128…92` |

The cross street was not a usable branch because `MarketWest` and `MarketEast` occupied its road surface. Their first Phase 2D change is to move behind the southern sidewalk, keeping the critical avenue unchanged while making the crossing truthful.

## Layout contract

```text
                       north connector / spawn return
main avenue ───────────────────────────────────────┐
     │ warehouse       36+ stud camera turn       │
     │                                      park landmark
     │            grass perimeter ┌───────────────┤
     │                            │   open plaza  │
crossing at z=24 ═════════════════╧═══════════════╝
     │ repositioned market shells
     │ objective gate at z=-28 (still mandatory)
```

- **Critical path:** spawn → avenue → gate remains direct and unchanged.
- **Optional loop:** crossing → plaza south edge → open centre → north connector → spawn area.
- **Pacing:** destructible north pair introduces the verb; the plaza is a lower-density movement/camera release; the gate remains the test.
- **Guidance:** continuous asphalt and pale paving provide leading lines; green ground differentiates the rest space; one amber/cyan landmark anchors the west edge.
- **No bypass:** every park connection rejoins north of the city gate. Two primitive district cordons join the gate towers to the foundation edges, so the collapsed central gate is the only southbound opening.

## Metrics and budgets

| Item | Provisional threshold | Basis |
| --- | ---: | --- |
| Required approach width | at least `40` studs | Brontide is 15.6 studs wide with a 24–42 stud camera arm. |
| Open plaza | at least `80 × 52` studs | Fits one charge budget and allows a full camera turn without a tight interior. |
| Perimeter clearance | at least `34` studs on required turns | Existing Phase 2C movement contract. |
| Added world parts | at most `40` | Keep the first expansion smaller than one-and-a-half destructible archetypes. |
| Added lights | `0` | Existing ten lights remain the scene-lighting baseline. |
| Decorative physics | `0` colliding/queryable/touchable parts | Trees, planters, rings, and trim are scale cues, not gameplay obstacles. |
| Materials | existing built-in palette only | Avoid asset, texture, and batch proliferation during layout testing. |

The foundation and road slabs may collide because they define traversal. Small foliage and landmark trim must be anchored with collision, touch, query, and shadow casting disabled.

## Verification gates

- The north–south critical path and objective remain unchanged.
- Synthetic navigation completes the full optional loop in both directions without a jump, snag, or gate bypass.
- The camera maintains its configured arm in the plaza centre when no authored geometry obstructs it.
- All added decorative parts satisfy the no-physics/no-shadow contract.
- The exact world and SceneAnalysis composition delta is recorded; triangle/draw results are reported only when the service returns valid view data.
- An uncoached player must later notice the branch, identify it as a park/plaza, and return to the objective without verbal guidance.

## Exact-commit result

Studio regression at commit `ea02de3` produced:

| Measure | Before | After | Delta |
| --- | ---: | ---: | ---: |
| World descendants | `274` | `323` | `+49` |
| World `BasePart` instances | `213` | `251` | `+38` |
| World models | `41` | `52` | `+11` |
| World lights | `10` | `10` | `0` |
| SceneAnalysis total instances | `921` | `970` | `+49` |
| SceneAnalysis 3D objects | `309` | `358` | `+49` |

The plaza measured `88 × 52` studs, the warehouse/plaza turn retained `36` studs, and every decorative part passed the anchored/no-collision/no-touch/no-query/no-shadow contract. Synthetic navigation completed the full loop in both directions. An explicit side-route probe exposed a legacy gate bypass during the working-tree test; the added cordons stopped Brontide at approximately `z=-23.3` with the gate intact. After two real validated smashes, the central route reached approximately `z=-58.8` with the gate collapsed.

Eight radial camera-collision probes from the plaza centre were unobstructed at both the configured 24- and 42-stud distances. The final SceneAnalysis triangle query returned zero passes, so it is treated as unavailable rather than evidence of zero render cost. Overhead and player-scale captures confirmed the green perimeter, civic rings, west landmark, and open centre; the first straight paving pattern was replaced because it read as parking bays.

The automated geometry gates pass. Whether an uncoached player notices the loop, reads it as a park/plaza, enjoys fighting there, and returns to the gate remains unproven.
