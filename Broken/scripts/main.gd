extends Control

const UI := "res://assets/ui/"
const BGM := "res://assets/audio/"
const BGM_TRACKS := {
	1: "01_Limbo_Isle_of_the_Dead_loop.ogg",
	2: "02_Eroded_World_Le_Gibet_loop.ogg",
	3: "03_Fallen_Heaven_BWV582_loop.ogg",
	4: "04_End_Mahler9_Adagio_loop.ogg"
}

var game := BrokenGameState.new()
var log_view: RichTextLabel
var story_title: Label
var battle_log_toggle: Button
var battle_scroll: ScrollContainer
var battle_board: VBoxContainer
var actions_box: VBoxContainer
var action_title: Label
var status_panel: PanelContainer
var status_box: HBoxContainer
var game_body: HBoxContainer
var selection_panel: PanelContainer
var selection_cards: HBoxContainer
var main_menu_panel: PanelContainer
var main_menu_actions: VBoxContainer
var main_menu_buttons: VBoxContainer
var logo: TextureRect
var bgm_player: AudioStreamPlayer
var current_bgm_file := ""
var battle_log_expanded := false
var was_in_combat := false
var last_combat_events: Array = []
var defense_feedback: Dictionary = {}
var last_defense_feedback: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_audio()
	_build_ui()
	_process_result(game.main_menu())

func _build_audio() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BackgroundMusic"
	bgm_player.volume_db = -5.0
	bgm_player.finished.connect(_restart_bgm)
	add_child(bgm_player)

func _sync_bgm() -> void:
	var desired_file := ""
	if not game.player.is_empty() and game.phase != "MAIN_MENU" and game.phase != "CHARACTER_SELECT":
		desired_file = BGM_TRACKS.get(mini(game.current_floor, 4), BGM_TRACKS[4])
	if desired_file == current_bgm_file: return
	current_bgm_file = desired_file
	bgm_player.stop()
	if desired_file.is_empty(): return
	var stream := load(BGM + desired_file) as AudioStream
	if stream:
		var ogg_stream := stream as AudioStreamOggVorbis
		if ogg_stream: ogg_stream.loop = true
		bgm_player.stream = stream
		bgm_player.play()
	else:
		current_bgm_file = ""

func _restart_bgm() -> void:
	if not current_bgm_file.is_empty() and bgm_player.stream:
		bgm_player.play()

func _texture(file_name: String) -> Texture2D:
	return load(UI + file_name) as Texture2D

func _panel_style() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _texture("ui-panel-dark-texture.png")
	style.texture_margin_left = 42
	style.texture_margin_top = 42
	style.texture_margin_right = 42
	style.texture_margin_bottom = 42
	style.content_margin_left = 22
	style.content_margin_top = 18
	style.content_margin_right = 22
	style.content_margin_bottom = 18
	return style

