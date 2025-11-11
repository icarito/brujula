extends Control


# Para evitar salto de cámara al capturar mouse (ignorar eventos en el centro)
var ignore_mouse_motion_center := false
var mouse_motion_center: Vector2 = Vector2.ZERO
# Para ignorar el siguiente InputEventMouseMotion sintético tras warp_mouse
var ignore_next_mouse_motion := false
var ignore_timer := 0.0



# Para ignorar eventos de mouse tras un touch (Web: evita dobles eventos)
var ignore_mouse_due_to_touch := false
var _touch_mouse_ignore_timer : Timer = null
const TOUCH_MOUSE_IGNORE_TIME := 0.3
# Guardar la posición del último touch para filtrar mouse sintético
var last_touch_pos : Vector2 = Vector2.ZERO
const MOUSE_TOUCH_POSITION_THRESHOLD := 8.0 # píxeles

func _on_input_mode_changed(mode):
	if mobile_input_fix and mode == mobile_input_fix.InputMode.MOUSE:
		ignore_mouse_motion_center = true
		mouse_motion_center = get_viewport().get_visible_rect().size * 0.5

func _on_ignore_next_mouse_motion():
	ignore_next_mouse_motion = true
	ignore_timer = 0.1  # Ignorar por 0.1 segundos máximo


func _input(event):
	# Filtro avanzado: ignorar mouse si ocurre justo donde fue el último touch y en ventana de tiempo
	if (event is InputEventMouseMotion or event is InputEventMouseButton) and ignore_mouse_due_to_touch:
		var mouse_pos : Vector2 = event.position if event.has_method("position") else Vector2.ZERO
		if last_touch_pos.distance_to(mouse_pos) <= MOUSE_TOUCH_POSITION_THRESHOLD:
			return
	if event is InputEventMouseMotion:
		if ignore_next_mouse_motion:
			ignore_next_mouse_motion = false
			return
	elif event is InputEventScreenTouch:
		if event.pressed:
			# Si hay un nuevo touch, cancelar el temporizador y permitir input
			ignore_mouse_due_to_touch = false
			if _touch_mouse_ignore_timer:
				_touch_mouse_ignore_timer.stop()
			last_touch_pos = event.position
		else:
			# Al soltar touch, iniciar temporizador para ignorar mouse brevemente
			if not _touch_mouse_ignore_timer:
				_touch_mouse_ignore_timer = Timer.new()
				_touch_mouse_ignore_timer.one_shot = true
				_touch_mouse_ignore_timer.wait_time = TOUCH_MOUSE_IGNORE_TIME
				_touch_mouse_ignore_timer.timeout.connect(_on_touch_mouse_ignore_timeout)
				add_child(_touch_mouse_ignore_timer)
			ignore_mouse_due_to_touch = true
			last_touch_pos = event.position
			_touch_mouse_ignore_timer.start(TOUCH_MOUSE_IGNORE_TIME)
	elif event is InputEventScreenDrag:
		pass
	elif event is InputEventMouseButton:
		pass

func _on_touch_mouse_ignore_timeout():
	ignore_mouse_due_to_touch = false
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

# Reference to the MobileInputFix node
var mobile_input_fix: Node = null

# Original crosshair scale for restoration
var original_crosshair_scale: Vector2 = Vector2.ONE

var mouse_motion_relative_threshold := 5.0 # Umbral para relative grande

func _ready():
	# Enable on touchscreen devices OR when touch emulation is enabled (for testing)
	var has_touchscreen = DisplayServer.is_touchscreen_available()
	var touch_emulation = ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false)

	if not has_touchscreen and not touch_emulation:
		visible = false
		set_process(false)
		return

	# (Conexión de señal se realiza después de obtener el nodo real de mobile_input_fix)

	# Wait for scene tree to be ready
	await get_tree().process_frame

	# Get reference to MobileInputFix for input mode changes
	player = get_parent().get_parent() # GUI -> CogitoPlayer
	if player:
		mobile_input_fix = player.get_node_or_null("MobileInputFix")
		if mobile_input_fix:
			if mobile_input_fix.has_signal("input_mode_changed"):
				# Set initial visibility based on current mode
				if has_touchscreen:
					# On hybrid devices, start hidden (mouse mode)
					visible = (mobile_input_fix.current_mode == mobile_input_fix.InputMode.TOUCH)
				# Conectar señal para ignorar el primer mouse motion tras cambio de modo
				mobile_input_fix.connect("input_mode_changed", Callable(self, "_on_input_mode_changed"))
			# Conectar señal para ignorar el siguiente mouse motion sintético tras warp_mouse
			if mobile_input_fix.has_signal("ignore_next_mouse_motion"):
				mobile_input_fix.connect("ignore_next_mouse_motion", Callable(self, "_on_ignore_next_mouse_motion"))

		# Try to find the neck and head nodes
		var body = player.get_node_or_null("Body")
		if body:
			player_neck = body.get_node_or_null("Neck")
			if player_neck:
				player_head = player_neck.get_node_or_null("Head")

		# Find the player HUD manager for crosshair control
		var hud_path = get_parent().get_node_or_null("Panel/AspectRatioContainer/Player_HUD")
		if hud_path:
			player_hud_manager = hud_path
			var crosshair = player_hud_manager.get_node_or_null("Crosshair")
			if crosshair:
				original_crosshair_scale = crosshair.scale
				# Enlarge crosshair for touch mode
				crosshair.scale = original_crosshair_scale * 1.5

		# Conectar a señales de menú del player
		if player and player.has_signal("menu_opened"):
			player.connect("menu_opened", Callable(self, "_on_menu_opened"))
		if player and player.has_signal("menu_closed"):
			player.connect("menu_closed", Callable(self, "_on_menu_closed"))

func _process(delta):
	if ignore_timer > 0:
		ignore_timer -= delta
		if ignore_timer <= 0:
			ignore_next_mouse_motion = false
	# Manejo de rotación de cámara con joystick derecho (frame-rate independiente)
	if right_joystick and right_joystick.is_pressed and player:
		var joystick_output = right_joystick.output
		var yaw_delta = -joystick_output.x * camera_sensitivity * delta * 60.0
		var pitch_delta = -joystick_output.y * camera_sensitivity * delta * 60.0
		if "apply_look_input" in player:
			player.apply_look_input(yaw_delta, pitch_delta)

func hide_touch_controls():
	visible = false
	set_process(false)

func show_touch_controls():
	visible = true
	set_process(true)

func _on_menu_opened():
	hide_touch_controls()

func _on_menu_closed():
	show_touch_controls()
