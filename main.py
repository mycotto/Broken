# main.py
from textual.app import App, ComposeResult
from textual.widgets import Header, Footer, Button, Static, Log
from textual.containers import Container, VerticalScroll
from textual.screen import Screen
from typing import Optional

from core import PlayerCharacter, ability_modifier
from engine import GameEngine

class ActionButton(Button):
    def __init__(self, *args, callback: Optional[callable] = None, **kwargs):
        super().__init__(*args, **kwargs)
        self.press_callback = callback

class CharacterScreen(Screen):
    CSS = """
    CharacterScreen { align: center middle; }
    #char-dialog { width: 70; height: 30; background: $surface; border: thick $primary; padding: 1 2; layout: vertical; }
    #char-title { text-align: center; text-style: bold; margin-bottom: 1; }
    #char-body { layout: horizontal; height: 1fr; }
    #char-left, #char-right { width: 1fr; padding: 0 1; }
    #char-right { border-left: dashed $primary; }
    .stat-line { margin-bottom: 1; }
    """
    
    def __init__(self, player: PlayerCharacter, current_floor: int):
        super().__init__()
        self.player = player
        self.current_floor = current_floor

    def compose(self) -> ComposeResult:
        with Container(id="char-dialog"):
            yield Static("📜 角色面板与规则", id="char-title")
            with Container(id="char-body"):
                with VerticalScroll(id="char-left"):
                    yield Static("【核心属性】", classes="stat-line")
                    for ab in ['strength', 'dexterity', 'constitution', 'intelligence', 'wisdom', 'charisma']:
                        mod = ability_modifier(self.player.abilities[ab])
                        sign = "+" if mod >= 0 else ""
                        yield Static(f"  {ab.upper()[:3]}: {self.player.abilities[ab]} ({sign}{mod})", classes="stat-line")
                    
                    yield Static("\n【战斗状态】", classes="stat-line")
                    yield Static(f"  HP: {self.player.current_hp}/{self.player.max_hp}", classes="stat-line")
                    yield Static(f"  AC: {self.player.ac}", classes="stat-line")
                    yield Static(f"  护盾: {self.player.temp_hp}", classes="stat-line")
                    if self.current_floor == 2:
                        yield Static(f"  🧠 记忆: {self.player.memory}", classes="stat-line")

                with VerticalScroll(id="char-right"):
                    yield Static("【已装备遗物】", classes="stat-line")
                    if not self.player.relics: yield Static("  无", classes="stat-line")
                    for r in self.player.relics:
                        yield Static(f"  ✨ {r.name}: {r.effect_desc}", classes="stat-line")
                    
                    yield Static("\n【游戏规则】", classes="stat-line")
                    yield Static("1.防御判定:", classes="stat-line")
                    yield Static(" 硬抗: AC-敌方掷骰>=5免疫,>=2受20%,>=0受30%,<0全额", classes="stat-line")
                    yield Static(" 闪避: 敏捷豁免同上,但>=0受50%", classes="stat-line")
                    yield Static(" 招架: 力量检定>=敌方则抵消1d8+力Mod伤害", classes="stat-line")
                    if self.current_floor == 2:
                        yield Static("2.第二层法则：", classes="stat-line")
                        yield Static(" 记忆归零将导致融入背景(Game Over)", classes="stat-line")

            yield Button("关闭面板", variant="primary", id="close-char")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "close-char": self.app.pop_screen()

class RoguelikeApp(App):
    CSS = """
    Screen { layout: horizontal; }
    #game-view { width: 2fr; height: 100%; border-right: solid green; }
    #sidebar { width: 1fr; height: 100%; layout: vertical; }
    #status { height: auto; background: $boost; color: white; padding: 1; text-style: bold; }
    /* 修改为 text-style: bold 使日志更醒目 */
    #game-log { height: 1fr; border-bottom: solid green; text-style: bold; }
    #actions { height: 1fr; padding: 1; overflow-y: auto; }
    ActionButton { width: 100%; margin-bottom: 1; }
    .combat-btn { background: $error; }
    .explore-btn { background: $primary; }
    .target-btn { background: $warning; color: black; }
    """

    def compose(self) -> ComposeResult:
        yield Header()
        with Container(id="game-view"):
            yield Static(id="status")
            yield Log(id="game-log")
        with VerticalScroll(id="sidebar"):
            yield Container(id="actions")
        yield Footer()

    def on_mount(self):
        self.engine = GameEngine()
        self.process_engine_result(self.engine.start_new_game())

    def write_log(self, msg: str):
        try: self.query_one("#game-log", Log).write_line(msg)
        except Exception: pass

    def update_status_bar(self):
        self.query_one("#status", Static).update(self.engine.get_status_text())

    def clear_actions(self):
        self.query_one("#actions", Container).remove_children()

    def add_action(self, label: str, callback: Optional[callable], css_class: str = "explore-btn", disabled: bool = False):
        btn = ActionButton(label, classes=css_class, callback=callback)
        if disabled: btn.disabled = True
        self.query_one("#actions", Container).mount(btn)

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if isinstance(event.button, ActionButton) and event.button.press_callback:
            event.button.press_callback()

    def process_engine_result(self, result: dict):
        if not result: return
        if result.get("clear_log"): self.query_one("#game-log", Log).clear()

        for l in result.get("logs", []): self.write_log(l)
        self.update_status_bar()
        
        if result.get("action_type") == "show_character_screen":
            self.push_screen(CharacterScreen(self.engine.player, self.engine.current_floor))
            return

        if "timer" in result:
            next_action = result["next_action"]
            self.clear_actions()
            self.set_timer(result["timer"], lambda: self.process_engine_result(self.engine.execute_action(next_action)))
            return

        self.clear_actions()
        for act in result.get("actions", []):
            action_id = act["action_id"]
            args = act.get("args", {})
            callback = lambda aid=action_id, a=args: self.process_engine_result(self.engine.execute_action(aid, a))
            self.add_action(act["label"], callback, act.get("css", "explore-btn"), act.get("disabled", False))

if __name__ == "__main__":
    app = RoguelikeApp()
    app.run()