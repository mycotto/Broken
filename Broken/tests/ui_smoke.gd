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
	screen._process_result(game_state.start_combat(["LostSoul"], false))
	await process_frame
	assert(screen.actions_box.get_child_count() == 5)
	print("Broken UI smoke test passed")
	quit()

func _collect_portrait_buttons(node: Node, portraits: Array) -> void:
	if node is TextureButton: portraits.append(node)
	for child in node.get_children(): _collect_portrait_buttons(child, portraits)
