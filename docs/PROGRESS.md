# Progress

## 2026-05-29

- Reworked the top pinball row into left Standby Zone, middle Launch Zone, and right Unit Spawn Zone.
- Changed Launch outcomes to `standby / split / spawn`, routing standby balls left and spawn balls directly right.
- Removed the visible spawn slot from the Standby Zone, leaving gold, magic, and upgrade as the current standby choices.
- Reduced the split lineage cap from three split outcomes to two before forced direct spawn.
- Reworked phase-end rewards into fixed three-chamber blueprint offers: Launch Zone, Standby Zone, and Unit Spawn Zone.
- Added blueprint metadata (`chamber`, `sourceType`) to reward cards and mapped legacy rewards into same-chamber fallback pools.
- Default natural rewards now prioritize chamber buildings, then same-chamber relics or doctrine techs, with repeatable legacy cards as fallback.
- Updated reward UI to ask which machine chamber to modify and to display the blueprint chamber on each card.
- Added a mouse-only global speed control that cycles `1x`, `2x`, and `4x`, with Phaser time, Matter physics, and custom battle/phase delta capped at `4x`.
- Added `natural_blueprint_reward_probe` to prove non-debug phase rewards can create a three-chamber build, recover non-SPAWN value within 15 seconds, queue and deploy units, and produce combat impact.
- Updated the v1.2 readiness audit to include the three-chamber blueprint reward requirement and to fail when completion evidence is missing.
- Slowed unit gate shortening by 5x: the high-tier gate no longer fully opens within a single phase, preserving the baffle while early units are still coming online.
- Enabled adaptive advanced wrapping for reward choice descriptions so Chinese text stays centered inside each reward card.
- Changed automatic battle camera focus to follow the living player unit closest to the enemy base instead of the midpoint frontline.
- Tightened the automatic camera focus rule to use true distance to the enemy base, so overshot units do not steal focus from the closest living player unit.
- Reduced top pinball slot frame heights to one third of their previous size and moved the recovered vertical space into the battlefield.
- Made the debug and build drawers mutually exclusive so opening debug no longer opens or gets covered by the build panel.
- Repositioned the top-row debug preset buttons so they reserve space for the build/debug drawer toggles instead of sitting underneath them.
- Earlier launch slot tuning used a 1:3:1 split/fire/miss layout before the later Standby/Split/Spawn reroute replaced it.
- Rebalanced the top machine row by shrinking the unit zone to 75% of its previous width and assigning the reclaimed width to the launch zone.
- Rebalanced Launch Zone slots to `standby / split / spawn = 2 / 1 / 2`, making Split one fifth of the launch area.
