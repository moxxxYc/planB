# Long Battlefield Camera And Soft Three-Lane Design

## Context

The prototype currently renders the battle as a short diagonal 3/4 battlefield that fits almost entirely on screen. The previous layout pass made the combat plane wider, but the battlefield still reads as a compact board rather than a long warfront.

This design keeps the current prototype art style and the top three-stage pinball machine. The change is focused on the lower battle system: longer path, deeper battlefield space, camera viewport, tactical minimap strip, and soft three-lane combat.

## Goals

- Make the battlefield feel longer and deeper without turning it into a free RTS map.
- Keep the main battle in a pseudo 2D / 3/4 diagonal view.
- Let the screen show only part of the battlefield when useful; bases do not always need to be visible at the same time.
- Replace the current minimap thumbnail with a compact battle-line information strip.
- Split spawns into three soft lanes so units distribute across the battlefield width.
- Add readable auto-targeting through aggro range and attack range, while keeping deterministic combat.

## Non-Goals

- No Dota-style hard three-lane map with towers, jungle, intersections, or route choices.
- No free camera over a full RTS terrain.
- No complex pathfinding, obstacle avoidance, formations, or player micro-control.
- No major art upgrade. Existing SVG fallback units and simple terrain shapes remain acceptable.
- No changes to the top pinball pipeline, unit slot gate, or reward selection flow in this pass.

## Chosen Approach

Use a longer one-dimensional battle axis with three parallel soft lanes.

The battle simulation remains deterministic and readable: each unit has progress along the main battle axis plus a lane assignment. Rendering projects that world state into a diagonal 3/4 view. The visible screen becomes a camera viewport into this longer axis, while the minimap becomes a horizontal battle-line strip rather than a geographical screenshot.

This gives the prototype the desired Dota-like sense of observing a long conflict without importing Dota's map complexity.

## Alternatives Considered

### Pure Horizontal Battle

This would be easiest to read and easiest to implement, but it pulls the prototype back toward a flat lane-battle presentation. It also conflicts with the earlier requirement to keep a pseudo 2D / 3/4 battlefield.

### Full Diagonal Map Thumbnail

This preserves geographical fidelity, but a long diagonal battlefield inside a rectangle creates large inactive corners. The user correctly called out that the problem is not black color; it is wasted minimap area.

### Hard Three-Lane Map

This would add strategy-map flavor, but it would imply Dota-like route topology, defenses, path choices, and more pathfinding. That is too much system weight for this prototype.

## World Model

Battle units should use a longer world axis than the current base-to-base span. The first pass can keep `x` as the main progress coordinate and add a lane identifier:

- `top`
- `middle`
- `bottom`

Each lane is a parallel band across the battlefield width. Lanes are tactical distribution bands, not separate maps.

Recommended first-pass world values:

- Player base near the low end of the axis.
- Enemy base near the high end of the axis.
- Total axis length roughly 2.5 to 3 times the current effective battlefield length.
- Camera viewport covers roughly 35% to 45% of the full axis.

The exact constants should be tuned visually after implementation.

## Camera

The main screen renders a viewport into the longer battlefield.

Default camera behavior:

- Follow the current combat hotspot when the player is not manually inspecting.
- The combat hotspot comes from overlapping blue/red lane pressure or the existing frontline calculation.
- When no units are fighting, bias the camera toward the most advanced active unit cluster.
- The camera moves only along the main battle axis in this pass.

Manual camera behavior:

- Clicking the minimap strip centers the camera on that battle-axis position.
- Dragging the viewport box on the minimap scrubs the camera along the axis.
- Manual movement does not control units.
- After a short idle period, the camera may return to following the combat hotspot.

## Minimap Strip

Replace the rectangle thumbnail with a horizontal battle-line strip.

Elements:

- Left endpoint: player base.
- Right endpoint: enemy base.
- Blue heat: player unit density along the axis.
- Red heat: enemy unit density along the axis.
- Yellow highlight: active combat hotspot where opposing pressure overlaps.
- White viewport frame: the portion of the long battlefield currently visible on the main screen.
- Optional lane bands: top, middle, bottom can be shown as three thin rows inside the strip.

