# 🧬 rocky-evo

**自我修复 · 自我进化 · 自我迭代 — AI Agent 永不停止的进化引擎。**

**Self-Healing · Self-Evolving · Self-Iterating — A perpetual evolution engine for AI agents.**

---

## Overview / 概述

一个公开 OpenClaw 技能：每 4 小时收集所有原始日志喂给 AI，AI 自行分析问题并自动修复，结果注入到绑定的通讯通道。零硬编码、全通道适配、模型自动跟随。

A public OpenClaw skill: every 4h, collects all raw logs → AI analyzes → AI auto-fixes → reports to bound channel. Zero hardcoding, channel-agnostic, model auto-follow.

### 核心流程

```
收集原始日志 → AI 分析 → AI 自动修复 → 发送报告到通道
Collect raw logs → AI analyzes → AI auto-fixes → Report to channel
```

### 三大核心

| Pillar | Meaning |
|--------|---------|
| **Self-Healing / 自我修复** | AI reads raw logs, discovers anomalies, executes fixes autonomously |
| **Self-Evolving / 自我进化** | Each cycle learns from new data, adapts, becomes more effective |
| **Self-Iterating / 自我迭代** | 4h closed loop: each iteration builds on the last, perpetually |

---

## Compatibility / 环境兼容

| Requirement | Status |
|-------------|--------|
| Agent 类型 | ✅ main / helper / multi-agent 全兼容 |
| 通讯通道 | ✅ 飞书 / 微信 / Telegram / Discord / Slack / 自动检测 |
| 模型类型 | ✅ API Key / 订阅(OAuth) / Fallback 链 / 自动跟随 |
| 操作系统 | ✅ macOS / Linux |
| 安装路径 | ✅ 默认路径 / 自定义 `OPENCLAW_STATE_DIR` |
| 零硬编码 | ✅ 无 agent ID / 无通道名 / 无模型名硬编码 |

---

## How It Works / 工作原理

### ① 收集原始日志

```bash
scripts/full_analyze.sh
```

4小时内的所有原始数据：

| Source | Content |
|--------|---------|
| `gateway.log` | 所有请求/响应活动 |
| `gateway.err.log` | 错误和异常 |
| `agents/*/sessions/*.jsonl` | Agent 所有会话 |
| `cron/runs/*.jsonl` | 定时任务执行记录 |
| `openclaw.json` | 配置（机密已脱敏） |

**不做分类，不做预过滤，不做假设。** 原始数据就是全部事实。

### ② AI 分析

AI 读取全部数据，自行判断：
- 日志中有无错误/警告？
- 服务是否正常运行？
- API Key 是否快过期？
- 模型 fallback 切换是否正常？
- Agent 是否有异常行为？

**没有预定义规则，纯 AI 判断。**

### ③ AI 自动修复

AI 直接执行修复命令：重启服务、清理过期 session、调整配置、轮转日志、重连通道，或其他任何它认为需要修复的问题。

**没有预写修复脚本，AI 决定修什么、怎么修。**

### ④ 发送报告

修复结果自动发送到 agent 绑定的通道。读取 `openclaw.json` bindings → `sessions_list` 匹配通道 → `sessions_send` 发送。找不到活跃会话则直接输出报告摘要。

---

## Installation / 安装

### 前置条件

- OpenClaw（支持技能的任何版本）
- `jq`、`awk`、`bash` 4+

### 从 ClawHub 安装（推荐）

```bash
# Coming soon: claw install rocky-evo
```

### 手动安装

```bash
git clone https://github.com/openclaw/rocky-evo.git
cp -r rocky-evo ~/.openclaw/skills/
```

### 验证

```bash
ls ~/.openclaw/skills/rocky-evo/
# SKILL.md  scripts/  README.md  LICENSE  _meta.json
```

---

## Configuration / 配置

| 触发命令 | 效果 |
|---------|------|
| `/rocky-evo` | 手动触发进化周期 |
| `/自动修复` | 同上 |

Cron 每 4 小时自动触发。

| 环境变量 | 默认值 | 说明 |
|----------|--------|------|
| `ANALYZE_WINDOW` | `240` | 分析窗口（分钟），需与 cron 间隔一致 |
| `OPENCLAW_STATE_DIR` | `$HOME/.openclaw` | OpenClaw 数据目录 |

---

## File Structure / 文件结构

```
rocky-evo/
├── SKILL.md             # AI 进化指令（AI 读取此文件执行）
├── README.md            # 本说明文档
├── LICENSE              # MIT 许可
├── _meta.json           # ClawHub 发布元数据
├── .gitignore
├── .gitattributes
└── scripts/
    └── full_analyze.sh  # 原始日志收集脚本（只读，不做分析）
```

---

## Security / 安全

### 自动机密脱敏

`full_analyze.sh` 在输出配置前自动删除敏感字段：

| 字段 | 处理 |
|------|------|
| `models.providers[].apiKey` | ✅ 删除 |
| `任意深度的 appSecret` | ✅ 删除（`jq walk()`） |
| `gateway.auth/remote.token` | ✅ 删除 |
| `mcp.servers[].env` | ✅ 删除 |

### 只读设计

收集脚本纯只读：无危险命令、无临时文件、无网络请求、不修改任何文件。

---

## Testing / 测试

30 项测试全部通过（15 单元测试 + 15 逆向测试）。

### 关键场景验证

| 场景 | 结果 |
|------|------|
| 空环境（无任何数据） | ✅ 干净输出 |
| 1万行日志压力测试 | ✅ <1s，零泄露 |
| session 文件含二进制数据 | ✅ 不崩溃 |
| jq 失败 / JSON 损坏 | ✅ 自动 fallback 到 cat |
| 文件无权限（chmod 000） | ✅ 优雅跳过 |
| 单行 100KB | ✅ 正常通过 |
| Unicode 中/日/韩/emoji/特殊字符 | ✅ 完整保留 |
| ANALYZE_WINDOW=0/-1/999999 | ✅ 全部正常 |
| 真实配置脱敏 | ✅ JSON 合法，零泄露 |

---

## Platform / 社区平台

| Platform | Purpose |
|----------|---------|
| [GitHub](https://github.com/openclaw/rocky-evo) | 源码仓库，Issue，PR |
| [Gitee](https://gitee.com/openclaw/rocky-evo) | 国内镜像 |
| [ClawHub](https://clawhub.ai) | OpenClaw 技能市场（一键安装） |

---

## License / 许可

MIT — 详见 [LICENSE](./LICENSE)
