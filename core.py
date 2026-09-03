# core.py
import random
from typing import Dict, List, Tuple, Optional, Any

ABILITIES = ['strength', 'dexterity', 'constitution', 'intelligence', 'wisdom', 'charisma']
SKILLS = {
    'athletics': 'strength', 'acrobatics': 'dexterity', 'sleight_of_hand': 'dexterity', 'stealth': 'dexterity',
    'arcana': 'intelligence', 'history': 'intelligence', 'investigation': 'intelligence', 'nature': 'intelligence', 'religion': 'intelligence',
    'animal_handling': 'wisdom', 'insight': 'wisdom', 'medicine': 'wisdom', 'perception': 'wisdom', 'survival': 'wisdom',
    'deception': 'charisma', 'intimidation': 'charisma', 'performance': 'charisma', 'persuasion': 'charisma'
}

def ability_modifier(score: int) -> int:
    return (score - 10) // 2

def d(dice: str) -> int:
    if 'd' not in dice: return int(dice)
    mod = 0
    if '+' in dice:
        dice_part, mod_part = dice.split('+')
        mod = int(mod_part)
    elif '-' in dice:
        dice_part, mod_part = dice.split('-')
        mod = -int(mod_part)
    else:
        dice_part = dice
    num_str, die_str = dice_part.split('d')
    return sum(random.randint(1, int(die_str)) for _ in range(int(num_str))) + mod

class Combatant:
    def __init__(self, name: str, ac: int, max_hp: int, abilities: Dict[str, int], prof_bonus: int):
        self.name = name
        self.ac = ac
        self.max_hp = max_hp
        self.current_hp = max_hp
        self.temp_hp = 0
        self.relics = []
        self.abilities = abilities
        self.prof_bonus = prof_bonus
        self.skills: Dict[str, bool] = {skill: False for skill in SKILLS}
        self.saves: Dict[str, bool] = {ability: False for ability in ABILITIES}

    def get_ability_mod(self, ability: str) -> int:
        base = ability_modifier(self.abilities[ability])
        return base + (self.prof_bonus if self.saves[ability] else 0)

    def roll_attack(self, bonus: int = 0) -> int:
        return random.randint(1, 20) + bonus

    def take_damage(self, damage: int) -> Tuple[bool, List[str]]:
        logs = []
        damage_to_hp = damage
        
        if self.temp_hp > 0 and damage > 0:
            if self.temp_hp >= damage:
                self.temp_hp -= damage
                damage_to_hp = 0
                logs.append(f"  🛡️ 护盾吸收了全部 {damage} 点伤害！")
            else:
                damage_to_hp -= self.temp_hp
                logs.append(f"  🛡️ 护盾吸收了 {self.temp_hp} 点伤害，剩余 {damage - self.temp_hp} 点穿透！")
                self.temp_hp = 0
        
        if damage_to_hp > 0:
            self.current_hp = max(0, self.current_hp - damage_to_hp)
            logs.append(f"  ➥ {self.name} 受到 {damage_to_hp} 点伤害，剩余生命值 {self.current_hp}/{self.max_hp}")
        else:
            if not logs:
                logs.append(f"  ➥ {self.name} 毫发无伤！")
        
        return False, logs

    def is_alive(self) -> bool:
        return self.current_hp > 0

class Monster(Combatant):
    def __init__(self, name: str, ac: int, max_hp: int, abilities: Dict[str, int], prof_bonus: int = 2, attacks: List[Dict] = None, tier: str = "normal"):
        super().__init__(name, ac, max_hp, abilities, prof_bonus)
        self.attacks = attacks or []
        self.next_attack_penalty = 0
        self.tier = tier

    def get_next_attack(self) -> Dict:
        return self.attacks[0]

class PlayerCharacter(Combatant):
    def __init__(self, name: str, char_class: str, level: int, abilities: Dict[str, int]):
        ac = 10 + ability_modifier(abilities['dexterity'])
        hit_dice = {'fighter': 10, 'wizard': 6, 'cleric': 8, 'rogue': 8}.get(char_class.lower(), 8)
        hp_per_level = hit_dice // 2 + 1 + ability_modifier(abilities['constitution'])
        max_hp = hit_dice + (level - 1) * hp_per_level
        prof_bonus = (level + 7) // 4

        super().__init__(name, max(16, ac), max_hp, abilities, prof_bonus)
        self.char_class = char_class
        self.level = level
        self.memory = 10
        self.max_memory = 20
        
        self.bonus_attack = 0
        self.bonus_shield = 0
        self.bonus_hp = 0
        
        self.next_attack_bonus = 0
        self.next_attack_roll_bonus = 0  # 用于迷途者的罗盘
        self.first_attack_this_combat = True
        self.dream_attack_buff = 0
        self.rule_break_penalty = 0
        self.disabled_action = None
        self.last_attack_missed = False
        
        if char_class.lower() == 'fighter':
            self.skills['athletics'] = True
            self.skills['perception'] = True
            self.saves['strength'] = True
            self.saves['constitution'] = True

    def trigger_event(self, event_name, *args, **kwargs) -> Tuple[Any, List[str]]:
        default_result = kwargs.get('default_result')
        all_logs = []
        event_args = list(args)

        # These hooks transform a numeric value.  Feed each relic the result
        # produced by the previous relic so their effects compose instead of
        # silently overwriting one another.
        transform_arg_index = {
            "on_attack_hit": -1,
            "on_attack_roll": 0,
            "on_pre_take_damage": 0,
        }.get(event_name)

        for relic in list(self.relics):
            method = getattr(relic, event_name, None)
            if method:
                res = method(self, *event_args)
                if res is not None:
                    if isinstance(res, tuple) and len(res) == 2 and isinstance(res[1], list):
                        result, logs = res
                        default_result = result
                        all_logs.extend(logs)
                    else:
                        result = res
                        default_result = result

                    if transform_arg_index is not None:
                        event_args[transform_arg_index] = result
        return default_result, all_logs

    def take_damage(self, damage: int) -> Tuple[bool, List[str]]:
        _, logs = super().take_damage(damage)
        revived = False
        if self.current_hp <= 0:
            # 触发复活类遗物，如果任意遗物返回 True，则复活成功
            revived, event_logs = self.trigger_event("on_pre_death", default_result=False)
            logs.extend(event_logs)
        return revived, logs