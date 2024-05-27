extends ConfirmationDialog
signal input_selected(chosen_input: InputEvent)

@export var listening_wait_time: float = 0.35
@export var listening_max_time: float = 5
@export var show_progress_bar: bool = true
@export_group("Text")
@export var btn_listening: String = ". . ."
@export var title_listening: String = "Listening for Input"
@export var title_confirm: String = "Confirm Input"
@export var timeout_text: String = "Timed Out"
@export var already_exists_msg: String = "Input already exists ({action})"

var chosen_input: InputEvent
var src: ggsUIComponent
var type: ggsInputHelper.InputType
var accept_mouse: bool
var accept_modifiers: bool
var accept_axis: bool
var use_icons: bool

var input_helper: ggsInputHelper = ggsInputHelper.new()

@onready var already_exists_label: Label = $MainCtnr/AlreadyExistsLabel
@onready var ok_btn: Button = get_ok_button()
@onready var cancel_btn: Button = get_cancel_button()
@onready var listen_btn: Button = $MainCtnr/ListenBtn
@onready var listen_timer: Timer = $ListenTimer
@onready var max_listen_timer: Timer = $MaxListenTimer
@onready var listen_progress: ProgressBar = $MainCtnr/ListenProgress


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	confirmed.connect(_on_confirmed)
	
	listen_btn.pressed.connect(_on_listen_btn_pressed)
	listen_timer.timeout.connect(_on_listen_timer_timeout)
	max_listen_timer.timeout.connect(_on_max_listen_timer_timeout)
	
	listen_btn.mouse_entered.connect(_on_AnyBtn_mouse_entered.bind(listen_btn))
	ok_btn.mouse_entered.connect(_on_AnyBtn_mouse_entered.bind(ok_btn))
	cancel_btn.mouse_entered.connect(_on_AnyBtn_mouse_entered.bind(cancel_btn))
	listen_btn.focus_entered.connect(_on_AnyBtn_focus_entered)
	ok_btn.focus_entered.connect(_on_AnyBtn_focus_entered)
	cancel_btn.focus_entered.connect(_on_AnyBtn_focus_entered)
	cancel_btn.pressed.connect(_on_cancel_btn_pressed)
	
	listen_btn.focus_neighbor_bottom = cancel_btn.get_path()
	ok_btn.focus_neighbor_top = listen_btn.get_path()
	cancel_btn.focus_neighbor_top = listen_btn.get_path()
	
	listen_timer.wait_time = listening_wait_time
	max_listen_timer.wait_time = listening_max_time


func _process(_delta: float) -> void:
	listen_progress.value = listen_timer.time_left / listen_timer.wait_time


func _input(event: InputEvent) -> void:
	if not _event_is_valid(event):
		return
	
	_set_btn_text_or_icon(event)
	
	var input_already_exists: Array = input_helper.input_already_exists(event, src.setting.action)
	if input_already_exists[0]:
		already_exists_label.text = already_exists_msg.format({"action": input_already_exists[1].capitalize()})
		
		listen_progress.hide()
		already_exists_label.show()
		listen_timer.stop()
		max_listen_timer.start()
		return
	
	listen_progress.show()
	already_exists_label.hide()
	listen_timer.start()
	max_listen_timer.start()
	
	chosen_input = event


### Input Validation

func _event_is_valid(event: InputEvent) -> bool:
	var type_is_acceptable: bool = _event_type_is_acceptable(event)
	var has_modifier: bool = _event_has_modifier(event)
	var is_double_click: bool = _event_is_double_click(event)
	var mouse_btn_is_valid: bool = _event_mouse_btn_is_valid(event)
	var event_is_single_press: bool = (event.is_pressed() and not event.is_echo())
	
	var is_valid: bool
	if accept_modifiers:
		is_valid = (
			type_is_acceptable and
			event_is_single_press and
			not is_double_click and
			mouse_btn_is_valid
		)
	else:
		is_valid = (
			type_is_acceptable and
			event_is_single_press and
			not is_double_click and
			mouse_btn_is_valid and 
			not has_modifier
		)
	
	return is_valid


