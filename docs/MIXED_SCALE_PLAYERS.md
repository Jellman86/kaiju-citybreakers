# Mixed-scale human and kaiju feasibility

Status: feasibility implementation in progress; physical-device and human playtest gates remain open.

## Conclusion

Roblox can support one ordinary human-scale player and one physically much larger kaiju player in the same server. The roles can use different character models, collision groups, cameras, movement metrics, attacks, and spawn locations while sharing one server-authoritative round.

This should be implemented as an **in-experience custom character system**, not by trying to publish an enormous standard marketplace avatar. Roblox's standard avatar-body specification deliberately keeps a Normal body within a maximum total height of `9.5` studs, while Roblox separately supports custom humanoid imports, custom `StarterCharacter` models, manual character loading, per-player camera settings, and `Model:ScaleTo()`.

The exact stable upper scale for this experience is not documented by Roblox. It is therefore a prototype and physical-device question, not something to infer from the existence of a scaling API.

## What is true now

- A classic avatar is approximately `5` studs tall; more humanoid avatars are commonly `6–6.5` studs tall.
- Current Brontide uses `Model:ScaleTo(4)` and measures approximately `15.6 × 24.7 × 28.1` studs. It is already physically larger than a human avatar, including its character assembly and spatial bounds; the camera and city cues strengthen that real difference rather than creating it from nothing.
- Every player currently becomes Brontide. There is no human role, role-specific spawn pipeline, or dual-scale traversal layer yet.
- The current `1400 × 1100` world, `24–42` stud kaiju camera arm, road widths, attacks, building hitboxes, and destruction timings were derived from the current 24.7-stud Brontide. Increasing only the character scale would invalidate those metrics.

Roblox documents one stud as approximately `28 cm`. A `60–75` stud kaiju would therefore read as roughly `17–21 m` tall and stand around `10–13` human avatar heights. That is genuinely giant while remaining a practical first feasibility band. A 100-metre kaiju would be roughly `357` studs tall and would require a fundamentally larger world, much longer visibility, different streaming assumptions, and much more distant cameras; defer that scale until the mixed-role prototype proves its value.

## Recommended architecture

### Role-owned character spawning

- Generalize `KaijuService` into a server-owned character/role service.
- Keep `Players.CharacterAutoLoads = false`; assign `Human` or `Kaiju` before spawning and make the server create or load the appropriate character.
- Human players use an ordinary R15 character at approximately `5–6.5` studs.
- Prototype the kaiju by reusing the existing R15 controller and Brontide shell at a provisional scale that produces `60–75` studs of height. A later Blender production asset should be imported as a custom humanoid rig rather than relying permanently on an enlarged marketplace avatar.
- Put all role metrics in data: bounds, walk speed, acceleration, jump/step height, camera distance, attack reach, turn rate, spawn clearance, and interaction layers.

### Two honest movement and camera scales

- Give the human a conventional close third-person camera and the kaiju a much longer collision-aware camera arm. Roblox cameras are local to each player, so the two clients do not need the same camera configuration.
- Derive streets, alleys, doors, cover, slopes, ledges, and objective reach from both measured characters. A human route and a kaiju route can overlap, cross, or be vertically layered, but neither may depend on decorative scale cues alone.
- Keep useful human-scale spaces—shelters, service tunnels, rooftops, power controls, evacuation routes or vehicles—so the human player has meaningful verbs rather than merely watching the kaiju.

### Collision and combat

- Use separate `HumanCharacter`, `KaijuCharacter`, `World`, and attack-query collision groups.
- Humans must be physically blocked by Brontide, but not by every articulated giant limb. Keep the full character groups non-colliding and add one smooth, massless contact hull that collides only with humans. This is an engineering hypothesis that must be replaced by a server-owned boundary if representative tests still produce unstable launching.
- Resolve contact damage, bounded knockback, Smash, Charge, Beam, and human weapon hits through server-validated spatial queries and explicit damage rules. A physics touch alone is never proof of a valid hit.
- Humans use a stylized energy blaster and ordinary Humanoid health/death. Brontide can also be defeated. Both roles respawn through the existing manual character lifecycle; no gore or realistic civilian framing is introduced.
- Keep movement and combat server-checked. Roblox normally gives clients authority over their character physics, so neither scale nor a reported touch is proof that a valid hit occurred.
- Treat a building collapse containing a human as an authored gameplay event: telegraph it, provide an escape route, and prevent permanent trapping. Cosmetic debris remains non-authoritative and locally bounded.