func _button_style(file_name: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _texture(file_name)
	style.texture_margin_left = 52
	style.texture_margin_top = 26
	style.texture_margin_right = 52
	style.texture_margin_bottom = 26
	style.content_margin_left = 24
	style.content_margin_right = 24
	return style

func _apply_button_style(button: Button, normal_file := "ui-button-normal-v2.png") -> void:
	button.add_theme_stylebox_override("normal", _button_style(normal_file))
	button.add_theme_stylebox_override("hover", _button_style(normal_file))
	button.add_theme_stylebox_override("disabled", _button_style(normal_file))
	button.add_theme_color_override("font_color", Color("efe8d5"))
	button.add_theme_color_override("font_hover_color", Color("f7d77e"))
	button.add_theme_color_override("font_disabled_color", Color("797b81"))

func _build_ui() -> void:
	var background := TextureRect.new()
	background.texture = _texture("main-menu-shattered-heaven-styx.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.035, 0.06, 0.52)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 34)
	root.add_theme_constant_override("margin_right", 34)
	root.add_theme_constant_override("margin_top", 20)
	root.add_theme_constant_override("margin_bottom", 24)
	add_child(root)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	root.add_child(layout)

	logo = TextureRect.new()
	logo.texture = _texture("broken-title-logo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(0, 112)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(logo)

	status_panel = PanelContainer.new()
	status_panel.add_theme_stylebox_override("panel", _panel_style())
	status_panel.custom_minimum_size = Vector2(0, 70)
	layout.add_child(status_panel)
	status_box = HBoxContainer.new()
	status_box.alignment = BoxContainer.ALIGNMENT_CENTER
	status_box.add_theme_constant_override("separation", 24)
	status_panel.add_child(status_box)

	game_body = HBoxContainer.new()
	game_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	game_body.add_theme_constant_override("separation", 16)
	layout.add_child(game_body)
	_build_game_body()

	selection_panel = PanelContainer.new()
	selection_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	selection_panel.add_theme_stylebox_override("panel", _panel_style())
	layout.add_child(selection_panel)
	var selection_content := VBoxContainer.new()
	selection_content.add_theme_constant_override("separation", 12)
	selection_panel.add_child(selection_content)
	var selection_title := Label.new()
	selection_title.text = "选择轮回者的战斗职业"
	selection_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selection_title.add_theme_font_size_override("font_size", 28)
	selection_content.add_child(selection_title)
	selection_cards = HBoxContainer.new()
	selection_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	selection_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	selection_cards.add_theme_constant_override("separation", 16)
	selection_content.add_child(selection_cards)

	main_menu_panel = PanelContainer.new()
	main_menu_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_menu_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	layout.add_child(main_menu_panel)
	var menu_center := CenterContainer.new()
	main_menu_panel.add_child(menu_center)
	main_menu_actions = VBoxContainer.new()
	main_menu_actions.custom_minimum_size = Vector2(390, 0)
	main_menu_actions.add_theme_constant_override("separation", 20)
	menu_center.add_child(main_menu_actions)
	var menu_subtitle := Label.new()
	menu_subtitle.text = "在诸神遗骸与冥河雾海之间，找回仍属于你的名字。"
	menu_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_subtitle.add_theme_font_size_override("font_size", 20)
	menu_subtitle.add_theme_color_override("font_color", Color("d1c8b0"))
	main_menu_actions.add_child(menu_subtitle)
	main_menu_actions.add_child(HSeparator.new())
	main_menu_buttons = VBoxContainer.new()
	main_menu_buttons.add_theme_constant_override("separation", 12)
	main_menu_actions.add_child(main_menu_buttons)

func _build_game_body() -> void:
	var story_panel := PanelContainer.new()
	story_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_panel.size_flags_stretch_ratio = 1.85
	story_panel.add_theme_stylebox_override("panel", _panel_style())
	game_body.add_child(story_panel)
	var story_box := VBoxContainer.new()
	story_box.add_theme_constant_override("separation", 10)
	story_panel.add_child(story_box)
	var story_header := HBoxContainer.new()
	story_header.add_theme_constant_override("separation", 12)
	story_box.add_child(story_header)
	story_title = Label.new()
	story_title.text = "旅途记录"
	story_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_title.add_theme_font_size_override("font_size", 27)
	story_title.add_theme_color_override("font_color", Color("dbc184"))
	story_header.add_child(story_title)
	battle_log_toggle = Button.new()
	battle_log_toggle.visible = false
	battle_log_toggle.custom_minimum_size = Vector2(176, 42)
	battle_log_toggle.add_theme_font_size_override("font_size", 16)
	battle_log_toggle.add_theme_color_override("font_color", Color("dbc184"))
	battle_log_toggle.pressed.connect(_toggle_battle_log)
	story_header.add_child(battle_log_toggle)
	log_view = RichTextLabel.new()
	log_view.bbcode_enabled = false
	log_view.scroll_following = true
	log_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_view.add_theme_font_size_override("normal_font_size", 20)
	log_view.add_theme_color_override("default_color", Color("e2e1df"))
	story_box.add_child(log_view)
	battle_scroll = ScrollContainer.new()
	battle_scroll.visible = false
	battle_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	story_box.add_child(battle_scroll)
	battle_board = VBoxContainer.new()
	battle_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_board.add_theme_constant_override("separation", 12)
	battle_scroll.add_child(battle_board)

	var action_panel := PanelContainer.new()
	action_panel.custom_minimum_size = Vector2(430, 0)
	action_panel.add_theme_stylebox_override("panel", _panel_style())
	game_body.add_child(action_panel)
	var action_box := VBoxContainer.new()
	action_box.add_theme_constant_override("separation", 12)
	action_panel.add_child(action_box)
	action_title = Label.new()
	action_title.text = "行动"
	action_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_title.add_theme_font_size_override("font_size", 29)
	action_title.add_theme_color_override("font_color", Color("dbc184"))
	action_box.add_child(action_title)
	action_box.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	action_box.add_child(scroll)
	actions_box = VBoxContainer.new()
	actions_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_box.add_theme_constant_override("separation", 10)
	scroll.add_child(actions_box)

func _status_chip(icon_file: String, text: String) -> Control:
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 7)
	var icon := TextureRect.new()
	icon.texture = _texture(icon_file)
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(icon)
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	chip.add_child(label)
	return chip

func _refresh_status() -> void:
	for child in status_box.get_children(): child.queue_free()
	if game.player.is_empty(): return
	status_box.add_child(_status_chip("icon-health-v2.png", "%d / %d" % [game.player.current_hp, game.player.max_hp]))
	status_box.add_child(_status_chip("icon-shield-v2.png", "%d" % game.player.temp_hp))
	status_box.add_child(_status_chip("icon-ac-v2.png", "%d" % game.player.ac))
	if game.current_floor >= 2: status_box.add_child(_status_chip("icon-memory-v2.png", "%d / %d" % [game.player.memory, game.player.max_memory]))
	if game.is_mage(): status_box.add_child(_status_chip("icon-mage-spell-charge.png", "%d / 5" % game.player.charge))
	if game.is_shadowdancer():
		var shadow_status := Label.new()
		shadow_status.text = "🌑 %d / 4" % game.player.shadow_marks
		shadow_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		shadow_status.add_theme_font_size_override("font_size", 18)
		shadow_status.add_theme_color_override("font_color", Color("a99ad5"))
		status_box.add_child(shadow_status)
	if game.is_spellsword() and not game.magic_armors.is_empty():
		var armor_entries := []
		for armor in game.magic_armors: armor_entries.append("%s·%d" % [armor.name, armor.turns])
		var armor_status := Label.new()
		armor_status.text = "🪄 %s" % " / ".join(armor_entries)
		armor_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		armor_status.add_theme_font_size_override("font_size", 18)
		armor_status.add_theme_color_override("font_color", Color("cfb7ed"))
		status_box.add_child(armor_status)
	status_box.add_child(_status_chip("potion-bottle.png", "%d/%d" % [game.player.items.size(), BrokenGameState.MAX_POTION_SLOTS]))
	var distance := Label.new()
	distance.text = "距离 %d 步" % game.distance_to_boss
	distance.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	distance.add_theme_font_size_override("font_size", 19)
	distance.add_theme_color_override("font_color", Color("b9bdd0"))
	status_box.add_child(distance)

func _is_combat_context() -> bool:
	if game.phase.begins_with("COMBAT") or game.phase == "TARGETING": return true
	if game.phase in ["SPELL_SELECT", "SPELL_TARGET", "MAGIC_ARMOR_SELECT"]: return true
	return game.phase in ["ITEM_SELECT", "ITEM_TARGET"] and game.inventory_opened_from_combat

func _toggle_battle_log() -> void:
	if not _is_combat_context(): return
	battle_log_expanded = not battle_log_expanded
	_refresh_story_panel()

func _refresh_story_panel() -> void:
	var in_combat := _is_combat_context()
	if in_combat and not was_in_combat: battle_log_expanded = false
	if not in_combat: battle_log_expanded = false
	was_in_combat = in_combat
	battle_log_toggle.visible = in_combat
	battle_scroll.visible = in_combat and not battle_log_expanded
	log_view.visible = not in_combat or battle_log_expanded
	if not in_combat:
		story_title.text = "旅途记录"
		return
	if battle_log_expanded:
		story_title.text = "战斗记录"
		battle_log_toggle.text = "⚔️ 返回战斗概览"
		return
	story_title.text = "战斗概览"
	battle_log_toggle.text = "📜 展开战斗记录"
	_refresh_battle_board()

func _combat_card_style(border_color: Color, background_color := Color(0.04, 0.055, 0.09, 0.92)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	return style

func _battle_focus_style() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _texture("combat-focus-frame.png")
	style.texture_margin_left = 76
	style.texture_margin_top = 76
	style.texture_margin_right = 76
	style.texture_margin_bottom = 76
	style.content_margin_left = 30
	style.content_margin_top = 24
	style.content_margin_right = 30
	style.content_margin_bottom = 24
	return style

func _health_bar(current_hp: int, max_hp: int, fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = maxi(1, max_hp)
	bar.value = current_hp
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 11)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.015, 0.02, 0.035, 0.95)
	background.set_corner_radius_all(6)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _combat_phase_hint() -> String:
	match game.phase:
		"COMBAT_PLAYER": return "选择行动"
		"TARGETING": return "锁定目标"
		"COMBAT_ENEMY": return "敌方行动"
		"COMBAT_DEFEND": return "选择反制"
		"SPELL_SELECT": return "选择法术"
		"SPELL_TARGET": return "选择法术目标"
		"MAGIC_ARMOR_SELECT": return "选择魔装"
		"ITEM_SELECT", "ITEM_TARGET": return "使用道具"
	return "战斗进行中。"

func _recent_battle_event() -> String:
	if not last_defense_feedback.is_empty() and game.phase != "COMBAT_DEFEND":
		return _defense_recent_text(last_defense_feedback)
	var lines: Array = []
	for entry in last_combat_events:
		for raw_line in str(entry).split("\n", false):
			var line := raw_line.strip_edges()
			if line.is_empty() or line.begins_with("===") or line.begins_with("---"): continue
			if line in ["【你的回合】", "【敌人回合】", "请选择应对方式："]: continue
			lines.append(line)
	if lines.is_empty(): return "最近结果会显示在这里；完整过程可随时展开查看。"
	return "上一次：%s" % lines.back()

func _defense_recent_text(feedback: Dictionary) -> String:
	var action_name := str(feedback.get("action", "防御"))
	var status := "成功" if bool(feedback.get("success", false)) else "失败"
	var details := ["上一轮防御：%s（%s）" % [action_name, status]]
	var check_text := str(feedback.get("check_text", ""))
	if not check_text.is_empty(): details.append(check_text)
	details.append("防御后伤害 %d" % int(feedback.get("damage", 0)))
	var shield_absorbed := int(feedback.get("shield_absorbed", 0))
	var hp_loss := int(feedback.get("hp_loss", 0))
	if shield_absorbed > 0: details.append("护盾 -%d" % shield_absorbed)
	if hp_loss > 0:
		details.append("HP -%d" % hp_loss)
	else:
		details.append("HP 未损失")
	return " · ".join(details)

func _add_compact_unit(parent: Container, title: String, detail: String, current_hp: int, max_hp: int, color: Color) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _combat_card_style(color, Color(0.025, 0.035, 0.06, 0.9)))
	parent.add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	card.add_child(content)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color", color.lightened(0.2))
	content.add_child(heading)
	content.add_child(_health_bar(current_hp, max_hp, color))
	var status := Label.new()
	status.text = detail
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", Color("dce1eb"))
	content.add_child(status)

func _add_focus_value(parent: Container, label_text: String, value_text: String, color: Color) -> void:
	var chip := PanelContainer.new()
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.add_theme_stylebox_override("panel", _combat_card_style(color, Color(0.025, 0.03, 0.05, 0.95)))
	parent.add_child(chip)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	chip.add_child(content)
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color("c8cbd4"))
	content.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 26)
	value.add_theme_color_override("font_color", color.lightened(0.2))
	content.add_child(value)

