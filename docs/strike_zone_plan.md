# Strike Zone UI + CPU Targeting — Plan & Progress

Source: game designer handoff. Recorded-clip/screenshot deliverables are ignored; verify in-editor instead.

## Status

- [x] Stage 1 — Strike zone data + visual (verified in-game)
- [x] Stage 2 — CPU pitcher targeting + reticle (verified in-game)
- [~] Stage 3 — Fade behavior (implemented; needs in-game check)

## Stage 1 — Strike zone data + visual

**`batter_data.gd`** add:

```gdscript
@export var zone_half_width: float = 0.22
@export var zone_bottom_y: float = 0.5
@export var zone_top_y: float = 1.05
```

World space, relative to home plate (0,0,0). Defaults ≈ MLB zone for a 1.8m batter. Could later be computed from height.

**`batter.gd`** add:

```gdscript
func get_strike_zone() -> AABB:
    return AABB(
        Vector3(-data.zone_half_width, data.zone_bottom_y, -0.1),
        Vector3(data.zone_half_width * 2, data.zone_top_y - data.zone_bottom_y, 0.2)
    )
```

**New scene** `gameplay/ui/strike_zone.tscn`
- `CanvasLayer` root (own layer, separate from score HUD)
- Child `Control` with `strike_zone.gd`

**`strike_zone.gd`**
- `@export var batter_cam: Camera3D`, `@export var batter: Node3D`
- `_process`: get `batter.get_strike_zone()`, project 8 corners via `batter_cam.unproject_position()`, compute screen rect, `queue_redraw()`
- `_draw`: `draw_rect()` semi-transparent fill + brighter outline

**Verify**
1. Zone overlays the plate, aligned with the pitcher's target
2. Zone moves when `zone_bottom_y` / `zone_top_y` change in the `.tres`

## Stage 2 — CPU pitcher targeting + reticle

**`pitcher.gd`**
- `@export var batter: Node3D`
- `func _pick_target() -> Vector3`: random point inside the batter's strike zone, small margin from edges
- `_start_pitch()` calls `_pick_target()` and sets `target_point` before aiming

**New scene** `gameplay/ui/pitch_reticle.tscn`
- `Control` drawing a small circle/crosshair
- `@export var pitcher: Node3D`, `@export var batter_cam: Camera3D`
- `_process`: project `pitcher.target_point` to screen, position itself there

**Verify**
1. Pitcher picks a spot in the zone, reticle appears there, ball crosses near it
2. Reticle moves to a new spot each pitch

## Stage 3 — Fade behavior

**Pitcher signals:** `windup_started` (new), `ball_pitched` (exists)

**Strike zone:** `windup_started` → tween alpha to 0.3; `ball_pitched` → hold 0.3; next `windup_started` (or `ball_dead`) → tween back to 1.0

**Reticle:** `windup_started` → fade to 0; reappear on next windup

**Verify:** full at-bat: full-opacity zone + reticle → windup → zone 30%, reticle gone → pitch → next pitch resets

## Watch for (all stages)

- `unproject_position` needs the point in front of the camera. Zone at Z=0, batter cam at Z=-1.5 → safe. (Actual cam is at Z=-2.)
- Jitter = `_process` fighting `_physics_process`. Project in `_process`, read data in `_physics_process`.
- When `gameplay.tscn` reloads between batters, UI must re-fetch the new batter's zone. Read fresh in `_ready()`; consider reconnecting to `bases_changed` or similar.

## Notes / Log

- Stage 1: `get_strike_zone()` offsets by `plate_position` so the zone stays at the plate while the batter runs. Overlay hides when BatterCam isn't current (fielding cam) or any corner is behind the camera. `StrikeZone` instance added to `gameplay.tscn`. Batter `.tres` files don't set the zone fields yet, so they use script defaults; add `zone_*` lines to a `.tres` to override. Headless load shows no script errors.
- Stage 2: `pitcher.gd` has `batter` + `target_margin` (0.03 m) exports; `_pick_target()` picks uniformly inside the zone (z = zone center). First target is picked deferred in `_ready` because Batter's `data` loads after Pitcher's `_ready`; each `_start_pitch` picks a new one. `pitch_reticle.tscn` (Control, under `UI`) projects `target_point`; hidden when BatterCam isn't current. Open item for Stage 3: the target changes at launch, so the reticle shows the previous pitch's spot until then — Stage 3 should pick the target at `windup_started` (reticle is hidden then) or earlier.

- Stage 3: added Pitcher WINDUP state (windup_time 0.7s) and windup_started signal. No ball_dead signal exists, so UI resets on GameState.play_state_changed(DEAD). Target is now picked reveal_lead_time (1.0s) before the windup and announced via new pitch_ready signal; zone/reticle return to full alpha then, dim/hide on windup_started. Pitcher wired into StrikeZone/Zone.