### Rendering, streaming, and mobile limits

- Keep the moving kaiju assembly compact: a small number of render meshes, simple invisible collision proxies, no decorative physical assemblies, and distance-appropriate mesh fidelity.
- Keep the large static world streamable and spatially coherent. Roblox warns that large moving assemblies can stream as a unit and cause network/CPU spikes; scaling should not multiply Brontide into hundreds of moving parts.
- Validate that a human can see the distant kaiju silhouette when needed. Streaming and effects can disappear outside loaded areas, so essential tracking requires deliberate model/LOD and UI treatment rather than assuming every distant detail exists on the client.
- Continue to resolve gameplay-critical distant queries on the server because client spatial queries only see streamed-in content.

## Smallest useful prototype

Build a separate two-client **Mixed-Scale Lab** before resizing the production city:

1. Spawn one ordinary R15 human and one `60–75` stud Brontide through role-specific server spawning.
2. Use one truthful city block containing a human doorway/interior route, a street, one `40–80` stud building, rooftop access, and one destructible exterior.
3. Give the human one useful objective and the kaiju one destruction objective that interact without requiring finished combat balance.
4. Test human, kaiju, and spectator sightlines; both cameras; spawn clearance; slopes; stairs; doorways; attacks; collapse escape; respawn; and role switching.
5. Run two-client security, streaming, memory, client/server frame-time, and network tests, including a physical phone as the lower baseline.

## Provisional gates

- The human and kaiju maintain at least a `10:1` standing-height ratio in actual model bounds.
- Neither camera clips into its own character or loses the other role during the teaching encounter.
- Direct contact cannot fling either player; all damage is reproduced by an authoritative query in a two-client test.
- Human fire can damage and defeat the kaiju, while Smash, Charge, Beam, and sustained contact can damage and defeat humans.
- The human completes a useful task and the kaiju completes a useful task without verbal coaching.
- The human can identify intact, threatened, and collapsed structures from their camera height.
- The physical-phone client remains at or above the project's provisional `30 FPS` destruction threshold, with no unbounded memory, instance, physics, or remote growth.

## Recommendation

Adopt mixed-scale play as a **feasibility spike**, not yet as the final game format. It is technically possible and would make the kaiju fantasy substantially more honest, but it changes the game from one-scale destruction into asymmetric multiplayer. Prove role fun and mobile stability in the Mixed-Scale Lab before rebuilding the five-zone map or designing human-versus-kaiju progression.

## Primary sources

- [Avatar Settings](https://create.roblox.com/docs/studio/avatar-settings) — ordinary avatar heights and global scale controls.
- [Character body specifications](https://create.roblox.com/docs/avatar/character-bodies/specifications) — standard avatar-body size limits.
- [Characters](https://create.roblox.com/docs/characters) and [importing character bodies](https://create.roblox.com/docs/art/characters/import) — custom humanoid rigs and using an imported model as a playable character.
- [`Model`](https://create.roblox.com/docs/reference/engine/classes/Model) — model scaling, bounds, pivots, and model LOD/streaming properties.
- [`Players`](https://create.roblox.com/docs/reference/engine/classes/Players) — manual character loading and server-controlled spawn timing.
- [Custom cameras](https://create.roblox.com/docs/workspace/camera) — per-player zoom and fully scriptable local cameras.
- [Collisions](https://create.roblox.com/docs/workspace/collisions) — collision groups and character collision filtering.
- [Network ownership](https://create.roblox.com/docs/physics/network-ownership) — distributed character/assembly physics and security consequences.
- [Instance streaming](https://create.roblox.com/docs/workspace/streaming) and [streaming techniques](https://create.roblox.com/docs/workspace/streaming/techniques) — large-world memory, moving assemblies, distant models, and server-side queries.
- [Improve performance](https://create.roblox.com/docs/performance-optimization/improve) — physics, collision, replication, client-local visuals, and streaming guidance.
- [Moving objects](https://create.roblox.com/docs/tutorials/use-case-tutorials/physics/create-moving-objects) — Roblox's approximate physical conversion of one stud to `28 cm`.
