# 3D First Person Template

A small, asset-free Godot 4 starting point for a first-person game. It includes a complete menu flow, persistent settings, character movement, and physics-object interaction.

## Included systems

- Main menu with **Start Game**, **Options**, and **Quit**
- Pause menu with **Resume**, **Options**, and **Return to Main Menu**
- Persistent mouse sensitivity, field of view, master volume, fullscreen, and VSync settings
- First-person walking, mouse look, jumping, collision, and gravity
- Ray-based interaction and a reusable `pickup` group
- Rigid-body pickup, carrying, dropping, and a context prompt
- A small physics test room with three movable props

## Requirements

- Godot 4.7 or newer

## Run

Clone the repository, then open `project.godot` in Godot and press **F6** or **F5**. If the Godot executable is available on your `PATH`, you can also launch the project from a terminal:

```powershell
godot --path .
```

## Controls

- **WASD** or **arrow keys** — move
- **Mouse** — look around
- **Space** — jump
- **E** — pick up or drop the targeted physics object
- **Escape** — pause, resume, or leave the options menu

## Reusing the interaction system

Any `RigidBody3D` in the `pickup` group can be picked up. Give it a collision layer detected by the player's `InteractionRay`; this template uses the named **Pickups** layer (layer 3).

Global user preferences are owned by `scripts/game_settings.gd` and saved to `user://settings.cfg`. The options interface is a reusable scene at `options_menu.tscn`.

## Smoke test

```powershell
godot --headless --path . --script res://tests/smoke_test.gd
```
