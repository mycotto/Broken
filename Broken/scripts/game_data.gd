class_name BrokenGameData
extends RefCounted

const MONSTERS := {
	"LostSoul": {"name": "迷途古魂", "ac": 10, "hp": 6, "tier": "normal", "attacks": [{"name": "锈蚀短剑", "bonus": 2, "damage": "1d4"}]},
	"ExplodingLostSoul": {"name": "冥河怨魂", "ac": 10, "hp": 6, "tier": "normal", "explodes": true, "attacks": [{"name": "锈蚀短剑", "bonus": 2, "damage": "1d4"}]},
	"WindborneLust": {"name": "风卷欲魂", "ac": 13, "hp": 9, "tier": "normal", "attacks": [{"name": "虚影抓击", "bonus": 4, "damage": "1d6+2"}]},
	"CerberusPup": {"name": "刻耳柏洛斯幼犬", "ac": 13, "hp": 28, "tier": "elite", "attacks": [{"name": "双头撕咬", "bonus": 5, "damage": "2d6+3"}]},
	"MireHungry": {"name": "泥沼饿魂", "ac": 9, "hp": 35, "tier": "elite", "attacks": [{"name": "腐臂拍击", "bonus": 3, "damage": "1d8+3"}]},
	"CharonTheFerryman": {"name": "冥河摆渡人・卡戎", "ac": 14, "hp": 40, "tier": "boss", "boss_kind": "charon", "attacks": [{"name": "冥河船篙劈砍", "bonus": 7, "damage": "1d10+4"}]},
	"SolidifiedWounded": {"name": "凝固伤者", "ac": 10, "hp": 38, "tier": "normal", "attacks": [{"name": "求死之击", "bonus": 3, "damage": "1d8+2"}]},
	"FracturedEcho": {"name": "断裂回响", "ac": 15, "hp": 32, "tier": "normal", "attacks": [{"name": "时空撕裂", "bonus": 6, "damage": "1d8+3"}]},
	"DoomsdayPreacher": {"name": "终末传教士", "ac": 15, "hp": 42, "tier": "elite", "random_attack": true, "attacks": [{"name": "末日宣判(近)", "bonus": 5, "damage": "1d8+3"}, {"name": "遗忘经文(远)", "bonus": 5, "damage": "1d6+2"}]},
	"OblivionAggregate": {"name": "遗忘聚合体", "ac": 13, "hp": 36, "tier": "elite", "attacks": [{"name": "记忆剥夺", "bonus": 5, "damage": "2d4+3"}]},
	"ErodedAfterimage": {"name": "蚀光残像", "ac": 14, "hp": 22, "tier": "normal", "attacks": [{"name": "刺目之光", "bonus": 6, "damage": "1d10+2"}]},
	"HollowMessenger": {"name": "空壳信使", "ac": 12, "hp": 30, "tier": "normal", "attacks": [{"name": "空洞投递", "bonus": 4, "damage": "1d6+1"}]},
	"MemoryKeeper": {"name": "守忆者", "ac": 16, "hp": 70, "tier": "boss", "boss_kind": "memory", "random_attack": true, "attacks": [{"name": "千名之压", "bonus": 6, "damage": "2d6+4"}, {"name": "吞忆之击", "bonus": 6, "damage": "1d10+4"}, {"name": "遗忘低语", "unblockable": true, "memory_damage": 2}]},
	"NingGuShengGe": {"name": "凝固圣歌", "ac": 15, "hp": 20, "tier": "normal", "attacks": [{"name": "诅咒声波", "bonus": 5, "damage": "1d6+2"}]},
	"TuiSeShengXiang": {"name": "褪色圣像", "ac": 11, "hp": 30, "tier": "normal", "attacks": [{"name": "石拳砸击", "bonus": 4, "damage": "1d8+4"}]},
	"ShenZhiTaiXian": {"name": "神之苔藓", "ac": 10, "hp": 24, "tier": "normal", "attacks": [{"name": "蚀光孢子", "bonus": 3, "damage": "1d6+1"}]},
	"KongBaiLieXi": {"name": "空白裂隙", "ac": 16, "hp": 18, "tier": "normal", "attacks": [{"name": "遗忘触碰", "bonus": 5, "damage": "1d4+2"}]},
	"BengJieChiTianShi": {"name": "崩解炽天使", "ac": 17, "hp": 56, "tier": "elite", "random_attack": true, "attacks": [{"name": "残翼斩击", "bonus": 6, "damage": "1d10+4"}, {"name": "圣光余烬", "bonus": 6, "damage": "1d8+2"}]},
	"ShenZhiHuiXiang": {"name": "神之回响", "ac": 15, "hp": 50, "tier": "elite", "attacks": [{"name": "临终低语", "bonus": 7, "damage": "2d6+3"}]},
	"CanYiShouMenRen": {"name": "残翼守门人", "ac": 17, "hp": 80, "tier": "boss", "boss_kind": "gatekeeper", "attacks": [{"name": "崩解圣剑", "bonus": 8, "damage": "2d8+5"}]},
	"ZhongMoBenShen": {"name": "终末本身", "ac": 18, "hp": 130, "tier": "boss", "boss_kind": "end", "attacks": [{"name": "空白吞噬", "bonus": 9, "damage": "2d10+4"}]}
}