func _event_type_is_acceptable(event: InputEvent) -> bool:
	var is_acceptable: bool = false
	
	if (
		type == ggsInputHelper.InputType.KEYBOARD or
		type == ggsInputHelper.InputType.MOUSE
	):
		if accept_mouse:
			is_acceptable = (
				event is InputEventKey or
				event is InputEventMouseButton
			)
		else:
			is_acceptable = (event is InputEventKey)
	
	elif (
		type == ggsInputHelper.InputType.GP_BTN or
		type == ggsInputHelper.InputType.GP_MOTION
	):
		if accept_axis:
			is_acceptable = (
				event is InputEventJoypadButton or
				event is InputEventJoypadMotion
			)
		else:
			is_acceptable = (event is InputEventJoypadButton)
	
	return is_acceptable


func _event_has_modifier(event: InputEvent) -> bool:
	var has_modifier: bool
	
	if event is InputEventWithModifiers:
		has_modifier = (
			event.shift_pressed or
			event.alt_pressed or
			event.ctrl_pressed
		)
	
	return has_modifier


func _event_is_double_click(event: InputEvent) -> bool:
	var is_double_click: bool
	
	if event is InputEventMouseButton:
		is_double_click = event.double_click
	
	return is_double_click


func _event_mouse_btn_is_valid(event: InputEvent) -> bool:
	var mouse_btn_is_valid: bool = true
	
	if event is InputEventMouseButton:
		mouse_btn_is_valid = (event.button_index >= 0 and event.button_index <= 9)
	
	return mouse_btn_is_valid


### Input Listening

func _set_btn_text_or_icon(event: InputEvent) -> void:
	if (
		use_icons and
		(type == ggsInputHelper.InputType.MOUSE or
		type == ggsInputHelper.InputType.GP_BTN or
		type == ggsInputHelper.InputType.GP_MOTION)
	):
		listen_btn.icon = input_helper.get_event_as_icon(event, src.icon_db)
		
		if listen_btn.icon == null:
			listen_btn.text = input_helper.get_event_as_text(event)
		else:
			listen_btn.text = ""
		
		return
	
	listen_btn.icon = null
	listen_btn.text = input_helper.get_event_as_text(event)


func _start_listening() -> void:
	listen_btn.text = btn_listening
	listen_btn.icon = null
	title = title_listening
	
	ok_btn.release_focus()
	ok_btn.disabled = true
	ok_btn.focus_mode = Control.FOCUS_NONE
	
	listen_btn.release_focus()
	listen_btn.disabled = true
	listen_btn.focus_mode = Control.FOCUS_NONE
	
	cancel_btn.release_focus()
	
	if show_progress_bar:
		listen_progress.show()
	
	set_process_input(true)
	set_process(true)
	max_listen_timer.start()


func _stop_listening(timed_out: bool = false) -> void:
	title = title_confirm
	
	listen_btn.focus_mode = Control.FOCUS_ALL
	listen_btn.disabled = false
	listen_btn.grab_focus()
	
	if timed_out:
		listen_btn.text = timeout_text
		listen_btn.icon = null
	
	if not timed_out:
		ok_btn.focus_mode = Control.FOCUS_ALL
		ok_btn.disabled = false
		ok_btn.grab_focus()
	
	listen_progress.hide()
	already_exists_label.hide()
	
	set_process_input(false)
	set_process(false)
	max_listen_timer.stop()


func _on_listen_btn_pressed() -> void:
	_start_listening()
	GGS.play_sfx(GGS.SFX.INTERACT)


func _on_listen_timer_timeout() -> void:
	_stop_listening()


func _on_max_listen_timer_timeout() -> void:
	_stop_listening(true)


### Window

func _on_visibility_changed() -> void:
	if visible:
		ok_btn.release_focus()
		chosen_input = null
		_start_listening()


func _on_confirmed() -> void:
	input_selected.emit(chosen_input)
	GGS.play_sfx(GGS.SFX.INTERACT)


### SFX

func _on_AnyBtn_mouse_entered(Btn: Button) -> void:
	GGS.play_sfx(GGS.SFX.MOUSE_OVER)
	
	if src.grab_focus_on_mouse_over:
		Btn.grab_focus()


func _on_AnyBtn_focus_entered() -> void:
	GGS.play_sfx(GGS.SFX.FOCUS)


func _on_cancel_btn_pressed() -> void:
	GGS.play_sfx(GGS.SFX.INTERACT)
