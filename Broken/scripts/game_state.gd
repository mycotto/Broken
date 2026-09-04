class_name BrokenGameState
extends RefCounted

var rng := RandomNumberGenerator.new()
var player: Dictionary
var enemies: Array = []
var pending_enemies: Array = []
var pending_defense := {}
var current_floor := 1
var distance_to_boss := 0
var combat_round := 1
var phase := "INIT"
var shield_bash_cooldown := 0
var defend_cooldown := 0
var defending := false
var combat_ac_bonus := 0
var combat_damage_bonus := 0
var combat_attack_roll_bonus := 0
var combat_enemy_attack_penalty := 0
var combat_enemy_attack_penalty_sources: Array = []
var mage_spells: Array = []
var pending_spell := {}
var pending_item := {}

func _init() -> void:
	rng.randomize()

func roll_dice(expression: String) -> int:
	if not expression.contains("d"): return expression.to_int()
	var modifier := 0
	var dice_part := expression
	if expression.contains("+"):
		var plus := expression.split("+", false); dice_part = plus[0]; modifier = plus[1].to_int()
	elif expression.contains("-"):
		var minus := expression.split("-", false); dice_part = minus[0]; modifier = -minus[1].to_int()
	var pieces := dice_part.split("d")
	var total := modifier
	for index in range(pieces[0].to_int()): total += rng.randi_range(1, pieces[1].to_int())
	return total

func roll_d20() -> int: return rng.randi_range(1, 20)
func alive(entity: Dictionary) -> bool: return entity.get("current_hp", 0) > 0
func alive_enemies() -> Array:
	return enemies.filter(func(enemy): return alive(enemy))
func ability_mod(score: int) -> int: return floori((score - 10) / 2.0)
func _action(label: String, id: String, args := {}, style := "explore", disabled := false) -> Dictionary:
	return {"label": label, "id": id, "args": args, "style": style, "disabled": disabled}
func _result(logs: Array, actions: Array = [], timer := 0.0, next_action := "") -> Dictionary:
	var result := {"logs": logs, "actions": actions}
	if timer > 0.0: result["timer"] = timer; result["next_action"] = next_action
	return result

func start_new_game(character_id := "") -> Dictionary:
	if character_id.is_empty(): return character_select()
	var character := BrokenGameData.character(character_id)
	player = {"name":character.name, "class_id":character_id, "class_name":character.class_name, "class_title":character.title, "ac":character.ac, "max_hp":character.hp, "current_hp":character.hp, "temp_hp":0, "memory":10, "max_memory":20,
		"strength":character.strength, "dexterity":character.dexterity, "constitution":character.constitution, "intelligence":character.intelligence, "wisdom":character.wisdom, "charisma":character.charisma, "bonus_attack":0, "bonus_shield":0,
		"next_attack_bonus":0, "next_attack_roll_bonus":0, "dream_attack_buff":0, "last_attack_missed":false,
		"disabled_action":"", "rule_break_penalty":0, "relics":[], "items":[], "charge":0, "used_spell_ids":[], "third_floor_event_used":false}
	current_floor = 1; distance_to_boss = rng.randi_range(6, 9); combat_round = 1; enemies = []
	return generate_explore(["\n“又一次，从冥河的雾里醒来”\n", "你作为【%s】踏入了破碎世界。" % player.class_name, "地狱第 1 层：灵薄狱 | 距离冥河渡口还有 %d 步" % distance_to_boss])

func character_select() -> Dictionary:
	phase = "CHARACTER_SELECT"
	var actions := []
	for id in ["warrior", "mage"]:
		var character := BrokenGameData.character(id)
		actions.append(_action("【%s】\n%s\nHP %d | AC %d" % [character.class_name, character.description, character.hp, character.ac], "choose_character", {"character_id":id}, "character"))
	return _result(["\n=============== 选择你的角色 ===============", "每个角色拥有独立的攻击与防御技能。"], actions)

func main_menu() -> Dictionary:
	phase = "MAIN_MENU"
	return _result([], [_action("开始游戏", "open_character_select", {}, "menu"), _action("退出游戏", "quit_game", {}, "menu")])

func is_mage() -> bool: return not player.is_empty() and player.get("class_id", "") == "mage"
func action_display_name(id: String) -> String:
	var names := {"attack":"强力攻击", "shield_bash":"护盾猛击", "defend":"守卫姿态", "arcane_bolt":"奥术飞弹", "arcane_torrent":"奥术洪流", "spell_slot":"法术位"}
	return names.get(id, id)

func get_status_text() -> String:
	if player.is_empty(): return ""
	var text := "❤️ HP: %d/%d | 🛡️ 护盾: %d | AC: %d" % [player.current_hp, player.max_hp, player.temp_hp, player.ac]
	if current_floor >= 2: text += " | 🧠 记忆: %d/%d" % [player.memory, player.max_memory]
	if is_mage(): text += " | ✨ 充能: %d/5" % player.charge
	text += " | 🗺️ 距离: %d步" % distance_to_boss
	if phase.begins_with("COMBAT") or phase == "TARGETING" or phase.begins_with("SPELL_"): text += " | 回合: %d" % combat_round
	if player.rule_break_penalty > 0: text += " | ⚠️ 规则崩溃: -%d" % player.rule_break_penalty
	return text

func execute_action(id: String, args := {}) -> Dictionary:
	match id:
		"open_character_select": return character_select()
		"choose_character": return start_new_game(args.character_id)
		"generate_explore": return generate_explore()
		"start_combat": return start_combat(args.enemies, args.get("is_elite", false))
		"rest": return rest()
		"mystery": return mystery()
		"treasure": return treasure()
		"studio": return studio()
		"memory_shard": return memory_shard()
		"time_rift": return time_rift()
		"rule_collapse": return rule_collapse()
		"third_floor_event": return third_floor_event()
		"skip_to_third_boss": return skip_to_third_boss()
		"third_floor_heal": return third_floor_heal()
		"level_up": return level_up(args.kind)
		"select_target": return select_target(args.next)
		"cancel_target": return player_actions()
		"attack": return player_attack(args.index)
		"shield_bash": return shield_bash(args.index)
		"defend": return defend()
		"arcane_bolt": return arcane_bolt(args.index)
		"arcane_torrent": return arcane_torrent()
		"spell_slot": return spell_slot()
		"cast_spell": return cast_spell(args.spell_id)
		"cast_spell_target": return cast_spell_target(args.index)
		"items": return show_item_selection()
		"use_item": return use_item(args.index)
		"use_item_target": return use_item_target(args.index)
		"cancel_items": return player_actions()
		"pickup_item": return resolve_potion_pickup(true)
		"discard_item": return resolve_potion_pickup(false)
		"enemy_turn": return enemy_turn()
		"tough": return resolve_tough()
		"dodge": return resolve_dodge()
		"parry": return resolve_parry()
		"arcane_barrier": return resolve_arcane_barrier()
		"energy_counter": return resolve_energy_counter()
		"restart": return restart_game()
	return _result(["无效操作：%s" % id])

