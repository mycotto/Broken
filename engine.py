# engine.py
import random
from core import PlayerCharacter, d, Combatant, ability_modifier
from monsters import (LostSoul, WindborneLust, CharonTheFerryman, CerberusPup, MireHungry,
                      SolidifiedWounded, FracturedEcho, DoomsdayPreacher, OblivionAggregate, 
                      ErodedAfterimage, HollowMessenger, MemoryKeeper, ExplodingLostSoul,
                      NingGuShengGe, TuiSeShengXiang, ShenZhiTaiXian, KongBaiLieXi, 
                      BengJieChiTianShi, ShenZhiHuiXiang, CanYiShouMenRen, ZhongMoBenShen)
from relics import roll_relic
from typing import Tuple, List

MONSTER_MAP_F1 = {"LostSoul": LostSoul, "WindborneLust": WindborneLust, "CerberusPup": CerberusPup, "MireHungry": MireHungry, "CharonTheFerryman": CharonTheFerryman}
MONSTER_MAP_F2 = {"SolidifiedWounded": SolidifiedWounded, "FracturedEcho": FracturedEcho, "DoomsdayPreacher": DoomsdayPreacher, "OblivionAggregate": OblivionAggregate, "ErodedAfterimage": ErodedAfterimage, "HollowMessenger": HollowMessenger, "MemoryKeeper": MemoryKeeper}
MONSTER_MAP_F3 = {"NingGuShengGe": NingGuShengGe, "TuiSeShengXiang": TuiSeShengXiang, "ShenZhiTaiXian": ShenZhiTaiXian, "KongBaiLieXi": KongBaiLieXi, "BengJieChiTianShi": BengJieChiTianShi, "ShenZhiHuiXiang": ShenZhiHuiXiang, "CanYiShouMenRen": CanYiShouMenRen, "ZhongMoBenShen": ZhongMoBenShen}