const RELICS := {
	"houpan": {"name": "侯判所残碑", "rarity": "common", "effect": "最大生命 +8", "lore": "灵薄狱无名墓碑的碎块…"},
	"wet_sand": {"name": "冥河湿沙", "rarity": "common", "effect": "护甲等级 +1", "lore": "卡戎渡口的河沙…"},
	"soul_fire": {"name": "迷途魂火", "rarity": "common", "effect": "攻击伤害 +1", "lore": "灵薄狱古魂散出的微光…"},
	"limbo_ash": {"name": "灵薄狱灰烬", "rarity": "common", "effect": "最大生命 +5", "lore": "灵薄狱地面的灰烬，带着死寂的温度…"},
	"oar": {"name": "卡戎船桨碎片", "rarity": "rare", "effect": "攻击 25% 概率击退", "lore": "从冥河摆渡人的船桨上崩落的木片…"},
	"black_wind": {"name": "黑风絮", "rarity": "rare", "effect": "被攻击 15% 概率完全闪避", "lore": "色欲圈黑风中的一缕…"},
	"dog_tooth": {"name": "泥沼犬齿", "rarity": "rare", "effect": "攻击使敌人减速", "lore": "刻耳柏洛斯幼犬的牙齿…"},
	"judge_pressure": {"name": "审判官之压", "rarity": "rare", "effect": "战斗开始获得5点护盾", "lore": "米诺斯审判庭的威压残留…"},
	"fear_face": {"name": "恐怖之面", "rarity": "rare", "effect": "攻击 20% 概率恐惧敌人", "lore": "美杜莎之怨凝成的面具…"},
	"silver_key": {"name": "银钥匙碎片", "rarity": "epic", "effect": "每进入新房间，恢复 3 点生命", "lore": "净界之门银钥匙的一角…"},
	"soul_ticket": {"name": "渡魂符", "rarity": "epic", "effect": "死亡后原地复活一次，生命回到30%", "lore": "卡戎不愿承认的凭证…", "used": false},
	"nameplate": {"name": "凝固者的铭牌", "rarity": "common", "effect": "被击中时减免2点伤害，下次攻击伤害-1", "lore": "一枚从凝固伤者胸口取下的锈蚀铭牌。"},
	"faded_stamp": {"name": "褪色邮票", "rarity": "common", "effect": "若生命未满，进房回5血(3次)", "lore": "一张半透明的邮票，上面的地址正在消失。", "uses": 3},
	"yesterday_coin": {"name": "昨日硬币", "rarity": "common", "effect": "伤害为奇数时+1", "lore": "一枚永远落在昨天的硬币。"},
	"eroded_shard": {"name": "蚀光残片", "rarity": "rare", "effect": "攻击伤害+2或3，15%反噬1血", "lore": "一块散发着病态金光的碎片。"},
	"broken_second": {"name": "断裂秒针", "rarity": "rare", "effect": "战斗首次攻击伤害+4", "lore": "一根永远停在断裂时刻的秒针。", "used": false},
	"mother_cloth": {"name": "褪色母亲的空衣", "rarity": "rare", "effect": "低血量被击35%闪避，下次攻击伤害-2", "lore": "一件颜色已被洗尽的婴儿襁褓。"},
	"memory_tablet": {"name": "守忆者刻名石板", "rarity": "epic", "effect": "首次濒死恢复5血5盾", "lore": "从守忆者身上剥落的铭板。", "used": false},
	"dream_echo": {"name": "某人梦的回响", "rarity": "epic", "effect": "进房低血回4血，否则下次攻击+3", "lore": "一缕弥留之际逸散的梦境。"},
	"candle": {"name": "融化的烛泪", "rarity": "common", "effect": "每场战斗开始恢复3血，结束时失去1血", "lore": "神最后的祷告燃烧殆尽后留下的蜡泪。"},
	"reverse_hymn": {"name": "倒放圣歌的残页", "rarity": "common", "effect": "攻击命中20%概率使敌人下次攻击命中-1", "lore": "天堂圣歌倒放后形成的诅咒文本。"},
	"pilgrim_beads": {"name": "断裂的朝圣者念珠", "rarity": "common", "effect": "进入战斗获得2点临时护盾", "lore": "前往天堂的朝圣者遗落的念珠。"},
	"moss_spores": {"name": "神之苔藓的孢子", "rarity": "common", "effect": "攻击命中+1伤害，战后10%概率失去3-5血", "lore": "从神遗体上采集的发光孢子。"},
	"echo_accuracy": {"name": "昨日残响的准度", "rarity": "rare", "effect": "若上一轮攻击未命中，本轮攻击骰+2", "lore": "上一秒的箭矢还没落地。"},
	"prophecy": {"name": "褪色的预言书页", "rarity": "rare", "effect": "每场战斗首次攻击判定+4", "lore": "神之图书馆脱落的一页。", "used": false},
	"inevitable_end": {"name": "终末的必然", "rarity": "epic", "effect": "未命中时强行命中，但伤害减半", "lore": "靠近终末时，未命中这个概念消失。"},
	"compass": {"name": "迷途者的罗盘", "rarity": "common", "effect": "攻击伤害为偶数时，下一次攻击命中骰+1", "lore": "指针永远偏转15度的破损罗盘。"},
	"destiny_die": {"name": "天命骰", "rarity": "epic", "effect": "你的攻击骰结果固定 +1", "lore": "神死前最后掷出的骰子。"},
	"wind_page": {"name": "风卷残页", "rarity": "rare", "effect": "闪避成功后，下次攻击伤害 +2", "lore": "黑风中抢救下来的书页。"},
	"god_ash": {"name": "神之灰烬", "rarity": "epic", "effect": "每场战斗限一次，生命归零时恢复8点", "lore": "神遗体表面脱落的灰白色粉末。", "used": false},
	"ferry_ticket": {"name": "冥河船票", "rarity": "epic", "effect": "进入 Boss 房间时，恢复 10 点生命", "lore": "卡戎不承认的凭证。"},
	"court_ink": {"name": "审判庭的墨水", "rarity": "common", "effect": "对精英敌人造成的伤害 +1", "lore": "审判官用来书写判决的墨水。"}
}

