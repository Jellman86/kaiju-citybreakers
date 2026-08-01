# Multiplayer Studio regression

The automated multiplayer gate verifies durable destruction state and the mixed-scale role lifecycle with one existing client and one genuinely late client. It uses Roblox's native [`StudioTestService`](https://create.roblox.com/docs/reference/engine/classes/StudioTestService) and adds no package, service, runner, or cost.

## Evidence boundary

This is an engineering regression, not a human playtest or representative-device performance run. It proves server authority, replication, client reconstruction, and effect non-replay in separate Studio processes. It does not prove latency tolerance, subjective readability, control comfort, or live-service behaviour.

## Run from Edit mode

With Rojo connected and Studio in Edit mode, execute this through a plugin-security-capable Studio command surface:

```lua
local StudioTestService = game:GetService("StudioTestService")
local result = StudioTestService:ExecuteMultiplayerTestAsync(
	1,
	"KaijuMultiplayerCombatV2"
)
print(result)
```

The argument intentionally starts one client. The server harness collapses the north warehouse through that client's normal ability remote, then calls `StudioTestService:AddPlayers(1)` to create the late client. The first client is the kaiju and the late client is human. After the replication checks, the kaiju client leaves and the server must promote and reload the remaining player as the kaiju. `EndTest()` returns one structured pass/fail result to the Edit-mode caller.

## Acceptance contract

- The first client becomes ready and the normal round reaches `Active`.
- Three spatially valid, cooldown-respecting client attack requests collapse `north_warehouse`.
- Server state ends at health `0`, `Collapsed`, sequence `2`, with the collapsed proxy active and damage hitbox queryable.
- The existing client and late client independently report the same replicated attributes and show only the collapsed visual variant.
- The existing client observes the live collapse effect; the late client receives no historical debris burst.
- The first player has the replicated `Kaiju` role and the late player has the replicated `Human` role.
- Actual character bounds maintain a standing-height ratio of at least `10:1`; camera ranges are `58–105` studs for the provisional kaiju and `6–18` studs for the human.
- The full kaiju and human rigs remain in separate non-colliding groups; a smooth `KaijuContactHull` physically collides with the human group and not the world.
- A server contact query applies the configured human damage and keeps the explicit knockback within its velocity cap.
- The human cannot damage a structure by invoking a kaiju-only ability directly, but one normal human blaster request raycasts from the server-known character and damages Brontide by the configured amount.
- One normal kaiju Smash defeats the human; the same player respawns at full health with the `Human` role.
- The human client has a Fire touch action, no Smash touch action, and retains Roblox's native custom camera.
- When the kaiju client leaves through `StudioTestService`, the remaining human is promoted, reloaded and reaches at least 90% of the original kaiju's measured height.
- Any missing client, streamed model, state, visual, or proxy produces a bounded timeout and explicit failure reason.

## Production safety

The test entry points return immediately unless both conditions hold:

1. `RunService:IsStudio()` is true.
2. `StudioTestService:GetTestArgs()` exactly matches the versioned test name.

Clients submit observations only; the server owns pass/fail decisions and validates report types and player identities. GitHub Actions continues to lint and build the harness, but cannot execute Roblox Studio on the free hosted Linux runner. Record each executed Studio result against the exact implementation commit in [PLAYTESTS.md](PLAYTESTS.md).
