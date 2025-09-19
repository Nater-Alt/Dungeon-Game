# Dark Delve — Gloamkeep Vertical Slice

Engine: **Godot 4.x (GDScript)**

## Overview
Dark Delve drops you into the shifting underbelly of Gloamkeep, a stealth-forward 2D dungeon crawler that balances light and shadow. Dynamic lighting, a responsive fog-of-war shader, faction-based AI, puzzles, and an Eclipse timer that warps the layout combine to create a 20–30 minute run built entirely from in-engine placeholder assets.

## Getting Started
1. Install [Godot 4.2 or newer](https://godotengine.org/download). (Mono build not required.)
2. Open the editor and select **Import** → choose `game/project.godot`.
3. Press **F5** (Play) to launch the vertical slice.

### Platform Notes
- **Windows/macOS/Linux:** The project uses only engine-generated assets and AudioStreamGenerators; no external dependencies required.
- **Exports:** Configure standard Godot export templates. The build avoids platform-specific APIs.

## Controls
| Action | Keyboard / Mouse | Gamepad |
| ------ | ---------------- | ------- |
| Move | WASD | Left stick |
| Sprint | Left Shift | Left trigger / LB |
| Crouch | `C` | B / Circle |
| Interact / Use | `E` | A / Cross |
| Toggle Torch | `F` | X / Square |
| Use Item (ration/flare) | `R` | Y / Triangle |
| Drop Rope | `Q` | Left bumper |
| Dodge | Space | Right bumper |
| Parry | `X` | Right trigger |
| Throw Knife/Flare | Right Mouse | Right stick click |
| Pause Menu | Esc | Start |
| Debug Overlay | F7 | (keyboard only) |

Controls can be remapped via **Project → Project Settings → Input Map** in the editor; runtime remapping UI is planned via the stretch goals system.

## Systems Highlights
- **Lighting & Fog:** Light2D torches with occluders, vignette that reacts to light reserves, and a shader-driven fog-of-war with explored memory.
- **Stealth & Audio:** Footstep intensity scales with stance; AI listens for noise markers broadcast to the debug overlay. Captions describe audio cues for accessibility.
- **Combat:** Sprinting drains stamina, dodges grant i-frames, parries cancel damage. Flare and knife projectiles are pooled via simple scene instantiation.
- **Procedural Dungeon:** `DungeonGenerator` stitches 12–18 rooms (ensuring loops and shortcuts) and rewires corridors at Eclipse ticks 8 and 4. Keys obey logic constraints.
- **Puzzles:** Mirror rotation, rune order, and lever/bridge puzzles inject varied interactions without text walls.
- **AI Factions:** Lantern-Bearers rely on sight, Silent Order on hearing, and the Gloom Caster plus Eclipse Warden miniboss add ranged/phase variety.
- **Save/Load:** Three JSON slots persist stats, inventory, dungeon seed, and player position.
- **Dev Tools:** F7 toggles an overlay with FPS, draw calls, AI states, and noise counts. The pause menu surfaces audio sliders, colorblind modes, and save/load buttons.

## Configuration & Stretch Goals
Runtime tuning lives in [`config/game.json`](config/game.json) and hot-reloads through the `ConfigService` autoload.

```json
{
  "difficulty": "normal",        // easy / normal / hard adjusts HP & stamina pools
  "light_radius": 320.0,          // base fog reveal in pixels
  "enemy_density": 0.75,          // scales active enemy count per layout
  "drop_rates": {                 // guide for future loot distribution hooks
    "torches": 0.4,
    "flares": 0.25,
    "rations": 0.35,
    "keys": 0.12
  },
  "stretch_goals": {
    "enable_story_codex": false,
    "enable_daily_seed": true,    // uses yyyyMMdd as the world seed
    "enable_hardcore_mode": false
  }
}
```

Toggle stretch goals to experiment with daily seeds or hardcore balancing (death on Eclipse zero). The config watcher refreshes these values every ~1.5 seconds while the game runs.

## Project Layout
```
├── config/
│   └── game.json
├── docs/
│   ├── QA_CHECKLIST.md
│   └── TEST_PLAN.md
└── game/
    ├── project.godot
    ├── autoload/
    │   ├── audio_manager.gd
    │   ├── config_service.gd
    │   ├── dungeon_generator.gd
    │   ├── game_state.gd
    │   └── save_manager.gd
    ├── scenes/
    │   ├── main/ (main scene, camera & fog controllers)
    │   ├── player/ (player, projectiles)
    │   ├── enemies/ (faction scenes & shadow bolt)
    │   ├── props/ (rooms, torches, pickups, doors)
    │   ├── puzzles/ (three puzzle archetypes)
    │   └── ui/ (HUD, pause, debug overlay)
    ├── shaders/ (fog & vignette materials)
    └── assets/ (gradient-based textures & light masks)
```

## Scene Graph (Core Runtime)
```
Main (Node2D)
├── WorldRoot (Node2D)
│   ├── PlayerContainer → Player (CharacterBody2D)
│   ├── LightGroup (torches, emissives)
│   └── Procedural rooms / doors / enemies (instanced at runtime)
├── Effects (CanvasLayer)
│   ├── Vignette (ColorRect + shader)
│   ├── FogMask (ColorRect + shader + controller script)
│   ├── HUD (Control)
│   ├── PauseMenu (Control)
│   └── DebugOverlay (Control)
└── EclipseTimer (Timer)

Autoload singletons:
AudioManager, ConfigService, DungeonGenerator, GameState, SaveManager
```

## Assets
All sprites, lights, and audio are procedural placeholders generated via Godot resources (`GradientTexture2D`, `AudioStreamGenerator`). No external copyright applies.

## Troubleshooting
- **Audio silent?** Ensure the Master/Music/SFX sliders in the pause menu are above zero. The AudioStreamGenerator requires a short warm-up (~0.5 s) on first play.
- **Fog not updating?** The fog shader needs a valid camera reference; confirm the camera reparented to the player (see console output) and that `FogMask` has the `fog_controller.gd` script attached.
- **Controller dead zones:** Adjust in `project.godot` → Input Map if your device needs smaller deadzones.
- **Save errors:** Check the Godot editor output. On desktop platforms the saves reside under `user://saves/slot_X.json`.

## QA & Testing
- Quick regression sweep: follow `docs/QA_CHECKLIST.md`.
- Scenario-based manual runs: see `docs/TEST_PLAN.md`.

## Credits
Design & implementation: this repository. All code and assets are original placeholders crafted for the vertical slice.
