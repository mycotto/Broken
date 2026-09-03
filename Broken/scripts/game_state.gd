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

func start_new_game() -> Dictionary:
	player = {"name":"轮回者", "ac":16, "max_hp":28, "current_hp":28, "temp_hp":0, "memory":10, "max_memory":20,
		"strength":18, "dexterity":16, "constitution":16, "intelligence":10, "wisdom":12, "charisma":13, "bonus_attack":0, "bonus_shield":0,
		"next_attack_bonus":0, "next_attack_roll_bonus":0, "dream_attack_buff":0, "last_attack_missed":false,
		"disabled_action":"", "rule_break_penalty":0, "relics":[]}
	current_floor = 1; distance_to_boss = rng.randi_range(6, 9); combat_round = 1; enemies = []
	return generate_explore(["\n“又一次，从冥河的雾里醒来”\n", "地狱第 1 层：灵薄狱 | 距离冥河渡口还有 %d 步" % distance_to_boss])

func get_status_text() -> String:
	if player.is_empty(): return ""
	var text := "❤️ HP: %d/%d | 🛡️ 护盾: %d | AC: %d" % [player.current_hp, player.max_hp, player.temp_hp, player.ac]
	if current_floor >= 2: text += " | 🧠 记忆: %d/%d" % [player.memory, player.max_memory]
	text += " | 🗺️ 距离: %d步" % distance_to_boss
	if phase.begins_with("COMBAT") or phase == "TARGETING": text += " | 回合: %d" % combat_round
	if player.rule_break_penalty > 0: text += " | ⚠️ 规则崩溃: -%d" % player.rule_break_penalty
	return text

func execute_action(id: String, args := {}) -> Dictionary:
	match id:
		"generate_explore": return generate_explore()
		"start_combat": return start_combat(args.enemies, args.get("is_elite", false))
		"rest": return rest()
		"mystery": return mystery()
		"treasure": return treasure()
		"studio": return studio()
		"memory_shard": return memory_shard()
		"time_rift": return time_rift()
		"rule_collapse": return rule_collapse()
		"level_up": return level_up(args.kind)
		"select_target": return select_target(args.next)
		"cancel_target": return player_actions()
		"attack": return player_attack(args.index)
		"shield_bash": return shield_bash(args.index)
		"defend": return defend()
		"enemy_turn": return enemy_turn()
		"tough": return resolve_tough()
		"dodge": return resolve_dodge()
		"parry": return resolve_parry()
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
	var actions := options.slice(0, 3)
	actions.append(_action("📜 角色面板", "character"))
	return _result(logs, actions)

func rest() -> Dictionary:
	var amount := roll_dice("1d8") + 3; heal(amount)
	return proceed(["你在祭坛前休息，恢复了 %d 点HP。" % amount])
func mystery() -> Dictionary:
	var logs: Array = []; var event: String = ["trap","heal","buff"].pick_random()
	if event == "trap": logs.append("⚠️ 你踏入了一个隐蔽的陷阱！"); logs.append_array(apply_damage(roll_dice("1d6")))
	elif event == "heal": var amount := roll_dice("1d10"); heal(amount); logs.append("✨ 你发现神圣泉水，恢复了 %d 点HP。" % amount)
	else: player.strength += 1; player.dexterity += 1; logs.append("🛡️ 古老石碑令力量和敏捷永久 +1！")
	return proceed(logs)
func treasure() -> Dictionary: return gain_relic("treasure", [])
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
	shield_bash_cooldown = 0; defend_cooldown = 0; defending = false; combat_round = 1; player.disabled_action = ""; player.last_attack_missed = false
	var penalty := 0
	if current_floor >= 3:
		for enemy in enemies:
			if enemy.tier == "boss": penalty = maxi(penalty, 2)
			elif enemy.tier == "elite": penalty = maxi(penalty, rng.randi_range(1, 2))
			else: penalty = maxi(penalty, 1)
	player.rule_break_penalty = penalty
	var logs := initial_logs.duplicate(); logs.append("\n=============== 战斗开始 ===============")
	for enemy in enemies: logs.append("遭遇【%s】 HP: %d/%d" % [enemy.name, enemy.current_hp, enemy.max_hp])
	if penalty > 0: logs.append("⚠️【规则崩溃】所有判定掷骰 -%d！" % penalty)
	logs.append_array(relic_event("combat_start", {}).logs)
	if enemies.any(func(e): return e.tier == "boss"): logs.append_array(relic_event("boss_enter", {}).logs)
	return player_actions(logs)