class GameEngine:
    def __init__(self):
        self.player = None
        self.enemies = []
        self.distance_to_boss = 0
        self.shield_bash_cooldown = 0
        self.defend_cooldown = 0  # 守卫姿态冷却
        self.is_defending = False
        self.combat_round = 1
        self.pending_defend_data = {}
        self.pending_enemy_attacks = []
        self.phase = "INIT"
        self.current_floor = 1

    def get_status_text(self) -> str:
        p = self.player
        if not p: return ""
        status = f"❤️ HP: {p.current_hp}/{p.max_hp} | 🛡️ 护盾: {p.temp_hp} | AC: {p.ac}"
        if self.current_floor >= 2:
            status += f" | 🧠 记忆: {p.memory}/{p.max_memory}"
        status += f" | 🗺️ 距离: {self.distance_to_boss}步"
        if self.phase.startswith("COMBAT") or self.phase == "TARGETING":
            status += f" | 回合: {self.combat_round}"
        if p.rule_break_penalty > 0:
            status += f" | ⚠️ 规则崩溃: -{p.rule_break_penalty}"
        return status

    def start_new_game(self) -> dict:
        self.player = PlayerCharacter("轮回者", "fighter", 3, {'strength': 18, 'dexterity': 16, 'constitution': 16, 'intelligence': 10, 'wisdom': 12, 'charisma': 13})
        self.current_floor = 1
        self.distance_to_boss = random.randint(6, 9)
        self.shield_bash_cooldown = 0
        self.defend_cooldown = 0
        self.is_defending = False
        self.enemies = []
        self.combat_round = 1
        logs = ['\n“又一次，从冥河的雾里醒来”\n', f"地狱第 1 层：灵薄狱 | 距离冥河渡口还有 {self.distance_to_boss} 步"]
        return self._generate_explore_options(logs)

    def execute_action(self, action_id: str, args: dict = None) -> dict:
        if args is None: args = {}
        method = getattr(self, action_id, None)
        if method: return method(**args)
        return {"logs": ["Error: Invalid action"], "actions": []}

    def _post_combat_proceed(self, initial_logs=None) -> dict:
        logs = initial_logs or []

        # Exploration events also deal damage.  A character who was not
        # revived by a relic must not continue into room-entry healing or the
        # next encounter.
        if not self.player.is_alive():
            return self._do_game_over(logs)

        _, room_logs = self.player.trigger_event("on_room_enter", default_result=None)
        logs.extend(room_logs)

        if not self.player.is_alive():
            return self._do_game_over(logs)

        if self.current_floor >= 2:
            mem_loss = 1
            self.player.memory -= mem_loss
            logs.append(f"🌫️ 褪色的世界侵蚀着你的记忆... 记忆值 -{mem_loss}。当前记忆: {self.player.memory}/{self.player.max_memory}")
            if self.player.memory <= 0:
                return self._do_memory_game_over(logs)

        self.distance_to_boss -= 1
        if self.distance_to_boss <= 0:
            if self.current_floor == 1: return self._start_boss_fight(logs)
            elif self.current_floor == 2: return self._start_floor_2_boss_fight(logs)
            elif self.current_floor == 3: return self._start_floor_3_boss_fight(logs)
        else:
            logs.append(f"\n--- ⏳ 距离法则断裂处还有 {self.distance_to_boss} 步 ---")
            if self.current_floor == 1: return {"logs": logs, "timer": 1.0, "next_action": "generate_explore_options", "actions": []}
            elif self.current_floor == 2: return {"logs": logs, "timer": 1.0, "next_action": "generate_floor_2_explore_options", "actions": []}
            elif self.current_floor == 3: return {"logs": logs, "timer": 1.0, "next_action": "generate_floor_3_explore_options", "actions": []}
        return {"logs": logs, "actions": []}

    def _generate_explore_options(self, initial_logs=None) -> dict:
        self.phase = "EXPLORE"
        logs = initial_logs or []
        logs.append("\n--- 🗺️ 探索地图 ---")
        logs.append("前方出现了 3 条道路：")
        options = [
            ("⚔️ 遭遇 迷途古魂", "start_combat", {"enemies": ["LostSoul", "LostSoul"], "is_elite": False}),
            ("⚔️ 遭遇 风卷欲魂", "start_combat", {"enemies": ["WindborneLust", "LostSoul"], "is_elite": False}),
            ("⚔️ 精英：刻耳柏洛斯幼犬", "start_combat", {"enemies": ["CerberusPup"], "is_elite": True}),
            ("⚔️ 精英：泥沼饿魂", "start_combat", {"enemies": ["MireHungry"], "is_elite": True}),
            ("🛏️ 废弃的祭坛", "rest_at_shrine", {}),
            ("❓ 神秘低语", "resolve_mystery", {}),
            ("🎁 隐秘的宝箱", "resolve_treasure", {})
        ]
        chosen = random.sample(options, 3)
        actions = [{"label": t, "action_id": a, "args": ar, "css": "explore-btn"} for t, a, ar in chosen]
        actions.append({"label": "📜 角色面板", "action_id": "show_character_screen", "args": {}, "css": "explore-btn"})
        return {"logs": logs, "actions": actions}

    def generate_explore_options(self) -> dict: return self._generate_explore_options()
    def rest_at_shrine(self) -> dict:
        heal = d('1d8') + 3
        self.player.current_hp = min(self.player.max_hp, self.player.current_hp + heal)
        return self._post_combat_proceed([f"你在祭坛前休息，恢复了 {heal} 点HP。"])

    def resolve_mystery(self) -> dict:
        logs = []
        event = random.choice(["trap", "heal", "buff"])
        if event == "trap":
            dmg = d('1d6'); _, dmg_logs = self.player.take_damage(dmg)
            logs.append("⚠️ 你踏入了一个隐蔽的陷阱！"); logs.extend(dmg_logs)
        elif event == "heal":
            heal = d('1d10'); self.player.current_hp = min(self.player.max_hp, self.player.current_hp + heal)
            logs.append(f"✨ 你发现了一股神圣的泉水，恢复了 {heal} 点HP。")
        elif event == "buff":
            self.player.abilities['strength'] += 1; self.player.abilities['dexterity'] += 1
            logs.append("🛡️ 你触摸了一块古老的石碑，力量和敏捷永久 +1！")
        return self._post_combat_proceed(logs)

    def resolve_treasure(self) -> dict:
        logs = []
        owned_names = [r.name for r in self.player.relics]
        relic, relic_logs = roll_relic("treasure", owned_names)
        logs.extend(relic_logs)
        if relic and not any(r.name == relic.name for r in self.player.relics):
            self.player.relics.append(relic); logs.append("📌 遗物已装备！"); logs.extend(relic.on_acquire(self.player))
        return self._post_combat_proceed(logs)

    def _start_boss_fight(self, initial_logs=None) -> dict:
        logs = initial_logs or []
        logs.append("\n" + "="*50)
        logs.append("【最终挑战：冥河摆渡人】")
        logs.append("黑水翻涌，巨大的阴影笼罩了你。")
        logs.append("「生者！退去！此河只载亡魂，不渡活人！」")
        return self.start_combat(["CharonTheFerryman"], True, logs)

    def _show_level_up_options(self, initial_logs=None) -> dict:
        self.phase = "LEVEL_UP"
        logs = initial_logs or []
        logs.append("\n✨ 在跨越冥河之际，你的灵魂得到了某种升华...")
        logs.append("请选择一项强化：")
        upgrade_pool = [
            ("⚔️ 灵魂锋芒 (攻击判定+1)", "apply_level_up", {"upgrade_type": "attack"}),
            ("❤️ 生命汲取 (最大生命+5)", "apply_level_up", {"upgrade_type": "hp"}),
            ("🛡️ 坚固壁垒 (护盾获得量+1)", "apply_level_up", {"upgrade_type": "shield"})
        ]
        actions = [{"label": t, "action_id": a, "args": ar, "css": "explore-btn"} for t, a, ar in upgrade_pool]
        return {"logs": logs, "actions": actions}

    def apply_level_up(self, upgrade_type: str) -> dict:
        logs = []
        if upgrade_type == "attack":
            self.player.bonus_attack += 1
            logs.append("⚔️ 你的攻击更加精准！攻击判定永久 +1。")
        elif upgrade_type == "hp":
            self.player.bonus_hp += 5; self.player.max_hp += 5; self.player.current_hp += 5
            logs.append("❤️ 你的生命力更加强盛！最大生命永久 +5。")
        elif upgrade_type == "shield":
            self.player.bonus_shield += 1
            logs.append("🛡️ 你的护盾更加坚固！护盾获得量永久 +1。")
        if self.current_floor == 1: return self.enter_floor_2(logs)
        else: return self.enter_floor_3(logs)

    def enter_floor_2(self, initial_logs=None) -> dict:
        self.current_floor = 2
        self.distance_to_boss = random.randint(6, 9)
        self.enemies = []; self.combat_round = 1; self.phase = "EXPLORE"
        self.player.memory = 10 
        logs = initial_logs or []
        logs.append("\n你踏上了冥河之船，前往更深层的地狱...")
        logs.append("\n" + "="*15 + " 第二层：蚀之人间 " + "="*15)
        logs.append("这里的颜色像被水浸泡过一样剥落，时间法则在此断裂。")
        logs.append('你必须收集“记忆残片”来保持自我，否则将融入背景！')
        return self._generate_floor_2_explore_options(logs)

    def _generate_floor_2_explore_options(self, initial_logs=None) -> dict:
        self.phase = "EXPLORE"
        logs = initial_logs or []
        logs.append("\n--- 🗺️ 褪色街道 ---")
        logs.append("前方出现了 3 条道路：")
        options = [
            ("⚔️ 遭遇 凝固伤者", "start_combat", {"enemies": ["SolidifiedWounded", "SolidifiedWounded"], "is_elite": False}),
            ("⚔️ 遭遇 空壳信使与蚀光残像", "start_combat", {"enemies": ["HollowMessenger", "ErodedAfterimage"], "is_elite": False}),
            ("⚔️ 精英：终末传教士", "start_combat", {"enemies": ["DoomsdayPreacher"], "is_elite": True}),
            ("⚔️ 精英：遗忘聚合体", "start_combat", {"enemies": ["OblivionAggregate"], "is_elite": True}),
            ("🖼️ 褪色的画室", "resolve_faded_studio", {}),
            ("🧠 记忆残片", "resolve_memory_shard", {}),
            ("⚠️ 时间裂缝", "resolve_time_rift", {})
        ]
        if random.random() < 0.30: options.append(("🎁 褪色的宝箱", "resolve_treasure", {}))
        chosen = random.sample(options, 3)
        actions = [{"label": t, "action_id": a, "args": ar, "css": "explore-btn"} for t, a, ar in chosen]
        actions.append({"label": "📜 角色面板", "action_id": "show_character_screen", "args": {}, "css": "explore-btn"})
        return {"logs": logs, "actions": actions}

    def generate_floor_2_explore_options(self) -> dict: return self._generate_floor_2_explore_options()

    def resolve_faded_studio(self) -> dict:
        logs = ["你走进一间褪色的画室，阳光从窗户照进来，但那是'昨天'的阳光，不会移动。"]
        event = random.choice(["relic", "memory"])
        if event == "relic":
            owned_names = [r.name for r in self.player.relics]
            relic, relic_logs = roll_relic("normal", owned_names)
            logs.extend(relic_logs)
            if relic and not any(r.name == relic.name for r in self.player.relics):
                self.player.relics.append(relic); logs.append("📌 遗物已装备！"); logs.extend(relic.on_acquire(self.player))
        else:
            heal_mem = 3; self.player.memory = min(self.player.max_memory, self.player.memory + heal_mem)
            logs.append(f"✨ 你在画布后找到了一丝熟悉的色彩，记忆值恢复 {heal_mem}。当前记忆: {self.player.memory}/{self.player.max_memory}")
        return self._post_combat_proceed(logs)

    def resolve_memory_shard(self) -> dict:
        logs = ["你发现了一个闪闪发光的碎片——一枚戒指、一段童谣，或一张全家福。"]
        heal_mem = random.randint(3, 5); self.player.memory = min(self.player.max_memory, self.player.memory + heal_mem)
        logs.append(f"✨ 记忆残片被收集！记忆值恢复 {heal_mem}。当前记忆: {self.player.memory}/{self.player.max_memory}")
        dmg = d('1d4'); _, dmg_logs = self.player.take_damage(dmg)
        logs.append(f"⚠️ 但过去的幻影划伤了你！"); logs.extend(dmg_logs)
        return self._post_combat_proceed(logs)

    def resolve_time_rift(self) -> dict:
        logs = ["你踏入了一片颜色浓艳得不真实的区域，时间法则在这里断裂！"]
        event = random.choice(["temporal_overlap", "debuff", "memory_loss"])
        if event == "temporal_overlap":
            hp_gain = 5; self.player.max_hp += hp_gain
            self.player.current_hp = min(self.player.max_hp, self.player.current_hp + hp_gain)
            logs.append(f'🧬 【昨日之韧】：“昨天”更健康的你与现在的你重叠了！最大生命永久 +{hp_gain}，并恢复了 {hp_gain} 点生命。')
        elif event == "debuff":
            dmg = d('2d8'); _, dmg_logs = self.player.take_damage(dmg)
            logs.append(f"💥 时间的乱流撕扯着你的身体！"); logs.extend(dmg_logs)
        else:
            mem_loss = 3; self.player.memory -= mem_loss
            logs.append(f"🌫️ 你忘记了为什么出发。记忆值大幅降低 {mem_loss}！当前记忆: {self.player.memory}/{self.player.max_memory}")
            if self.player.memory <= 0: return self._do_memory_game_over(logs)
        return self._post_combat_proceed(logs)

    def _start_floor_2_boss_fight(self, initial_logs=None) -> dict:
        logs = initial_logs or []
        logs.append("\n" + "="*50)
        logs.append("【第二层Boss：守忆者】")
        logs.append("一个由文字、姓名和地图组成的巨大人形挡住了去路。")
        logs.append("他没有敌意，只是在用成千上万种声音喃喃自语，试图记住一切。")
        return self.start_combat(["MemoryKeeper"], True, logs)

    def _do_memory_game_over(self, initial_logs=None) -> dict:
        self.phase = "GAME_OVER"
        logs = initial_logs or []
        logs.append("\n💀 你的记忆彻底归零...")
        logs.append("你没有死，但你'融入了背景'——变成了NPC之一，失去了玩家身份。")
        actions = [{"label": "🔄 轮回重启", "action_id": "restart_game", "args": {}, "css": "explore-btn"}]
        return {"logs": logs, "actions": actions}

    # ================= 第三层：陨落天堂 =================
    def enter_floor_3(self, initial_logs=None) -> dict:
        self.current_floor = 3
        self.distance_to_boss = random.randint(6, 9)
        self.enemies = []; self.combat_round = 1; self.phase = "EXPLORE"
        logs = initial_logs or []
        logs.append("\n守忆者的身躯崩塌，化作漫天飞舞的纸屑。")
        logs.append("你顺着纸屑飞舞的方向，来到了曾经的天堂。")
        
        # 恢复记忆
        heal_mem = 8
        self.player.memory = min(self.player.max_memory, self.player.memory + heal_mem)
        logs.append(f"✨ 跨越层级的瞬间，你的记忆得到了某种补充，恢复了 {heal_mem} 点记忆值。当前记忆: {self.player.memory}/{self.player.max_memory}")
        
        logs.append("\n" + "="*15 + " 第三层：陨落天堂 " + "="*15)
        logs.append("神圣的殿堂已经崩坏，天使的羽毛散落一地。")
        logs.append("这里的法则正在崩溃，你的所有判定都将受到干扰。")
        return self._generate_floor_3_explore_options(logs)

    def _generate_floor_3_explore_options(self, initial_logs=None) -> dict:
        self.phase = "EXPLORE"
        logs = initial_logs or []
        logs.append("\n--- 🗺️ 崩坏圣堂 ---")
        logs.append("前方出现了 3 条道路：")
        options = [
            ("⚔️ 遭遇 凝固圣歌与空白裂隙", "start_combat", {"enemies": ["NingGuShengGe", "KongBaiLieXi"], "is_elite": False}),
            ("⚔️ 遭遇 褪色圣像与神之苔藓", "start_combat", {"enemies": ["TuiSeShengXiang", "ShenZhiTaiXian"], "is_elite": False}),
            ("⚔️ 精英：崩解炽天使", "start_combat", {"enemies": ["BengJieChiTianShi"], "is_elite": True}),
            ("⚔️ 精英：神之回响", "start_combat", {"enemies": ["ShenZhiHuiXiang"], "is_elite": True}),
            ("🙏 神之遗骸", "rest_at_shrine", {}),
            ("⚠️ 崩坏法则", "resolve_rule_collapse", {}),
            ("🧠 记忆残片", "resolve_memory_shard", {})
        ]
        if random.random() < 0.20: options.append(("🎁 神之宝库", "resolve_treasure", {}))
        chosen = random.sample(options, 3)
        actions = [{"label": t, "action_id": a, "args": ar, "css": "explore-btn"} for t, a, ar in chosen]
        actions.append({"label": "📜 角色面板", "action_id": "show_character_screen", "args": {}, "css": "explore-btn"})
        return {"logs": logs, "actions": actions}

    def generate_floor_3_explore_options(self) -> dict: return self._generate_floor_3_explore_options()

    def resolve_rule_collapse(self) -> dict:
        logs = ["你触碰了一团崩坏的光芒，现实的规则在你眼前扭曲！"]
        event = random.choice(["debuff", "heal", "memory_loss"])
        if event == "debuff":
            dmg = d('2d10'); _, dmg_logs = self.player.take_damage(dmg)
            logs.append(f"💥 规则的反噬撕裂了你的灵魂！"); logs.extend(dmg_logs)
        elif event == "heal":
            heal = d('2d8'); self.player.current_hp = min(self.player.max_hp, self.player.current_hp + heal)
            logs.append(f"✨ 你在崩坏中窥见了一丝真理，恢复了 {heal} 点HP。")
        else:
            mem_loss = 4; self.player.memory -= mem_loss
            logs.append(f"🌫️ 你的认知被严重扭曲。记忆值大幅降低 {mem_loss}！当前记忆: {self.player.memory}/{self.player.max_memory}")
            if self.player.memory <= 0: return self._do_memory_game_over(logs)
        return self._post_combat_proceed(logs)

    def _start_floor_3_boss_fight(self, initial_logs=None) -> dict:
        logs = initial_logs or []
        logs.append("\n" + "="*50)
        logs.append("【第三层Boss：残翼守门人】")
        logs.append("天堂大门的最后守护者挡住了去路。翅膀折断，圣剑崩裂。")
        logs.append("它机械地举起剑，执行着早已没有意义的指令。")
        return self.start_combat(["CanYiShouMenRen"], True, logs)

    def enter_floor_4(self, initial_logs=None) -> dict:
        self.current_floor = 4
        self.enemies = []; self.combat_round = 1; self.phase = "COMBAT_PLAYER"
        logs = initial_logs or []
        logs.append("\n残翼守门人倒下，天堂的大门轰然碎裂。")
        logs.append("你走进了最深处。这里没有光，没有暗，只有一片纯粹的空白。")
        logs.append("\n" + "="*15 + " 终末 " + "="*15)
        logs.append("一个没有形态的存在在此显现。神老死之后，世界开始遗忘自己。")
        logs.append('你不是在和一个敌人战斗，你是在和“结束”这个概念本身对峙。')
        return self.start_combat(["ZhongMoBenShen"], True, logs)

    # ================= 战斗系统 =================
    def start_combat(self, enemies: list, is_elite: bool, initial_logs=None) -> dict:
        self.phase = "COMBAT_PLAYER"
        monster_map = MONSTER_MAP_F1 if self.current_floor == 1 else MONSTER_MAP_F2 if self.current_floor == 2 else MONSTER_MAP_F3
        self.enemies = [monster_map[e]() for e in enemies]
        self.shield_bash_cooldown = 0; self.defend_cooldown = 0; self.is_defending = False; self.combat_round = 1
        
        self.player.first_attack_this_combat = True
        self.player.disabled_action = None
        self.player.last_attack_missed = False
        
        # 计算规则崩溃减益 (仅第三层生效)
        penalty = 0
        if self.current_floor >= 3:
            for e in self.enemies:
                if e.tier == 'boss': penalty = max(penalty, 2)
                elif e.tier == 'elite': penalty = max(penalty, random.choice([1, 2]))
                elif e.tier == 'normal': penalty = max(penalty, 1)
        self.player.rule_break_penalty = penalty
        
        logs = initial_logs or []
        if not any("Boss" in l for l in logs): 
            logs.append("\n" + "="*15 + " 战斗开始 " + "="*15)
        for e in self.enemies: logs.append(f"遭遇 【{e.name}】 HP: {e.current_hp}/{e.max_hp}")
        
        if penalty > 0:
            logs.append(f"\n⚠️ 【规则崩溃】生效！当前层级法则崩坏，你的所有判定掷骰 -{penalty}！")
        
        _, start_logs = self.player.trigger_event("on_combat_start", default_result=None)
        logs.extend(start_logs)
        
        # 如果是Boss战，触发进入Boss房效果
        is_boss = any(e.tier == 'boss' for e in self.enemies)
        if is_boss:
            _, boss_logs = self.player.trigger_event("on_boss_enter", default_result=None)
            logs.extend(boss_logs)
            
        return self._show_player_actions(logs)

    def _show_player_actions(self, initial_logs=None) -> dict:
        if not self.player.is_alive(): return self._do_game_over(initial_logs)
        if not any(e.is_alive() for e in self.enemies): return self._combat_victory(initial_logs)

        self.phase = "COMBAT_PLAYER"
        logs = initial_logs or []; logs.append("\n【你的回合】")
        actions = []
        
        # 处理技能封锁
        if self.player.disabled_action == 'attack':
            actions.append({"label": "⚔️ 强力攻击 (被遗忘)", "action_id": "disabled", "args": {}, "css": "combat-btn", "disabled": True})
        else:
            actions.append({"label": "⚔️ 强力攻击 (1d10+5)", "action_id": "show_target_selection", "args": {"next_action": "player_attack"}, "css": "combat-btn"})
            
        if self.player.disabled_action == 'shield_bash' or self.shield_bash_cooldown > 0:
            label = "🛡️ 护盾猛击 (被遗忘)" if self.player.disabled_action == 'shield_bash' else f"🛡️ 护盾猛击 (冷却: {self.shield_bash_cooldown}回合)"
            actions.append({"label": label, "action_id": "disabled", "args": {}, "css": "combat-btn", "disabled": True})
        else:
            actions.append({"label": "🛡️ 护盾猛击 (1d8+5 伤害+护盾)", "action_id": "show_target_selection", "args": {"next_action": "player_shield_bash"}, "css": "combat-btn"})
            
        if self.player.disabled_action == 'defend' or self.defend_cooldown > 0:
            label = "🏃 守卫姿态 (被遗忘)" if self.player.disabled_action == 'defend' else f"🏃 守卫姿态 (冷却: {self.defend_cooldown}回合)"
            actions.append({"label": label, "action_id": "disabled", "args": {}, "css": "combat-btn", "disabled": True})
        else:
            actions.append({"label": "🏃 守卫姿态 (AC+3, 下次攻击+2命中/+1伤害)", "action_id": "player_defend", "args": {}, "css": "combat-btn"})
            
        actions.append({"label": "📜 角色面板", "action_id": "show_character_screen", "args": {}, "css": "explore-btn"})
        return {"logs": logs, "actions": actions}

    def show_target_selection(self, next_action: str) -> dict:
        self.phase = "TARGETING"
        logs = ["\n🎯 请选择攻击目标："]
        actions = []
        alive_enemies = [e for e in self.enemies if e.is_alive()]
        for i, e in enumerate(alive_enemies):
            actions.append({"label": f"攻击 【{e.name}】(HP: {e.current_hp}/{e.max_hp})", "action_id": next_action, "args": {"target_idx": i}, "css": "target-btn"})
        actions.append({"label": "↩️ 取消", "action_id": "cancel_target_selection", "args": {}, "css": "explore-btn"})
        return {"logs": logs, "actions": actions}

    def cancel_target_selection(self) -> dict: return self._show_player_actions()

    def _consume_attack_buffs(self, base_damage: int) -> Tuple[int, List[str]]:
        logs = []
        final_base = base_damage
        if self.player.next_attack_bonus != 0:
            final_base += self.player.next_attack_bonus
            if self.player.next_attack_bonus > 0: logs.append(f"  ⚔️ 力量涌动，伤害 {self.player.next_attack_bonus:+d}")
            else: logs.append(f"  📉 力量被削弱，伤害 {self.player.next_attack_bonus:+d}")
            self.player.next_attack_bonus = 0
        if self.player.dream_attack_buff != 0:
            final_base += self.player.dream_attack_buff
            if self.player.dream_attack_buff > 0: logs.append(f"  💭【某人梦的回响】释放！伤害 +{self.player.dream_attack_buff}")
            self.player.dream_attack_buff = 0
        return final_base, logs

    def player_attack(self, target_idx: int) -> dict:
        target = [e for e in self.enemies if e.is_alive()][target_idx]
        
        # 消耗命中骰加成 (如迷途者的罗盘、守卫姿态)
        roll_bonus = self.player.next_attack_roll_bonus
        self.player.next_attack_roll_bonus = 0
        
        roll = self.player.roll_attack(7 + self.player.bonus_attack - self.player.rule_break_penalty + roll_bonus)
        logs = [f"你挥剑攻击 {target.name}，掷出 {roll} (DC{target.ac})"]
        if self.player.rule_break_penalty > 0: logs.append(f"  (受规则崩溃影响，判定 -{self.player.rule_break_penalty})")
        if roll_bonus > 0: logs.append(f"  🎯 蓄力完毕，命中骰 +{roll_bonus}")
        
        # on_attack_roll 钩子
        new_roll, roll_logs = self.player.trigger_event("on_attack_roll", roll, default_result=roll)
        if new_roll != roll:
            roll = new_roll
            logs.extend(roll_logs)
        
        hit = roll >= target.ac
        forced_hit = False
        damage_mult = 1.0
        
        if not hit:
            forced_result, miss_logs = self.player.trigger_event("on_attack_miss", target, default_result=(False, 1.0))
            forced_hit, damage_mult = forced_result
            logs.extend(miss_logs)
            if forced_hit:
                hit = True
        
        self.player.last_attack_missed = not hit
        
        if hit:
            base_damage = d('1d10') + 5
            final_dmg, hit_logs = self.player.trigger_event("on_attack_hit", target, base_damage, default_result=base_damage)
            logs.extend(hit_logs)
            if not self.player.is_alive(): return self._do_game_over(logs)
            final_dmg, buff_logs = self._consume_attack_buffs(final_dmg)
            logs.extend(buff_logs)
            if forced_hit:
                final_dmg = max(1, final_dmg // 2)
                logs.append(f"  ⬜ 力量被稀释，伤害减半至 {final_dmg} 点。")
            logs.append(f"  ✔ 命中！造成 {final_dmg} 点伤害。")
            self.player.first_attack_this_combat = False
            target_logs = target.take_damage(final_dmg)[1]; logs.extend(target_logs)
            if not target.is_alive() and isinstance(target, ExplodingLostSoul):
                explode_dmg = random.randint(3, 5)
                logs.append(f"  💥 {target.name} 死亡时发生自爆！")
                revived, exp_logs = self.player.take_damage(explode_dmg)
                logs.extend(exp_logs)
                if not self.player.is_alive(): return self._do_game_over(logs)
        else: 
            logs.append("  ✖ 攻击落空！")
            self.player.first_attack_this_combat = False
            if self.player.next_attack_bonus != 0 or self.player.dream_attack_buff != 0:
                logs.append("  ⚠️ 蓄积的力量随着落空而消散。")
                self.player.next_attack_bonus = 0
                self.player.dream_attack_buff = 0
        return self._schedule_enemy_turn(logs)

    def player_shield_bash(self, target_idx: int) -> dict:
        if self.shield_bash_cooldown > 0 or self.player.disabled_action == 'shield_bash': return self._show_player_actions(["护盾猛击不可用！"])
        target = [e for e in self.enemies if e.is_alive()][target_idx]
        
        # 消耗命中骰加成
        roll_bonus = self.player.next_attack_roll_bonus
        self.player.next_attack_roll_bonus = 0
        
        roll = self.player.roll_attack(7 + self.player.bonus_attack - self.player.rule_break_penalty + roll_bonus)
        logs = [f"你举盾撞向 {target.name}，掷出 {roll} (DC{target.ac})"]
        if self.player.rule_break_penalty > 0: logs.append(f"  (受规则崩溃影响，判定 -{self.player.rule_break_penalty})")
        if roll_bonus > 0: logs.append(f"  🎯 蓄力完毕，命中骰 +{roll_bonus}")
        
        # on_attack_roll 钩子
        new_roll, roll_logs = self.player.trigger_event("on_attack_roll", roll, default_result=roll)
        if new_roll != roll:
            roll = new_roll
            logs.extend(roll_logs)
        
        hit = roll >= target.ac
        forced_hit = False
        damage_mult = 1.0
        
        if not hit:
            forced_result, miss_logs = self.player.trigger_event("on_attack_miss", target, default_result=(False, 1.0))
            forced_hit, damage_mult = forced_result
            logs.extend(miss_logs)
            if forced_hit:
                hit = True
        
        self.player.last_attack_missed = not hit
        
        if hit:
            base_damage = d('1d8') + 5
            final_dmg, hit_logs = self.player.trigger_event("on_attack_hit", target, base_damage, default_result=base_damage)
            logs.extend(hit_logs)
            if not self.player.is_alive(): return self._do_game_over(logs)
            final_dmg, buff_logs = self._consume_attack_buffs(final_dmg)
            logs.extend(buff_logs)
            if forced_hit:
                final_dmg = max(1, final_dmg // 2)
                logs.append(f"  ⬜ 力量被稀释，伤害减半至 {final_dmg} 点。")
            logs.append(f"  ✔ 命中！造成 {final_dmg} 点伤害。")
            self.player.first_attack_this_combat = False
            target_logs = target.take_damage(final_dmg)[1]; logs.extend(target_logs)
            if not target.is_alive() and isinstance(target, ExplodingLostSoul):
                explode_dmg = random.randint(3, 5)
                logs.append(f"  💥 {target.name} 死亡时发生自爆！")
                revived, exp_logs = self.player.take_damage(explode_dmg)
                logs.extend(exp_logs)
                if not self.player.is_alive(): return self._do_game_over(logs)
        else: 
            logs.append("  ✖ 攻击落空！")
            self.player.first_attack_this_combat = False
            if self.player.next_attack_bonus != 0 or self.player.dream_attack_buff != 0:
                logs.append("  ⚠️ 蓄积的力量随着落空而消散。")
                self.player.next_attack_bonus = 0
                self.player.dream_attack_buff = 0
        shield_amount = d('1d10') + 5 + self.player.bonus_shield
        self.player.temp_hp += shield_amount
        logs.append(f"  🛡️ 获得了 {shield_amount} 点护盾！"); self.shield_bash_cooldown = 3
        return self._schedule_enemy_turn(logs)

    def player_defend(self) -> dict:
        if self.player.disabled_action == 'defend' or self.defend_cooldown > 0: return self._show_player_actions(["守卫姿态不可用！"])
        self.is_defending = True; self.player.ac += 3
        self.player.last_attack_missed = False
        self.player.next_attack_roll_bonus += 2
        self.player.next_attack_bonus += 1
        self.defend_cooldown = 2  # 下回合不可用，下下回合恢复
        return self._schedule_enemy_turn(["你摆出守卫姿态！AC+3，并寻找反击机会（下次攻击命中+2，伤害+1）。"])

    def _schedule_enemy_turn(self, initial_logs=None) -> dict:
        self.phase = "COMBAT_ENEMY"
        # A lock applied during the previous enemy turn lasts until the player
        # commits one action.  Clear it here, after that action has resolved.
        self.player.disabled_action = None
        logs = initial_logs or []; logs.append("\n【敌人回合】")
        self.pending_enemy_attacks = [e for e in self.enemies if e.is_alive()]
        return {"logs": logs, "timer": 0.5, "next_action": "execute_next_enemy_attack", "actions": []}

    def execute_next_enemy_attack(self) -> dict:
        if not self.pending_enemy_attacks or not self.player.is_alive(): return self._end_enemy_turn()

        enemy = self.pending_enemy_attacks.pop(0)
        logs = []

        if enemy.tier == 'boss':
            summon, boss_logs = enemy.boss_phase(self.player, self.combat_round)
            logs.extend(boss_logs)
            if not self.player.is_alive(): return self._do_game_over(logs)
            if summon:
                if isinstance(enemy, CharonTheFerryman): new_mob = ExplodingLostSoul()
                elif isinstance(enemy, MemoryKeeper): new_mob = FracturedEcho()
                elif isinstance(enemy, ZhongMoBenShen): new_mob = KongBaiLieXi()
                else: new_mob = None
                if new_mob:
                    self.enemies.append(new_mob); self.pending_enemy_attacks.append(new_mob)
                    logs.append(f"  ★ 召唤了 1 名【{new_mob.name}】！")

        att = enemy.get_next_attack()
        if att.get('unblockable'):
            mem_dmg = att.get('memory_damage', 0)
            self.player.memory -= mem_dmg
            logs.append(f"  🧠 {enemy.name} 发动【{att['name']}】！你无法防御，记忆值 -{mem_dmg}！当前记忆: {self.player.memory}/{self.player.max_memory}")
            if self.player.memory <= 0: return self._do_memory_game_over(logs)
            return {"logs": logs, "timer": 0.5, "next_action": "execute_next_enemy_attack", "actions": []}

        nat_roll = random.randint(1, 20)
        penalty = getattr(enemy, 'next_attack_penalty', 0)
        e_roll = nat_roll + att['bonus'] - penalty
        if penalty > 0:
            logs.append(f"  (受击退/减速/恐惧影响，{enemy.name}攻击检定 -{penalty})")
            enemy.next_attack_penalty = 0

        e_dmg = d(att['damage'])
        logs.append(f"  ⚔️ {enemy.name} 发动【{att['name']}】！掷出 {e_roll}，造成 {e_dmg} 点伤害")

        (final_dmg, handled), def_logs = self.player.trigger_event("on_defend", e_roll, e_dmg, default_result=(e_dmg, False))
        logs.extend(def_logs)

        if handled:
            if final_dmg > 0:
                final_dmg, pre_logs = self.player.trigger_event("on_pre_take_damage", final_dmg, default_result=final_dmg)
                logs.extend(pre_logs)
                revived, dmg_logs = self.player.take_damage(final_dmg); logs.extend(dmg_logs)
            if final_dmg == 0:
                _, dodge_logs = self.player.trigger_event("on_dodge_success", default_result=None)
                logs.extend(dodge_logs)
            if not self.player.is_alive(): return self._do_game_over(logs)
            else: return {"logs": logs, "timer": 0.5, "next_action": "execute_next_enemy_attack", "actions": []}
        else:
            self.pending_defend_data = {"roll": e_roll, "dmg": e_dmg}
            return self._prompt_defense(logs)

    def _prompt_defense(self, initial_logs=None) -> dict:
        self.phase = "COMBAT_DEFEND"
        logs = initial_logs or []; logs.append("请选择应对方式：")
        actions = [
            {"label": "🛡️ 硬抗 (AC判定)", "action_id": "resolve_defend_tough", "args": {}, "css": "combat-btn"},
            {"label": "🏃 闪避 (敏捷豁免)", "action_id": "resolve_defend_dodge", "args": {}, "css": "combat-btn"},
            {"label": "⚔️ 招架 (力量检定)", "action_id": "resolve_defend_parry", "args": {}, "css": "combat-btn"}
        ]
        return {"logs": logs, "actions": actions}

    def resolve_defend_tough(self) -> dict:
        e_roll, e_dmg = self.pending_defend_data['roll'], self.pending_defend_data['dmg']
        diff = self.player.ac - e_roll; logs = []; actual_dmg = e_dmg
        if diff >= 5: actual_dmg = 0; logs.append("  🛡️ 完美格挡！免疫伤害。")
        elif diff >= 2: actual_dmg = max(1, e_dmg * 2 // 10); logs.append(f"  🛡️ 擦伤！受到20%伤害 ({actual_dmg}点)。")
        elif diff >= 0: actual_dmg = max(1, e_dmg * 3 // 10); logs.append(f"  🛡️ 硬抗！受到30%伤害 ({actual_dmg}点)。")
        else: logs.append(f"  💥 防御被击穿！受到全额伤害 ({actual_dmg}点)。")
        return self._apply_damage_and_continue(actual_dmg, logs)

    def resolve_defend_dodge(self) -> dict:
        e_roll, e_dmg = self.pending_defend_data['roll'], self.pending_defend_data['dmg']
        dex_save = random.randint(1, 20) + self.player.get_ability_mod('dexterity') - self.player.rule_break_penalty
        diff = dex_save - e_roll; logs = [f"  🏃 你尝试闪避！敏捷豁免掷出 {dex_save}"]
        if self.player.rule_break_penalty > 0: logs.append(f"  (受规则崩溃影响，判定 -{self.player.rule_break_penalty})")
        actual_dmg = e_dmg
        if diff >= 5: actual_dmg = 0; logs.append("  完美闪避！免疫伤害。")
        elif diff >= 2: actual_dmg = max(1, e_dmg * 2 // 10); logs.append(f"  轻巧闪避！受到20%伤害 ({actual_dmg}点)。")
        elif diff >= 0: actual_dmg = max(1, e_dmg * 5 // 10); logs.append(f"  勉强闪避！受到50%伤害 ({actual_dmg}点)。")
        else: logs.append(f"  闪避失败！受到全额伤害 ({actual_dmg}点)。")
        return self._apply_damage_and_continue(actual_dmg, logs)

    def resolve_defend_parry(self) -> dict:
        e_roll, e_dmg = self.pending_defend_data['roll'], self.pending_defend_data['dmg']
        strength_mod = ability_modifier(self.player.abilities['strength'])
        str_check = random.randint(1, 20) + strength_mod - self.player.rule_break_penalty
        logs = [f"  ⚔️ 你举起武器招架！力量检定掷出 {str_check}"]
        if self.player.rule_break_penalty > 0: logs.append(f"  (受规则崩溃影响，判定 -{self.player.rule_break_penalty})")
        actual_dmg = e_dmg
        if str_check >= e_roll:
            parry_reduction = d('1d8') + strength_mod
            actual_dmg = max(0, e_dmg - parry_reduction)
            logs.append(f"  招架成功！抵消了 {parry_reduction} 点伤害，受到 {actual_dmg} 点伤害。")
        else: logs.append(f"  招架失败！受到全额伤害 ({actual_dmg}点)。")
        return self._apply_damage_and_continue(actual_dmg, logs)

    def _apply_damage_and_continue(self, dmg: int, initial_logs=None) -> dict:
        logs = initial_logs or []
        if dmg > 0:
            final_dmg, pre_logs = self.player.trigger_event("on_pre_take_damage", dmg, default_result=dmg)
            logs.extend(pre_logs)
            revived, dmg_logs = self.player.take_damage(final_dmg); logs.extend(dmg_logs)
        if not self.player.is_alive(): return self._do_game_over(logs)
        else: return {"logs": logs, "timer": 0.5, "next_action": "execute_next_enemy_attack", "actions": []}

    def _end_enemy_turn(self) -> dict:
        if self.is_defending: self.player.ac -= 3; self.is_defending = False
        if self.shield_bash_cooldown > 0: self.shield_bash_cooldown -= 1
        if self.defend_cooldown > 0: self.defend_cooldown -= 1
        self.combat_round += 1
        
        logs = []
        # 处理崩解炽天使的AC下降 (第4回合开始时生效)
        if self.combat_round >= 4:
            for e in self.enemies:
                if isinstance(e, BengJieChiTianShi) and e.ac == 17:
                    e.ac = 15
                    logs.append(f"  💔 {e.name} 的神圣光环消散，护甲等级降至 15！")
                    
        if logs:
            return self._show_player_actions(logs)
        return self._show_player_actions()

    def _combat_victory(self, initial_logs=None) -> dict:
        logs = initial_logs or []
        logs.append("\n" + "="*15 + " 战斗胜利 " + "="*15)
        if self.player.temp_hp > 0: self.player.temp_hp = 0; logs.append("战斗结束，你的护盾消散了。")
        
        # on_combat_end 钩子
        _, end_logs = self.player.trigger_event("on_combat_end", default_result=None)
        logs.extend(end_logs)
        if not self.player.is_alive(): return self._do_game_over(logs)
        
        is_boss_fight = any(e.tier == 'boss' for e in self.enemies)
        is_elite_fight = is_boss_fight or any(e.tier == 'elite' for e in self.enemies)
        
        if not is_elite_fight:
            heal_amount = max(1, self.player.max_hp // 5)
            self.player.current_hp = min(self.player.max_hp, self.player.current_hp + heal_amount)
            logs.append(f"你稍作喘息，恢复了 {heal_amount} 点HP。")
        else:
            logs.append("激烈的战斗让你无暇喘息，未能恢复生命。")

        enemy_type = "elite" if is_elite_fight else "normal"
        owned_names = [r.name for r in self.player.relics]
        relic, relic_logs = roll_relic(enemy_type, owned_names)
        logs.extend(relic_logs)
        if relic and not any(r.name == relic.name for r in self.player.relics):
            self.player.relics.append(relic); logs.append("📌 遗物已装备！"); logs.extend(relic.on_acquire(self.player))

        if is_boss_fight: return self._game_victory(logs)
        else: return self._post_combat_proceed(logs)

    def _game_victory(self, initial_logs=None) -> dict:
        self.phase = "GAME_OVER"
        logs = initial_logs or []
        if self.current_floor == 1:
            logs.append("\n🎉 胜利！你击败了卡戎，通过了第一层地狱！")
            return self._show_level_up_options(logs)
        elif self.current_floor == 2:
            logs.append("\n🎉 胜利！你击败了守忆者，守住了自我！")
            return self._show_level_up_options(logs)
        elif self.current_floor == 3:
            logs.append("\n🎉 胜利！你击败了残翼守门人，天堂的大门已为你敞开！")
            return self.enter_floor_4(logs)
        elif self.current_floor == 4:
            logs.append("\n🎉 胜利！你击败了终末本身！")
            logs.append("空白停止了扩张，崩坏的世界在你身后缓缓重组。")
            logs.append("你完成了不可能的旅程，跨越了地狱的所有层级。")
            actions = [{"label": "🔄 重新开始", "action_id": "restart_game", "args": {}, "css": "explore-btn"}]
            return {"logs": logs, "actions": actions}

    def _do_game_over(self, initial_logs=None) -> dict:
        self.phase = "GAME_OVER"
        logs = initial_logs or []; logs.append("\n💀 你倒在了探索途中...")
        actions = [{"label": "🔄 重新开始", "action_id": "restart_game", "args": {}, "css": "explore-btn"}]
        return {"logs": logs, "actions": actions}

    def show_character_screen(self) -> dict:
        return {"action_type": "show_character_screen", "logs": [], "actions": []}

    def restart_game(self) -> dict:
        result = self.start_new_game()
        result["clear_log"] = True
        return result
