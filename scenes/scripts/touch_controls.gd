extends CanvasLayer
## Touch Controls Manager
## Manages virtual joysticks for mobile/tablet input

@onready var left_joystick = %LeftJoystick
@onready var right_joystick = %RightJoystick
@onready var action_buttons = $ActionButtons

# Camera sensitivity for the right joystick
@export var camera_sensitivity: float = 2.0

# Reference to the player's camera/head for rotation
var player_head: Node3D = null
var player_neck: Node3D = null
var player: CharacterBody3D = null
var player_hud_manager: Control = null

# Touch tracking for visibility
var active_touches: int = 0
var touch_mode_active: bool = false

# Original crosshair scale for restoration
var original_crosshair_scale: Vector2 = Vector2.ONE

func _ready():
	# Start hidden - will show on first touch
	visible = false
	
	# Only enable on touchscreen devices
	if not DisplayServer.is_touchscreen_available():
		set_process_input(false)
		return
	
	# Wait for parent (player) to be ready
	await get_parent().ready
	
	# Get reference to player and camera
	player = get_parent()
	if player:
		# Try to find the neck and head nodes
		var body = player.get_node_or_null("Body")
		if body:
			player_neck = body.get_node_or_null("Neck")
			if player_neck:
				player_head = player_neck.get_node_or_null("Head")
		
		# Find the player HUD manager for crosshair control
		var hud_path = player.get_node_or_null("GUI/Player_HUD")
		if hud_path:
			player_hud_manager = hud_path
			var crosshair = player_hud_manager.get_node_or_null("Crosshair")
			if crosshair:
				original_crosshair_scale = crosshair.scale

func _input(event: InputEvent) -> void:
	# Track touch events to show/hide controls
	if event is InputEventScreenTouch:
		if event.pressed:
			active_touches += 1
			if not visible:
				visible = true
				_enter_touch_mode()
		else:
			active_touches = maxi(0, active_touches - 1)
			if active_touches == 0:
				visible = false
				_exit_touch_mode()

func _enter_touch_mode() -> void:
	if touch_mode_active:
		return
	touch_mode_active = true
	
	# Make crosshair bigger in touch mode
	if player_hud_manager:
		var crosshair = player_hud_manager.get_node_or_null("Crosshair")
		if crosshair:
			crosshair.scale = original_crosshair_scale * 1.5

func _exit_touch_mode() -> void:
	if not touch_mode_active:
		return
	touch_mode_active = false
	
	# Restore crosshair to original size
	if player_hud_manager:
		var crosshair = player_hud_manager.get_node_or_null("Crosshair")
		if crosshair:
			crosshair.scale = original_crosshair_scale

func _process(delta):
	# Only process if visible and touch mode is active
	if not visible or not touch_mode_active:
		return
	
	# Handle camera rotation with right joystick
	if right_joystick and right_joystick.is_pressed and player_head and player_neck:
		var joystick_output = right_joystick.output
		
		# Rotate neck (yaw)
		player_neck.rotate_y(deg_to_rad(-joystick_output.x * camera_sensitivity))
		
		# Rotate head (pitch)
		player_head.rotate_x(deg_to_rad(-joystick_output.y * camera_sensitivity))
		
		# Clamp head rotation
		player_head.rotation.x = clamp(player_head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