func _battle_focus_art(file_name: String, side := 72.0) -> TextureRect:
	var art := TextureRect.new()
	art.texture = _texture(file_name)
	art.custom_minimum_size = Vector2(side, side)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return art

func _add_battle_focus(parent: VBoxContainer) -> void:
	var showing_feedback := not defense_feedback.is_empty()
	var feedback_success := bool(defense_feedback.get("success", false))
	var focus := PanelContainer.new()
	focus.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus.add_theme_stylebox_override("panel", _battle_focus_style())
	parent.add_child(focus)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	focus.add_child(content)
	if showing_feedback:
		var action_name := str(defense_feedback.get("action", "防御"))
		var damage: int = defense_feedback.get("damage", 0)
		var result_row := HBoxContainer.new()
		result_row.add_theme_constant_override("separation", 14)
		content.add_child(result_row)
		result_row.add_child(_battle_focus_art("combat-defense-success.png" if feedback_success else "combat-defense-failure.png", 78.0))
		var result_text := VBoxContainer.new()
		result_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		result_text.add_theme_constant_override("separation", 6)
		result_row.add_child(result_text)
		var result_label := Label.new()
		result_label.text = "✓ 防御成功  ·  结果结算中" if feedback_success else "✕ 防御失败  ·  结果结算中"
		result_label.add_theme_font_size_override("font_size", 18)
		result_label.add_theme_color_override("font_color", Color("9be1b1") if feedback_success else Color("ef9b9b"))
		result_text.add_child(result_label)
		var result_title := Label.new()
		result_title.text = "【%s】已结算" % action_name
		result_title.add_theme_font_size_override("font_size", 31)
		result_title.add_theme_color_override("font_color", Color("eff9ef") if feedback_success else Color("fff0ec"))
		result_text.add_child(result_title)
		var result_detail := Label.new()
		result_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result_detail.text = "本次防御后伤害：0" if damage == 0 else "本次防御后伤害：%d（护盾会优先吸收）" % damage
		result_detail.add_theme_font_size_override("font_size", 19)
		result_detail.add_theme_color_override("font_color", Color("d5e5d8") if feedback_success else Color("f0d6d2"))
		result_text.add_child(result_detail)
		return
	if game.phase == "COMBAT_DEFEND":
		var source := str(game.pending_defense.get("source_name", "敌人"))
		var attack := str(game.pending_defense.get("attack_name", "攻击"))
		var enemy_roll: int = game.pending_defense.get("roll", 0)
		var damage: int = game.pending_defense.get("damage", 0)
		var intent_row := HBoxContainer.new()
		intent_row.add_theme_constant_override("separation", 14)
		content.add_child(intent_row)
		intent_row.add_child(_battle_focus_art("combat-enemy-intent.png", 76.0))
		var intent_text := VBoxContainer.new()
		intent_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		intent_text.add_theme_constant_override("separation", 6)
		intent_row.add_child(intent_text)
		var warning := Label.new()
		warning.text = "⚠️ 敌人来袭  ·  现在选择反制"
		warning.add_theme_font_size_override("font_size", 18)
		warning.add_theme_color_override("font_color", Color("ef9b9b"))
		intent_text.add_child(warning)
		var title := Label.new()
		title.text = "%s  使用【%s】" % [source, attack]
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.add_theme_font_size_override("font_size", 31)
		title.add_theme_color_override("font_color", Color("fff0ec"))
		intent_text.add_child(title)
		var values := HBoxContainer.new()
		values.add_theme_constant_override("separation", 10)
		content.add_child(values)
		_add_focus_value(values, "攻击判定", str(enemy_roll), Color("e77c69"))
		_add_focus_value(values, "来袭伤害", str(damage), Color("d3ab56"))
		var preview := Label.new()
		preview.text = "攻击判定与原始伤害已公开；根据你的构筑与规则选择反制。"
		preview.add_theme_font_size_override("font_size", 17)
		preview.add_theme_color_override("font_color", Color("e8e0c3"))
		content.add_child(preview)
		return
	var phase := Label.new()
	phase.text = "第 %d 回合  ·  %s" % [game.combat_round, _combat_phase_hint()]
	phase.add_theme_font_size_override("font_size", 18)
	phase.add_theme_color_override("font_color", Color("b9cde5"))
	content.add_child(phase)
	var title := Label.new()
	title.text = "你的回合" if game.phase == "COMBAT_PLAYER" else _combat_phase_hint()
	title.add_theme_font_size_override("font_size", 31)
	title.add_theme_color_override("font_color", Color("f0e8d0"))
	content.add_child(title)
	var detail := Label.new()
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if game.phase == "COMBAT_PLAYER":
		detail.text = "从右侧选择技能。敌方的 AC、血量和异常状态已收在上方状态条中。"
	elif game.phase == "TARGETING":
		detail.text = "选择要处理的敌人；优先击杀威胁最高或血量最低的目标。"
	else:
		detail.text = "等待当前行动结算；完整过程可随时从右上角的战斗记录查看。"
	detail.add_theme_font_size_override("font_size", 18)
	detail.add_theme_color_override("font_color", Color("d5d9e2"))
	content.add_child(detail)