func generate_explore(initial_logs: Array = []) -> Dictionary:
	phase = "EXPLORE"
	var logs := initial_logs.duplicate()
	var options: Array
	if current_floor == 1:
		logs.append("\n--- 🗺️ 探索地图 ---\n前方出现了 3 条道路：")
		options = [_action("⚔️ 遭遇 迷途古魂", "start_combat", {"enemies":["LostSoul","LostSoul"]}), _action("⚔️ 遭遇 风卷欲魂", "start_combat", {"enemies":["WindborneLust","LostSoul"]}), _action("⚔️ 精英：刻耳柏洛斯幼犬", "start_combat", {"enemies":["CerberusPup"],"is_elite":true}), _action("⚔️ 精英：泥沼饿魂", "start_combat", {"enemies":["MireHungry"],"is_elite":true}), _action("🛏️ 废弃的祭坛", "rest"), _action("❓ 神秘低语", "mystery"), _action("🎁 隐秘的宝箱", "treasure")]
	elif current_floor == 2:
		logs.append("\n--- 🗺️ 褪色街道 ---\n前方出现了 3 条道路：")
		options = [_action("⚔️ 遭遇 凝固伤者", "start_combat", {"enemies":["SolidifiedWounded","SolidifiedWounded"]}), _action("⚔️ 遭遇 空壳信使与蚀光残像", "start_combat", {"enemies":["HollowMessenger","ErodedAfterimage"]}), _action("⚔️ 精英：终末传教士", "start_combat", {"enemies":["DoomsdayPreacher"],"is_elite":true}), _action("⚔️ 精英：遗忘聚合体", "start_combat", {"enemies":["OblivionAggregate"],"is_elite":true}), _action("🖼️ 褪色的画室", "studio"), _action("🧠 记忆残片", "memory_shard"), _action("⚠️ 时间裂缝", "time_rift")]
		if rng.randf() < 0.3: options.append(_action("🎁 褪色的宝箱", "treasure"))
	else:
		logs.append("\n--- 🗺️ 崩坏圣堂 ---\n前方出现了 3 条道路：")
		options = [_action("⚔️ 遭遇 凝固圣歌与空白裂隙", "start_combat", {"enemies":["NingGuShengGe","KongBaiLieXi"]}), _action("⚔️ 遭遇 褪色圣像与神之苔藓", "start_combat", {"enemies":["TuiSeShengXiang","ShenZhiTaiXian"]}), _action("⚔️ 精英：崩解炽天使", "start_combat", {"enemies":["BengJieChiTianShi"],"is_elite":true}), _action("⚔️ 精英：神之回响", "start_combat", {"enemies":["ShenZhiHuiXiang"],"is_elite":true}), _action("🙏 神之遗骸", "rest"), _action("⚠️ 崩坏法则", "rule_collapse"), _action("🧠 记忆残片", "memory_shard")]
		if rng.randf() < 0.2: options.append(_action("🎁 神之宝库", "treasure"))
	options.shuffle()
	var actions: Array
	if current_floor == 3 and not player.get("third_floor_event_used", false):
		# The event remains available until a choice consumes it, so it cannot be missed by rerolling the map.
		actions = [_action("圣阶抉择", "third_floor_event", {}, "event")]
		actions.append_array(options.slice(0, 2))
	else:
		actions = options.slice(0, 3)
	actions.append(_action("角色面板", "character"))
	return _result(logs, actions)

func third_floor_event() -> Dictionary:
	phase = "THIRD_FLOOR_EVENT"
	return _result([
		"\n【圣阶抉择】",
		"崩坏圣堂的尽头，一段由碎裂星光砌成的阶梯横跨虚空。",
		"阶梯直通天堂大门；一旁则漂浮着一缕尚未熄灭的神性余晖。"
	], [
		_action("踏上断阶：跳过本层，直面残翼守门人", "skip_to_third_boss", {}, "event"),
		_action("汲取余晖：恢复 5 点生命，继续探索", "third_floor_heal", {}, "event")
	])

func skip_to_third_boss() -> Dictionary:
	player.third_floor_event_used = true
	distance_to_boss = 0
	return start_floor_boss(["你踏上断裂圣阶。脚下的崩坏圣堂被抛在身后，你直抵天堂大门。"])

func third_floor_heal() -> Dictionary:
	player.third_floor_event_used = true
	heal(5)
	return proceed(["你触碰神性余晖，恢复了 5 点生命。余晖随之熄灭。"])

func rest() -> Dictionary:
	var amount := roll_dice("1d8") + 3; heal(amount)
	return proceed(["你在祭坛前休息，恢复了 %d 点HP。" % amount])
func mystery() -> Dictionary:
	var logs: Array = []; var event: String = ["trap","heal","buff"].pick_random()
	if event == "trap": logs.append("⚠️ 你踏入了一个隐蔽的陷阱！"); logs.append_array(apply_damage(roll_dice("1d6")))
	elif event == "heal": var amount := roll_dice("1d10"); heal(amount); logs.append("✨ 你发现神圣泉水，恢复了 %d 点HP。" % amount)
	else:
		if is_mage(): player.intelligence += 1; player.wisdom += 1; logs.append("🔮 古老石碑令智力和智慧永久 +1！")
		else: player.strength += 1; player.dexterity += 1; logs.append("🛡️ 古老石碑令力量和敏捷永久 +1！")
	return proceed(logs)
func treasure() -> Dictionary:
	var potion_ids: Array = BrokenGameData.POTIONS.keys()
	var potion := BrokenGameData.make_potion(potion_ids.pick_random())
	pending_item = {"item":potion}
	phase = "POTION_PICKUP"
	return _result(["🧪 宝箱里发现【%s】！\n效果：%s" % [potion.name, potion.description], "要把它放进道具栏吗？"], [_action("拾取【%s】" % potion.name, "pickup_item", {}, "item"), _action("丢弃药水", "discard_item", {}, "item")])

func resolve_potion_pickup(pick_up: bool) -> Dictionary:
	if phase != "POTION_PICKUP" or pending_item.is_empty(): return generate_explore(["没有等待处理的药水。"])
	var potion: Dictionary = pending_item.item; pending_item = {}
	var logs := []
	if pick_up:
		player.items.append(potion)
		logs.append("🧪 你拾取【%s】，已放入道具栏（当前 %d 瓶）。" % [potion.name, player.items.size()])
	else:
		logs.append("🗑️ 你丢弃了【%s】。" % potion.name)
	return gain_relic("treasure", logs)
func studio() -> Dictionary:
	if rng.randi_range(0, 1) == 0: return gain_relic("normal", ["你走进褪色画室，画布后藏着一件遗物。"])
	player.memory = mini(player.max_memory, player.memory + 3)
	return proceed(["你在画布后找到熟悉的色彩，记忆值恢复 3。"])
func memory_shard() -> Dictionary:
	var amount := rng.randi_range(3, 5); player.memory = mini(player.max_memory, player.memory + amount)
	var logs := ["✨ 收集记忆残片！记忆值恢复 %d。" % amount, "⚠️ 过去的幻影划伤了你！"]
	logs.append_array(apply_damage(roll_dice("1d4")))
	return proceed(logs)
func time_rift() -> Dictionary:
	var event: String = ["hp","damage","memory"].pick_random(); var logs: Array = ["你踏入一片颜色浓艳得不真实的时间裂缝！"]
	if event == "hp": player.max_hp += 5; heal(5); logs.append("🧬【昨日之韧】最大生命永久 +5，并恢复5点生命。")
	elif event == "damage": logs.append_array(apply_damage(roll_dice("2d8")))
	else:
		player.memory -= 3; logs.append("🌫️ 你忘记了为什么出发。记忆 -3。")
		if player.memory <= 0: return memory_over(logs)
	return proceed(logs)
