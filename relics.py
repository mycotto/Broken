# relics.py
import random
from typing import List, Tuple, Any, Dict, Optional

class Relic:
    def __init__(self, name, rarity, effect_desc, lore):
        self.name = name
        self.rarity = rarity
        self.effect_desc = effect_desc
        self.lore = lore

    def on_acquire(self, player) -> List[str]: return []
    def on_attack_hit(self, player, target, damage) -> Optional[Tuple[int, List[str]]]: return None
    def on_attack_roll(self, player, roll) -> Optional[Tuple[int, List[str]]]: return None
    def on_attack_miss(self, player, target) -> Optional[Tuple[Tuple[bool, float], List[str]]]: return None
    def on_defend(self, player, enemy_attack_roll, enemy_damage) -> Optional[Tuple[Tuple[int, bool], List[str]]]: return None
    def on_dodge_success(self, player) -> Optional[Tuple[None, List[str]]]: return None
    def on_boss_enter(self, player) -> Optional[Tuple[None, List[str]]]: return None
    def on_room_enter(self, player) -> Optional[Tuple[None, List[str]]]: return None
    def on_pre_death(self, player) -> Optional[Tuple[bool, List[str]]]: return None
    def on_combat_start(self, player) -> Optional[Tuple[None, List[str]]]: return None
    def on_combat_end(self, player) -> Optional[Tuple[None, List[str]]]: return None
    def on_pre_take_damage(self, player, damage) -> Optional[Tuple[int, List[str]]]: return None

# ================= 第一层遗物 =================
class RelicHouPanSuoCanBei(Relic):
    def __init__(self): super().__init__("侯判所残碑", "common", "最大生命 +8", "灵薄狱无名墓碑的碎块…")
    def on_acquire(self, player):
        player.max_hp += 8; player.current_hp += 8
        return [f"最大生命提升！当前HP: {player.current_hp}/{player.max_hp}"]

class RelicMingHeShiSha(Relic):
    def __init__(self): super().__init__("冥河湿沙", "common", "护甲等级 +1", "卡戎渡口的河沙…")
    def on_acquire(self, player):
        player.ac += 1
        return [f"护甲等级提升！当前AC: {player.ac}"]

class RelicMiTuHunHuo(Relic):
    def __init__(self): super().__init__("迷途魂火", "common", "攻击伤害 +1", "灵薄狱古魂散出的微光…")
    def on_attack_hit(self, player, target, damage):
        return damage + 1, [" 🔥【迷途魂火】发动，伤害+1！"]

class RelicLingBoYuHuiJin(Relic):
    def __init__(self): super().__init__("灵薄狱灰烬", "common", "最大生命 +5", "灵薄狱地面的灰烬，带着死寂的温度…")
    def on_acquire(self, player):
        player.max_hp += 5; player.current_hp += 5
        return [f"最大生命提升！当前HP: {player.current_hp}/{player.max_hp}"]

class RelicKaRongChuanJiang(Relic):
    def __init__(self): super().__init__("卡戎船桨碎片", "rare", "攻击 25% 概率击退", "从冥河摆渡人的船桨上崩落的木片…")
    def on_attack_hit(self, player, target, damage):
        if random.random() < 0.25:
            target.next_attack_penalty = getattr(target, 'next_attack_penalty', 0) + 2
            return damage, [" 🚣【卡戎船桨碎片】发动，击退敌人！"]
        return None

class RelicHeiFengXu(Relic):
    def __init__(self): super().__init__("黑风絮", "rare", "被攻击 15% 概率完全闪避", "色欲圈黑风中的一缕…")
    def on_defend(self, player, enemy_attack_roll, enemy_damage):
        if random.random() < 0.15:
            return (0, True), [" 🌪️【黑风絮】触发！一阵黑风卷过，你完全闪避了本次攻击！"]
        return None

class ReliNiZhaoQuanChi(Relic):
    def __init__(self): super().__init__("泥沼犬齿", "rare", "攻击使敌人减速", "刻耳柏洛斯幼犬的牙齿…")
    def on_attack_hit(self, player, target, damage):
        target.next_attack_penalty = getattr(target, 'next_attack_penalty', 0) + 2
        return damage, [" 🦷【泥沼犬齿】发动，减速敌人！"]

