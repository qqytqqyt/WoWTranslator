# WoWeuCN-Interface — 魔兽世界界面中文翻译 / Chinese UI Translation

---

## 简体中文

**WoWeuCN-Interface** 将游戏界面翻译成简体中文——窗口标题、按钮、菜单、选项、系统弹窗、ESC 游戏菜单等界面文本，无需更换客户端语言。**支持任意语言的客户端**：英语、德语、法语、西班牙语、葡萄牙语、意大利语、俄语、韩语等（插件在运行时根据客户端当前语言自动建立对照表）。

### 支持的游戏版本（同一项目，按版本下载对应文件）

| 版本 | Interface |
|------|-----------|
| 正式服 Retail (Midnight) | 12.1.x |
| 经典旧世 Classic Era | 1.15.x |
| 周年庆服 Anniversary (TBC) | 2.5.x |
| 熊猫人之谜怀旧服 MoP Classic | 5.5.x |

### 特色

- **安全翻译架构**：本插件**从不修改任何暴雪全局字符串、不调用任何保护函数**。所有翻译都通过插件自身的延迟渲染通道改写界面文字，从根本上避免了 12.x 版本因 taint（污染）与 secret（机密值）机制导致的“界面操作被阻止”、战斗功能失效等问题。
- **实时翻译**：界面刷新后毫秒级重新翻译，打开任何面板即刻显示中文。
- **格式化文本支持**：内置数千条格式模板，`Abandon "任务名"?`、`Level 80` 这类带参数的动态文本也能正确翻译并保留参数。
- **不改动字体**：默认不替换任何字体，英文文本外观保持原样；中文由客户端自带的字体回退机制渲染。若中文显示为方块，可在设置中开启“全局替换界面字体”。
- **完整选项**：ESC → 选项 → 插件 → WoWeuCN-Interface，或使用命令 `/wcni`（`on` / `off` / `rescan` / `status`）。

### 有意保留英文的部分（正式服）

战斗记录、浮动战斗文字、冷却管理器、伤害统计等界面在 12.x 中直接处理机密数值，为保证战斗功能绝不被阻断，这些界面刻意保持英文。

### 配套插件（强烈推荐一起使用）

- **WoWeuCN-Quests** — 任务标题、目标与剧情文本翻译
- **WoWeuCN-Tooltips** — 物品、法术、NPC、成就等鼠标提示翻译

### 说明

- 进入游戏后约 2 秒开始翻译（等待暴雪界面初始化完成，属于安全设计的一部分）。
- 由服务器发送的文本（聊天信息、物品名等）不在本插件范围内，请配合上述配套插件。

---

## English

**WoWeuCN-Interface** translates the World of Warcraft user interface into Simplified Chinese — window titles, buttons, menus, options, system popups, the ESC game menu and more — without changing your client language. **Works with clients in any language**: English, German, French, Spanish, Portuguese, Italian, Russian, Korean and more (the addon builds its translation table at runtime from your client's current language).

### Supported game versions (one project, pick the file for your version)

| Version | Interface |
|---------|-----------|
| Retail (Midnight) | 12.1.x |
| Classic Era | 1.15.x |
| Anniversary (TBC) | 2.5.x |
| MoP Classic | 5.5.x |

### Highlights

- **Taint-safe architecture**: the addon **never modifies any Blizzard global string and never calls protected functions**. All translation is done by rewriting rendered text from the addon's own deferred passes, which structurally avoids the 12.x taint/secret-value problems ("Interface action failed", broken combat features) that plague global-replacement approaches.
- **Live retranslation**: text is re-translated within the same frame whenever the UI refreshes, so panels show Chinese the moment they open.
- **Formatted text support**: thousands of built-in format templates translate parameterized text like `Abandon "QuestName"?` or `Level 80` while preserving the values.
- **Fonts untouched**: no fonts are replaced by default — English text keeps its original look, and Chinese renders through the client's built-in font fallback. An optional global font swap is available in the settings if your client shows squares instead of Chinese.
- **Full options**: ESC → Options → AddOns → WoWeuCN-Interface, or `/wcni` (`on` / `off` / `rescan` / `status`).

### Deliberately kept in English (Retail)

The combat log, floating combat text, cooldown manager and damage meter process secret combat values in 12.x; these surfaces intentionally stay English so combat functionality can never be blocked.

### Companion addons (strongly recommended)

- **WoWeuCN-Quests** — quest titles, objectives and story text
- **WoWeuCN-Tooltips** — item, spell, NPC and achievement tooltips

### Notes

- Translation starts about 2 seconds after the loading screen (waiting for Blizzard's UI initialization to finish — part of the safety design).
- Server-sent text (chat messages, item names, etc.) is out of scope for this addon — use the companion addons above.