func rule_collapse() -> Dictionary:
	var event: String = ["damage","heal","memory"].pick_random(); var logs: Array = ["你触碰了一团崩坏的光芒！"]
	if event == "damage": logs.append_array(apply_damage(roll_dice("2d10")))
	elif event == "heal": var amount := roll_dice("2d8"); heal(amount); logs.append("✨ 恢复了 %d 点HP。" % amount)
	else:
		player.memory -= 4; logs.append("🌫️ 认知被扭曲，记忆 -4。")
		if player.memory <= 0: return memory_over(logs)
	return proceed(logs)

func proceed(initial_logs: Array) -> Dictionary:
	var logs := initial_logs.duplicate()
	if not alive(player): return game_over(logs)
	logs.append_array(relic_event("room", {}).logs)
	if not alive(player): return game_over(logs)
	if current_floor >= 2:
		player.memory -= 1; logs.append("🌫️ 褪色世界侵蚀记忆... 当前 %d/%d" % [player.memory, player.max_memory])
		if player.memory <= 0: return memory_over(logs)
	distance_to_boss -= 1
	if distance_to_boss <= 0: return start_floor_boss(logs)
	logs.append("\n--- 距离法则断裂处还有 %d 步 ---" % distance_to_boss)
	return _result(logs, [], 0.65, "generate_explore")

func start_floor_boss(logs: Array) -> Dictionary:
	if current_floor == 1:
		logs.append("\n==================================================\n【最终挑战：冥河摆渡人】\n黑水翻涌，巨大的阴影笼罩了你。\n「生者！退去！此河只载亡魂，不渡活人！」")
		return start_combat(["CharonTheFerryman"], true, logs)
	if current_floor == 2:
		logs.append("\n==================================================\n【第二层Boss：守忆者】\n一个由文字、姓名和地图组成的巨大人形挡住了去路。\n他没有敌意，只是在用成千上万种声音喃喃自语，试图记住一切。")
		return start_combat(["MemoryKeeper"], true, logs)
	if current_floor == 3:
		logs.append("\n==================================================\n【第三层Boss：残翼守门人】\n天堂大门的最后守护者挡住了去路。翅膀折断，圣剑崩裂。\n它机械地举起剑，执行着早已没有意义的指令。")
		return start_combat(["CanYiShouMenRen"], true, logs)
	return start_combat(["ZhongMoBenShen"], true, logs)

func start_combat(ids: Array, _is_elite := false, initial_logs: Array = []) -> Dictionary:
	phase = "COMBAT_PLAYER"; enemies = []
	for id in ids: enemies.append(BrokenGameData.make_monster(id))
	shield_bash_cooldown = 0; defend_cooldown = 0; defending = false; combat_ac_bonus = 0; combat_damage_bonus = 0; combat_attack_roll_bonus = 0; combat_enemy_attack_penalty = 0; combat_enemy_attack_penalty_sources = []; mage_spells = []; pending_spell = {}; pending_item = {}; combat_round = 1; player.disabled_action = ""; player.last_attack_missed = false
	if is_mage():
		player.charge = 0; player.used_spell_ids = []
		var spell_ids: Array = BrokenGameData.MAGE_SPELLS.keys(); spell_ids.shuffle()
		for spell_id in spell_ids.slice(0, 3): mage_spells.append(BrokenGameData.mage_spell(spell_id))
	var penalty := 0
	if current_floor >= 3:
		for enemy in enemies:
			if enemy.tier == "boss": penalty = maxi(penalty, 2)
			elif enemy.tier == "elite": penalty = maxi(penalty, rng.randi_range(1, 2))
			else: penalty = maxi(penalty, 1)
	player.rule_break_penalty = penalty
	var logs := initial_logs.duplicate(); logs.append("\n=============== 战斗开始 ===============")
	for enemy in enemies: logs.append("遭遇【%s】 HP: %d/%d" % [enemy.name, enemy.current_hp, enemy.max_hp])
	if is_mage(): logs.append("本场法术位已准备 3 个高阶法术；每个法术可各施放一次，均需 3 层充能。")
	if penalty > 0: logs.append("⚠️【规则崩溃】所有判定掷骰 -%d！" % penalty)
	logs.append_array(relic_event("combat_start", {}).logs)
	if enemies.any(func(e): return e.tier == "boss"): logs.append_array(relic_event("boss_enter", {}).logs)
	return player_actions(logs)

func player_actions(initial_logs: Array = []) -> Dictionary:
	if not alive(player): return game_over(initial_logs)
	if alive_enemies().is_empty(): return victory(initial_logs)
	phase = "COMBAT_PLAYER"; var logs := initial_logs.duplicate(); logs.append("\n【你的回合】")
	var actions: Array
	if is_mage():
		var remaining_slots := 0
		for spell in mage_spells:
			if not player.used_spell_ids.has(spell.id): remaining_slots += 1
		var spell_label := "法术位（剩余 %d/3；需要 3 层充能：%d/3）" % [remaining_slots, player.charge]
		if remaining_slots == 0: spell_label = "法术位（本场三个高阶法术均已释放）"
		actions = [_action("奥术飞弹 (1d8+4；获得 1 层充能)", "select_target", {"next":"arcane_bolt"}, "combat", player.disabled_action == "arcane_bolt"), _action("奥术洪流（获得 3 层充能）", "arcane_torrent", {}, "combat", player.disabled_action == "arcane_torrent"), _action(spell_label, "spell_slot", {}, "combat", player.disabled_action == "spell_slot" or remaining_slots == 0 or player.charge < 3), _action("🧪 道具栏（%d）" % player.items.size(), "items", {}, "combat", player.items.is_empty()), _action("角色面板", "character")]
	else:
		actions = [_action("强力攻击 (1d10+5)", "select_target", {"next":"attack"}, "combat", player.disabled_action == "attack"), _action("护盾猛击 (1d8+5 伤害+护盾)", "select_target", {"next":"shield_bash"}, "combat", player.disabled_action == "shield_bash" or shield_bash_cooldown > 0), _action("守卫姿态 (AC+3, 下次攻击+2命中/+1伤害)", "defend", {}, "combat", player.disabled_action == "defend" or defend_cooldown > 0), _action("🧪 道具栏（%d）" % player.items.size(), "items", {}, "combat", player.items.is_empty()), _action("角色面板", "character")]
	return _result(logs, actions)

func show_item_selection() -> Dictionary:
	if phase != "COMBAT_PLAYER": return player_actions(["药水只能在你的战斗回合使用。"])
	if player.items.is_empty(): return player_actions(["道具栏为空。"])
	phase = "ITEM_SELECT"
	var actions := []
	for index in range(player.items.size()):
		var item: Dictionary = player.items[index]
		actions.append(_action("🧪【%s】\n%s" % [item.name, item.description], "use_item", {"index":index}, "item"))
	actions.append(_action("返回战斗行动", "cancel_items"))
	return _result(["\n【道具栏】使用药水不消耗本回合行动。"], actions)

