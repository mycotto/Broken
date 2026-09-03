extends Control

var game := BrokenGameState.new()
var status_label: Label
var log_view: RichTextLabel
var actions_box: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_process_result(game.start_new_game())

func _build_ui() -> void:
	var background := ColorRect.new(); background.color = Color("15141d"); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var root := MarginContainer.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_theme_constant_override("margin_left", 20); root.add_theme_constant_override("margin_right", 20); root.add_theme_constant_override("margin_top", 18); root.add_theme_constant_override("margin_bottom", 18); add_child(root)
	var columns := HBoxContainer.new(); columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL; columns.size_flags_vertical = Control.SIZE_EXPAND_FILL; columns.add_theme_constant_override("separation", 16); root.add_child(columns)
	var left := VBoxContainer.new(); left.size_flags_horizontal = Control.SIZE_EXPAND_FILL; left.size_flags_stretch_ratio = 2.0; columns.add_child(left)
	var title := Label.new(); title.text = "BROKEN"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 34); left.add_child(title)
	status_label = Label.new(); status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; status_label.add_theme_font_size_override("font_size", 18); left.add_child(status_label)
	log_view = RichTextLabel.new(); log_view.bbcode_enabled = false; log_view.scroll_following = true; log_view.size_flags_vertical = Control.SIZE_EXPAND_FILL; log_view.add_theme_font_size_override("normal_font_size", 17); left.add_child(log_view)
	var right_panel := PanelContainer.new(); right_panel.custom_minimum_size = Vector2(360, 0); columns.add_child(right_panel)
	var right := VBoxContainer.new(); right.add_theme_constant_override("separation", 10); right_panel.add_child(right)
	var action_title := Label.new(); action_title.text = "行动"; action_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; action_title.add_theme_font_size_override("font_size", 22); right.add_child(action_title)
	actions_box = VBoxContainer.new(); actions_box.size_flags_vertical = Control.SIZE_EXPAND_FILL; actions_box.add_theme_constant_override("separation", 8); right.add_child(actions_box)

func _process_result(result: Dictionary) -> void:
	if result.get("clear_log", false): log_view.clear()
	for line in result.get("logs", []): log_view.append_text("%s\n" % line)
	status_label.text = game.get_status_text()
	for child in actions_box.get_children(): child.queue_free()
	for action in result.get("actions", []):
		var button := Button.new(); button.text = action.label; button.disabled = action.get("disabled", false); button.custom_minimum_size = Vector2(0, 45); button.add_theme_font_size_override("font_size", 17); button.pressed.connect(_pressed.bind(action)); actions_box.add_child(button)
	if result.has("timer"):
		await get_tree().create_timer(result.timer).timeout
		_process_result(game.execute_action(result.next_action))

func _pressed(action: Dictionary) -> void:
	if action.id == "character":
		var dialog := AcceptDialog.new(); dialog.title = "角色面板与规则"; dialog.size = Vector2i(680, 560)
		var text := RichTextLabel.new(); text.bbcode_enabled = false; text.text = game.character_text(); text.custom_minimum_size = Vector2(630, 440); text.add_theme_font_size_override("normal_font_size", 17); dialog.add_child(text); add_child(dialog)
		dialog.confirmed.connect(dialog.queue_free)
		dialog.close_requested.connect(dialog.queue_free)
		dialog.popup_centered(); return
	_process_result(game.execute_action(action.id, action.args))
