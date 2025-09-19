# Manual Test Plan

## Smoke Test
1. Launch Godot 4.2+, open `game/project.godot`, and press **Play** to enter the dungeon.
2. Verify the HUD displays HP/STA/LGT and Eclipse 12 pips.
3. Move with WASD, sprint with Shift, crouch with `C`, and ensure stamina drains/regenerates.
4. Toggle the torch with `F`; observe fog radius shrinking when unlit and vignette intensifying.

## Stealth & Combat
1. Approach a Lantern-Bearer while crouched and confirm delayed detection; sprint to trigger immediate chase and detection stinger.
2. Throw a flare (`Right Mouse`) to lure a Silent Order ambusher; confirm it investigates the noise marker.
3. Practice dodge (`Space`) and parry (`X`) against melee enemies; ensure successful parry plays a stinger and cancels damage.
4. Defeat the Eclipse Warden miniboss—note phase transition at 50% HP and shadow wave casts.

## Puzzles
1. Solve the light-angle puzzle by rotating mirrors until the gate opens and HUD clue updates.
2. Rotate rune tiles until the solution order matches the hint; ensure clue log updates.
3. Activate the timed lever and sprint the bridge path before it retracts; confirm failure resets after timer expiration.

## Progression & Systems
1. Let the Eclipse timer tick to 8 and 4; watch corridor shift announcements and enemy patrol updates.
2. Collect keys, torches, and rations; confirm inventory label updates and locked doors consume keys.
3. Use Pause > Settings to adjust audio sliders and colorblind filters; verify fog contrast changes.
4. Save to Slot 1, quit to project, relaunch, and load Slot 1; validate player position, stats, and dungeon layout persist.
5. Toggle debug overlay (`F7`) to inspect AI states, FPS, and noise marker count.

## Accessibility & Controllers
1. Connect a gamepad; confirm stick movement, triggers for sprint/dodge, and face buttons for interact/use.
2. Enable colorblind options from the pause menu and ensure fog tint adjusts per selection.
3. Check caption panel displays audio cue text for ambience layers and stingers.