func use_item(index: int) -> Dictionary:
	if phase != "ITEM_SELECT" or index < 0 or index >= player.items.size(): return player_actions(["该药水不可用。"])
	var item: Dictionary = player.items[index]
	if item.get("targeted", false):
		pending_item = {"index":index, "item":item}; phase = "ITEM_TARGET"
		var actions := []; var target_index := 0
		for enemy in alive_enemies():
			actions.append(_action("对【%s】使用【%s】(HP:%d/%d)" % [enemy.name, item.name, enemy.current_hp, enemy.max_hp], "use_item_target", {"index":target_index}, "target")); target_index += 1
		actions.append(_action("返回道具栏", "items"))
		return _result(["🎯 请选择【%s】的目标：" % item.name], actions)
	return apply_item(item, index, {})

func use_item_target(index: int) -> Dictionary:
	var targets := alive_enemies()
	if pending_item.is_empty() or index < 0 or index >= targets.size(): return show_item_selection()
	return apply_item(pending_item.item, pending_item.index, targets[index])

func apply_item(item: Dictionary, item_index: int, target: Dictionary) -> Dictionary:
	if item_index < 0 or item_index >= player.items.size(): return player_actions(["该药水不可用。"])
	player.items.remove_at(item_index); pending_item = {}
	var logs := ["🧪 使用【%s】。" % item.name]
	match item.kind:
		"heal":
			var before: int = player.current_hp; heal(item.amount); logs.append("❤️ 恢复 %d 点生命（%d → %d）。" % [player.current_hp - before, before, player.current_hp])
		"damage_bonus":
			combat_damage_bonus += item.amount; logs.append("⚔️ 本场攻击伤害 +%d（当前 +%d）。" % [item.amount, combat_damage_bonus])
		"roll_bonus":
			combat_attack_roll_bonus += item.amount; logs.append("🎯 本场攻击判定 +%d（当前 +%d）。" % [item.amount, combat_attack_roll_bonus])
		"enemy_roll_penalty":
			combat_enemy_attack_penalty += item.amount; combat_enemy_attack_penalty_sources.append("灰雾削弱药剂 -%d" % item.amount); logs.append("🌫️ 敌人本场攻击判定 -%d（当前 -%d）。" % [item.amount, combat_enemy_attack_penalty])
		"shield":
			var shield: int = item.amount + player.bonus_shield; player.temp_hp += shield; logs.append("🛡️ 获得 %d 点护盾。" % shield)
		"damage":
			if target.is_empty(): return player_actions(["需要选择伤害药水的目标。"])
			logs.append("💥 对【%s】造成 %d 点伤害。" % [target.name, item.amount]); logs.append_array(damage_enemy(target, item.amount))
	if alive_enemies().is_empty(): return victory(logs)
	return player_actions(logs)

func select_target(next: String) -> Dictionary:
	phase = "TARGETING"; var actions := []; var index := 0
	for enemy in alive_enemies(): actions.append(_action("攻击【%s】(HP:%d/%d)" % [enemy.name, enemy.current_hp, enemy.max_hp], next, {"index":index}, "target")); index += 1
	actions.append(_action("取消", "cancel_target"))
	return _result(["\n🎯 请选择攻击目标："], actions)

func player_attack(index: int) -> Dictionary: return attack_target(index, "1d10", false)
func arcane_bolt(index: int) -> Dictionary:
	var result := attack_target(index, "1d8", false, "施放【奥术飞弹】攻击", 4, 7)
	player.charge = mini(5, player.charge + 1)
	result.logs.insert(0, "✨ 奥术飞弹凝聚成功，获得 1 层充能（当前 %d/5）。" % player.charge)
	return result

func arcane_torrent() -> Dictionary:
	if player.disabled_action == "arcane_torrent": return player_actions(["奥术洪流不可用！"])
	var before: int = player.charge; player.charge = mini(5, player.charge + 3)
	return schedule_enemy(["🌊 奥术洪流涌入体内，充能 %d → %d/5。" % [before, player.charge]])

func spell_slot() -> Dictionary:
	var remaining_slots := 0
	for spell in mage_spells:
		if not player.used_spell_ids.has(spell.id): remaining_slots += 1
	if remaining_slots == 0 or player.charge < 3: return player_actions(["法术位尚未就绪！"])
	phase = "SPELL_SELECT"
	var actions := []
	for spell in mage_spells:
		actions.append(_action("【%s】\n%s" % [spell.name, spell.description], "cast_spell", {"spell_id":spell.id}, "spell", player.used_spell_ids.has(spell.id)))
	actions.append(_action("暂不施放", "cancel_target"))
	return _result(["\n【法术位已就绪】从本场抽取的 3 个高阶法术中选择一个。", "每次释放消耗 3 层充能；本场剩余 %d 个高阶法术可用。" % remaining_slots], actions)

func cast_spell(spell_id: String) -> Dictionary:
	if player.charge < 3: return player_actions(["法术位尚未就绪！"])
	var spell := BrokenGameData.mage_spell(spell_id)
	if not mage_spells.any(func(item): return item.id == spell_id): return player_actions(["该法术不在本场法术位中。"])
	if player.used_spell_ids.has(spell_id): return spell_slot()
	if spell.targeted:
		pending_spell = spell; phase = "SPELL_TARGET"
		var actions := []; var index := 0
		for enemy in alive_enemies(): actions.append(_action("对【%s】施放【%s】(HP:%d/%d)" % [enemy.name, spell.name, enemy.current_hp, enemy.max_hp], "cast_spell_target", {"index":index}, "target")); index += 1
		actions.append(_action("返回法术选择", "spell_slot"))
		return _result(["🎯 请选择【%s】的目标：" % spell.name], actions)
	return resolve_spell(spell, {})

func cast_spell_target(index: int) -> Dictionary:
	var targets := alive_enemies()
	if pending_spell.is_empty() or index < 0 or index >= targets.size(): return spell_slot()
	return resolve_spell(pending_spell, targets[index])

func resolve_spell(spell: Dictionary, target: Dictionary) -> Dictionary:
	player.charge -= 3; player.used_spell_ids.append(spell.id); pending_spell = {}
	var logs := ["释放法术位【%s】！消耗 3 层充能（剩余 %d/5）。" % [spell.name, player.charge]]
	match spell.kind:
		"damage":
			logs.append("☄️【%s】必中，造成 %d 点伤害。" % [spell.name, spell.amount]); logs.append_array(damage_enemy(target, spell.amount))
		"shield":
			player.temp_hp += spell.amount + player.bonus_shield; logs.append("🛡️ 获得 %d 点护盾。" % (spell.amount + player.bonus_shield))
		"ac":
			player.ac += spell.amount; combat_ac_bonus += spell.amount; logs.append("🌀 绝对领域展开，本场 AC +%d（当前 %d）。" % [spell.amount, player.ac])
		"damage_shield":
			logs.append("⚡【%s】必中，造成 %d 点伤害。" % [spell.name, spell.amount]); logs.append_array(damage_enemy(target, spell.amount)); player.temp_hp += spell.shield + player.bonus_shield; logs.append("🛡️ 获得 %d 点护盾。" % (spell.shield + player.bonus_shield))
		"heal_shield":
			heal(spell.amount); player.temp_hp += spell.shield + player.bonus_shield; logs.append("❤️ 恢复 %d 点生命，获得 %d 点护盾。" % [spell.amount, spell.shield + player.bonus_shield])
		"curse":
			player.temp_hp += spell.amount + player.bonus_shield; logs.append("🛡️ 获得 %d 点护盾。" % (spell.amount + player.bonus_shield))
			for enemy in alive_enemies():
				enemy.combat_attack_penalty += 3; enemy.combat_attack_penalty_sources.append("失序诅咒 -3"); enemy.ac -= 2; logs.append("【%s】陷入失序：本场攻击判定 -3，AC -2（当前 AC %d）。" % [enemy.name, enemy.ac])
	if alive_enemies().is_empty(): return victory(logs)
	return schedule_enemy(logs)