func _refresh_battle_board() -> void:
	for child in battle_board.get_children():
		battle_board.remove_child(child)
		child.queue_free()
	var heading := Label.new()
	heading.text = "战况"
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color", Color("9faabd"))
	battle_board.add_child(heading)
	var top_strip := HBoxContainer.new()
	top_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_strip.add_theme_constant_override("separation", 10)
	battle_board.add_child(top_strip)
	var player_column := VBoxContainer.new()
	player_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_column.size_flags_stretch_ratio = 1.0
	top_strip.add_child(player_column)
	var player_resources: Array = []
	if game.current_floor >= 2: player_resources.append("记忆 %d/%d" % [game.player.memory, game.player.max_memory])
	if game.is_mage(): player_resources.append("充能 %d/5" % game.player.charge)
	if game.is_shadowdancer(): player_resources.append("影痕 %d/4" % game.player.shadow_marks)
	if game.is_spellsword() and not game.magic_armors.is_empty(): player_resources.append("魔装 %d" % game.magic_armors.size())
	var player_detail := "HP %d/%d · 护盾 %d · AC %d" % [game.player.current_hp, game.player.max_hp, game.player.temp_hp, game.player.ac]
	if not player_resources.is_empty(): player_detail += " · " + " / ".join(player_resources)
	_add_compact_unit(player_column, "%s · %s" % [game.player.name, game.player.class_name], player_detail, game.player.current_hp, game.player.max_hp, Color("559fe7"))
	var versus := Label.new()
	versus.text = "VS"
	versus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	versus.add_theme_font_size_override("font_size", 18)
	versus.add_theme_color_override("font_color", Color("d4c9a4"))
	top_strip.add_child(versus)
	var enemy_column := VBoxContainer.new()
	enemy_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_column.size_flags_stretch_ratio = 1.25
	enemy_column.add_theme_constant_override("separation", 5)
	top_strip.add_child(enemy_column)
	for enemy in game.alive_enemies():
		var tier: String = enemy.tier
		var tier_name := "普通"
		var color := Color("a2626a")
		if tier == "elite":
			tier_name = "精英"
			color = Color("ca9b45")
		elif tier == "boss":
			tier_name = "首领"
			color = Color("b178d4")
		var penalty: int = enemy.next_attack_penalty
		var enemy_subtitle := "%s · HP %d/%d · AC %d" % [tier_name, enemy.current_hp, enemy.max_hp, enemy.ac]
		if penalty > 0: enemy_subtitle += " · 下次攻击 -%d" % penalty
		if enemy.get("poison_turns", 0) > 0: enemy_subtitle += " · 中毒 %d 回合" % enemy.poison_turns
		_add_compact_unit(enemy_column, enemy.name, enemy_subtitle, enemy.current_hp, enemy.max_hp, color)
	_add_battle_focus(battle_board)
	var recent_panel := PanelContainer.new()
	recent_panel.add_theme_stylebox_override("panel", _combat_card_style(Color("687893"), Color(0.025, 0.035, 0.055, 0.88)))
	battle_board.add_child(recent_panel)
	var recent := Label.new()
	recent.text = _recent_battle_event()
	recent.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recent.add_theme_font_size_override("font_size", 16)
	recent.add_theme_color_override("font_color", Color("dce1eb"))
	recent_panel.add_child(recent)

