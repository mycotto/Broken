# AGENTS.md

## 项目定位

《Broken》是一款基于 Godot 4.7 的中文暗黑 Roguelike。正式项目根目录为 `Broken/`；根目录的 Python/Textual 文件是早期原型，仅供规则参考，不是当前版本的运行入口。

## 常用命令

在仓库根目录执行：

- 运行游戏：`& .\tools\godot\Godot_v4.7.2-stable_win64.exe --path Broken --editor`
- 逻辑测试：`& .\tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path Broken --script res://tests/smoke.gd`
- UI 冒烟测试：`& .\tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path Broken --script res://tests/ui_smoke.gd`

## 结构

- `Broken/project.godot`：Godot 项目配置、主场景和导出目标。
- `Broken/Main.tscn`：主场景，仅加载主界面脚本。
- `Broken/scripts/game_data.gd`：怪物、遗物、职业、魔装、法术和药水的静态数据。
- `Broken/scripts/game_state.gd`：探索、战斗、奖励、遗物事件与职业机制的核心状态机；改动前先确认相关阶段和事件钩子。
- `Broken/scripts/main.gd`：动态 UI、输入分发、状态栏、贴图和分层 BGM。
- `Broken/tests/smoke.gd`：规则与职业机制的回归测试。
- `Broken/tests/ui_smoke.gd`：主菜单、选角及基础 UI 冒烟测试。
- `Broken/assets/`：UI 美术、技能图标和音乐资源。

## 约定

- 新增内容优先扩展 `game_data.gd` 的现有字典结构；保持 `id`、`name`、`effect` 等字段和现有命名风格一致。
- 规则修改需同步检查 `game_state.gd`、角色面板文案和对应测试，避免“实际效果”与“玩家说明”不一致。
- 界面、日志和玩家可见说明保持中文；资源路径使用 `res://`。
- 不引入额外插件或依赖；优先使用 Godot 内置节点、资源与 GDScript。
- 保留 Python 原型文件，除非任务明确要求维护或删除它们。