func player_actions(initial_logs: Array = []) -> Dictionary:
	if not alive(player): return game_over(initial_logs)
	if alive_enemies().is_empty(): return victory(initial_logs)
	phase = "COMBAT_PLAYER"; var logs := initial_logs.duplicate(); logs.append("\n【你的回合】")
	var actions := [_action("⚔️ 强力攻击 (1d10+5)", "select_target", {"next":"attack"}, "combat", player.disabled_action == "attack"), _action("🛡️ 护盾猛击 (1d8+5 伤害+护盾)", "select_target", {"next":"shield_bash"}, "combat", player.disabled_action == "shield_bash" or shield_bash_cooldown > 0), _action("🏃 守卫姿态 (AC+3, 下次攻击+2命中/+1伤害)", "defend", {}, "combat", player.disabled_action == "defend" or defend_cooldown > 0), _action("📜 角色面板", "character")]
	return _result(logs, actions)

func select_target(next: String) -> Dictionary:
	phase = "TARGETING"; var actions := []; var index := 0
	for enemy in alive_enemies(): actions.append(_action("攻击【%s】(HP:%d/%d)" % [enemy.name, enemy.current_hp, enemy.max_hp], next, {"index":index}, "target")); index += 1
	actions.append(_action("↩️ 取消", "cancel_target"))
	return _result(["\n🎯 请选择攻击目标："], actions)

func player_attack(index: int) -> Dictionary: return attack_target(index, "1d10", false)
func shield_bash(index: int) -> Dictionary:
	if shield_bash_cooldown > 0 or player.disabled_action == "shield_bash": return player_actions(["护盾猛击不可用！"])
	return attack_target(index, "1d8", true)
func attack_target(index: int, dice: String, bash: bool) -> Dictionary:
	var targets := alive_enemies()
	if index < 0 or index >= targets.size(): return player_actions(["目标已消失。"])
	var target: Dictionary = targets[index]; var roll_bonus: int = player.next_attack_roll_bonus; player.next_attack_roll_bonus = 0
	var roll: int = roll_d20() + 7 + player.bonus_attack - player.rule_break_penalty + roll_bonus
	var logs := ["你%s %s，掷出 %d (DC%d)" % ["举盾撞向" if bash else "挥剑攻击", target.name, roll, target.ac]]
	if roll_bonus != 0: logs.append("🎯 蓄力命中骰 %+d" % roll_bonus)
	var rolling := relic_event("attack_roll", {"roll":roll}); roll = rolling.value; logs.append_array(rolling.logs)
	var hit: bool = roll >= target.ac; var forced := false
	if not hit:
		var missing := relic_event("attack_miss", {"target":target}, {"hit":false, "mult":1.0}); logs.append_array(missing.logs)
		if missing.value.hit: hit = true; forced = true
	player.last_attack_missed = not hit
	if hit:
		var damage := roll_dice(dice) + 5
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
	var penalty: int = enemy.next_attack_penalty; var enemy_roll: int = roll_d20() + attack.bonus - penalty; enemy.next_attack_penalty = 0
	var damage := roll_dice(attack.damage); logs.append("⚔️ %s 发动【%s】！掷出 %d，造成 %d 点伤害。" % [enemy.name, attack.name, enemy_roll, damage])
	var defended := relic_event("defend", {"roll":enemy_roll, "damage":damage})
	logs.append_array(defended.logs)
	if defended.value.handled:
		logs.append_array(apply_damage(defended.value.damage))
		if defended.value.damage == 0: logs.append_array(relic_event("dodge", {}).logs)
		if not alive(player): return game_over(logs)
		return _result(logs, [], 0.35, "enemy_turn")
	pending_defense = {"roll":enemy_roll, "damage":damage}
	phase = "COMBAT_DEFEND"
	return _result(logs + ["请选择应对方式："], [_action("🛡️ 硬抗 (AC判定)", "tough", {}, "combat"), _action("🏃 闪避 (敏捷豁免)", "dodge", {}, "combat"), _action("⚔️ 招架 (力量检定)", "parry", {}, "combat")])