func _action_icon(action: Dictionary) -> Texture2D:
	var id: String = action.id
	if id == "select_target": id = action.args.get("next", "")
	if id == "tough" and game.is_spellsword(): return _texture("icon-spellsword-tough.png")
	var icons := {
		"attack":"icon-warrior-power-attack.png", "shield_bash":"icon-warrior-shield-bash.png", "defend":"icon-warrior-guard-stance.png",
		"arcane_bolt":"icon-arcane-missile.png", "arcane_torrent":"icon-arcane-torrent.png", "spell_slot":"icon-spell-slots.png",
		"tough":"icon-warrior-endure.png", "dodge":"icon-warrior-dodge.png", "parry":"icon-warrior-parry.png",
		"arcane_barrier":"icon-mage-spell-charge.png", "energy_counter":"icon-spell-slots.png",
		"items":"potion-bottle.png", "use_item":"potion-bottle.png", "drop_inventory_item":"potion-bottle.png",
		"spellsword_attack":"icon-spellsword-attack.png", "magic_guard":"icon-spellsword-guard.png", "magic_armor_ritual":"icon-spellsword-ritual.png",
		"magic_dodge":"icon-spellsword-dodge.png", "magic_parry":"icon-spellsword-parry.png",
		"shadow_combo":"icon-shadowdancer-combo.png", "shadow_poison":"icon-shadowdancer-poison.png", "shadow_execute":"icon-shadowdancer-execute.png",
		"shadow_dodge":"icon-shadowdancer-dodge.png", "shadow_smoke":"icon-shadowdancer-smoke.png", "shadow_substitute":"icon-shadowdancer-substitute.png"
	}
	if icons.has(id): return _texture(icons[id])
	return null