class RelicShenPanGuanZhiYa(Relic):
    def __init__(self): super().__init__("审判官之压", "rare", "战斗开始获得5点护盾", "米诺斯审判庭的威压残留…")
    def on_combat_start(self, player):
        shield = 5 + player.bonus_shield
        player.temp_hp += shield
        return None, [f" ⚖️【审判官之压】发动，获得 {shield} 点护盾！"]

class RelicKongBuZhiMian(Relic):
    def __init__(self): super().__init__("恐怖之面", "rare", "攻击 20% 概率恐惧敌人", "美杜莎之怨凝成的面具…")
    def on_attack_hit(self, player, target, damage):
        if random.random() < 0.20:
            target.next_attack_penalty = getattr(target, 'next_attack_penalty', 0) + 3
            return damage, [" 👻【恐怖之面】发动，敌人陷入恐惧！"]
        return None

class RelicYinYaoShiSuiPian(Relic):
    def __init__(self): super().__init__("银钥匙碎片", "epic", "每进入新房间，恢复 3 点生命", "净界之门银钥匙的一角…")
    def on_room_enter(self, player):
        heal = 3
        player.current_hp = min(player.max_hp, player.current_hp + heal)
        return None, [f"【银钥匙碎片】闪烁微光，你恢复了 {heal} 点生命。"]

class RelicDuHunFu(Relic):
    def __init__(self): 
        super().__init__("渡魂符", "epic", "死亡后原地复活一次，生命回到30%", "卡戎不愿承认的凭证…")
        self.used = False
    def on_pre_death(self, player):
        if player.current_hp > 0: return None
        if not self.used:
            self.used = True
            player.current_hp = player.max_hp * 3 // 10
            return True, ["\n  ✨【渡魂符】触发！你从死亡边缘挣扎归来！", f"  ✨ 生命值恢复至 {player.current_hp}/{player.max_hp}\n"]
        return None

# ================= 第二层遗物 =================
class RelicNingGuZheMingPai(Relic):
    def __init__(self): super().__init__("凝固者的铭牌", "common", "被击中时减免2点伤害，下次攻击伤害-1", "一枚从凝固伤者胸口取下的锈蚀铭牌，上面刻着已无人记得的名字。不死诅咒让痛苦延迟，但从未消失。")
    def on_pre_take_damage(self, player, damage):
        if damage > 0:
            reduced_dmg = max(0, damage - 2)
            if reduced_dmg < damage:
                player.next_attack_bonus -= 1
                return reduced_dmg, [" 🛡️【凝固者的铭牌】发动，减免2点伤害！下次攻击伤害-1。"]
        return None

class RelicTuiSeYouPiao(Relic):
    def __init__(self): 
        super().__init__("褪色邮票", "common", "若生命未满，进房回5血(3次)", "一张半透明的邮票，上面的地址正在以肉眼可见的速度消失。信使的口袋越来越轻，直到什么都不剩。")
        self.uses = 3
    def on_room_enter(self, player):
        if self.uses > 0 and player.current_hp < player.max_hp:
            self.uses -= 1
            heal = 5
            player.current_hp = min(player.max_hp, player.current_hp + heal)
            logs = [f" ✉️【褪色邮票】发动，恢复了 {heal} 点生命。剩余次数: {self.uses}"]
            if self.uses == 0:
                player.relics.remove(self)
                logs.append(" ✉️【褪色邮票】已彻底褪色，从身上脱落。")
            return None, logs
        return None

class RelicZuoRiYingBi(Relic):
    def __init__(self): super().__init__("昨日硬币", "common", "伤害为奇数时+1", "一枚永远落在昨天的硬币，正面是今天，反面是昨天。时间在这里不是线性的，而是翻转的。")
    def on_attack_hit(self, player, target, damage):
        if damage % 2 != 0:
            return damage + 1, [" 🪙【昨日硬币】翻转！伤害为奇数，+1。"]
        return None

class RelicShiGuangCanPian(Relic):
    def __init__(self): super().__init__("蚀光残片", "rare", "攻击伤害+2或3，15%反噬1血", "一块散发着病态金光的碎片，从天堂坠落时溅出。它很美，但会灼伤持有者。")
    def on_attack_hit(self, player, target, damage):
        bonus = random.randint(2, 3)
        damage += bonus
        logs = [f" ✨【蚀光残片】发光！伤害+{bonus}。"]
        if random.random() < 0.15:
            final_dmg, damage_logs = player.trigger_event("on_pre_take_damage", 1, default_result=1)
            _, taken_logs = player.take_damage(final_dmg)
            logs.append(" 💥【蚀光残片】反噬！")
            logs.extend(damage_logs)
            logs.extend(taken_logs)
        return damage, logs