const CHARACTERS := {
	"warrior": {"name": "轮回者", "class_name": "战士", "title": "破碎守卫", "description": "高生命、高 AC 的近战角色。用强力攻击、护盾猛击和守卫姿态稳步推进。", "ac": 16, "hp": 28, "strength": 18, "dexterity": 16, "constitution": 16, "intelligence": 10, "wisdom": 12, "charisma": 13},
	"mage": {"name": "轮回者", "class_name": "法师", "title": "失落的星术师", "description": "中等生命、较低 AC 的控能角色。积累充能后施放高阶法术。", "ac": 13, "hp": 25, "strength": 8, "dexterity": 14, "constitution": 14, "intelligence": 18, "wisdom": 16, "charisma": 12},
	"spellsword": {"name": "轮回者", "class_name": "魔剑士", "title": "契印持剑者", "description": "以生命驾驭短暂魔装的近战角色。魔装会强化进攻与防守，但血祭换装需要付出代价。", "ac": 14, "hp": 26, "strength": 16, "dexterity": 14, "constitution": 15, "intelligence": 14, "wisdom": 12, "charisma": 12}
}

const MAGIC_ARMORS := {
	"bulwark": {"name": "壁垒魔装", "description": "获得 3 点护盾，AC +1。", "shield": 3, "ac": 1, "roll": 0, "damage": 0},
	"hunter": {"name": "猎痕魔装", "description": "攻击判定 +1，攻击伤害 +1。", "shield": 0, "ac": 0, "roll": 1, "damage": 1},
	"duelist": {"name": "决斗魔装", "description": "AC +1，攻击判定 +1。", "shield": 0, "ac": 1, "roll": 1, "damage": 0},
	"ravager": {"name": "噬火魔装", "description": "获得 2 点护盾，攻击伤害 +1。", "shield": 2, "ac": 0, "roll": 0, "damage": 1}
}

