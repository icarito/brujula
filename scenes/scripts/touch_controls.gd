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

# Original crosshair scale for restoration
var original_crosshair_scale: Vector2 = Vector2.ONE

func _ready():
	# Only enable on touchscreen devices
	if not DisplayServer.is_touchscreen_available():
		visible = false
		set_process(false)
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
				# Enlarge crosshair for touch mode
				crosshair.scale = original_crosshair_scale * 1.5

func _process(delta):
	# Handle camera rotation with right joystick
	if right_joystick and right_joystick.is_pressed and player_head and player_neck:
		var joystick_output = right_joystick.output
		
		# Rotate neck (yaw)
		player_neck.rotate_y(deg_to_rad(-joystick_output.x * camera_sensitivity))
		
		# Rotate head (pitch)
		player_head.rotate_x(deg_to_rad(-joystick_output.y * camera_sensitivity))
		
		# Clamp head rotation
		player_head.rotation.x = clamp(player_head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