func shield_bash(index: int) -> Dictionary:
	if shield_bash_cooldown > 0 or player.disabled_action == "shield_bash": return player_actions(["护盾猛击不可用！"])
	return attack_target(index, "1d8", true)
func attack_target(index: int, dice: String, bash: bool, attack_text := "", damage_bonus := 5, roll_base := 7) -> Dictionary:
	var targets := alive_enemies()
	if index < 0 or index >= targets.size(): return player_actions(["目标已消失。"])
	var target: Dictionary = targets[index]; var roll_bonus: int = player.next_attack_roll_bonus; player.next_attack_roll_bonus = 0
	var roll: int = roll_d20() + roll_base + player.bonus_attack + combat_attack_roll_bonus - player.rule_break_penalty + roll_bonus
	var action_text: String = attack_text if not attack_text.is_empty() else ("举盾撞向" if bash else "挥剑攻击")
	var logs := ["你%s %s，掷出 %d (DC%d)" % [action_text, target.name, roll, target.ac]]
	if roll_bonus != 0: logs.append("🎯 蓄力命中骰 %+d" % roll_bonus)
	var rolling := relic_event("attack_roll", {"roll":roll}); roll = rolling.value; logs.append_array(rolling.logs)
	var hit: bool = roll >= target.ac; var forced := false
	if not hit:
		var missing := relic_event("attack_miss", {"target":target}, {"hit":false, "mult":1.0}); logs.append_array(missing.logs)
		if missing.value.hit: hit = true; forced = true
	player.last_attack_missed = not hit
	if hit:
		var damage := roll_dice(dice) + damage_bonus + combat_damage_bonus
		var hitting := relic_event("attack_hit", {"target":target, "damage":damage}); damage = hitting.value; logs.append_array(hitting.logs)
		if not alive(player): return game_over(logs)
		if player.next_attack_bonus != 0: damage += player.next_attack_bonus; logs.append("⚔️ 力量涌动，伤害 %+d" % player.next_attack_bonus); player.next_attack_bonus = 0
		if player.dream_attack_buff != 0: damage += player.dream_attack_buff; logs.append("💭 梦境释放，伤害 +%d" % player.dream_attack_buff); player.dream_attack_buff = 0
		if forced: damage = maxi(1, damage / 2); logs.append("⬜ 强制命中，伤害减半至 %d。" % damage)
		logs.append("✔ 命中！造成 %d 点伤害。" % damage); logs.append_array(damage_enemy(target, damage))
		if not alive(target) and target.get("explodes", false):
			logs.append("💥 %s 死亡时自爆！" % target.name); logs.append_array(apply_damage(rng.randi_range(3, 5)))
			if not alive(player): return game_over(logs)
	else:
		logs.append("✖ 攻击落空！"); player.next_attack_bonus = 0; player.dream_attack_buff = 0
	if bash:
		var shield: int = roll_dice("1d10") + 5 + player.bonus_shield; player.temp_hp += shield; shield_bash_cooldown = 3; logs.append("🛡️ 获得 %d 点护盾！" % shield)
	return schedule_enemy(logs)

func defend() -> Dictionary:
	if defend_cooldown > 0 or player.disabled_action == "defend": return player_actions(["守卫姿态不可用！"])
	defending = true; player.ac += 3; player.next_attack_roll_bonus += 2; player.next_attack_bonus += 1; defend_cooldown = 2; player.last_attack_missed = false
	return schedule_enemy(["你摆出守卫姿态！AC+3，下次攻击命中+2、伤害+1。"])
func schedule_enemy(logs: Array) -> Dictionary:
	phase = "COMBAT_ENEMY"; player.disabled_action = ""; pending_enemies = alive_enemies().duplicate()
	logs.append("\n【敌人回合】")
	return _result(logs, [], 0.35, "enemy_turn")

func enemy_turn() -> Dictionary:
	if pending_enemies.is_empty() or not alive(player): return end_enemy_turn()
	var enemy: Dictionary = pending_enemies.pop_front(); var logs := []
	if enemy.tier == "boss":
		logs.append_array(boss_phase(enemy))
		if not alive(player): return game_over(logs)
		if enemy.get("summon", "") != "":
			var added := BrokenGameData.make_monster(enemy.summon); enemies.append(added); pending_enemies.append(added); enemy.erase("summon"); logs.append("★ 召唤了【%s】！" % added.name)
	var attacks: Array = enemy.attacks; var attack: Dictionary = attacks[rng.randi_range(0, attacks.size() - 1)] if enemy.get("random_attack", false) else attacks[0]
	if attack.get("unblockable", false):
		player.memory -= attack.memory_damage; logs.append("🧠 %s 发动【遗忘低语】！无法防御，记忆 -%d。" % [enemy.name, attack.memory_damage])
		if player.memory <= 0: return memory_over(logs)
		return _result(logs, [], 0.35, "enemy_turn")
	var next_penalty: int = enemy.next_attack_penalty
	var combat_penalty: int = enemy.combat_attack_penalty
	var penalty: int = next_penalty + combat_penalty + combat_enemy_attack_penalty
	var base_roll: int = roll_d20() + attack.bonus
	var enemy_roll: int = base_roll - penalty
	var penalty_sources: Array = []
	penalty_sources.append_array(enemy.next_attack_penalty_sources)
	penalty_sources.append_array(enemy.combat_attack_penalty_sources)
	penalty_sources.append_array(combat_enemy_attack_penalty_sources)
	enemy.next_attack_penalty = 0; enemy.next_attack_penalty_sources = []
	var damage := roll_dice(attack.damage)
	if penalty > 0:
		var source_text := "、".join(penalty_sources) if not penalty_sources.is_empty() else "攻击判定削弱 -%d" % penalty
		logs.append("⚔️ %s 发动【%s】！掷出 %d（%d - %d），造成 %d 点伤害。\n   削弱来源：%s" % [enemy.name, attack.name, enemy_roll, base_roll, penalty, damage, source_text])
	else:
		logs.append("⚔️ %s 发动【%s】！掷出 %d，造成 %d 点伤害。" % [enemy.name, attack.name, enemy_roll, damage])
	var defended := relic_event("defend", {"roll":enemy_roll, "damage":damage})
	logs.append_array(defended.logs)
	if defended.value.handled:
		logs.append_array(apply_damage(defended.value.damage))
		if defended.value.damage == 0: logs.append_array(relic_event("dodge", {}).logs)
		if not alive(player): return game_over(logs)
		return _result(logs, [], 0.35, "enemy_turn")
	pending_defense = {"roll":enemy_roll, "damage":damage}
	phase = "COMBAT_DEFEND"
	if is_mage():
		return _result(logs + ["请选择应对方式："], [_action("奥术屏障（消耗 1 充能，本次 AC+3，获得 6 护盾）", "arcane_barrier", {}, "combat", player.charge < 1), _action("硬抗 (AC判定)", "tough", {}, "combat"), _action("能量对冲（智慧判定；失败受伤+35%，获得 1 充能）", "energy_counter", {}, "combat")])
	return _result(logs + ["请选择应对方式："], [_action("硬抗 (AC判定)", "tough", {}, "combat"), _action("闪避 (敏捷豁免)", "dodge", {}, "combat"), _action("招架 (力量检定)", "parry", {}, "combat")])

