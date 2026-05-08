---
name: rocky-evo
version: 16.0.0
description: "自我修复·自我进化·自我迭代 — 收集4小时内所有原始日志喂给AI，AI自行分析并自动修复，修复结果注入活跃会话。Self-healing, self-evolving, self-iterating AI agent."
author: openclaw
homepage: https://clawhub.ai
repository: https://github.com/openclaw/rocky-evo
license: MIT
slug: rocky-evo
tags:
  - self-healing
  - self-evolving
  - auto-fix
  - log-analysis
  - maintenance
  - openclaw
  - 自我修复
  - 自我进化
  - 日志分析
  - 自动修复
metadata:
  openclaw:
    emoji: "🧬"
    triggers:
      - keyword: /rocky-evo
      - keyword: /自动修复
---

# rocky-evo v16.0.0

## 安装限制

**仅限主 agent 安装。**

## 核心流程

```
dump 原始日志 → AI 分析 → AI 自动修复 → 注入修复结果到活跃会话
```

## 执行步骤

### 步骤 1: 收集4小时内所有原始日志

```bash
OPENCLAW_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
SKILL_DIR="$(dirname "$(find "$OPENCLAW_DIR/skills" -name "SKILL.md" -path "*/rocky-evo/SKILL.md" 2>/dev/null | head -1)")"
ANALYZE_WINDOW=240 bash "$SKILL_DIR/scripts/full_analyze.sh"
```

输出包含（原样 dump，不分类不筛选）：
- `gateway.log` + `gateway.err.log`
- 所有 agent 的会话 jsonl
- cron runs 记录
- `openclaw.json` 配置（机密已脱敏）

### 步骤 2: AI 分析并自动修复

AI 自己看原始日志，自行判断问题并直接执行修复命令。

**自动适配当前 agent 的模型**：
- 从 `openclaw.json` 读取当前 agent 的模型配置
- API Key 模型 → 关注 rate limit、key 过期、配额耗尽
- 订阅/Portal 模型（`authHeader: true`，无需 API Key）→ 关注 OAuth 令牌、订阅状态
- 备用模型链 → 关注 fallback 切换是否正常

**不需要任何预定义修复脚本，AI 自己决定修什么、怎么修。**

### 步骤 3: 发到 Agent 绑定的通道（必须执行）

修复完成后，**必须**发到当前 agent 绑定的通道。

1. 读取 `openclaw.json` 的 `agents.bindings`，找到当前 agent 绑定的通道
2. 调用 `sessions_list({ activeWithinSeconds: 3600 })` 获取活跃会话
3. session key 格式: `agent:AGENT_ID:CHANNEL_NAME:TYPE:USER_ID` → 按 CHANNEL_NAME 匹配
4. 调用 `sessions_send({ sessionKey, message })` 发送报告
5. 找不到会话则直接输出报告摘要作为本 agent 的回复

支持任意通道：feishu / openclaw-weixin / telegram / discord / slack / 其他

### 步骤 4: 保存报告

```bash
REPORT_PATH="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}/rocky-evo-report.md"
# 保存报告到 $REPORT_PATH
```

## 触发方式

- 用户发送 `/rocky-evo` 或 `/自动修复` 手动触发
- Cron 定时每4小时自动触发