const MAGE_SPELLS := {
	"starfall": {"name": "星陨术", "description": "必中：对一个敌人造成 28 点伤害。", "targeted": true, "kind": "damage", "amount": 28},
	"void_barrier": {"name": "虚空壁垒", "description": "获得 20 点护盾。", "targeted": false, "kind": "shield", "amount": 20},
	"absolute_field": {"name": "绝对领域", "description": "本场战斗 AC 永久 +4。", "targeted": false, "kind": "ac", "amount": 4},
	"arcane_siphon": {"name": "奥术虹吸", "description": "必中：对一个敌人造成 14 点伤害，并获得 10 点护盾。", "targeted": true, "kind": "damage_shield", "amount": 14, "shield": 10},
	"echo_revival": {"name": "回响复苏", "description": "恢复 8 点生命，并获得 10 点护盾。", "targeted": false, "kind": "heal_shield", "amount": 8, "shield": 10},
	"disorder_curse": {"name": "失序诅咒", "description": "获得 8 点护盾；所有敌人本场攻击判定 -3，AC -2。", "targeted": false, "kind": "curse", "amount": 8}
}

const POTIONS := {
	"healing": {"name": "微光疗愈药剂", "description": "恢复 5 点生命。", "kind": "heal", "amount": 5},
	"might": {"name": "猩红力量药剂", "description": "本场攻击伤害 +1。", "kind": "damage_bonus", "amount": 1},
	"precision": {"name": "银辉精准药剂", "description": "本场攻击判定 +2。", "kind": "roll_bonus", "amount": 2},
	"weakening": {"name": "灰雾削弱药剂", "description": "敌人本场攻击判定 -2。", "kind": "enemy_roll_penalty", "amount": 2},
	"barrier": {"name": "琥珀护盾药剂", "description": "获得 8 点护盾。", "kind": "shield", "amount": 8},
	"fire": {"name": "爆燃投掷药剂", "description": "对一个敌人造成 6 点伤害。", "kind": "damage", "amount": 6, "targeted": true}
}

static func make_monster(id: String) -> Dictionary:
	var monster: Dictionary = MONSTERS[id].duplicate(true)
	monster["id"] = id
	monster["max_hp"] = monster["hp"]
	monster["current_hp"] = monster["hp"]
	monster["next_attack_penalty"] = 0
	monster["next_attack_penalty_sources"] = []
	monster["combat_attack_penalty"] = 0
	monster["combat_attack_penalty_sources"] = []
	return monster

static func make_relic(id: String) -> Dictionary:
	var relic: Dictionary = RELICS[id].duplicate(true)
	relic["id"] = id
	return relic

static func character(id: String) -> Dictionary:
	return CHARACTERS[id].duplicate(true)

static func make_magic_armor(id: String) -> Dictionary:
	var armor: Dictionary = MAGIC_ARMORS[id].duplicate(true)
	armor["id"] = id
	return armor

static func mage_spell(id: String) -> Dictionary:
	var spell: Dictionary = MAGE_SPELLS[id].duplicate(true)
	spell["id"] = id
	return spell

static func make_potion(id: String) -> Dictionary:
	var potion: Dictionary = POTIONS[id].duplicate(true)
	potion["id"] = id
	return potion
