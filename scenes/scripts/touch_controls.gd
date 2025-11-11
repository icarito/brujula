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
			# Limitar área táctil de joysticks fijos: solo permitir input si el toque está en la mitad correspondiente
			var viewport_size = get_viewport().get_visible_rect().size
			var half_x = viewport_size.x * 0.5
			if left_joystick and event.position.x <= half_x:
				pass # El joystick izquierdo responderá normalmente
			elif right_joystick and event.position.x > half_x:
				pass # El joystick derecho responderá normalmente
			else:
				# Ignorar toques fuera de las áreas válidas
				return
			# Cancelar el temporizador y permitir input normal
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


# Escalado original del crosshair para restaurar
var original_crosshair_scale: Vector2 = Vector2.ONE
var crosshair_scaled_for_touch := false

var mouse_motion_relative_threshold := 5.0 # Umbral para relative grande

func _ready():
	_update_touch_scale()


func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_update_touch_scale()

# Escalado automático para pantallas pequeñas
func _update_touch_scale():
	var viewport_size = get_viewport().get_visible_rect().size
	var is_small_screen = viewport_size.x < 900 or viewport_size.y < 600

	# Adaptativo: tamaño según lado corto, límites y proporciones
	var short_side = min(viewport_size.x, viewport_size.y)
	# Más grandes en móvil, más chicos en normal
	var joystick_percent = 0.80 if is_small_screen else 0.20
	var button_percent = 0.22 if is_small_screen else 0.10
	var joystick_size = clamp(short_side * joystick_percent, 160, 600) if is_small_screen else clamp(short_side * joystick_percent, 80, 180)
	var button_size = clamp(short_side * button_percent, 80, 220) if is_small_screen else clamp(short_side * button_percent, 48, 96)

	# Calcular margen inferior de 2cm en píxeles reales
	var dpi = DisplayServer.screen_get_dpi()
	var margin_cm = 2.0
	var margin_px = int((dpi / 2.54) * margin_cm)
	if left_joystick:
		left_joystick.custom_minimum_size = Vector2(joystick_size, joystick_size)
		left_joystick.size = Vector2(joystick_size, joystick_size)
		left_joystick.anchor_left = 0.0
		left_joystick.anchor_right = 0.0
		left_joystick.anchor_top = 1.0
		left_joystick.anchor_bottom = 1.0
		left_joystick.offset_left = 0
		left_joystick.offset_bottom = margin_px
		if "clampzone_size" in left_joystick:
			left_joystick.clampzone_size = joystick_size * 0.45
		var left_base = left_joystick.get_node_or_null("Base")
		if left_base:
			left_base.custom_minimum_size = Vector2(joystick_size, joystick_size)
			left_base.size = Vector2(joystick_size, joystick_size)
	if right_joystick:
		right_joystick.custom_minimum_size = Vector2(joystick_size, joystick_size)
		right_joystick.size = Vector2(joystick_size, joystick_size)
		right_joystick.anchor_left = 1.0
		right_joystick.anchor_right = 1.0
		right_joystick.anchor_top = 1.0
		right_joystick.anchor_bottom = 1.0
		right_joystick.offset_right = 0
		right_joystick.offset_bottom = margin_px
		if "clampzone_size" in right_joystick:
			right_joystick.clampzone_size = joystick_size * 0.45
		var right_base = right_joystick.get_node_or_null("Base")
		if right_base:
			right_base.custom_minimum_size = Vector2(joystick_size, joystick_size)
			right_base.size = Vector2(joystick_size, joystick_size)
	if action_buttons:
		action_buttons.anchor_left = 1.0
		action_buttons.anchor_right = 1.0
		action_buttons.anchor_top = 1.0
		action_buttons.anchor_bottom = 1.0
		action_buttons.offset_right = 0
		action_buttons.offset_bottom = margin_px
		for btn_name in ["JumpButton", "InteractButton", "SprintButton", "CrouchButton"]:
			var btn = action_buttons.get_node_or_null(btn_name)
			if btn:
				if btn is Control:
					btn.custom_minimum_size = Vector2(button_size, button_size)
				btn.scale = Vector2.ONE
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
				if not mobile_input_fix.is_connected("input_mode_changed", Callable(self, "_on_input_mode_changed")):
					mobile_input_fix.connect("input_mode_changed", Callable(self, "_on_input_mode_changed"))
			# Conectar señal para ignorar el siguiente mouse motion sintético tras warp_mouse
			if mobile_input_fix.has_signal("ignore_next_mouse_motion"):
				if not mobile_input_fix.is_connected("ignore_next_mouse_motion", Callable(self, "_on_ignore_next_mouse_motion")):
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
				if not crosshair_scaled_for_touch:
					original_crosshair_scale = crosshair.scale
					crosshair.scale = original_crosshair_scale * 1.5
					crosshair_scaled_for_touch = true
			elif crosshair_scaled_for_touch:
				# Si el crosshair ya no existe, resetea el flag
				crosshair_scaled_for_touch = false

		# Conectar a señales de menú del player evitando duplicados
		if player and player.has_signal("menu_opened"):
			if not player.is_connected("menu_opened", Callable(self, "_on_menu_opened")):
				player.connect("menu_opened", Callable(self, "_on_menu_opened"))
		if player and player.has_signal("menu_closed"):
			if not player.is_connected("menu_closed", Callable(self, "_on_menu_closed")):
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