func resolve_tough() -> Dictionary:
	var diff: int = player.ac - pending_defense.roll; var actual: int = pending_defense.damage; var logs := []
	if diff >= 5: actual = 0; logs.append("🛡️ 完美格挡！免疫伤害。")
	elif diff >= 2: actual = maxi(1, pending_defense.damage * 2 / 10); logs.append("🛡️ 擦伤！受到20%%伤害。")
	elif diff >= 0: actual = maxi(1, pending_defense.damage * 3 / 10); logs.append("🛡️ 硬抗！受到30%%伤害。")
	else: logs.append("💥 防御被击穿！")
	return apply_and_continue(actual, logs)
func resolve_dodge() -> Dictionary:
	var save: int = roll_d20() + ability_mod(player.dexterity) - player.rule_break_penalty; var diff: int = save - pending_defense.roll; var actual: int = pending_defense.damage; var logs := ["🏃 敏捷豁免掷出 %d" % save]
	if diff >= 5: actual = 0; logs.append("完美闪避！")
	elif diff >= 2: actual = maxi(1, pending_defense.damage * 2 / 10); logs.append("轻巧闪避！受到20%%伤害。")
	elif diff >= 0: actual = maxi(1, pending_defense.damage * 5 / 10); logs.append("勉强闪避！受到50%%伤害。")
	else: logs.append("闪避失败！")
	return apply_and_continue(actual, logs)
func resolve_parry() -> Dictionary:
	var strength: int = ability_mod(player.strength); var check: int = roll_d20() + strength - player.rule_break_penalty; var actual: int = pending_defense.damage; var logs := ["⚔️ 力量检定掷出 %d" % check]
	if check >= pending_defense.roll: var reduced := roll_dice("1d8") + strength; actual = maxi(0, actual - reduced); logs.append("招架成功！抵消 %d 点伤害。" % reduced)
	else: logs.append("招架失败！")
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
	if damage > 0: player.current_hp = maxi(0, player.current_hp - damage); logs.append("➥ 轮回者受到 %d 点伤害，剩余 %d/%d" % [damage, player.current_hp, player.max_hp])
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
				if id == "oar" and rng.randf() < .25: target.next_attack_penalty += 2; logs.append("🚣【卡戎船桨碎片】击退敌人。")
				if id == "dog_tooth": target.next_attack_penalty += 2; logs.append("🦷【泥沼犬齿】减速敌人。")
				if id == "fear_face" and rng.randf() < .2: target.next_attack_penalty += 3; logs.append("👻【恐怖之面】恐惧敌人。")
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
				if player.current_hp <= 0 and id == "soul_ticket" and not relic.used: relic.used = true; player.current_hp = player.max_hp * 3 / 10; value = true; logs.append("✨【渡魂符】复活，生命恢复至30%%。")
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
		var locks := ["attack","shield_bash","defend"]; player.disabled_action = locks.pick_random(); logs.append("🚫【法则褪色】下回合无法使用【%s】！" % player.disabled_action)
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
	var result := start_new_game()
	result["clear_log"] = true
	return result

func character_text() -> String:
	var text := "【核心属性】\nSTR: %d (%+d)  DEX: %d (%+d)  CON: %d (%+d)\nINT: %d (%+d)  WIS: %d (%+d)  CHA: %d (%+d)\n\n【战斗状态】\nHP: %d/%d\nAC: %d\n护盾: %d" % [player.strength, ability_mod(player.strength), player.dexterity, ability_mod(player.dexterity), player.constitution, ability_mod(player.constitution), player.intelligence, ability_mod(player.intelligence), player.wisdom, ability_mod(player.wisdom), player.charisma, ability_mod(player.charisma), player.current_hp, player.max_hp, player.ac, player.temp_hp]
	if current_floor >= 2: text += "\n记忆: %d/%d" % [player.memory, player.max_memory]
	text += "\n\n【已装备遗物】"
	if player.relics.is_empty(): text += "\n无"
	for relic in player.relics: text += "\n✨ %s：%s" % [relic.name, relic.effect]
	text += "\n\n【游戏规则】\n1. 防御判定：\n硬抗：AC-敌方掷骰 >=5免疫，>=2受20%，>=0受30%，<0全额。\n闪避：敏捷豁免同上，但>=0受50%。\n招架：力量检定>=敌方则抵消1d8+力量调整值伤害。\n2. 第二层法则：记忆归零将导致融入背景（Game Over）。"
	return text
