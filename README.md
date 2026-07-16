# Dawei — Cursor / GPT 技术人格与安全研究配置包

给 Cursor 和 Codex/GPT 加一套直接、暴躁但会把活干完的中文技术人格（Dawei），以及逆向、渗透、内存、CTF、游戏安全、授权安全六个专业 Skill。

所有配置都从本仓库拉取，不依赖任何第三方中转服务器。

## 目录结构

```text
.cursor/
├── rules/dawei-*.mdc        # Cursor Project Rules（Dawei 人格，5 个模块）
├── rules/waiwai-gpt56.mdc   # Cursor 版 waiwai 完整提示词（--profile waiwai）
├── rules/waiwai-behavior.mdc# Cursor 版 waiwai 去冲突行为叠加层（--profile both）
└── skills/dawei-*/          # Agent Skills（6 个，各档共用）
codex/
├── AGENTS.md                # Codex/GPT 用，从 dawei rules 合并生成
├── waiwai-gpt56-ruleset.md  # Codex/GPT 用的 waiwai 完整提示词
└── waiwai-behavior.md       # Codex/GPT 用的 waiwai 去冲突行为叠加层
install.command             # 从 GitHub 下载并安装
```

## 一键安装（从 git 下载）

在终端运行，脚本会自动 `git clone` 本仓库最新内容再安装：

```bash
# 交互式：选择装到 Cursor 项目 / Codex(全局) / 两者
curl -fsSL https://raw.githubusercontent.com/dawei-ux/Cursor-Gpt-Armor-Penetration/main/install.command | bash
```

或先克隆再执行：

```bash
git clone https://github.com/dawei-ux/Cursor-Gpt-Armor-Penetration.git
cd Cursor-Gpt-Armor-Penetration
chmod +x install.command

# 装到某个 Cursor 项目
./install.command --mode cursor --target "/你的项目目录"

# 装到 Codex/GPT（全局 ~/.codex），默认 Dawei 人格
./install.command --mode gpt

# 装到 Codex/GPT，改用 waiwai 的 GPT-5.6 提示词
./install.command --mode gpt --profile waiwai

# 两个都装
./install.command --mode both --target "/你的项目目录"
```

`--profile` 选择人格，**Cursor 和 Codex/GPT 都生效**，交互模式下也会询问：

- `dawei`（默认）：Cursor 安装 `dawei-*.mdc`，Codex 用合并后的 `AGENTS.md`。
- `waiwai`：只用 waiwai 的完整 GPT-5.6 提示词。Cursor 安装 `waiwai-gpt56.mdc`，Codex 用 `waiwai-gpt56-ruleset.md`（见「致谢」）。
- `both`：**两套一起用**。Dawei 负责身份/人格，waiwai 作为「去冲突的行为叠加层」。Cursor 安装 `dawei-*.mdc` + `waiwai-behavior.mdc`，Codex 的 `AGENTS.md` 是二者拼接。

```bash
./install.command --mode both --target "/你的项目目录" --profile both
```

6 个 Skill 三种情况都共用。

### 两套一起用如何防止冲突？

两套原始文件都是「always-apply 常驻系统提示词」，直接同时挂上去会在**身份**上打架：Dawei 说"你是 Dawei"，waiwai 说"You are Codex, based on GPT-5.6"，还各有招呼语和验证方式。

`both` 档的做法是**分工 + 去冲突**：

- **身份、自称、招呼语、验证方式一律以 Dawei 为准。**
- waiwai 只保留「执行行为」部分，做成 `waiwai-behavior.mdc` / `codex/waiwai-behavior.md`，其中已删除会冲突的段落：`You are Codex...` 身份声明、`VERIFICATION TOKEN`（`CHECK_SYSTEM_PROMPT_ACTIVE`）、`BEGIN.` 等。
- 叠加层顶部写明"你仍然是 Dawei，如有措辞冲突以 Dawei 核心规则优先"，让模型有明确的优先级。

想要 waiwai 的**完整原版**（含身份声明和验证 token），就用 `--profile waiwai`，别和 Dawei 混装。

安装前会把同名旧配置备份到 `.cursor/backups/`（Cursor）或 `~/.codex/backups/`（Codex）。

## 安装位置

- **Cursor**：Rules 放进项目 `.cursor/rules/`，Skills 放进 `.cursor/skills/`。
- **Codex/GPT**：`AGENTS.md` 写入 `~/.codex/AGENTS.md`，Skills 放进 `~/.codex/skills/`。

## 验证

完全重启 Cursor 或新开 Codex 会话后。

## 致谢 / 来源

- `codex/waiwai-gpt56-ruleset.md` 与 `.cursor/rules/waiwai-gpt56.mdc`：GPT-5.6 / Codex 系统提示词，来自 linux.do 论坛大佬 **waiwai**，主页 <https://linux.do/u/waiwai/summary>。收录于此仅作整理与致谢，版权与思路归原作者所有。

## 卸载

删除对应文件即可，需要恢复就从 `backups/` 里最近的备份拷回：

- Cursor：`.cursor/rules/dawei-*.mdc`、`.cursor/skills/dawei-*`
- Codex/GPT：`~/.codex/AGENTS.md`、`~/.codex/skills/dawei-*`