func resolve_tough() -> Dictionary:
	return resolve_tough_with_bonus(0, [])
func resolve_arcane_barrier() -> Dictionary:
	if player.charge < 1: return _result(["充能不足，无法展开奥术屏障。"])
	player.charge -= 1; player.temp_hp += 6
	return resolve_tough_with_bonus(3, ["✨ 消耗 1 层充能，获得 6 点护盾；奥术屏障使本次防御 AC +3（充能剩余 %d/5）。" % player.charge])
func resolve_tough_with_bonus(ac_bonus: int, logs: Array) -> Dictionary:
	var diff: int = player.ac + ac_bonus - pending_defense.roll; var actual: int = pending_defense.damage
	if diff >= 5: actual = 0; logs.append("🛡️ 完美格挡！免疫伤害。")
	elif diff >= 2: actual = maxi(1, pending_defense.damage * 2 / 10); logs.append("🛡️ 擦伤！受到20%伤害。")
	elif diff >= 0: actual = maxi(1, pending_defense.damage * 3 / 10); logs.append("🛡️ 硬抗！受到30%伤害。")
	else: logs.append("💥 防御被击穿！")
	return apply_and_continue(actual, logs)
func resolve_dodge() -> Dictionary:
	var save: int = roll_d20() + ability_mod(player.dexterity) - player.rule_break_penalty; var diff: int = save - pending_defense.roll; var actual: int = pending_defense.damage; var logs := ["🏃 敏捷豁免掷出 %d" % save]
	if diff >= 5: actual = 0; logs.append("完美闪避！")
	elif diff >= 2: actual = maxi(1, pending_defense.damage * 2 / 10); logs.append("轻巧闪避！受到20%伤害。")
	elif diff >= 0: actual = maxi(1, pending_defense.damage * 5 / 10); logs.append("勉强闪避！受到50%伤害。")
	else: logs.append("闪避失败！")
	return apply_and_continue(actual, logs)
func resolve_parry() -> Dictionary:
	var strength: int = ability_mod(player.strength); var check: int = roll_d20() + strength - player.rule_break_penalty; var actual: int = pending_defense.damage; var logs := ["⚔️ 力量检定掷出 %d" % check]
	if check >= pending_defense.roll: var reduced := roll_dice("1d8") + strength; actual = maxi(0, actual - reduced); logs.append("招架成功！抵消 %d 点伤害。" % reduced)
	else: logs.append("招架失败！")
	return apply_and_continue(actual, logs)
func resolve_energy_counter() -> Dictionary:
	var wisdom: int = ability_mod(player.wisdom); var check: int = roll_d20() + wisdom - player.rule_break_penalty; var actual: int = pending_defense.damage; var logs := ["🔮 智慧检定掷出 %d" % check]
	if check >= pending_defense.roll:
		actual = maxi(1, pending_defense.damage * 3 / 10); logs.append("能量对冲成功！受到30%伤害。")
	else:
		actual = ceili(pending_defense.damage * 1.35); player.charge = mini(5, player.charge + 1); logs.append("⚠️ 能量对冲失控！本次受到伤害 +35%%，但获得 1 层额外充能（当前 %d/5）。" % player.charge)
	return apply_and_continue(actual, logs)
func apply_and_continue(amount: int, logs: Array) -> Dictionary:
	logs.append_array(apply_damage(amount))
	if not alive(player): return game_over(logs)
	return _result(logs, [], 0.35, "enemy_turn")
func end_enemy_turn() -> Dictionary:
	if defending: player.ac -= 3; defending = false
	if shield_bash_cooldown > 0: shield_bash_cooldown -= 1
	if defend_cooldown > 0: defend_cooldown -= 1
	combat_round += 1; var logs := []
	if combat_round >= 4:
		for enemy in enemies:
			if enemy.id == "BengJieChiTianShi" and enemy.ac == 17: enemy.ac = 15; logs.append("💔 崩解炽天使的护甲等级降至15！")
	return player_actions(logs)

func heal(amount: int) -> void: player.current_hp = mini(player.max_hp, player.current_hp + amount)
func damage_enemy(enemy: Dictionary, amount: int) -> Array:
	enemy.current_hp = maxi(0, enemy.current_hp - amount)
	return ["➥ %s 受到 %d 点伤害，剩余 %d/%d" % [enemy.name, amount, enemy.current_hp, enemy.max_hp]]
func apply_damage(amount: int) -> Array:
	if amount <= 0: return []
	var modified := relic_event("pre_damage", {"damage":amount}); var damage: int = modified.value; var logs: Array = modified.logs
	if player.temp_hp > 0:
		var shield := mini(player.temp_hp, damage); player.temp_hp -= shield; damage -= shield; logs.append("🛡️ 护盾吸收 %d 点伤害。" % shield)
	if damage > 0: player.current_hp = maxi(0, player.current_hp - damage); logs.append("➥ %s受到 %d 点伤害，剩余 %d/%d" % [player.name, damage, player.current_hp, player.max_hp])
	if player.current_hp <= 0:
		var death := relic_event("death", {}); logs.append_array(death.logs)
	return logs