class RelicDuanLieMiaoZhen(Relic):
    def __init__(self):
        super().__init__("断裂秒针", "rare", "战斗首次攻击伤害+4", "一根从钟楼废墟中捡到的秒针，永远停在断裂的那一刻。时间被压缩在前两秒，然后永远断裂。")
        self.used = False
    def on_combat_start(self, player):
        self.used = False
        return None, []
    def on_attack_hit(self, player, target, damage):
        if not self.used:
            self.used = True
            return damage + 4, [" ⏱️【断裂秒针】跳跃！首次攻击伤害+4。"]
        return None

class RelicTuiSeMuQinDeKongYi(Relic):
    def __init__(self): super().__init__("褪色母亲的空衣", "rare", "低血量被击35%闪避，下次攻击-2", "一件颜色已被洗尽的婴儿襁褓，空无一物，却仍有温度。怀抱是温暖的，但会让你软弱。")
    def on_defend(self, player, enemy_attack_roll, enemy_damage):
        if player.current_hp < player.max_hp * 0.4 and random.random() < 0.35:
            player.next_attack_bonus -= 2
            return (0, True), [" 👗【褪色母亲的空衣】包裹！完全闪避，但下次攻击伤害-2。"]
        return None

class RelicShouYiZheKeMingShiBan(Relic):
    def __init__(self): 
        super().__init__("守忆者刻名石板", "epic", "首次濒死恢复5血5盾", "从守忆者身上剥落的铭板，上面的名字在你触摸时轻声低语。记住名字，就是记住力量。")
        self.used = False
    def on_pre_death(self, player):
        if player.current_hp > 0: return None
        if not self.used:
            self.used = True
            player.current_hp = 5
            player.temp_hp += 5
            return True, [" 🪨【守忆者刻名石板】低语！你记住了名字，从死亡边缘醒来！恢复5点生命，获得5点护盾。"]
        return None

class RelicMouRenMengDeHuiXiang(Relic):
    def __init__(self): super().__init__("某人梦的回响", "epic", "进房低血回4血，否则下次攻击+3", "一缕弥留之际逸散的梦境，像温暖的雾气缠绕在你手腕上。他不愿醒来，也不愿让你就此睡去。")
    def on_room_enter(self, player):
        if player.current_hp < player.max_hp / 2:
            heal = 4
            player.current_hp = min(player.max_hp, player.current_hp + heal)
            return None, [f" 💭【某人梦的回响】轻抚...恢复了 {heal} 点生命。"]
        else:
            player.dream_attack_buff += 3
            return None, [" 💭【某人梦的回响】蓄力！下次攻击伤害+3。"]

# ================= 第三层遗物 =================
class RelicRongHuaDeZhuLei(Relic):
    def __init__(self): super().__init__("融化的烛泪", "common", "每场战斗开始恢复3血，结束时失去1血", "神最后的祷告燃烧殆尽后留下的蜡泪。温暖是真实的，但蜡注定会凝固。")
    def on_combat_start(self, player):
        heal = 3
        player.current_hp = min(player.max_hp, player.current_hp + heal)
        return None, [f" 🕯️【融化的烛泪】温暖流淌...恢复了 {heal} 点生命。"]
    def on_combat_end(self, player):
        final_dmg, damage_logs = player.trigger_event("on_pre_take_damage", 1, default_result=1)
        _, taken_logs = player.take_damage(final_dmg)
        return None, [" 🕯️【融化的烛泪】凝固..."] + damage_logs + taken_logs

class RelicDaoFangShengGeDeCanYe(Relic):
    def __init__(self): super().__init__("倒放圣歌的残页", "common", "攻击命中20%概率使敌人下次攻击命中-1", "天堂圣歌倒放后形成的诅咒文本。音节顺序错了，节奏就全乱了。")
    def on_attack_hit(self, player, target, damage):
        if random.random() < 0.20:
            target.next_attack_penalty = getattr(target, 'next_attack_penalty', 0) + 1
            return damage, [" 🎵【倒放圣歌的残页】诅咒！敌人下次攻击命中-1。"]
        return None

