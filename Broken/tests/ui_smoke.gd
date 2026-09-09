extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen: Node = (load("res://Main.tscn") as PackedScene).instantiate()
	root.add_child(screen)
	await process_frame
	var game_state: BrokenGameState = screen.get("game")
	assert(game_state.phase == "MAIN_MENU")
	var menu_buttons: VBoxContainer = screen.get("main_menu_buttons")
	assert(menu_buttons.get_child_count() == 2)
	(menu_buttons.get_child(0) as Button).emit_signal("pressed")
	await process_frame
	var portraits: Array = []
	_collect_portrait_buttons(screen, portraits)
	assert(portraits.size() == 4)
	assert(portraits[2].texture_normal != null)
	assert(portraits[3].texture_normal != null)
	var card_viewport_width: float = screen.get_viewport_rect().size.x
	var cards: HBoxContainer = screen.get("selection_cards")
	for card in cards.get_children():
		assert(card.get_global_rect().position.x >= 0)
		assert(card.get_global_rect().end.x <= card_viewport_width)
	portraits[0].emit_signal("pressed")
	await process_frame
	assert(game_state.player.class_id == "warrior")
	assert(game_state.player.name == "轮回者")
	assert(game_state.player.class_name == "战士")
	for file_name in ["combat-defense-success.png", "combat-defense-failure.png", "combat-enemy-intent.png", "combat-focus-frame.png"]:
		assert(screen._texture(file_name) != null)
	screen._process_result(game_state.start_combat(["LostSoul"], false))
	await process_frame
	assert(screen.actions_box.get_child_count() == 5)
	assert(screen.get("story_title").text == "战斗概览")
	assert(screen.get("battle_scroll").visible)
	assert(not screen.get("log_view").visible)
	assert(screen.get("battle_log_toggle").visible)
	var battle_board: VBoxContainer = screen.get("battle_board")
	assert(battle_board.get_child_count() >= 4)
	assert((screen.get("battle_scroll") as ScrollContainer).get_global_rect().size.y > 200)
	assert(battle_board.get_child(1).get_global_rect().size.y > 0)
	game_state.pending_defense = {"source_name":"迷途古魂", "attack_name":"锈蚀短剑", "roll":16, "damage":4}
	game_state.phase = "COMBAT_DEFEND"
	screen._process_result({"logs":[], "actions":[]})
	await process_frame
	var battle_text: Array = []
	_collect_label_text(screen.get("battle_board"), battle_text)
	assert(battle_text.has("迷途古魂  使用【锈蚀短剑】"))
	assert(battle_text.has("攻击判定"))
	assert(battle_text.has("16"))
	assert(battle_text.has("来袭伤害"))
	assert(battle_text.has("4"))
	assert(not battle_text.has("你的 AC"))
	screen._process_result({"logs":[], "actions":[], "defense_feedback":{"action":"招架", "success":true, "damage":0, "check_text":"力量检定 18 对 攻击判定 16", "shield_absorbed":0, "hp_loss":0}})
	await process_frame
	var defense_result_text: Array = []
	_collect_label_text(screen.get("battle_board"), defense_result_text)
	assert(defense_result_text.has("✓ 防御成功  ·  结果结算中"))
	assert(defense_result_text.has("【招架】已结算"))
	assert(defense_result_text.has("本次防御后伤害：0"))
	game_state.phase = "COMBAT_PLAYER"
	screen._process_result({"logs":[], "actions":[]})
	await process_frame
	var recent_result_text: Array = []
	_collect_label_text(screen.get("battle_board"), recent_result_text)
	assert(recent_result_text.has("上一轮防御：招架（成功） · 力量检定 18 对 攻击判定 16 · 防御后伤害 0 · HP 未损失"))
	screen._toggle_battle_log()
	await process_frame
	assert(screen.get("story_title").text == "战斗记录")
	assert(screen.get("log_view").visible)
	assert(not screen.get("battle_scroll").visible)
	screen._toggle_battle_log()
	screen._process_result(game_state.select_target("attack"))
	await process_frame
	assert(game_state.phase == "TARGETING")
	assert(screen.get("battle_scroll").visible)
	screen._process_result(game_state.player_actions())
	screen._process_result(game_state.show_item_selection())
	await process_frame
	assert(game_state.phase == "ITEM_SELECT")
	assert(screen.get("battle_scroll").visible)
	game_state.phase = "EXPLORE"
	screen._process_result(game_state.generate_explore())
	await process_frame
	assert(screen.get("story_title").text == "旅途记录")
	assert(screen.get("log_view").visible)
	assert(not screen.get("battle_scroll").visible)
	print("Broken UI smoke test passed")
	quit()

func _collect_portrait_buttons(node: Node, portraits: Array) -> void:
	if node is TextureButton: portraits.append(node)
	for child in node.get_children(): _collect_portrait_buttons(child, portraits)

func _collect_label_text(node: Node, labels: Array) -> void:
	if node is Label: labels.append((node as Label).text)
	for child in node.get_children(): _collect_label_text(child, labels)
