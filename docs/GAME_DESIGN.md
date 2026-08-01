# Game design: Kaiju Citybreakers

Major design claims and provisional playtest gates are traced in [RESEARCH.md](RESEARCH.md). This document describes the intended experience; the research ledger distinguishes evidence from hypotheses.

## One-sentence pitch

Up to four players become original kaiju, smash through a reactive toy-like city, mutate during the run, and defeat the defence force before the island's unstable energy core overloads.

## Audience and rating target

- Primary audience: Roblox players roughly 9–15 who enjoy creatures, destruction, action, collecting, and cooperative play.
- Secondary audience: parents and older players who enjoy short roguelite runs and polished creature animation.
- Content target: Minimal or Mild. Buildings break, robots spark, and kaiju are knocked down; there is no gore or realistic civilian harm.
- Platforms: mobile first, then keyboard/mouse and gamepad.

The precise audience should be validated by watching the user's son and two or three friends play the greybox without coaching.

## Product pillars

### 1. Feel enormous immediately

Within thirty seconds, the player should topple something that looked large. Scale comes from animation weight, camera framing, sound, debris, frightened defence units, and environmental reactions—not just an oversized character model.

### 2. Destruction is the main verb

Buildings are not background decoration. Breaking them opens routes, releases energy, creates hazards, changes enemy navigation, and contributes directly to the round objective.

### 3. Better with friends, complete alone

Cooperation produces combo opportunities and revives, but enemy scaling and objective timing allow a solo player to complete every normal run.

### 4. Every run creates a story

Mutation choices, escalating defenders, district events, boss behaviour, and physics reactions should create memorable outcomes worth showing to friends.

### 5. Original monsters, readable powers

Each kaiju has a distinct silhouette, colour language, movement style, and combat role. Abilities must remain legible on a phone screen.

## Core loop

1. Select a kaiju in the social harbour hub.
2. Emerge into a city district.
3. Break marked infrastructure and defeat defenders to collect unstable energy.
4. Choose one of three temporary mutations at energy thresholds.
5. Complete two district objectives while the defence level rises.
6. Fight the district boss or trigger an escape sequence.
7. Receive research points, mastery progress, and cosmetic rewards.
8. Return to the hub and start another run.

## First-run experience

The player should reach the fantasy quickly:

- 0:00–0:10: choose the starter kaiju; one sentence explains the goal.
- 0:10–0:30: walk from the harbour into a fragile warehouse block.
- 0:30–1:00: destroy the first objective and earn the first mutation.
- 1:00–2:00: encounter drones and learn the signature ability.
- Before 5:00: see the boss, a major event, or a dramatic district transformation.

Tutorials use icons, highlighted targets, camera framing, and short prompts. Avoid dialogue boxes and long text.

## Vertical-slice round

### Map

One compact coastal district with:

- Harbour spawn.
- Warehouse block for initial destruction.
- Power substation as objective one.
- Downtown avenue as a spectacle corridor.
- Defence hangar as objective two and boss arena.

### Starter kaiju: working codename Brontide

- Role: durable close-range disruptor.
- Silhouette: broad shoulders, forward horn crown, heavy tail, glowing mineral seams.
- Basic attack: three-hit claw and shoulder combo.
- Signature: seismic tail slam with a clear ground warning.
- Mobility: short armoured charge.
- Passive: breaking structures fills a Resonance meter; full Resonance empowers the next ability.

All details are placeholders until silhouette and movement tests prove them fun.

### Enemy set

- Scout drone: circles and fires slow, readable shots.
- Defence turret: stationary area denial introduced after the first objective.
- Boss prototype: a single bipedal defence mech with three telegraphed attacks.

Only the scout drone is required for the earliest playable build.

### Building damage states

1. Intact: normal collision and visual state.
2. Damaged: cracked material, smoke, altered collision, energy leak.
3. Collapsed: authored rubble model, short-lived cosmetic debris, new traversable opening.

The server controls the state. Cosmetic debris is created locally and automatically cleaned up.

## Mutation examples

- Aftershock: tail slam releases a second delayed ring.
- Crystal Hide: temporary armour after breaking a structure.
- Storm Lungs: signature attack chains to nearby drones.
- Burrowing Momentum: charge travels farther after moving continuously.
- Team Resonance: nearby kaiju gain energy when this player breaks an objective.

The slice needs three choices total, not a complete mutation catalogue.

## Progression after the slice

- Kaiju mastery unlocks side-grade ability variants and cosmetics.
- Account research unlocks additional original kaiju.
- Seasonal city conditions alter runs without invalidating old content.
- No paid statistical advantage. Potential monetization is cosmetic only and is not required to implement the game.

## Future mode: Dominion

A competitive three-versus-three territory mode built from the same combat and destruction systems:

- Three energy reactors replace traditional MOBA lanes.
- Teams power their nest by controlling reactors.
- City destruction changes traversal and sight lines.
- NPC defenders target the leading team to reduce snowballing.
- Eight-minute match target.

Dominion begins only after the PvE vertical slice proves combat, destruction, networking, and device controls.

## Non-goals for the vertical slice

- Large open world.
- More than one playable kaiju.
- Persistent inventory or trading.
- Paid products or monetization UI.
- Complex quests or narrative cinematics.
- Fully simulated structural destruction.
- PvP balance.
- Licensed characters, sounds, locations, or branding.

## Success criteria

These are provisional vertical-slice gates, not external industry benchmarks. Change them when recorded playtests provide better evidence.

The vertical slice passes when:

- A new player destroys the first building within sixty seconds without verbal instruction.
- The basic attack, signature ability, and charge are understandable on mobile and desktop.
- One player can finish the round; two players can finish faster through cooperation.
- The server remains authoritative over damage and objective state.
- The district maintains at least 30 FPS on a representative lower-end mobile profile.
- Three consecutive two-client playtests complete without a blocking error.
- Testers ask to play another run before being shown progression or rewards.