func relic_event(event: String, context: Dictionary, default_value = null) -> Dictionary:
	var value = context.get("damage", context.get("roll", default_value)); var logs := []
	if event == "defend": value = {"handled":false, "damage":context.damage}
	for relic in player.relics.duplicate():
		var id: String = relic.id
		match event:
			"combat_start":
				if id == "judge_pressure": var shield: int = 5 + player.bonus_shield; player.temp_hp += shield; logs.append("⚖️【审判官之压】获得 %d 点护盾。" % shield)
				if id == "pilgrim_beads": var beads: int = 2 + player.bonus_shield; player.temp_hp += beads; logs.append("📿【断裂的朝圣者念珠】获得 %d 点护盾。" % beads)
				if id == "candle": heal(3); logs.append("🕯️【融化的烛泪】恢复3点生命。")
				if id == "broken_second" or id == "prophecy" or id == "god_ash": relic.used = false
			"boss_enter":
				if id == "ferry_ticket": heal(10); logs.append("🎟️【冥河船票】恢复10点生命。")
			"room":
				if id == "silver_key": heal(3); logs.append("【银钥匙碎片】恢复3点生命。")
				if id == "faded_stamp" and relic.uses > 0 and player.current_hp < player.max_hp:
					heal(5); relic.uses -= 1; logs.append("✉️【褪色邮票】恢复5点生命，剩余%d次。" % relic.uses)
					if relic.uses == 0: player.relics.erase(relic); logs.append("✉️【褪色邮票】已褪色脱落。")
				if id == "dream_echo":
					if player.current_hp < player.max_hp / 2.0: heal(4); logs.append("💭【某人梦的回响】恢复4点生命。")
					else: player.dream_attack_buff += 3; logs.append("💭【某人梦的回响】下次攻击伤害+3。")
			"attack_roll":
				if id == "echo_accuracy" and player.last_attack_missed: value += 2; logs.append("🔄【昨日残响的准度】攻击骰+2。")
				if id == "prophecy" and not relic.used: relic.used = true; value += 4; logs.append("📜【褪色的预言书页】首次攻击骰+4。")
				if id == "destiny_die": value += 1; logs.append("🎲【天命骰】攻击骰+1。")
			"attack_miss":
				if id == "inevitable_end": value = {"hit":true, "mult":0.5}; logs.append("⬜【终末的必然】未命中被强制修正为命中，伤害减半。")
			"attack_hit":
				var target: Dictionary = context.target
				if id == "soul_fire": value += 1; logs.append("🔥【迷途魂火】伤害+1。")
				if id == "oar" and rng.randf() < .25: target.next_attack_penalty += 2; target.next_attack_penalty_sources.append("卡戎船桨碎片 -2"); logs.append("🚣【卡戎船桨碎片】击退敌人。")
				if id == "dog_tooth": target.next_attack_penalty += 2; target.next_attack_penalty_sources.append("泥沼犬齿 -2"); logs.append("🦷【泥沼犬齿】减速敌人。")
				if id == "fear_face" and rng.randf() < .2: target.next_attack_penalty += 3; target.next_attack_penalty_sources.append("恐怖之面 -3"); logs.append("👻【恐怖之面】恐惧敌人。")
				if id == "yesterday_coin" and value % 2 != 0: value += 1; logs.append("🪙【昨日硬币】伤害为奇数，+1。")
				if id == "eroded_shard":
					var bonus := rng.randi_range(2,3); value += bonus; logs.append("✨【蚀光残片】伤害+%d。" % bonus)
					if rng.randf() < .15: logs.append("💥【蚀光残片】反噬！"); logs.append_array(apply_damage(1))
				if id == "broken_second" and not relic.used: relic.used = true; value += 4; logs.append("⏱️【断裂秒针】首次攻击伤害+4。")
				if id == "moss_spores": value += 1; logs.append("🍄【神之苔藓的孢子】伤害+1。")
				if id == "reverse_hymn" and rng.randf() < .2: target.next_attack_penalty += 1; logs.append("🎵【倒放圣歌】敌人下次命中-1。")
				if id == "court_ink" and target.tier == "elite": value += 1; logs.append("🖋️【审判庭的墨水】对精英伤害+1。")
				if id == "compass" and value % 2 == 0: player.next_attack_roll_bonus += 1; logs.append("🧭【迷途者的罗盘】下次命中+1。")
			"defend":
				if id == "black_wind" and rng.randf() < .15: value = {"handled":true, "damage":0}; logs.append("🌪️【黑风絮】完全闪避！")
				if id == "mother_cloth" and player.current_hp < player.max_hp * .4 and rng.randf() < .35: player.next_attack_bonus -= 2; value = {"handled":true, "damage":0}; logs.append("👗【褪色母亲的空衣】完全闪避。")
			"dodge":
				if id == "wind_page": player.next_attack_bonus += 2; logs.append("🌪️【风卷残页】下次攻击伤害+2。")
			"pre_damage":
				if id == "nameplate" and value > 0: value = maxi(0, value - 2); player.next_attack_bonus -= 1; logs.append("🛡️【凝固者的铭牌】减免2点伤害，下次攻击伤害-1。")
			"death":
				if player.current_hp <= 0 and id == "soul_ticket" and not relic.used: relic.used = true; player.current_hp = player.max_hp * 3 / 10; value = true; logs.append("✨【渡魂符】复活，生命恢复至30%。")
				if player.current_hp <= 0 and id == "memory_tablet" and not relic.used: relic.used = true; player.current_hp = 5; player.temp_hp += 5; value = true; logs.append("🪨【守忆者刻名石板】复活，恢复5血5盾。")
				if player.current_hp <= 0 and id == "god_ash" and not relic.used: relic.used = true; player.current_hp = 8; value = true; logs.append("🌋【神之灰烬】复活，恢复8点生命。")
			"combat_end":
				if id == "candle": logs.append("🕯️【融化的烛泪】凝固..."); logs.append_array(apply_damage(1))
				if id == "moss_spores" and rng.randf() < .1: var loss := rng.randi_range(3,5); logs.append("🍄【神之苔藓的孢子】分解！"); logs.append_array(apply_damage(loss))
	return {"value":value, "logs":logs}

func boss_phase(enemy: Dictionary) -> Array:
	var logs := []; var kind: String = enemy.get("boss_kind", "")
	if combat_round > 0 and combat_round % 3 == 0:
		if kind == "charon": enemy.summon = "ExplodingLostSoul"; logs.append("★ 卡戎挥动船篙，冥河中爬出亡魂！")
		elif kind == "memory": enemy.summon = "FracturedEcho"; logs.append("★ 守忆者身上的文字蠕动，断裂回响降临！")
		elif kind == "end": enemy.summon = "KongBaiLieXi"; logs.append("🌀 现实崩塌，【空白裂隙】从中分裂！")
		elif kind == "gatekeeper":
			logs.append("☀️ 残翼守门人释放【天堂余晖】！")
			logs.append_array(apply_damage(roll_dice("2d6"))); player.next_attack_roll_bonus -= 2; logs.append("🌟 下次攻击命中 -2！")
	if kind == "end" and combat_round > 0 and combat_round % 4 == 0:
		var locks := ["arcane_bolt", "arcane_torrent", "spell_slot"] if is_mage() else ["attack", "shield_bash", "defend"]
		player.disabled_action = locks.pick_random(); logs.append("🚫【法则褪色】下回合无法使用【%s】！" % action_display_name(player.disabled_action))
	return logs

func gain_relic(kind: String, initial_logs: Array, advance := true) -> Dictionary:
	var logs := initial_logs.duplicate(); var owned := []
	for relic in player.relics: owned.append(relic.name)
	var chance := 1.0 if kind == "treasure" else .8 if kind == "elite" else .3
	if rng.randf() > chance: logs.append("未发现任何遗物。 "); return proceed(logs) if advance else _result(logs)
	var roll := rng.randf(); var rarity := "common"
	if kind == "elite": rarity = "epic" if roll < .15 else "rare" if roll < .6 else "common"
	else: rarity = "epic" if roll < .05 else "rare" if roll < .2 else "common"
	var candidates := []
	for id in BrokenGameData.RELICS:
		var template: Dictionary = BrokenGameData.RELICS[id]
		if template.rarity == rarity and not owned.has(template.name): candidates.append(id)
	if candidates.is_empty():
		for id in BrokenGameData.RELICS:
			if not owned.has(BrokenGameData.RELICS[id].name): candidates.append(id)
	if candidates.is_empty(): logs.append("你已经拥有所有遗物。 "); return proceed(logs) if advance else _result(logs)
	var relic := BrokenGameData.make_relic(candidates.pick_random()); player.relics.append(relic)
	logs.append("✨ 发现遗物！【%s】\n“%s”\n效果：%s" % [relic.name, relic.lore, relic.effect]); logs.append("📌 遗物已装备！"); logs.append_array(acquire_relic(relic))
	return proceed(logs) if advance else _result(logs)

