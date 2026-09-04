# Urban Night TileSet

This theme replaces the prototype's upscaled 16px urban ground with native 64px tiles.

## Layout

- `ground/asphalt/`: individual wet-asphalt variants.
- `ground/brick_paving/`: individual rain-darkened brick ground variants.
- `ground/curbs/`: asphalt-to-sidewalk transition and curb pieces.
- `ground/road_markings/`: individual road-marking overlays baked on asphalt.
- `ground/sidewalk/`: individual concrete sidewalk variants.
- `ground/water/`: seamless pool-water variants.
- `ground/pool_edges/`: pool boundaries, corners, and ladder pieces.
- `decals/ground/`: transparent overlays such as puddles, oil stains, cracks, and manholes.
- `structures/`: exterior walls, interior walls, and door/window layers.
- `structures/roof_occluders/`: non-colliding roof pieces that fade when a unit enters the building.
- `props/`: interactable containers and larger Sprite2D props.
- `props/vehicles/all_orientations_v2/`: two-piece vehicles in both vertical and horizontal orientations.
- `structures/stairs/urban_shape_v10/`: nine independent `64×64` stair forms using the exact silhouettes and viewing angle from `urban.png` atlas coordinates `[0,12]` through `[2,14]`; material is refined to match the sidewalk set.
- `atlases/ground/`: Godot import targets, assembled from the individual tiles.
- `atlases/structures/` and `atlases/props/`: matching import targets for structures and props.
- `../../source/urban_night/ground/`: AI-generated source masters retained for future extraction.

## Godot Import

Create a TileSet atlas source for each file in `atlases/ground/` with a `64×64` texture region size:

- `asphalt_01.png`: 2 columns × 2 rows.
- `sidewalk_01.png`: 2 columns × 2 rows.
- `road_markings_02.png`: 5 columns × 4 rows. Includes lane dashes, crosswalks, four road edges, four rounded edge corners, and four parking-bay edges. The last three cells are intentionally empty.
- `curbs_01.png`: 4 columns × 2 rows; the final bottom-right cell is intentionally empty.
- `brick_paving_01.png`: 3 columns × 2 rows; the final bottom-right cell is intentionally empty.
- `pool_water_01.png`: 2 columns × 2 rows.
- `pool_edges_01.png`: 4 columns × 2 rows; the final bottom-right cell is intentionally empty.
- `decals_01.png`: 2 columns × 2 rows; use on a non-colliding decal layer.
- `exterior_walls_02.png`: 4 columns × 4 rows; four straight edges, four outer corners, four doorways, and four window segments. This is the current exterior wall atlas.
- `interior_walls_02.png`: 4 columns × 3 rows; four straight edges, four room corners, and four doorways. This is the current interior wall atlas.
- `roof_occluders_01.png`: 2 columns × 1 row; use only on `RoofOccluder`, with collision disabled.
- `doors_windows_03.png`: 4 columns × 3 rows. Row 1 is north/south/east/west closed doors; rows 2–3 are the matching left/right swing states. This is the current runtime door atlas; each swing arc runs from the closed leaf's free end to the opened leaf's free end around its hinge.
- `containers_01.png`: 2 columns × 2 rows.
- `vehicles_all_orientations_02.png`: 4 columns × 2 rows. Columns 1–2 contain vertical sedan/van pairs; row 1 columns 3–4 contain the horizontal sedan; row 2 columns 3–4 contain the horizontal delivery van. Each vehicle spans either `1×2` or `2×1` cells.
- `stairs_urban_shape_10.png`: 3 columns × 3 rows. It contains the exact nine `urban.png` stair forms: northwest, north, northeast, west, center, east, southwest, south, and southeast. Mark traversal cells as height transitions in the TileSet.

`major_props_01.png` contains non-uniform regions. Use it from `Sprite2D` or as manually defined TileSet atlas regions: `sedan_abandoned_a` is `128×192`; `medical_locker_closed_a` is `128×128`.

`furniture_01.png` also uses manually defined regions: sofa `128×64`, tall shelf `64×128`, refrigerator `64×64`, kitchen counter `128×64`, and bed `128×64`.

Use `structures/doors_windows/topdown_v3/` and `doors_windows_03.png` for runtime maps.

Use walls on `StructureHigh` and keep their gameplay collision/height data in the Godot TileSet. Use roof occluders above them and fade that layer when player units enter a room.

Keep TileMapLayer scale at `Vector2(1, 1)`. Assign gameplay custom data such as `terrain` and `height` in Godot rather than baking logic into the image files.