func _add_action_button(action: Dictionary) -> void:
	var button := Button.new()
	button.text = action.label
	button.disabled = action.get("disabled", false)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var is_item_action: bool = action.get("style", "") == "item"
	button.custom_minimum_size = Vector2(0, 118 if is_item_action else 78 if action.get("style", "") == "combat" else 66)
	button.add_theme_font_size_override("font_size", 22 if is_item_action else 19)
	var icon := _action_icon(action)
	if icon:
		button.icon = icon
		button.expand_icon = false
		button.add_theme_constant_override("icon_max_width", 86 if is_item_action else 64)
	_apply_button_style(button)
	button.pressed.connect(_pressed.bind(action))
	actions_box.add_child(button)

func _build_character_cards(actions: Array) -> void:
	for child in selection_cards.get_children(): child.queue_free()
	for action in actions:
		var class_id: String = action.args.get("character_id", "")
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_stretch_ratio = 1.0
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _panel_style())
		selection_cards.add_child(card)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 10)
		card.add_child(content)
		var portrait := TextureButton.new()
		if class_id == "warrior": portrait.texture_normal = _texture("veteran-warrior-portrait.png")
		elif class_id == "mage": portrait.texture_normal = _texture("female-arcane-mage-refined.png")
		elif class_id == "spellsword": portrait.texture_normal = _texture("spellsword-portrait.png")
		elif class_id == "shadowdancer": portrait.texture_normal = _texture("shadowdancer-portrait.png")
		portrait.ignore_texture_size = true
		portrait.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(0, 240)
		portrait.tooltip_text = "点击选择%s" % ("战士" if class_id == "warrior" else "法师" if class_id == "mage" else "魔剑士" if class_id == "spellsword" else "影舞者")
		portrait.pressed.connect(_pressed.bind(action))
		content.add_child(portrait)
		var label := Label.new()
		label.text = action.label
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 15)
		content.add_child(label)

