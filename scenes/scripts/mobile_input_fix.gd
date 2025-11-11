extends Node

func _process(_delta):
	# En web, solo forzar mouse visible si está en modo TOUCH, el filtro global está activo y el mouse NO está capturado
	if OS.has_feature("web") and current_mode == InputMode.TOUCH and mouse_motion_blocked_web:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif not OS.has_feature("web"):
		# --- NATIVO: liberar mouse tras inactividad ---
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			mouse_idle_time += _delta
			if mouse_idle_time > MOUSE_IDLE_TIMEOUT:
				Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
				mouse_capture_enabled = false
		else:
			mouse_idle_time = 0.0

signal input_mode_changed(mode)
signal ignore_next_mouse_motion()

enum InputMode { MOUSE, TOUCH }
var current_mode : int = InputMode.TOUCH


var mouse_capture_enabled := false
var ignore_next_mouse_motion_event := false
var initial_release := false
var menu_open := false
var movement_paused := false
const MOUSE_IDLE_TIMEOUT := 1
var mouse_idle_time := 0.0
# Filtro para mouse move sintético tras touch en web
var last_touch_pos : Vector2 = Vector2.ZERO
## Eliminados flags redundantes para web
var mouse_motion_blocked_web := true # Bloquea mouse motion en web hasta mouse button real
const MOUSE_TOUCH_POSITION_THRESHOLD := 8.0
const IGNORE_MOUSE_MOTION_TIME := 0.25
var ignore_mouse_motion_timer : Timer = null

@onready var player = get_tree().get_root().find_child("CogitoPlayer", true, false)

func _ready() -> void:
	set_process_input(true)
	if OS.has_feature("web"):
		mouse_motion_blocked_web = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if not DisplayServer.is_touchscreen_available():
		mouse_capture_enabled = true
		current_mode = InputMode.MOUSE
		emit_signal("input_mode_changed", InputMode.MOUSE)
		return
	mouse_capture_enabled = false
	initial_release = true
	await get_tree().process_frame
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if player and player.has_signal("menu_opened"):
		player.connect("menu_opened", Callable(self, "_on_menu_opened"))
	if player and player.has_signal("menu_closed"):
		player.connect("menu_closed", Callable(self, "_on_menu_closed"))
	if player and player.has_signal("movement_paused"):
		player.connect("movement_paused", Callable(self, "_on_movement_paused"))



func _input(event):
	var is_web = OS.has_feature("web")

	if is_web:
		# --- WEB: nunca capturar mouse automáticamente ---
		if event is InputEventMouseButton and event.device == 0 and event.pressed:
			# Cualquier botón real: cambiar a modo MOUSE y desbloquear filtro
			current_mode = InputMode.MOUSE
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_motion_blocked_web = false
			emit_signal("input_mode_changed", InputMode.MOUSE)
			return
		# Si hay touch o joystick, solo volver a modo TOUCH y bloquear mouse si el mouse NO está capturado
		if (event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventJoypadMotion):
			if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
				current_mode = InputMode.TOUCH
				emit_signal("input_mode_changed", InputMode.TOUCH)
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				mouse_motion_blocked_web = true
				return
			else:
				# Si el mouse está capturado, ignora el evento y NO cambies el modo ni el mouse
				return
		if current_mode == InputMode.TOUCH:
			# Ignora todos los eventos de mouse en modo touch
			if event is InputEventMouseMotion or event is InputEventMouseButton:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				mouse_motion_blocked_web = true
				return
		# Si está bloqueado, ignora todos los mouse motion
		if mouse_motion_blocked_web and event is InputEventMouseMotion:
			return
		return

	# --- NATIVO: deja que Godot maneje la captura normalmente ---
	if not DisplayServer.is_touchscreen_available():
		return

	# En web: filtra mouse/touch según modo
	if OS.has_feature("web"):
		# Si estamos en modo TOUCH pero se detecta movimiento real de mouse, cambiamos a modo MOUSE
		if current_mode == InputMode.TOUCH:
			if event is InputEventMouseMotion and event.relative.length_squared() > 0.0:
				current_mode = InputMode.MOUSE
				emit_signal("input_mode_changed", InputMode.MOUSE)
			elif event is InputEventMouseButton:
				current_mode = InputMode.MOUSE
				emit_signal("input_mode_changed", InputMode.MOUSE)
			else:
				if event is InputEventMouseMotion or event is InputEventMouseButton:
					return

	if event is InputEventMouseMotion and event.relative.length_squared() > 1.0:
		var player_paused = false
		if player and ("is_movement_paused" in player):
			player_paused = player.is_movement_paused
		if menu_open or movement_paused or player_paused:
			return
		# Seguridad reforzada: solo manipular mouse si viewport existe, está visible, el juego está enfocado y el tamaño es válido
		var viewport = get_viewport()
		var can_capture := false
		var center := Vector2.ZERO
		if viewport:
			center = viewport.get_visible_rect().size * 0.5
			if center.x > 0 and center.y > 0:
				# Usar DisplayServer para saber si la ventana principal está enfocada (ID 0)
				if OS.has_feature("editor") or DisplayServer.window_is_focused(0):
					can_capture = true
		if can_capture and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.warp_mouse(center)
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			ignore_next_mouse_motion_event = true
			emit_signal("ignore_next_mouse_motion")
			mouse_capture_enabled = true
			if current_mode != InputMode.MOUSE:
				current_mode = InputMode.MOUSE
				emit_signal("input_mode_changed", InputMode.MOUSE)
		# Si el mouse está capturado, siempre reinicia el temporizador y permite el movimiento de cámara
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			mouse_idle_time = 0.0
			if initial_release:
				initial_release = false
		else:
			pass