func acquire_relic(relic: Dictionary) -> Array:
	match relic.id:
		"houpan": player.max_hp += 8; player.current_hp += 8; return ["最大生命提升！当前HP: %d/%d" % [player.current_hp, player.max_hp]]
		"limbo_ash": player.max_hp += 5; player.current_hp += 5; return ["最大生命提升！当前HP: %d/%d" % [player.current_hp, player.max_hp]]
		"wet_sand": player.ac += 1; return ["护甲等级提升！当前AC: %d" % player.ac]
		_: return []

func victory(initial_logs: Array) -> Dictionary:
	var logs := initial_logs.duplicate(); logs.append("\n=============== 战斗胜利 ===============")
	if combat_ac_bonus > 0:
		player.ac -= combat_ac_bonus; logs.append("🌀 战斗结束，绝对领域消散，AC 恢复至 %d。" % player.ac); combat_ac_bonus = 0
	if player.temp_hp > 0: player.temp_hp = 0; logs.append("战斗结束，护盾消散。")
	logs.append_array(relic_event("combat_end", {}).logs)
	if not alive(player): return game_over(logs)
	var boss := enemies.any(func(enemy): return enemy.tier == "boss")
	var elite := boss or enemies.any(func(enemy): return enemy.tier == "elite")
	if not elite: var amount := maxi(1, player.max_hp / 5); heal(amount); logs.append("你稍作喘息，恢复 %d 点HP。" % amount)
	var reward_kind := "elite" if elite else "normal"
	if boss:
		var reward := gain_relic(reward_kind, logs, false)
		# Boss progression must happen after the reward is applied, not after room movement.
		return boss_victory(reward.logs)
	return gain_relic(reward_kind, logs)

func boss_victory(logs: Array) -> Dictionary:
	if current_floor == 1:
		phase = "LEVEL_UP"
		logs.append("🎉 胜利！你击败卡戎，通过第一层地狱！请选择强化：")
		return _result(logs, [_action("⚔️ 灵魂锋芒 (攻击判定+1)", "level_up", {"kind":"attack"}), _action("❤️ 生命汲取 (最大生命+5)", "level_up", {"kind":"hp"}), _action("🛡️ 坚固壁垒 (护盾获得量+1)", "level_up", {"kind":"shield"})])
	if current_floor == 2:
		phase = "LEVEL_UP"
		logs.append("🎉 胜利！你击败守忆者，守住了自我！请选择强化：")
		return _result(logs, [_action("⚔️ 灵魂锋芒 (攻击判定+1)", "level_up", {"kind":"attack"}), _action("❤️ 生命汲取 (最大生命+5)", "level_up", {"kind":"hp"}), _action("🛡️ 坚固壁垒 (护盾获得量+1)", "level_up", {"kind":"shield"})])
	if current_floor == 3:
		current_floor = 4; logs.append("\n残翼守门人倒下，天堂的大门轰然碎裂。\n你走进了最深处。这里没有光，没有暗，只有一片纯粹的空白。\n\n=============== 终末 ===============\n一个没有形态的存在在此显现。神老死之后，世界开始遗忘自己。\n你不是在和一个敌人战斗，你是在和“结束”这个概念本身对峙。")
		return start_combat(["ZhongMoBenShen"], true, logs)
	phase = "GAME_OVER"; logs.append("🎉 胜利！你击败了终末本身！世界在你身后缓缓重组。")
	return _result(logs, [_action("🔄 重新开始", "restart")])

func level_up(kind: String) -> Dictionary:
	var logs := []
	if kind == "attack": player.bonus_attack += 1; logs.append("⚔️ 攻击判定永久 +1。")
	elif kind == "hp": player.max_hp += 5; player.current_hp += 5; logs.append("❤️ 最大生命永久 +5。")
	else: player.bonus_shield += 1; logs.append("🛡️ 护盾获得量永久 +1。")
	current_floor += 1; distance_to_boss = rng.randi_range(6,9); enemies = []; combat_round = 1
	if current_floor == 2:
		player.memory = 10; logs.append("\n你踏上了冥河之船，前往更深层的地狱...\n\n=============== 第二层：蚀之人间 ===============\n这里的颜色像被水浸泡过一样剥落，时间法则在此断裂。\n你必须收集“记忆残片”来保持自我，否则将融入背景！")
	else:
		player.memory = mini(player.max_memory, player.memory + 8); logs.append("\n守忆者的身躯崩塌，化作漫天飞舞的纸屑。\n你顺着纸屑飞舞的方向，来到了曾经的天堂。\n\n=============== 第三层：陨落天堂 ===============\n神圣的殿堂已经崩坏，天使的羽毛散落一地。\n这里的法则正在崩溃，你的所有判定都将受到干扰。")
	return generate_explore(logs)

func game_over(logs: Array) -> Dictionary:
	phase = "GAME_OVER"; logs.append("\n💀 你倒在了探索途中...")
	return _result(logs, [_action("🔄 轮回重启", "restart")])
func memory_over(logs: Array) -> Dictionary:
	phase = "GAME_OVER"; logs.append("\n💀 你的记忆彻底归零，融入了背景。")
	return _result(logs, [_action("🔄 轮回重启", "restart")])

func restart_game() -> Dictionary:
	var result := character_select()
	result["clear_log"] = true
	return result

func character_text() -> String:
	var text := "【%s・%s・%s】\n\n【核心属性】\nSTR: %d (%+d)  DEX: %d (%+d)  CON: %d (%+d)\nINT: %d (%+d)  WIS: %d (%+d)  CHA: %d (%+d)\n\n【战斗状态】\nHP: %d/%d\nAC: %d\n护盾: %d\n药水: %d" % [player.name, player.class_name, player.class_title, player.strength, ability_mod(player.strength), player.dexterity, ability_mod(player.dexterity), player.constitution, ability_mod(player.constitution), player.intelligence, ability_mod(player.intelligence), player.wisdom, ability_mod(player.wisdom), player.charisma, ability_mod(player.charisma), player.current_hp, player.max_hp, player.ac, player.temp_hp, player.items.size()]
	if current_floor >= 2: text += "\n记忆: %d/%d" % [player.memory, player.max_memory]
	if is_mage():
		text += "\n充能: %d/5" % player.charge
		text += "\n\n【法师技能】\n1. 奥术飞弹：1d8+4，使用后获得 1 层充能。\n2. 奥术洪流：获得 3 层充能。\n3. 法术位：充能达到 3 层后可用；本场抽取 3 个高阶法术，每个都能各施放一次，必中/直接生效。\n\n【法师防御】\n奥术屏障：消耗 1 层充能，获得 6 点护盾，本次 AC +3。\n硬抗：按 AC 判定。\n能量对冲：智慧判定成功受30%伤害；失败本次伤害+35%，获得1层充能。"
	text += "\n\n【已装备遗物】"
	if player.relics.is_empty(): text += "\n无"
	for relic in player.relics: text += "\n✨ %s：%s" % [relic.name, relic.effect]
	text += "\n\n【游戏规则】\n1. 防御判定：\n硬抗：AC-敌方掷骰 >=5免疫，>=2受20%，>=0受30%，<0全额。"
	if not is_mage(): text += "\n闪避：敏捷豁免同上，但>=0受50%。\n招架：力量检定>=敌方则抵消1d8+力量调整值伤害。"
	text += "\n2. 第二层法则：记忆归零将导致融入背景（Game Over）。"
	return text
