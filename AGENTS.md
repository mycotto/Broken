# AGENTS.md

基于 Textual 的桌面 roguelike 游戏（Python 3，终端 UI，界面文案为中文）。

## 命令

- 运行：`python main.py`

## 结构

- `core.py`：角色、属性、骰子等基础规则
- `engine.py`：战斗与楼层引擎（文件最大，改动前先看 `MONSTER_MAP` 的结构）
- `monsters.py` / `relics.py`：怪物与遗物定义
- `legacy.py`：旧版遗物逻辑（文件尚未出现在目录中）
- `main.py`：Textual 界面与屏幕

## 约定

- 新增怪物/遗物沿用现有数据结构和命名风格，不要改公共接口
- 界面文案保持中文
- 不引入新依赖；标准库和现有 Textual 能实现的，不加库