func _build_main_menu(actions: Array) -> void:
	for child in main_menu_buttons.get_children(): child.queue_free()
	for action in actions:
		var button := Button.new()
		button.text = action.label
		button.custom_minimum_size = Vector2(0, 76)
		button.add_theme_font_size_override("font_size", 23)
		_apply_button_style(button)
		button.pressed.connect(_pressed.bind(action))
		main_menu_buttons.add_child(button)

func _set_action_title() -> void:
	if game.phase == "CHARACTER_SELECT": action_title.text = "选择角色"
	elif game.phase == "THIRD_FLOOR_EVENT": action_title.text = "圣阶抉择"
	elif game.phase == "SPELL_SELECT": action_title.text = "选择高阶法术"
	elif game.phase == "SPELL_TARGET": action_title.text = "选择施法目标"
	elif game.phase == "MAGIC_ARMOR_SELECT": action_title.text = "选择魔装"
	elif game.phase == "ITEM_SELECT": action_title.text = "道具栏"
	elif game.phase == "ITEM_TARGET": action_title.text = "选择药水目标"
	elif game.phase == "POTION_PICKUP": action_title.text = "发现药水"
	elif game.phase == "TARGETING": action_title.text = "选择攻击目标"
	elif game.phase == "COMBAT_DEFEND": action_title.text = "选择防御方式"
	else: action_title.text = "行动"

