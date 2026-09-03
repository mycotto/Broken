# monsters.py
import random
from core import Monster, Combatant, d
from typing import List, Tuple, Dict

# ================= 第一层 =================
class LostSoul(Monster):
    def __init__(self): super().__init__("迷途古魂", 10, 6, {'strength': 8, 'dexterity': 10, 'constitution': 11, 'intelligence': 10, 'wisdom': 12, 'charisma': 9}, 2, [{'name': '锈蚀短剑', 'bonus': 2, 'damage': '1d4'}])

class ExplodingLostSoul(Monster):
    def __init__(self): super().__init__("冥河怨魂", 10, 6, {'strength': 8, 'dexterity': 10, 'constitution': 11, 'intelligence': 10, 'wisdom': 12, 'charisma': 9}, 2, [{'name': '锈蚀短剑', 'bonus': 2, 'damage': '1d4'}])

class WindborneLust(Monster):
    def __init__(self): super().__init__("风卷欲魂", 13, 9, {'strength': 6, 'dexterity': 16, 'constitution': 10, 'intelligence': 12, 'wisdom': 14, 'charisma': 15}, 2, [{'name': '虚影抓击', 'bonus': 4, 'damage': '1d6+2'}])

class CerberusPup(Monster):
    def __init__(self): super().__init__("刻耳柏洛斯幼犬", 13, 28, {'strength': 15, 'dexterity': 16, 'constitution': 14, 'intelligence': 6, 'wisdom': 12, 'charisma': 8}, 3, [{'name': '双头撕咬', 'bonus': 5, 'damage': '2d6+3'}], tier="elite")

class MireHungry(Monster):
    def __init__(self): super().__init__("泥沼饿魂", 9, 35, {'strength': 14, 'dexterity': 6, 'constitution': 16, 'intelligence': 8, 'wisdom': 10, 'charisma': 7}, 2, [{'name': '腐臂拍击', 'bonus': 3, 'damage': '1d8+3'}], tier="elite")

class CharonTheFerryman(Monster):
    def __init__(self): super().__init__("冥河摆渡人・卡戎", 14, 40, {'strength': 18, 'dexterity': 14, 'constitution': 18, 'intelligence': 12, 'wisdom': 16, 'charisma': 10}, 4, [{'name': '冥河船篙劈砍', 'bonus': 7, 'damage': '1d10+4'}], tier="boss")
    def boss_phase(self, target: Combatant, round_num: int) -> Tuple[bool, List[str]]:
        logs = []; summon = False
        if round_num > 0 and round_num % 3 == 0:
            logs.append(f"  ★ {self.name} 挥动船篙，冥河中爬出亡魂！"); summon = True
        return summon, logs

# ================= 第二层 =================
class SolidifiedWounded(Monster):
    def __init__(self): super().__init__("凝固伤者", 10, 38, {'strength': 14, 'dexterity': 8, 'constitution': 16, 'intelligence': 4, 'wisdom': 10, 'charisma': 6}, 2, [{'name': '求死之击', 'bonus': 3, 'damage': '1d8+2'}])

class FracturedEcho(Monster):
    def __init__(self): super().__init__("断裂回响", 15, 32, {'strength': 10, 'dexterity': 20, 'constitution': 12, 'intelligence': 12, 'wisdom': 14, 'charisma': 12}, 2, [{'name': '时空撕裂', 'bonus': 6, 'damage': '1d8+3'}])

class DoomsdayPreacher(Monster):
    def __init__(self): super().__init__("终末传教士", 15, 42, {'strength': 14, 'dexterity': 12, 'constitution': 14, 'intelligence': 16, 'wisdom': 14, 'charisma': 16}, 3, [{'name': '末日宣判(近)', 'bonus': 5, 'damage': '1d8+3'}, {'name': '遗忘经文(远)', 'bonus': 5, 'damage': '1d6+2'}], tier="elite")
    def get_next_attack(self) -> Dict: return random.choice(self.attacks)

class OblivionAggregate(Monster):
    def __init__(self): super().__init__("遗忘聚合体", 13, 36, {'strength': 12, 'dexterity': 18, 'constitution': 14, 'intelligence': 6, 'wisdom': 10, 'charisma': 8}, 3, [{'name': '记忆剥夺', 'bonus': 5, 'damage': '2d4+3'}], tier="elite")

class ErodedAfterimage(Monster):
    def __init__(self): super().__init__("蚀光残像", 14, 22, {'strength': 8, 'dexterity': 20, 'constitution': 8, 'intelligence': 10, 'wisdom': 12, 'charisma': 14}, 2, [{'name': '刺目之光', 'bonus': 6, 'damage': '1d10+2'}])

class HollowMessenger(Monster):
    def __init__(self): super().__init__("空壳信使", 12, 30, {'strength': 12, 'dexterity': 12, 'constitution': 14, 'intelligence': 8, 'wisdom': 10, 'charisma': 6}, 2, [{'name': '空洞投递', 'bonus': 4, 'damage': '1d6+1'}])

