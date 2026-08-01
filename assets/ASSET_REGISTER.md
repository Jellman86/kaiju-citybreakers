# Asset register

No external production asset has been adopted. Current playable geometry and Brontide's visual shell use Roblox primitives; locomotion uses Roblox's built-in R15 avatar system.

Every external, Creator Store, commissioned, generated, or permissively licensed asset must be registered **before** it is added to the game source.

## Required fields

| Asset key | Type | In-game purpose | Creator/owner | Source URL or Roblox asset ID | Licence/permission | Cost | Local source | Modifications | Script/security inspection | Performance review | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| _Example only_ | Model | _What it solves_ | _Name_ | _URL/ID_ | _Exact terms_ | `£0` | _Path or N/A_ | _Summary_ | _Date/result_ | _Date/result_ | Candidate/Adopted/Removed |

## Rules

- `£0` is mandatory but not sufficient; permission, provenance, originality, safety, maintenance, and performance must also pass.
- Creator Store models are inspected in a disposable place. Unknown scripts, remotes, telemetry, monetization, and unnecessary dependencies are removed or the model is rejected.
- Protected entertainment IP and confusingly similar fan assets are rejected even when listed as free.
- Original Blender sources live in `assets/blender/`; reviewed game exports live in `exports/` and are not committed when covered by `.gitignore`.
- Generated assets record the generator, prompt/reference provenance, date, terms, and human review. Paid or quota-dependent generation cannot become required for implementation.
- Audio records attribution text when its licence requires it.

The official Roblox Modular Building Kit candidate remains documented in `docs/REUSE_AUDIT.md`; it is not adopted and therefore is not listed as an active asset here. Creator Store searches performed for the first visual pass produced no kaiju model that passed the originality, relevance, provenance, inspection, and mobile-fit gates.
