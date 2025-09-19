# QA Checklist

- [ ] Launch project in Godot 4.2+ and ensure the main menu loads without errors.
- [ ] Validate dynamic lighting and fog-of-war render correctly when the player moves.
- [ ] Confirm player controls (move, sprint, crouch, interact, dodge, parry, throw) respond to keyboard and gamepad.
- [ ] Test stealth behaviour: enemies react differently to walking, sprinting, and crouching noise levels.
- [ ] Verify Eclipse timer ticks down, shifts corridors at 8 and 4, and updates HUD.
- [ ] Solve each puzzle (light angle, rune circuit, lever bridge) to ensure gates respond.
- [ ] Defeat at least one enemy of each type and the Eclipse Warden miniboss; check damage numbers and hit pause.
- [ ] Exercise save/load across all three slots and confirm the dungeon layout, inventory, and player position persist.
- [ ] Adjust audio sliders and colorblind options in Pause > Settings; ensure changes apply immediately.
- [ ] Toggle the debug overlay (`F7`) and confirm FPS, draw calls, and AI state text refresh.
- [ ] Run on Windows, macOS, and Linux export templates to confirm no platform-specific errors.