class RelicDuanLieDeChaoShengZheNianZhu(Relic):
    def __init__(self): super().__init__("断裂的朝圣者念珠", "common", "进入战斗获得2点临时护盾", "前往天堂的朝圣者遗落的念珠，已经断线。朝圣者的执念比珍珠更沉重。")
    def on_combat_start(self, player):
        shield = 2 + player.bonus_shield
        player.temp_hp += shield
        return None, [f" 📿【断裂的朝圣者念珠】执念护体...获得 {shield} 点护盾。"]

class RelicShenZhiTaiXianDeBaoZi(Relic):
    def __init__(self): super().__init__("神之苔藓的孢子", "common", "攻击命中+1伤害，战后10%概率失去3-5血", "从神遗体上采集的发光孢子。它在保护你，也在等待分解你的时机。")
    def on_attack_hit(self, player, target, damage):
        return damage + 1, [" 🍄【神之苔藓的孢子】附着！伤害+1。"]
    def on_combat_end(self, player):
        if random.random() < 0.10:
            dmg = random.randint(3, 5)
            final_dmg, damage_logs = player.trigger_event("on_pre_take_damage", dmg, default_result=dmg)
            _, taken_logs = player.take_damage(final_dmg)
            return None, [f" 🍄【神之苔藓的孢子】分解！"] + damage_logs + taken_logs
        return None

class RelicZuoRiCanXiangDeZhunDu(Relic):
    def __init__(self): super().__init__("昨日残响的准度", "rare", "若上一轮攻击未命中，本轮攻击骰+2", "断裂的时间线上，上一秒的箭矢还没落地，这一秒的箭矢已经学会了它的角度。")
    def on_attack_roll(self, player, roll):
        if player.last_attack_missed:
            return roll + 2, [" 🔄【昨日残响的准度】修正！过去的失误修正了现在的轨迹，攻击骰+2。"]
        return None

class RelicTuiSeDeYuYanShuYe(Relic):
    def __init__(self):
        super().__init__("褪色的预言书页", "rare", "每场战斗首次攻击判定+4", "一页从神之图书馆脱落的预言，上面的墨迹正在褪色，但第一个字还很清晰。")
        self.used = False
    def on_combat_start(self, player):
        self.used = False
        return None, []
    def on_attack_roll(self, player, roll):
        if not self.used:
            self.used = True
            return roll + 4, [" 📜【褪色的预言书页】展开！命运已被书写，首次攻击判定+4。"]
        return None

class RelicZhongMoDeBiRan(Relic):
    def __init__(self): super().__init__("终末的必然", "epic", "未命中时强行命中，但伤害减半", "当你靠近终末，'未命中'这个概念本身开始消失——但代价是，命中也变得不再真实。")
    def on_attack_miss(self, player, target):
        return (True, 0.5), [" ⬜【终末的必然】降临！未命中被强行修正为命中，但伤害减半。"]

# ================= 新增通用遗物 =================
class RelicMiTuZheDeLuoPan(Relic):
    def __init__(self): super().__init__("迷途者的罗盘", "common", "攻击伤害为偶数时，下一次攻击命中骰+1", "冥河雾中捡到的破损罗盘，指针永远偏转15度。它不会带你回家，但会让你到达某个地方。")
    def on_attack_hit(self, player, target, damage):
        if damage % 2 == 0:
            player.next_attack_roll_bonus += 1
            return damage, [" 🧭【迷途者的罗盘】偏转！伤害为偶数，下次攻击命中+1。"]
        return None

class RelicTianMingTou(Relic):
    def __init__(self): super().__init__("天命骰", "epic", "你的攻击骰结果固定 +1", "神死前最后掷出的骰子，数字永远比看起来大一点。")
    def on_attack_roll(self, player, roll):
        return roll + 1, [" 🎲【天命骰】显现！攻击骰+1。"]

class RelicFengJuanCanYe(Relic):
    def __init__(self): super().__init__("风卷残页", "rare", "闪避成功后，下次攻击伤害 +2", "色欲圈黑风中抢救下来的书页，上面记载着某种舞蹈的步法。")
    def on_dodge_success(self, player):
        player.next_attack_bonus += 2
        return None, [" 🌪️【风卷残页】舞步！闪避成功，下次攻击伤害+2。"]

class RelicShenZhiHuiJin(Relic):
    def __init__(self): 
        super().__init__("神之灰烬", "epic", "每场战斗限一次，生命值降至 0 时，恢复 8 点生命", "神遗体表面脱落的灰白色粉末，摸起来是温的。")
        self.used_this_combat = False
    def on_combat_start(self, player):
        self.used_this_combat = False
        return None, []
    def on_pre_death(self, player):
        if player.current_hp > 0: return None
        if not self.used_this_combat:
            self.used_this_combat = True
            player.current_hp = 8
            return True, [" 🌋【神之灰烬】余温！你从死亡边缘复苏，恢复 8 点生命。"]
        return None

