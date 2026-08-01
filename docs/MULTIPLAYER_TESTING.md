# Multiplayer Studio regression

The first automated multiplayer gate verifies durable destruction state with one existing client and one genuinely late client. It uses Roblox's native [`StudioTestService`](https://create.roblox.com/docs/reference/engine/classes/StudioTestService) and adds no package, service, runner, or cost.

## Evidence boundary

This is an engineering regression, not a human playtest or representative-device performance run. It proves server authority, replication, client reconstruction, and effect non-replay in separate Studio processes. It does not prove latency tolerance, subjective readability, control comfort, or live-service behaviour.

## Run from Edit mode

With Rojo connected and Studio in Edit mode, execute this through a plugin-security-capable Studio command surface:

```lua
local StudioTestService = game:GetService("StudioTestService")
local result = StudioTestService:ExecuteMultiplayerTestAsync(
	1,
	"KaijuMultiplayerDestructionV1"
)
print(result)
```

The argument intentionally starts one client. The server harness collapses the north warehouse through that client's normal ability remote, then calls `StudioTestService:AddPlayers(1)` to create the late client. `EndTest()` returns one structured pass/fail result to the Edit-mode caller.

## Acceptance contract

- The first client becomes ready and the normal round reaches `Active`.
- Three spatially valid, cooldown-respecting client attack requests collapse `north_warehouse`.
- Server state ends at health `0`, `Collapsed`, sequence `2`, with the collapsed proxy active and damage hitbox queryable.
- The existing client and late client independently report the same replicated attributes and show only the collapsed visual variant.
- The existing client observes the live collapse effect; the late client receives no historical debris burst.
- Any missing client, streamed model, state, visual, or proxy produces a bounded timeout and explicit failure reason.

## Production safety

The test entry points return immediately unless both conditions hold:

1. `RunService:IsStudio()` is true.
2. `StudioTestService:GetTestArgs()` exactly matches the versioned test name.

Clients submit observations only; the server owns pass/fail decisions and validates report types and player identities. GitHub Actions continues to lint and build the harness, but cannot execute Roblox Studio on the free hosted Linux runner. Record each executed Studio result against the exact implementation commit in [PLAYTESTS.md](PLAYTESTS.md).
