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
	selection_cards.add_theme_constant_override("separation", 28)
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
	var story_title := Label.new()
	story_title.text = "旅途记录"
	story_title.add_theme_font_size_override("font_size", 27)
	story_title.add_theme_color_override("font_color", Color("dbc184"))
	story_box.add_child(story_title)
	log_view = RichTextLabel.new()
	log_view.bbcode_enabled = false
	log_view.scroll_following = true
	log_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_view.add_theme_font_size_override("normal_font_size", 20)
	log_view.add_theme_color_override("default_color", Color("e2e1df"))
	story_box.add_child(log_view)

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

func _action_icon(action: Dictionary) -> Texture2D:
	var id: String = action.id
	if id == "select_target": id = action.args.get("next", "")
	var icons := {
		"attack":"icon-warrior-power-attack.png", "shield_bash":"icon-warrior-shield-bash.png", "defend":"icon-warrior-guard-stance.png",
		"arcane_bolt":"icon-arcane-missile.png", "arcane_torrent":"icon-arcane-torrent.png", "spell_slot":"icon-spell-slots.png",
		"tough":"icon-warrior-endure.png", "dodge":"icon-warrior-dodge.png", "parry":"icon-warrior-parry.png",
		"arcane_barrier":"icon-mage-spell-charge.png", "energy_counter":"icon-spell-slots.png",
		"items":"potion-bottle.png", "use_item":"potion-bottle.png", "drop_inventory_item":"potion-bottle.png",
		"spellsword_attack":"icon-warrior-power-attack.png", "magic_guard":"icon-shield-v2.png", "magic_armor_ritual":"icon-mage-spell-charge.png",
		"magic_dodge":"icon-warrior-dodge.png", "magic_parry":"icon-warrior-parry.png"
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
		card.custom_minimum_size = Vector2(360, 0)
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _panel_style())
		selection_cards.add_child(card)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 10)
		card.add_child(content)
		var portrait := TextureButton.new()
		if class_id == "warrior": portrait.texture_normal = _texture("veteran-warrior-portrait.png")
		elif class_id == "mage": portrait.texture_normal = _texture("female-arcane-mage-refined.png")
		portrait.ignore_texture_size = true
		portrait.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(0, 320)
		portrait.tooltip_text = "点击选择%s" % ("战士" if class_id == "warrior" else "法师" if class_id == "mage" else "魔剑士")
		portrait.pressed.connect(_pressed.bind(action))
		content.add_child(portrait)
		var label := Label.new()
		label.text = action.label
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 17)
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
	var selecting := game.phase == "CHARACTER_SELECT"
	var in_main_menu := game.phase == "MAIN_MENU"
	logo.visible = selecting or in_main_menu
	game_body.visible = not selecting and not in_main_menu
	status_panel.visible = not selecting and not in_main_menu
	selection_panel.visible = selecting
	main_menu_panel.visible = in_main_menu
	_sync_bgm()
	_refresh_status()
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