class RelicMingHeChuanPiao(Relic):
    def __init__(self): super().__init__("冥河船票", "epic", "进入 Boss 房间时，恢复 10 点生命", "卡戎不承认的凭证，但船会为你多等一程。")
    def on_boss_enter(self, player):
        heal = 10
        player.current_hp = min(player.max_hp, player.current_hp + heal)
        return None, [f" 🎟️【冥河船票】生效！恢复了 {heal} 点生命。"]

class RelicShenPanTingDeMoShui(Relic):
    def __init__(self): super().__init__("审判庭的墨水", "common", "对精英敌人造成的伤害 +1", "米诺斯审判官用来书写判决的墨水，对“重要人物”格外刺眼。")
    def on_attack_hit(self, player, target, damage):
        if getattr(target, 'tier', 'normal') == 'elite':
            return damage + 1, [" 🖋️【审判庭的墨水】刺目！对精英伤害+1。"]
        return None

ALL_RELICS = {
    "侯判所残碑": RelicHouPanSuoCanBei, "冥河湿沙": RelicMingHeShiSha, "迷途魂火": RelicMiTuHunHuo,
    "灵薄狱灰烬": RelicLingBoYuHuiJin, "卡戎船桨碎片": RelicKaRongChuanJiang, "黑风絮": RelicHeiFengXu, 
    "泥沼犬齿": ReliNiZhaoQuanChi, "审判官之压": RelicShenPanGuanZhiYa, "恐怖之面": RelicKongBuZhiMian,
    "银钥匙碎片": RelicYinYaoShiSuiPian, "渡魂符": RelicDuHunFu,
    "凝固者的铭牌": RelicNingGuZheMingPai, "褪色邮票": RelicTuiSeYouPiao, "昨日硬币": RelicZuoRiYingBi,
    "蚀光残片": RelicShiGuangCanPian, "断裂秒针": RelicDuanLieMiaoZhen, "褪色母亲的空衣": RelicTuiSeMuQinDeKongYi,
    "守忆者刻名石板": RelicShouYiZheKeMingShiBan, "某人梦的回响": RelicMouRenMengDeHuiXiang,
    "融化的烛泪": RelicRongHuaDeZhuLei, "倒放圣歌的残页": RelicDaoFangShengGeDeCanYe,
    "断裂的朝圣者念珠": RelicDuanLieDeChaoShengZheNianZhu, "神之苔藓的孢子": RelicShenZhiTaiXianDeBaoZi,
    "昨日残响的准度": RelicZuoRiCanXiangDeZhunDu, "褪色的预言书页": RelicTuiSeDeYuYanShuYe,
    "终末的必然": RelicZhongMoDeBiRan,
    "迷途者的罗盘": RelicMiTuZheDeLuoPan, "天命骰": RelicTianMingTou, "风卷残页": RelicFengJuanCanYe,
    "神之灰烬": RelicShenZhiHuiJin, "冥河船票": RelicMingHeChuanPiao, "审判庭的墨水": RelicShenPanTingDeMoShui
}

def roll_relic(enemy_type="normal", owned_relic_names=None) -> Tuple[Any, List[str]]:
    if owned_relic_names is None: owned_relic_names = []
    logs = []
    chance = 0.30 if enemy_type == "normal" else 0.80
    if enemy_type == "treasure": chance = 1.0
    if random.random() > chance: return None, ["未发现任何遗物。"]

    roll = random.random()
    if enemy_type == "elite":
        rarity = "epic" if roll < 0.15 else "rare" if roll < 0.60 else "common"
    else:
        rarity = "epic" if roll < 0.05 else "rare" if roll < 0.20 else "common"

    available = [cls for name, cls in ALL_RELICS.items() if cls().rarity == rarity and name not in owned_relic_names]
    if not available: available = [cls for name, cls in ALL_RELICS.items() if name not in owned_relic_names]
    if not available: return None, ["你已经拥有了所有遗物。"]

    relic = random.choice(available)()
    logs.append(f"✨ 发现遗物！【{relic.name}】")
    logs.append(f"“{relic.lore}”")
    logs.append(f"效果：{relic.effect_desc}")
    return relic, logs
