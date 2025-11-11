# Touch Controls for Mobile/Tablet

This project includes touch controls for mobile and tablet devices using the Virtual Joystick addon from the Godot Asset Library.

## Features

- **Left Joystick**: Controls player movement (forward, back, left, right)
- **Right Joystick**: Controls camera rotation (look around)
- **Action Buttons**: 
  - Jump button (↑)
  - Interact button (F)
  - Sprint button (⚡)
  - Crouch button (↓)

## Visibility

The touch controls use the Virtual Joystick addon's built-in "WHEN_TOUCHED" visibility mode, which means:
- Joysticks automatically appear when you touch their area
- They fade away when released
- This behavior is handled entirely by the addon for consistency

The controls are only enabled on touchscreen devices and completely disabled on desktop. When active, the crosshair is permanently enlarged by 50% for better visibility on mobile devices.

## How to Add Touch Controls to a Scene

The touch controls are implemented as a reusable scene (`scenes/touch_controls.tscn`) that can be added as a child to any `CogitoPlayer` instance:

1. Open your scene in the Godot editor
2. Find the `CogitoPlayer` node
3. Add a child node by instancing `res://scenes/touch_controls.tscn`
4. The touch controls will automatically:
   - Find the player's camera/head nodes
   - Show/hide based on device type
   - Connect to the player's input system

## Configuration

You can adjust the camera sensitivity by modifying the `camera_sensitivity` export variable in the TouchControls node (default: 2.0).

## Implementation Details

- **Addon**: Virtual Joystick from https://github.com/MarcoFazioRandom/Virtual-Joystick-Godot
- **Plugin Location**: `addons/virtual_joystick/`
- **Touch Controls Scene**: `scenes/touch_controls.tscn`
- **Touch Controls Script**: `scenes/scripts/touch_controls.gd`

### How It Works

### How It Works

- The left joystick uses input actions (`forward`, `back`, `left`, `right`) that are already configured in the project
- The right joystick directly manipulates the player's neck and head nodes for camera rotation
- Action buttons use `TouchScreenButton` nodes that emit standard input actions
- Joysticks use the addon's "WHEN_TOUCHED" visibility mode for automatic show/hide
- Crosshair is permanently enlarged by 50% on touchscreen devices for better targeting
- Controls are 50% transparent and properly anchored to bottom corners

### Performance Optimizations

The following optimizations have been implemented for better mobile performance:

1. **Touch Controls**:
   - Simplified visibility using addon's built-in "WHEN_TOUCHED" mode
   - Minimal processing overhead
   - Controls completely disabled on non-touchscreen devices

2. **Rendering** (in `project.godot`):
   - **Render scale set to 0.65** for better mobile performance
   - VRAM compression enabled for mobile (ETC2/ASTC)
   - GPU pixel snap enabled for 2D elements
   - Optimized texture settings

## Project Settings

The following settings have been configured in `project.godot`:

```gdscript
[input_devices]
pointing/emulate_touch_from_mouse=true
pointing/emulate_mouse_from_touch=false

[display]
window/stretch/scale=0.65  # Render resolution for mobile performance

[rendering]
textures/vram_compression/import_etc2_astc=true
2d/options/use_gpu_pixel_snap=true
```

These settings are required by the Virtual Joystick addon and enable testing with mouse input on desktop.

## Example Scene

The main scene (`scenes/ether.tscn`) includes touch controls as a reference implementation. Check the `CogitoPlayer/TouchControls` node in that scene.