The minimap is not a scaled picture of terrain. It is a tactical information display. This avoids invalid empty corners and makes the long battlefield readable.

## Soft Three-Lane Spawning

Each unit definition gains lane weights:

```ts
laneWeights: {
  top: number;
  middle: number;
  bottom: number;
}
```

Spawn lane is selected deterministically from those weights using the existing seeded random utilities. The first pass uses only unit data. Future rewards may add lane bias, but this pass does not need to add reward effects.

Suggested data direction:

- Small/basic units: broadly distributed.
- Frontline/tank units: middle-biased.
- Ranged/caster units: more side-lane-biased or spread out.
- Giant/siege units: strongly middle-biased.

The existing out-of-combat spawn queue behavior remains. The queue releases a specific unit, then that unit resolves its lane from the unit definition weights.

## Targeting And Combat

Each unit should have:

- `aggroRange`: how far it looks for targets.
- `attackRange`: how far it can attack once a target is chosen.

Targeting rules:

- If no target is in aggro range, move forward along the assigned lane.
- If enemies are in aggro range, choose the closest valid target by battle-axis distance plus lane distance.
- Units may target adjacent lanes when the range allows it.
- Ranged, caster, and siege units naturally cross lanes more often because their ranges are longer.
- Melee units can cross-lane target only when enemies are close enough.
- Base attacking remains tied to reaching the enemy end of the axis.

This preserves auto-battle readability without introducing pathfinding.

## Rendering

The battlefield renderer projects world-axis progress and lane into screen space:

- Axis progress determines position along the long diagonal.
- Lane determines offset perpendicular to the diagonal.
- Camera offset shifts which part of the long diagonal is visible.
- Units outside the visible viewport are not rendered on the main screen but remain visible as heat/dots on the minimap strip.

The current yellow frontline marker can stay, but it should follow the combat hotspot and become part of the camera/minimap language.

## Data And Code Boundaries

Expected code areas:

- `src/types/game.ts`: add lane type, lane weights, aggro range, camera/minimap state as needed.
- `src/data/units.ts`: add lane weights and aggro ranges.
- `src/systems/BattleSystem.ts`: spawn lane selection, target acquisition, lane-aware movement/attack decisions.
- `src/systems/GameState.ts`: initialize longer base positions and camera state.
- `src/scenes/PrototypeScene.ts`: camera projection, longer battlefield drawing, minimap strip rendering, minimap click/drag input.
- `src/systems/prototypeRules.test.ts`: deterministic lane assignment, lane-aware targeting, minimap/camera math where practical.

Keep the implementation readable. Avoid a large abstract engine layer unless the scene becomes too hard to maintain.

## Testing Plan

Unit tests:

- Unit lane assignment is deterministic for a seed and respects lane weights.
- Units acquire targets in their lane or adjacent lanes when within aggro range.
- Units do not attack enemies outside attack range.
- The frontline/combat hotspot ratio stays within 0..1.
- Camera target/viewport calculations clamp to the valid world axis.

Build validation:

- `npm test`
- `npm run typecheck`
- `npm run build`

Browser smoke:

- Load the local prototype.
- Confirm the main screen shows only a segment of the longer battlefield.
- Confirm minimap strip shows blue/red heat, yellow combat hotspot, and white viewport frame.
- Confirm clicking or dragging the minimap moves the camera.
- Confirm combat continues while camera is inspecting another segment.

## Acceptance Criteria

- The battlefield path feels significantly longer than the current compact board.
- The main viewport can show a partial battlefield segment rather than the whole warfront.
- The minimap no longer wastes large inactive areas; it reads as a battle-line information strip.
- Blue/red heat and yellow conflict highlight make the global battle state legible.
- Units spawn into top/middle/bottom soft lanes using data-driven lane weights.
- Units can auto-target by aggro range and attack by attack range without free RTS pathfinding.
- The top three-stage pinball UI remains intact.
- `npm run typecheck` passes.
- `npm run build` passes.
