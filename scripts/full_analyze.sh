#!/bin/bash
# rocky-evo 原始日志收集 - 只倒原始文件，不做任何分析
# 把4小时内的所有原始日志文件内容原样输出，AI自行判断

ANALYZE_WINDOW="${ANALYZE_WINDOW:-240}"
OC_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"

# 计算 4 小时前的时间戳（用于 gateway 日志过滤）
if date -v-${ANALYZE_WINDOW}M >/dev/null 2>&1; then
    CUTOFF=$(date -v-${ANALYZE_WINDOW}M '+%Y-%m-%dT%H:%M:%S' 2>/dev/null)
else
    CUTOFF=$(date -d "-${ANALYZE_WINDOW} minutes" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null)
fi
: "${CUTOFF:=unknown}"

echo "=== rocky-evo raw logs dump ==="
echo "window_minutes=$ANALYZE_WINDOW"
echo "time=$(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 1. Gateway 日志（仅近4小时）
if [ -f "$OC_DIR/logs/gateway.log" ]; then
    echo "### FILE: gateway.log ($(wc -c < "$OC_DIR/logs/gateway.log") bytes, last ${ANALYZE_WINDOW}min)"
    if [ "$CUTOFF" != "unknown" ]; then
        awk -v cutoff="$CUTOFF" 'match($0, /^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}/) {
            ts = substr($0, RSTART, 19)
            if (ts >= cutoff) { print; found=1; next }
        } found' "$OC_DIR/logs/gateway.log"
    else
        tail -5000 "$OC_DIR/logs/gateway.log"
    fi
    echo ""
fi

if [ -f "$OC_DIR/logs/gateway.err.log" ]; then
    echo "### FILE: gateway.err.log ($(wc -c < "$OC_DIR/logs/gateway.err.log") bytes, last ${ANALYZE_WINDOW}min)"
    if [ "$CUTOFF" != "unknown" ]; then
        awk -v cutoff="$CUTOFF" 'match($0, /^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}/) {
            ts = substr($0, RSTART, 19)
            if (ts >= cutoff) { print; found=1; next }
        } found' "$OC_DIR/logs/gateway.err.log"
    else
        tail -5000 "$OC_DIR/logs/gateway.err.log"
    fi
    echo ""
fi

# 2. 最近4小时的所有会话文件
for agent_dir in "$OC_DIR"/agents/*/sessions; do
    find "$agent_dir" -name "*.jsonl" -mmin -${ANALYZE_WINDOW} -not -name "*trajectory*" 2>/dev/null | while read f; do
        echo "### FILE: $f ($(wc -c < "$f") bytes)"
        cat "$f"
        echo ""
    done
done

# 3. 最近4小时的cron运行记录
find "$OC_DIR/cron/runs" -name "*.jsonl" -mmin -${ANALYZE_WINDOW} 2>/dev/null | while read f; do
    if [ -f "$f" ]; then
        echo "### FILE: $f ($(wc -c < "$f") bytes)"
        cat "$f"
        echo ""
    fi
done

# 4. openclaw.json 配置文件（脱敏：过滤 apiKey/appSecret/token/MCP env）
if [ -f "$OC_DIR/openclaw.json" ]; then
    echo "### FILE: openclaw.json ($(wc -c < "$OC_DIR/openclaw.json") bytes, sensitive fields redacted)"
    jq 'del(
      .models.providers[].apiKey,
      .gateway.auth.token,
      .gateway.remote.token,
      .mcp.servers[].env
    ) | walk(if type == "object" and has("appSecret") then del(.appSecret) else . end)' "$OC_DIR/openclaw.json" 2>/dev/null || cat "$OC_DIR/openclaw.json"
    echo ""
fi

echo "=== dump end ==="