class MemoryKeeper(Monster):
    def __init__(self): super().__init__("守忆者", 16, 70, {'strength': 18, 'dexterity': 10, 'constitution': 20, 'intelligence': 18, 'wisdom': 16, 'charisma': 14}, 5, [{'name': '千名之压', 'bonus': 6, 'damage': '2d6+4'}, {'name': '吞忆之击', 'bonus': 6, 'damage': '1d10+4'}, {'name': '遗忘低语', 'bonus': 0, 'damage': '0', 'unblockable': True, 'memory_damage': 2}], tier="boss")
    def get_next_attack(self) -> Dict: return random.choice(self.attacks)
    def boss_phase(self, target: Combatant, round_num: int) -> Tuple[bool, List[str]]:
        logs = []; summon = False
        if round_num > 0 and round_num % 3 == 0:
            logs.append(f"  ★ {self.name} 身上的文字蠕动，断裂的回响再次降临！"); summon = True
        return summon, logs

# ================= 第三层：陨落天堂 =================
class NingGuShengGe(Monster):
    def __init__(self): super().__init__("凝固圣歌", 15, 20, {'strength': 8, 'dexterity': 14, 'constitution': 10, 'intelligence': 10, 'wisdom': 14, 'charisma': 12}, 2, [{'name': '诅咒声波', 'bonus': 5, 'damage': '1d6+2'}])

class TuiSeShengXiang(Monster):
    def __init__(self): super().__init__("褪色圣像", 11, 30, {'strength': 16, 'dexterity': 6, 'constitution': 16, 'intelligence': 4, 'wisdom': 8, 'charisma': 6}, 2, [{'name': '石拳砸击', 'bonus': 4, 'damage': '1d8+4'}])

class ShenZhiTaiXian(Monster):
    def __init__(self): super().__init__("神之苔藓", 10, 24, {'strength': 10, 'dexterity': 8, 'constitution': 14, 'intelligence': 2, 'wisdom': 10, 'charisma': 4}, 2, [{'name': '蚀光孢子', 'bonus': 3, 'damage': '1d6+1'}])

class KongBaiLieXi(Monster):
    def __init__(self): super().__init__("空白裂隙", 16, 18, {'strength': 8, 'dexterity': 16, 'constitution': 10, 'intelligence': 12, 'wisdom': 14, 'charisma': 8}, 2, [{'name': '遗忘触碰', 'bonus': 5, 'damage': '1d4+2'}])

class BengJieChiTianShi(Monster):
    def __init__(self): super().__init__("崩解炽天使", 17, 56, {'strength': 16, 'dexterity': 14, 'constitution': 14, 'intelligence': 12, 'wisdom': 16, 'charisma': 14}, 3, [{'name': '残翼斩击', 'bonus': 6, 'damage': '1d10+4'}, {'name': '圣光余烬', 'bonus': 6, 'damage': '1d8+2'}], tier="elite")
    def get_next_attack(self) -> Dict: return random.choice(self.attacks)

class ShenZhiHuiXiang(Monster):
    def __init__(self): super().__init__("神之回响", 15, 50, {'strength': 8, 'dexterity': 12, 'constitution': 12, 'intelligence': 16, 'wisdom': 18, 'charisma': 14}, 3, [{'name': '临终低语', 'bonus': 7, 'damage': '2d6+3'}], tier="elite")

class CanYiShouMenRen(Monster):
    def __init__(self): super().__init__("残翼守门人", 17, 80, {'strength': 18, 'dexterity': 14, 'constitution': 18, 'intelligence': 10, 'wisdom': 16, 'charisma': 12}, 4, [{'name': '崩解圣剑', 'bonus': 8, 'damage': '2d8+5'}], tier="boss")
    def boss_phase(self, target: Combatant, round_num: int) -> Tuple[bool, List[str]]:
        logs = []
        if round_num > 0 and round_num % 3 == 0:
            logs.append(f"  ☀️ {self.name} 释放【天堂余晖】！神最后的圣光倾泻全场！")
            dmg = d('2d6')
            final_dmg = dmg
            trigger_event = getattr(target, "trigger_event", None)
            if trigger_event:
                final_dmg, damage_logs = trigger_event("on_pre_take_damage", dmg, default_result=dmg)
                logs.extend(damage_logs)
            _, dmg_logs = target.take_damage(final_dmg)
            logs.extend(dmg_logs)
            target.next_attack_roll_bonus -= 2
            logs.append("  🌟 圣光灼烧了你的双眼，下次攻击命中 -2！")
        return False, logs

class ZhongMoBenShen(Monster):
    def __init__(self): super().__init__("终末本身", 18, 130, {'strength': 10, 'dexterity': 10, 'constitution': 20, 'intelligence': 20, 'wisdom': 20, 'charisma': 10}, 5, [{'name': '空白吞噬', 'bonus': 9, 'damage': '2d10+4'}], tier="boss")
    def boss_phase(self, target: Combatant, round_num: int) -> Tuple[bool, List[str]]:
        logs = []; summon = False
        if round_num > 0 and round_num % 3 == 0:
            logs.append("  🌀 现实崩塌，【空白裂隙】从中分裂！"); summon = True
        if round_num > 0 and round_num % 4 == 0:
            action_name = random.choice(['attack', 'shield_bash', 'defend'])
            target.disabled_action = action_name
            logs.append(f"  🚫 【法则褪色】触发！你遗忘了如何使用【{action_name}】，下回合无法使用！")
        return summon, logs
