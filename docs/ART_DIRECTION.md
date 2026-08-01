# Art direction

## Visual thesis

Stylized tokusatsu spectacle: chunky original monsters, miniature-like architecture, readable silhouettes, saturated emergency lighting, and dramatic weather. The world can look impressive without chasing realism.

## Why this direction

- Toy-like buildings make authored destruction states believable.
- Large, simple forms remain legible on phones.
- Stylization lowers texture and geometry cost.
- It supports Mild content without realistic injury.
- Original silhouettes are easier to distinguish from licensed kaiju IP.

## Shape language

- Kaiju: one dominant mass, one recognizable crown/head shape, one locomotion signature, and one power motif.
- Human defence: angular, manufactured, modular, and visibly smaller.
- City: broad value groups, oversized rooftop details, clear destructible seams, and strong district colour coding.

## Starter kaiju constraints

- Must read clearly at thumbnail size.
- Avoid dorsal plates, facial proportions, roars, poses, colour layouts, or power effects strongly associated with an existing franchise character.
- Keep the first rig relatively simple: approximately 45–65 deforming bones, with facial animation limited to jaw, eyes, and a few expression controls.
- Build one clean LOD and collision proxy before adding surface detail.

## Blender deliverable rules

- Work in metres with a documented Roblox scale conversion.
- Apply transforms before export.
- Use predictable names: `KJ_Brontide_Body`, `ENV_Warehouse_A`, `DEF_Drone_A`.
- Keep origin/pivot placement consistent between intact, damaged, and collapsed building variants.
- Export animation clips separately with stable names.
- Store `.blend` sources in `assets/blender/`; place generated FBX/GLB files in `exports/models/`.

## Colour direction

- City base: concrete grey-blue, warm windows, painted district accents.
- Energy: turquoise and electric violet, used sparingly.
- Defence warnings: amber and red-orange.
- Starter kaiju: dark mineral body with a single bright energy seam colour.

Final palette decisions should be made after concept silhouettes rather than treated as fixed branding.

## Effects hierarchy

1. Gameplay telegraphs must be clearest.
2. Ability identity comes next.
3. Destruction spectacle follows.
4. Ambient particles remain quiet.

Provide reduced camera shake and reduced flashing settings from the first polished build.

