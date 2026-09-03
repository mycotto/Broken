extends SceneTree

func _init() -> void:
	assert(BrokenGameData.MONSTERS.size() == 21)
	assert(BrokenGameData.RELICS.size() == 32)
	for id in BrokenGameData.MONSTERS:
		var monster := BrokenGameData.make_monster(id)
		assert(monster.current_hp == monster.max_hp)
		assert(not monster.attacks.is_empty())
	for id in BrokenGameData.RELICS:
		assert(BrokenGameData.make_relic(id).name != "")
	var game := BrokenGameState.new()
	var start := game.start_new_game()
	assert(start.actions.size() == 4)
	assert(game.current_floor == 1)
	var combat := game.start_combat(["LostSoul"], false)
	assert(combat.actions.size() == 4)
	var targets := game.select_target("attack")
	assert(targets.actions.size() == 2)
	var guarded := game.defend()
	assert(guarded.get("next_action", "") == "enemy_turn")
	var enemy_result := game.enemy_turn()
	assert(not enemy_result.actions.is_empty())
	game.level_up("attack")
	assert(game.current_floor == 2)
	game.level_up("shield")
	assert(game.current_floor == 3)
	var boss_game := BrokenGameState.new()
	boss_game.start_new_game()
	boss_game.current_floor = 4
	boss_game.start_combat(["ZhongMoBenShen"], true)
	boss_game.combat_round = 3
	boss_game.pending_enemies = boss_game.enemies.duplicate()
	assert(not boss_game.enemy_turn().is_empty())
	print("Broken smoke test passed")
	quit()