func _process_result(result: Dictionary) -> void:
	if result.get("clear_log", false): log_view.clear()
	for line in result.get("logs", []): log_view.append_text("%s\n" % line)
	if _is_combat_context() and not result.get("logs", []).is_empty(): last_combat_events = result.get("logs", []).duplicate()
	if result.has("defense_feedback"):
		defense_feedback = (result.get("defense_feedback", {}) as Dictionary).duplicate()
		last_defense_feedback = defense_feedback.duplicate()
	elif not result.get("logs", []).is_empty():
		defense_feedback = {}
	var selecting := game.phase == "CHARACTER_SELECT"
	var in_main_menu := game.phase == "MAIN_MENU"
	logo.visible = selecting or in_main_menu
	game_body.visible = not selecting and not in_main_menu
	status_panel.visible = not selecting and not in_main_menu
	selection_panel.visible = selecting
	main_menu_panel.visible = in_main_menu
	_sync_bgm()
	_refresh_status()
	_refresh_story_panel()
	_set_action_title()
	if in_main_menu:
		_build_main_menu(result.get("actions", []))
	elif selecting:
		_build_character_cards(result.get("actions", []))
	else:
		for child in actions_box.get_children(): child.queue_free()
		for action in result.get("actions", []): _add_action_button(action)
	if result.has("timer"):
		await get_tree().create_timer(result.timer).timeout
		_process_result(game.execute_action(result.next_action))

func _pressed(action: Dictionary) -> void:
	if action.id == "quit_game":
		get_tree().quit()
		return
	if action.id == "character":
		var dialog := AcceptDialog.new()
		dialog.title = "角色面板与规则"
		dialog.size = Vector2i(720, 640)
		var text := RichTextLabel.new()
		text.bbcode_enabled = false
		text.text = game.character_text()
		text.custom_minimum_size = Vector2(670, 510)
		text.add_theme_font_size_override("normal_font_size", 17)
		dialog.add_child(text)
		add_child(dialog)
		dialog.confirmed.connect(dialog.queue_free)
		dialog.close_requested.connect(dialog.queue_free)
		dialog.popup_centered()
		return
	_process_result(game.execute_action(action.id, action.args))
