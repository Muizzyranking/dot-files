#!/usr/bin/env python3

import glob
import json
import os
import re
import sys
import time
from datetime import datetime

brain_dir = os.path.expanduser("~/.gemini/antigravity-cli/brain")
dirs = sorted(glob.glob(f"{brain_dir}/*/"), key=os.path.getmtime, reverse=True)
if not dirs:
    print(
        json.dumps(
            {
                "ready": False,
                "running": False,
                "busy": False,
                "attention": 0,
                "taskFinished": False,
                "actionNeeded": False,
                "sessions": [],
            }
        )
    )
    sys.exit(0)

# Check if agy process is alive
res = os.system('pgrep -f "/agy" >/dev/null 2>&1')
agy_running = res == 0

sessions = []
for i, d in enumerate(dirs[:6]):
    cid = os.path.basename(d.rstrip("/"))
    tp = os.path.join(d, ".system_generated/logs/transcript.jsonl")
    mtime_ms = os.path.getmtime(d) * 1000
    if os.path.exists(tp):
        sessions.append(
            {"id": cid, "path": d, "updated": mtime_ms, "isActive": (i == 0)}
        )

latest_brain = dirs[0]
transcript_path = os.path.join(latest_brain, ".system_generated/logs/transcript.jsonl")
conv_id = os.path.basename(latest_brain.rstrip("/"))

if not os.path.exists(transcript_path):
    print(
        json.dumps(
            {
                "ready": agy_running,
                "running": agy_running,
                "busy": False,
                "attention": 0,
                "taskFinished": False,
                "actionNeeded": False,
                "conversationId": conv_id,
                "sessions": sessions,
            }
        )
    )
    sys.exit(0)

last = None
last_user = None
step_count = 0
try:
    with open(transcript_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            l = line.strip()
            if not l:
                continue
            step_count += 1
            try:
                d = json.loads(l)
                if d.get("type") == "USER_INPUT":
                    last_user = d
                last = d
            except Exception:
                pass
except Exception:
    pass

if not last:
    print(
        json.dumps(
            {
                "ready": agy_running,
                "running": agy_running,
                "busy": False,
                "attention": 0,
                "taskFinished": False,
                "actionNeeded": False,
                "conversationId": conv_id,
                "sessions": sessions,
            }
        )
    )
    sys.exit(0)


def parse_iso(ts):
    if not ts:
        return 0
    try:
        dt = datetime.fromisoformat(ts)
        return dt.timestamp() * 1000
    except Exception:
        return 0


now_ms = time.time() * 1000
user_ts_ms = parse_iso(last_user.get("created_at")) if last_user else 0
last_ts_ms = parse_iso(last.get("created_at"))

has_tool_calls = bool(last.get("tool_calls"))
is_user_input = last.get("type") == "USER_INPUT"
# Final response means model sent its completed text to the user without calling more tools
is_final_response = last.get("type") == "PLANNER_RESPONSE" and not has_tool_calls

# Agent is busy from user input until the final response is written
busy = agy_running and not is_final_response

# Action needed: agent is asking the user a question or permission
attention = 0
if has_tool_calls:
    for tc in last.get("tool_calls", []):
        if tc.get("name") in ("ask_question", "ask_user"):
            attention = 1

turn_start_ms = user_ts_ms if user_ts_ms > 0 else last_ts_ms
elapsed_ms = (
    max(0, int(now_ms - turn_start_ms))
    if busy
    else max(0, int(last_ts_ms - turn_start_ms))
)

raw_model = last.get("model") or "Gemini"
model_display = raw_model
if "flash" in raw_model.lower():
    model_display = "Gemini 3.8 Flash"
elif "pro" in raw_model.lower():
    model_display = "Gemini Pro"

prompt_text = str(last_user.get("content", "")) if last_user else ""
prompt_text = re.sub(r"<USER_REQUEST>|\s*</USER_REQUEST>", "", prompt_text)
prompt_text = re.sub(
    r"<ADDITIONAL_METADATA>[\s\S]*?</ADDITIONAL_METADATA>", "", prompt_text
)
prompt_text = re.sub(
    r"<USER_SETTINGS_CHANGE>[\s\S]*?</USER_SETTINGS_CHANGE>", "", prompt_text
)
prompt_text = " ".join(prompt_text.strip().split())

out = {
    "ready": agy_running or os.path.exists(transcript_path),
    "running": agy_running,
    "busy": busy,
    "attention": attention,
    "taskFinished": is_final_response,
    "actionNeeded": (attention > 0),
    "conversationId": conv_id,
    "model": model_display,
    "stepIndex": last.get("step_index", step_count),
    "turnStartMs": turn_start_ms,
    "elapsedMs": elapsed_ms,
    "lastActivity": last_ts_ms,
    "inputTokens": last.get("input_tokens", 0),
    "outputTokens": last.get("output_tokens", 0),
    "cacheReadTokens": last.get("cache_read_tokens", 0),
    "lastPrompt": prompt_text[:140],
    "sessions": sessions,
}
print(json.dumps(out))
