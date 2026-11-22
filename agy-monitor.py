#!/usr/bin/env python3
from __future__ import annotations
"""
Antigravity (AGY) 实时性能与状态监控看板 (AGY Top / Monitor & AGY-Hub JSON Sidecar)

特性：
- 100% 纯本地只读解析：零网络请求、零反向代理、零 OAuth Token 读取，严格遵循防封号安全红线。
- 毫秒级极速解析：采用 SQLite (只读模式) + JSONL 流式扫描，零内存膨胀。
- 核心指标洞察：
  * 打乒乓球交互次数 (Total Model Roundtrips)
  * 当前是否排队、排队跳秒时长 (Current Queue/Stall Duration)
  * 上下文 Token 规模与 Token 生成速率 (Context Tokens & TPS)
  * 云端异常与算力熔断预警 (503 No Capacity / 429 ResourceExhausted / EOF Stream Broken)
  * 慢不慢判定灯 (🟢 畅通 / 🟡 迟缓 / 🔴 严重排队 / ⚠️ 异常 / ⏸️ 待命)
- 多视图与 GUI Sidecar 支持：
  * 全局大盘 (Overview)：一览所有活跃运行及最近完成的会话状态
  * 单会话钻取 (Detail)：深入单会话的单步延迟时序甘特图
  * GUI 结构化输出 (--json)：为 AGY-Hub macOS 状态栏应用提供毫秒级 JSON 数据源
- 容错与无依赖回退：优先使用 rich 呈现高刷新率终端看板，若无 rich 自动优雅降级为原生 ANSI 转义，绝不崩溃。
"""

import argparse
import hashlib
import json
import os
import re
import sqlite3
import sys
import time
from datetime import datetime, timedelta, timezone
from urllib.parse import quote

try:
    from rich.console import Console, Group
    from rich.live import Live
    from rich.table import Table
    from rich.panel import Panel
    from rich.text import Text
    from rich.layout import Layout
    HAVE_RICH = True
except ImportError:
    HAVE_RICH = False

DEFAULT_GEMINI_DIR = os.path.expanduser("~/.gemini/antigravity")
DEFAULT_CLI_DIR = os.path.expanduser("~/.gemini/antigravity-cli")
DB_PATH = os.path.join(DEFAULT_GEMINI_DIR, "conversation_summaries.db")
BRAIN_DIR = os.path.join(DEFAULT_GEMINI_DIR, "brain")
CONVERSATIONS_DIR = os.path.join(DEFAULT_GEMINI_DIR, "conversations")
COLLECTOR_ANCHOR_PATH = os.path.expanduser("~/Library/Application Support/Token Monitor/collector-anchor.json")
DAILY_ARCHIVE_PATH = os.path.expanduser("~/Library/Application Support/Token Monitor/daily-history-archive.json")
DEFAULT_USAGE_CACHE_PATH = os.path.expanduser("~/.agy-profiles/usage_daily_cache.json")
DEFAULT_INSPECT_CACHE_PATH = os.path.expanduser("~/.cache/agyhub/session_inspect_cache_v1.json")
INSPECT_CACHE_SCHEMA_VERSION = 1
_UNSET = object()

_INSPECT_MEM_CACHE: dict[str, dict] = {}
_USAGE_MEM_CACHE: dict[str, dict] = {}
_DESCRIPTOR_MEM_CACHE: dict[str, tuple[tuple, dict[str, dict]]] = {}

def clear_runtime_caches() -> None:

    _INSPECT_MEM_CACHE.clear()
    _USAGE_MEM_CACHE.clear()
    _DESCRIPTOR_MEM_CACHE.clear()

def _is_cache_disabled() -> bool:

    return os.environ.get("AGYHUB_DISABLE_CACHE", "").strip().lower() in ("1", "true", "yes")

def _resolve_inspect_cache_path(cache_path: str | None = None) -> str:

    if cache_path:
        return os.path.expanduser(cache_path)
    env_path = os.environ.get("AGYHUB_INSPECT_CACHE_PATH", "").strip()
    if env_path:
        return os.path.expanduser(env_path)
    return DEFAULT_INSPECT_CACHE_PATH

def _empty_inspect_cache() -> dict:
    return {
        "schema_version": INSPECT_CACHE_SCHEMA_VERSION,
        "sessions": {},
        "models": {},
    }

def _file_stat_sig(path: str) -> tuple[int, int] | None:
    try:
        st = os.stat(path)
        return (st.st_mtime_ns, st.st_size)
    except OSError:
        return None

def _atomic_write_json(path: str, payload: dict) -> bool:

    tmp_path = f"{path}.tmp.{os.getpid()}"
    try:
        parent = os.path.dirname(os.path.abspath(path))
        os.makedirs(parent, exist_ok=True)
        with open(tmp_path, "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False, separators=(",", ":"))
        os.replace(tmp_path, path)
        return True
    except Exception:
        try:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)
        except OSError:
            pass
        return False

def _get_inspect_cache(cache_path: str | None = None) -> tuple[dict, str, bool]:

    resolved = _resolve_inspect_cache_path(cache_path)
    disk_sig = _file_stat_sig(resolved)
    mem_entry = _INSPECT_MEM_CACHE.get(resolved)
    if mem_entry is not None and mem_entry.get("disk_sig") == disk_sig:
        return mem_entry["data"], resolved, False

    needs_rebuild = False
    data: dict | None = None
    if disk_sig is not None:
        try:
            with open(resolved, "r", encoding="utf-8") as f:
                loaded = json.load(f)
            if (
                isinstance(loaded, dict)
                and loaded.get("schema_version") == INSPECT_CACHE_SCHEMA_VERSION
                and isinstance(loaded.get("sessions"), dict)
                and isinstance(loaded.get("models"), dict)
            ):
                data = loaded
            else:
                needs_rebuild = True
        except Exception:
            needs_rebuild = True

    if data is None:
        data = _empty_inspect_cache()

    _INSPECT_MEM_CACHE[resolved] = {"disk_sig": disk_sig, "data": data}
    return data, resolved, needs_rebuild

def _save_inspect_cache(resolved_path: str, cache: dict) -> None:

    sessions = cache.get("sessions")
    if isinstance(sessions, dict) and len(sessions) > 1000:
        stale = [p for p in list(sessions.keys()) if not os.path.exists(p)]
        for p in stale:
            sessions.pop(p, None)
    models = cache.get("models")
    if isinstance(models, dict) and len(models) > 1000:
        stale_m = [p for p in list(models.keys()) if not os.path.exists(p)]
        for p in stale_m:
            models.pop(p, None)
    if _atomic_write_json(resolved_path, cache):
        _INSPECT_MEM_CACHE[resolved_path] = {
            "disk_sig": _file_stat_sig(resolved_path),
            "data": cache,
        }

def _get_rate_regime(now: datetime | None = None) -> list[bool]:

    ref_now = now or datetime.now()
    if ref_now.tzinfo is not None:
        ref_now = ref_now.astimezone().replace(tzinfo=None)
    return [ref_now >= datetime(2026, 12, 1), ref_now >= datetime(2027, 1, 1)]

def _db_fingerprint(db_path: str) -> list[int] | None:

    try:
        st = os.stat(db_path)
    except OSError:
        return None
    wal_mtime, wal_size = 0, 0
    try:
        wst = os.stat(f"{db_path}-wal")
        wal_mtime, wal_size = wst.st_mtime_ns, wst.st_size
    except OSError:
        pass
    return [st.st_mtime_ns, st.st_size, wal_mtime, wal_size]

def connect_sqlite_ro(db_path: str) -> sqlite3.Connection:

    abs_path = os.path.abspath(db_path)
    uri = f"file:{quote(abs_path)}?mode=ro"
    try:
        return sqlite3.connect(uri, uri=True, timeout=1.5)
    except Exception:
        return sqlite3.connect(abs_path, timeout=1.5)

def format_duration(seconds: float) -> str:

    if seconds < 0:
        return "0秒"
    if seconds < 60:
        return f"{int(seconds)}秒"
    minutes = int(seconds // 60)
    secs = int(seconds % 60)
    if minutes < 60:
        return f"{minutes}分{secs:02d}秒"
    hours = int(minutes // 60)
    rem_mins = int(minutes % 60)
    return f"{hours}小时{rem_mins}分"

def fmt_tokens(n: int) -> str:

    if n >= 1_000_000:
        return f"{n/1_000_000:.1f}M"
    elif n >= 1_000:
        return f"{n/1_000:.0f}k"
    return str(n)

def _normalize_lang(lang: str | None) -> str:

    low = (lang or "").strip().lower()
    if low.startswith("en"):
        return "en"
    return "zh"

def _localize_duration_units_en(text: str) -> str:

    return (
        text.replace("小时", "h")
        .replace("分", "m")
        .replace("秒", "s")
        .replace("本地:", "Local:")
        .replace("云端:", "Cloud:")
        .replace("本地 ", "Local ")
        .replace("云端 ", "Cloud ")
    )

def _localize_session_dict_en(s: dict) -> None:

    if not isinstance(s, dict):
        return
    if s.get("title") == "未知会话":
        s["title"] = "Unknown Session"
    if s.get("breakdown_str"):
        s["breakdown_str"] = _localize_duration_units_en(str(s["breakdown_str"]))
    if s.get("compact_time_str") and s["compact_time_str"] != "-":
        s["compact_time_str"] = _localize_duration_units_en(str(s["compact_time_str"]))

    err = s.get("recent_error")
    if isinstance(err, str) and err:
        err_map = {
            "🔴 503 云端算力不足排队中": "🔴 503 Cloud Capacity Queued",
            "⚠️ 网络断流重连中": "⚠️ Stream Disconnected, Reconnecting",
            "⚠️ 429 频控限流退避中": "⚠️ 429 Rate Limited",
        }
        s["recent_error"] = err_map.get(err, err)

    hd = str(s.get("health_desc") or "")
    hd_map = {
        "待命中": "Idle",
        "活跃处理中": "Active",
        "畅通": "Healthy",
        "503 算力不足排队中": "503 Capacity Queue",
        "网络断流重连中": "Stream Reconnecting",
        "429 限流退避中": "429 Rate Limited",
    }
    if hd in hd_map:
        s["health_desc"] = hd_map[hd]
    elif hd.startswith("稍慢 (长上下文推理 "):
        inner = _localize_duration_units_en(hd[len("稍慢 (长上下文推理 ") : -1])
        s["health_desc"] = f"Slow (Long Context {inner})"
    elif hd.startswith("严重排队 ("):
        inner = _localize_duration_units_en(hd[len("严重排队 (") : -1])
        s["health_desc"] = f"Severe Queue ({inner})"
    elif hd:
        s["health_desc"] = (
            hd.replace("503 云端算力不足排队中", "503 Cloud Capacity Queued")
            .replace("网络断流重连中", "Stream Disconnected, Reconnecting")
            .replace("429 频控限流退避中", "429 Rate Limited")
        )

    cp = str(s.get("current_phase") or "")
    cp_map = {
        "待命中": "Idle",
        "待命 (已输出回复)": "Idle (Replied)",
        "等待云端响应": "Waiting for Model",
        "模型输出中": "Streaming Output",
        "已接收用户输入": "User Input Received",
        "异常拦截": "Error Intercepted",
    }
    if cp in cp_map:
        s["current_phase"] = cp_map[cp]
    elif cp.startswith("执行工具 ["):
        s["current_phase"] = "Running Tool [" + cp[len("执行工具 [") :]

    ca = str(s.get("current_action") or "")
    ca_map = {
        "工具执行完毕，等待大模型下发下一步决策...": "Tools finished, awaiting next model step...",
        "正在向大模型提交 Prompt...": "Submitting prompt to model...",
        "遇到异常等待处理": "Error encountered, retrying...",
    }
    if ca in ca_map:
        s["current_action"] = ca_map[ca]
    elif ca == err and s.get("recent_error"):
        s["current_action"] = s["recent_error"]

    for step in s.get("history_steps") or []:
        if not isinstance(step, dict):
            continue
        sm = str(step.get("summary") or "")
        if sm.startswith("调用工具: "):
            step["summary"] = "Tool: " + sm[len("调用工具: ") :]
        elif sm == "输出回复/思考":
            step["summary"] = "Model response / thinking"
        elif sm == "工具执行完毕":
            step["summary"] = "Tool completed"
        elif sm == "工具输出反馈":
            step["summary"] = "Tool output"
        elif sm == "用户输入 Prompt":
            step["summary"] = "User Prompt"
        elif sm.startswith("用户输入: "):
            step["summary"] = "User: " + sm[len("用户输入: ") :]
        elif sm.startswith("错误: "):
            step["summary"] = "Error: " + sm[len("错误: ") :]

    for sub in s.get("subagents") or []:
        _localize_session_dict_en(sub)

def _resolve_model_rates(model_name: str, ctx_tokens: int, now: datetime | None = None) -> tuple[float, float, float]:

    model_lower = (model_name or "").lower()
    ref_now = now or datetime.now()
    if ref_now.tzinfo is not None:
        ref_now = ref_now.astimezone().replace(tzinfo=None)

    if "hydrogen" in model_lower:
        return (1.50, 0.075, 7.50)

    if "neon" in model_lower:
        return (3.00, 0.15, 15.00)

    if "argon" in model_lower or "carbon" in model_lower:
        if ref_now < datetime(2026, 12, 1):
            return (2.00, 0.10, 10.00)
        return (4.00, 0.20, 20.00)

    if "3.8-flash" in model_lower or "3.8_flash" in model_lower:
        if ref_now < datetime(2027, 1, 1):
            return (0.75, 0.075, 3.75)
        return (1.50, 0.15, 7.50)

    if "claude" in model_lower:
        if "5-5" in model_lower or "5.5" in model_lower:
            return (4.00, 0.20, 20.00) if "opus" in model_lower else (2.00, 0.10, 10.00)
        if "opus" in model_lower:
            return (5.00, 0.50, 25.00)
        return (3.00, 0.30, 15.00)

    if "gpt-oss" in model_lower:
        return (0.09, 0.009, 0.36)

    if "gpt-4" in model_lower or "o1" in model_lower:
        return (2.50, 1.25, 10.00)

    if "pro" in model_lower or "orchestrator" in model_lower:
        if ctx_tokens > 200_000:
            return (2.50, 0.25, 15.00)
        return (1.25, 0.125, 10.00)

    return (0.30, 0.03, 2.50)

def calculate_step_cost(
    model_name: str,
    in_tokens: int,
    cache_tokens: int,
    out_tokens: int,
    now: datetime | None = None,
) -> float:

    ctx_tokens = in_tokens + cache_tokens
    price_in, price_cache, price_out = _resolve_model_rates(model_name, ctx_tokens, now=now)
    return (in_tokens * price_in + cache_tokens * price_cache + out_tokens * price_out) / 1_000_000.0

def fmt_cost(cost_usd: float) -> str:

    if cost_usd <= 0:
        return "$0.00"
    if cost_usd < 0.01:
        return f"${cost_usd:.3f}"
    return f"${cost_usd:.2f}"

def fmt_hms_units(seconds: float) -> str:

    if seconds <= 0:
        return "0s"
    s = int(seconds)
    h = s // 3600
    m = (s % 3600) // 60
    sec = s % 60
    if h > 0:
        return f"{h}h{m}m{sec}s"
    if m > 0:
        return f"{m}m{sec}s"
    return f"{sec}s"

def parse_iso_dt(s: str) -> datetime:
    if not s:
        return datetime.now(timezone.utc)
    s = s.replace("Z", "+00:00")
    try:
        return datetime.fromisoformat(s)
    except Exception:
        return datetime.now(timezone.utc)

def _query_session_model_from_db(db_path: str) -> str:

    try:
        conn = connect_sqlite_ro(db_path)
        cur = conn.cursor()

        cur.execute("SELECT data FROM gen_metadata WHERE length(data) < 25000 ORDER BY idx DESC LIMIT 8")
        candidates = []
        for (data,) in cur.fetchall():
            if isinstance(data, str):
                data = data.encode("latin1", errors="ignore")
            matches = re.findall(rb"(gemini-[\w\.\-]+|claude-[\w\.\-]+|gpt-[\w\.\-]+|[\w\.\-]*(?:argon|carbon)[\w\.\-]*)", data)
            for item in matches:
                s = item.decode("latin1")
                if s not in candidates:
                    candidates.append(s)
        conn.close()

        for c in candidates:
            if c.endswith("-n") or "-tiered" in c:
                return c
        for c in candidates:
            if not any(x in c for x in ("-medium", "-low", "-high")):
                return c
        if candidates:
            return candidates[0]
    except Exception:
        pass
    return "-"

def get_session_model(
    uuid: str,
    conversations_dir: str | None = None,
    _inspect_cache: dict | None = None,
    _cache_dirty: list[bool] | None = None,
) -> str:

    conv_dir = conversations_dir or CONVERSATIONS_DIR
    db_path = os.path.abspath(os.path.join(conv_dir, f"{uuid}.db"))
    fp = _db_fingerprint(db_path)
    if fp is None:
        return "-"

    if _is_cache_disabled():
        return _query_session_model_from_db(db_path)

    standalone = _inspect_cache is None
    if standalone:
        cache, resolved_path, needs_rebuild = _get_inspect_cache()
        dirty = [needs_rebuild]
    else:
        cache = _inspect_cache
        resolved_path = ""
        dirty = _cache_dirty if _cache_dirty is not None else [False]

    models_map = cache.setdefault("models", {})
    cached = models_map.get(db_path)
    if isinstance(cached, dict) and cached.get("fp") == fp:
        return str(cached.get("model") or "-")

    model = _query_session_model_from_db(db_path)
    models_map[db_path] = {"fp": fp, "model": model}
    dirty[0] = True

    if standalone and dirty[0]:
        _save_inspect_cache(resolved_path, cache)
    return model

def extract_recent_steps(parsed_steps: list, limit: int = 12) -> list:

    history = []
    for i in range(max(0, len(parsed_steps) - limit), len(parsed_steps)):
        st = parsed_steps[i]
        st_idx = st.get("step_index", i + 1)
        st_type = st.get("type", "UNKNOWN")
        created_raw = st.get("created_at", "")
        st_time = created_raw[11:19] if len(created_raw) >= 19 else created_raw
        st_summary = ""
        if st_type == "PLANNER_RESPONSE":
            tcs = st.get("tool_calls", [])
            if tcs:
                first_tc = tcs[0] if isinstance(tcs[0], dict) else {}
                cname = first_tc.get("name", "tool")
                args = first_tc.get("args", {}) if isinstance(first_tc.get("args"), dict) else {}
                detail = args.get("toolSummary") or args.get("toolAction") or args.get("CommandLine") or ""
                if detail:
                    st_summary = f"调用工具: {cname} ({str(detail)[:36]})"
                else:
                    st_summary = f"调用工具: {cname}"
            else:
                st_summary = "输出回复/思考"
        elif st_type == "GENERIC":
            c = st.get("content", "")
            if "Completed At:" in c:
                st_summary = "工具执行完毕"
            else:
                st_summary = "工具输出反馈"
        elif st_type == "USER_INPUT":
            c = (st.get("content") or "").strip().replace("\n", " ")
            st_summary = f"用户输入: {c[:36]}" if c else "用户输入 Prompt"
        elif st_type == "ERROR_MESSAGE":
            st_summary = f"错误: {str(st.get('error', ''))[:40]}"
        else:
            st_summary = st_type
        history.append({
            "index": st_idx,
            "type": st_type,
            "time": st_time,
            "summary": st_summary
        })
    return history

def _read_subagent_descriptors(brain_dir: str, parent_uuid: str) -> dict[str, dict]:

    sub_dir = os.path.join(brain_dir, parent_uuid, ".system_generated", "subagents")
    descriptors: dict[str, dict] = {}
    if not os.path.isdir(sub_dir):
        return descriptors
    cache_disabled = _is_cache_disabled()
    fp: tuple | None = None
    if not cache_disabled:
        try:
            dir_st = os.stat(sub_dir)
            json_entries: list[tuple[str, int, int]] = []
            with os.scandir(sub_dir) as it:
                for entry in it:
                    if not entry.name.endswith(".json"):
                        continue
                    est = entry.stat()
                    json_entries.append((entry.name, est.st_mtime_ns, est.st_size))
            json_entries.sort()
            fp = (dir_st.st_mtime_ns, tuple(json_entries))
            cached = _DESCRIPTOR_MEM_CACHE.get(sub_dir)
            if cached is not None and cached[0] == fp:
                return dict(cached[1])
        except OSError:
            fp = None
    try:
        for fn in os.listdir(sub_dir):
            if not fn.endswith(".json"):
                continue
            fpath = os.path.join(sub_dir, fn)
            with open(fpath, "r", encoding="utf-8", errors="ignore") as f:
                data = json.load(f)
            cid = str(data.get("conversationId") or os.path.splitext(fn)[0]).strip()
            if not cid:
                continue
            desc = data.get("subagentDescriptor") or {}
            descriptors[cid] = {
                "type_name": str(desc.get("typeName") or "").strip(),
                "role": str(desc.get("role") or "").strip(),
                "state": str(data.get("state") or "").strip(),
            }
    except Exception:
        pass
    if not cache_disabled and fp is not None:
        _DESCRIPTOR_MEM_CACHE[sub_dir] = (fp, dict(descriptors))
    return descriptors

def _get_summary_columns(conn: sqlite3.Connection) -> set[str]:

    try:
        return {r[1] for r in conn.execute("PRAGMA table_info(conversation_summaries)").fetchall()}
    except Exception:
        return set()

def _resolve_root_parent(uuid: str, parent_map: dict[str, str]) -> str:

    curr = uuid
    visited = {curr}
    while True:
        pid = parent_map.get(curr, "")
        if not pid or pid in visited:
            break
        visited.add(pid)
        curr = pid
    return curr

def _parse_session_transcript_static(
    target_path: str,
    session_model: str,
    now_dt: datetime | None = None,
) -> dict:

    all_steps = []
    try:
        with open(target_path, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                line_str = line.strip()
                if not line_str:
                    continue
                try:
                    all_steps.append(json.loads(line_str))
                except Exception:
                    continue
    except Exception:
        pass

    if not all_steps:
        return {"empty": True}

    interactions = sum(1 for st in all_steps if st.get("type") == "PLANNER_RESPONSE")

    tot_active = 0.0
    tot_local = 0.0
    tot_err = 0.0
    tot_consumed = 0
    tot_cost_usd = 0.0
    tot_cache_consumed = 0
    tot_input_consumed = 0
    tot_output_consumed = 0
    recent_gen_samples: list[tuple[int, float]] = []

    step_times = []
    last_dt = None
    for s in all_steps:
        dt = parse_iso_dt(s.get("created_at", ""))
        if last_dt is not None and dt < last_dt:
            dt = last_dt
        else:
            last_dt = dt
        step_times.append(dt)

    for i in range(len(all_steps)):
        curr_s = all_steps[i]
        if curr_s.get("type") == "PLANNER_RESPONSE":
            in_t = curr_s.get("input_tokens") or 0
            cache_t = curr_s.get("cache_read_tokens") or 0
            out_t = curr_s.get("output_tokens") or 0
            tot_consumed += in_t + cache_t + out_t
            tot_cache_consumed += cache_t
            tot_input_consumed += in_t
            tot_output_consumed += out_t
            tot_cost_usd += calculate_step_cost(session_model, in_t, cache_t, out_t, now=now_dt)

        if i == 0:
            continue
        prev_s = all_steps[i - 1]

        t1 = step_times[i - 1]
        t2 = step_times[i]
        step_gap = max(0.0, (t2 - t1).total_seconds())

        is_idle_wait = (
            (prev_s.get("type") == "PLANNER_RESPONSE" and not prev_s.get("tool_calls"))
            or (prev_s.get("type") == "ERROR_MESSAGE" and curr_s.get("type") in ("USER_INPUT", "SYSTEM_MESSAGE"))
        )
        if not is_idle_wait:
            tot_active += step_gap

        if (
            curr_s.get("type") == "PLANNER_RESPONSE"
            and (curr_s.get("output_tokens") or 0) > 0
            and prev_s.get("type") in ("USER_INPUT", "GENERIC", "SYSTEM_MESSAGE")
            and 0.05 <= step_gap <= 180.0
        ):
            step_out = int(curr_s.get("output_tokens") or 0)

            if (step_out / step_gap) <= 500.0:
                recent_gen_samples.append((step_out, step_gap))

        if curr_s.get("type") == "GENERIC" and curr_s.get("content"):
            c = curr_s.get("content")
            m1 = re.search(r"Created At: (\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+\-]\d{2}:\d{2})", c)
            m2 = re.search(r"Completed At: (\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+\-]\d{2}:\d{2})", c)
            if m1 and m2:
                try:
                    dt1 = datetime.fromisoformat(m1.group(1))
                    dt2 = datetime.fromisoformat(m2.group(1))
                    tot_local += max(0.0, (dt2 - dt1).total_seconds())
                except Exception:
                    pass

        if curr_s.get("type") == "ERROR_MESSAGE":
            tot_err += step_gap

    tot_remote = max(0.0, tot_active - tot_local - tot_err)

    if recent_gen_samples:
        tail_samples = recent_gen_samples[-5:]
        sample_out = sum(x[0] for x in tail_samples)
        sample_dur = sum(x[1] for x in tail_samples)
        tps = round(sample_out / sample_dur, 1) if sample_dur > 0 else 0.0
    elif tot_remote > 0 and tot_output_consumed > 0:
        tps = round(tot_output_consumed / tot_remote, 1)
    else:
        tps = 0.0

    local_str = format_duration(tot_local)
    remote_str = format_duration(tot_remote)
    active_str = format_duration(tot_active)
    breakdown_str = f"{active_str} (本地: {local_str} | 云端: {remote_str})"
    compact_time_str = (
        f"{fmt_hms_units(tot_active)} (本地 {fmt_hms_units(tot_local)} | 云端 {fmt_hms_units(tot_remote)})"
        if tot_active > 0
        else "-"
    )

    recent_error = None
    error_code = None

    for step in reversed(all_steps[-10:]):
        if step.get("type") == "PLANNER_RESPONSE" and (step.get("output_tokens") or 0) > 0:
            break
        err = step.get("error")
        if err:
            err_str = str(err)
            if "503" in err_str or "No capacity" in err_str:
                recent_error = "🔴 503 云端算力不足排队中"
                error_code = "503"
                break
            elif "EOF" in err_str or "stream" in err_str:
                recent_error = "⚠️ 网络断流重连中"
                error_code = "EOF"
                break
            elif "429" in err_str or "ResourceExhausted" in err_str:
                recent_error = "⚠️ 429 频控限流退避中"
                error_code = "429"
                break

    input_tokens = 0
    cache_tokens = 0
    output_tokens = 0
    context_tokens = 0
    cache_pct = 0.0
    for step in reversed(all_steps):
        if step.get("type") == "PLANNER_RESPONSE":
            in_t = step.get("input_tokens") or 0
            cache_t = step.get("cache_read_tokens") or 0
            out_t = step.get("output_tokens") or 0
            if in_t or cache_t or out_t:
                input_tokens = in_t
                cache_tokens = cache_t
                output_tokens = out_t
                ctx_tot = in_t + cache_t
                context_tokens = ctx_tot
                cache_pct = round((cache_t / ctx_tot * 100.0), 1) if ctx_tot > 0 else 0.0
                break

    last_step = all_steps[-1]
    last_type = last_step.get("type")
    last_step_created_at = str(last_step.get("created_at") or "")
    current_phase = "待命中"
    current_action = ""
    uses_stall = False

    if last_type == "GENERIC":
        current_phase = "等待云端响应"
        current_action = "工具执行完毕，等待大模型下发下一步决策..."
        uses_stall = True
    elif last_type == "PLANNER_RESPONSE":
        tcs = last_step.get("tool_calls", [])
        if tcs:
            tc = tcs[0]
            name = tc.get("name", "tool") if isinstance(tc, dict) else "tool"
            args = tc.get("args", {}) if isinstance(tc, dict) else {}
            summary = args.get("toolSummary") or args.get("toolAction") or args.get("CommandLine") or ""
            current_phase = f"执行工具 [{name}]"
            current_action = f"{name}: {str(summary)[:60]}"
            uses_stall = True
        else:
            c = last_step.get("content", "")
            if c:
                current_phase = "待命 (已输出回复)"
                current_action = c.strip()[-60:].replace("\n", " ")
                uses_stall = False
            else:
                current_phase = "模型输出中"
                uses_stall = True
    elif last_type == "USER_INPUT":
        current_phase = "已接收用户输入"
        current_action = "正在向大模型提交 Prompt..."
        uses_stall = True
    elif last_type == "ERROR_MESSAGE":
        current_phase = "异常拦截"
        current_action = recent_error or "遇到异常等待处理"
        uses_stall = True

    return {
        "empty": False,
        "interactions": interactions,
        "input_tokens": input_tokens,
        "cache_tokens": cache_tokens,
        "output_tokens": output_tokens,
        "context_tokens": context_tokens,
        "cache_pct": cache_pct,
        "tps": tps,
        "total_tokens_consumed": tot_consumed,
        "total_cost_usd": round(tot_cost_usd, 6),
        "total_cache_consumed": tot_cache_consumed,
        "total_input_consumed": tot_input_consumed,
        "total_output_consumed": tot_output_consumed,
        "error_code": error_code,
        "current_phase": current_phase,
        "current_action": current_action,
        "recent_error": recent_error,
        "total_active_sec": round(tot_active, 2),
        "total_local_sec": round(tot_local, 2),
        "total_remote_sec": round(tot_remote, 2),
        "total_error_sec": round(tot_err, 2),
        "local_pct": round((tot_local / tot_active * 100.0), 1) if tot_active > 0 else 0.0,
        "remote_pct": round((tot_remote / tot_active * 100.0), 1) if tot_active > 0 else 0.0,
        "breakdown_str": breakdown_str,
        "compact_time_str": compact_time_str,
        "uses_stall": uses_stall,
        "last_step_created_at": last_step_created_at,
        "history_steps": extract_recent_steps(all_steps, limit=12),
    }

def _apply_dynamic_session_fields(res: dict, static_data: dict, brief: bool, now_utc: datetime) -> None:

    for k in (
        "interactions",
        "input_tokens",
        "cache_tokens",
        "output_tokens",
        "context_tokens",
        "cache_pct",
        "tps",
        "total_tokens_consumed",
        "total_cost_usd",
        "total_cache_consumed",
        "total_input_consumed",
        "total_output_consumed",
        "error_code",
        "current_phase",
        "current_action",
        "recent_error",
        "total_active_sec",
        "total_local_sec",
        "total_remote_sec",
        "total_error_sec",
        "local_pct",
        "remote_pct",
        "breakdown_str",
        "compact_time_str",
    ):
        res[k] = static_data[k]

    if static_data.get("uses_stall"):
        last_ts = static_data.get("last_step_created_at") or ""
        last_step_time = parse_iso_dt(last_ts) if last_ts else now_utc
        stall_sec = max(0.0, (now_utc - last_step_time).total_seconds())
        res["current_stall"] = round(stall_sec, 1)
    else:
        res["current_stall"] = 0.0

    if res["current_phase"] == "待命 (已输出回复)" and not res["is_running"]:
        res["health"] = "⏸️"
        res["health_code"] = "idle"
        res["health_desc"] = "待命中"
    elif res["recent_error"]:
        if "503" in res["recent_error"]:
            res["health"] = "🔴"
            res["health_code"] = "error_503"
            res["health_desc"] = "503 算力不足排队中"
        elif "断流" in res["recent_error"]:
            res["health"] = "⚠️"
            res["health_code"] = "error_eof"
            res["health_desc"] = "网络断流重连中"
        elif "429" in res["recent_error"]:
            res["health"] = "⚠️"
            res["health_code"] = "error_429"
            res["health_desc"] = "429 限流退避中"
        else:
            res["health"] = "⚠️"
            res["health_code"] = "warning"
            res["health_desc"] = res["recent_error"].replace("⚠️", "").replace("🔴", "").strip()
    else:
        if res["current_stall"] < 30:
            res["health"] = "🟢"
            res["health_code"] = "healthy"
            res["health_desc"] = "畅通"
        elif res["current_stall"] < 90:
            res["health"] = "🟡"
            res["health_code"] = "slow"
            res["health_desc"] = f"稍慢 (长上下文推理 {format_duration(res['current_stall'])})"
        else:
            res["health"] = "🔴"
            res["health_code"] = "stalled"
            res["health_desc"] = f"严重排队 ({format_duration(res['current_stall'])})"

    if not brief:
        res["history_steps"] = [dict(st) for st in (static_data.get("history_steps") or [])]

def _is_cascade_running(status: str | None, not_fully_idle: object = 0) -> bool:
    status_norm = str(status or "").strip().upper()
    if status_norm:
        return "RUNNING" in status_norm
    return bool(not_fully_idle == 1)


def inspect_session(
    uuid: str,
    brief: bool = True,
    db_path: str | None = None,
    brain_dir: str | None = None,
    conversations_dir: str | None = None,
    client_type: str = "app",
    now_dt: datetime | None = None,
    cache_path: str | None = None,
    _inspect_cache: dict | None = None,
    _cache_dirty: list[bool] | None = None,
    _preloaded_summary: tuple | None = None,
    _preloaded_descriptors: dict[str, dict] | None = None,
) -> dict:

    active_db_path = db_path or DB_PATH
    active_brain_dir = brain_dir or BRAIN_DIR
    active_conv_dir = conversations_dir or CONVERSATIONS_DIR
    now_utc = now_dt.astimezone(timezone.utc) if now_dt is not None else datetime.now(timezone.utc)

    if len(uuid) < 32 and os.path.exists(active_brain_dir):
        for d in os.listdir(active_brain_dir):
            if d.startswith(uuid):
                uuid = d
                break

    res = {
        "uuid": uuid,
        "short_id": uuid[:8],
        "client_type": client_type,
        "title": "未知会话",
        "is_running": False,
        "status_label": "IDLE",
        "interactions": 0,
        "input_tokens": 0,
        "cache_tokens": 0,
        "output_tokens": 0,
        "context_tokens": 0,
        "cache_pct": 0.0,
        "tps": 0.0,
        "total_tokens_consumed": 0,
        "total_cost_usd": 0.0,
        "total_cache_consumed": 0,
        "total_input_consumed": 0,
        "total_output_consumed": 0,
        "current_stall": 0.0,
        "health": "🟢",
        "health_code": "healthy",
        "health_desc": "畅通",
        "error_code": None,
        "current_phase": "待命中",
        "current_action": "",
        "recent_error": None,
        "history_steps": [],
        "exists": False,
        "model": "-",
        "parent_conversation_id": "",
        "agent_name": "",
        "agent_role": "",
        "subagents": [],
        "subagent_count": 0,
        "active_subagent_count": 0,
        "active_subagent_tps": 0.0,

        "total_active_sec": 0.0,
        "total_local_sec": 0.0,
        "total_remote_sec": 0.0,
        "total_error_sec": 0.0,
        "local_pct": 0.0,
        "remote_pct": 0.0,
        "breakdown_str": "-",
        "compact_time_str": "-",
    }

    if _preloaded_summary is not None:
        title_v, status_v, idle_flag_v, parent_v, agent_v = _preloaded_summary
        res["title"] = title_v or uuid[:8]
        res["is_running"] = _is_cascade_running(status_v, idle_flag_v)
        res["status_label"] = "RUNNING" if res["is_running"] else (status_v or "IDLE")
        res["parent_conversation_id"] = str(parent_v or "").strip()
        res["agent_name"] = str(agent_v or "").strip()
    elif os.path.exists(active_db_path):

        try:
            conn = connect_sqlite_ro(active_db_path)
            cols = _get_summary_columns(conn)
            cur = conn.cursor()
            parent_expr = "COALESCE(parent_conversation_id, '')" if "parent_conversation_id" in cols else "''"
            agent_expr = "COALESCE(agent_name, '')" if "agent_name" in cols else "''"
            cur.execute(
                f"SELECT title, status, not_fully_idle, {parent_expr}, {agent_expr} FROM conversation_summaries WHERE conversation_id=?",
                (uuid,),
            )
            row = cur.fetchone()
            conn.close()
            if row:
                res["title"] = row[0] or uuid[:8]
                res["is_running"] = _is_cascade_running(row[1], row[2])
                res["status_label"] = "RUNNING" if res["is_running"] else (row[1] or "IDLE")
                res["parent_conversation_id"] = str(row[3] or "").strip()
                res["agent_name"] = str(row[4] or "").strip()
        except Exception:
            pass

    if res["parent_conversation_id"]:
        descs = (
            _preloaded_descriptors
            if _preloaded_descriptors is not None
            else _read_subagent_descriptors(active_brain_dir, res["parent_conversation_id"])
        )
        info = descs.get(uuid)
        if info:
            res["agent_role"] = info.get("role", "")
            if not res["agent_name"]:
                res["agent_name"] = info.get("type_name", "")

    log_full_path = os.path.join(active_brain_dir, uuid, ".system_generated", "logs", "transcript_full.jsonl")
    log_path = os.path.join(active_brain_dir, uuid, ".system_generated", "logs", "transcript.jsonl")
    target_path = os.path.abspath(log_full_path if os.path.exists(log_full_path) else log_path)

    tf_sig = _file_stat_sig(target_path)
    if tf_sig is None:
        return res

    res["exists"] = True

    if _is_cache_disabled():
        session_model = get_session_model(uuid, conversations_dir=active_conv_dir)
        res["model"] = session_model
        static_data = _parse_session_transcript_static(target_path, session_model, now_dt=now_dt)
        if static_data.get("empty"):
            return res
        _apply_dynamic_session_fields(res, static_data, brief=brief, now_utc=now_utc)
        return res

    standalone = _inspect_cache is None
    if standalone:
        cache, resolved_cache_path, needs_rebuild = _get_inspect_cache(cache_path)
        dirty = [needs_rebuild]
    else:
        cache = _inspect_cache
        resolved_cache_path = ""
        dirty = _cache_dirty if _cache_dirty is not None else [False]

    session_model = get_session_model(
        uuid,
        conversations_dir=active_conv_dir,
        _inspect_cache=cache,
        _cache_dirty=dirty,
    )
    res["model"] = session_model

    rate_regime = _get_rate_regime(now_dt)
    tf_mtime_ns, tf_size = tf_sig
    sessions_cache = cache.setdefault("sessions", {})
    cached_entry = sessions_cache.get(target_path)
    if (
        isinstance(cached_entry, dict)
        and cached_entry.get("mtime_ns") == tf_mtime_ns
        and cached_entry.get("size") == tf_size
        and cached_entry.get("model") == session_model
        and cached_entry.get("rate_regime") == rate_regime
        and isinstance(cached_entry.get("static"), dict)
    ):
        static_data = cached_entry["static"]
    else:
        static_data = _parse_session_transcript_static(target_path, session_model, now_dt=now_dt)
        sessions_cache[target_path] = {
            "mtime_ns": tf_mtime_ns,
            "size": tf_size,
            "model": session_model,
            "rate_regime": rate_regime,
            "static": static_data,
        }
        dirty[0] = True

    if standalone and dirty[0]:
        _save_inspect_cache(resolved_cache_path, cache)

    if static_data.get("empty"):
        return res

    _apply_dynamic_session_fields(res, static_data, brief=brief, now_utc=now_utc)
    return res

def _group_sessions_tree(raw_sessions: list[dict], limit: int) -> list[dict]:

    by_id: dict[str, dict] = {s["uuid"]: s for s in raw_sessions}
    parent_map: dict[str, str] = {
        s["uuid"]: str(s.get("parent_conversation_id") or "").strip()
        for s in raw_sessions
    }

    for s in raw_sessions:
        s["subagents"] = []
        s["subagent_count"] = 0
        s["active_subagent_count"] = 0
        s["active_subagent_tps"] = 0.0

    roots: list[dict] = []
    children_by_root: dict[str, list[dict]] = {}
    for s in raw_sessions:
        uid = s["uuid"]
        direct_parent = parent_map.get(uid, "")
        if not direct_parent:
            roots.append(s)
            continue
        root_id = _resolve_root_parent(uid, parent_map)
        if root_id != uid and root_id in by_id:
            children_by_root.setdefault(root_id, []).append(s)
        elif s.get("is_running"):

            roots.append(s)

    for r in roots:
        uid = r["uuid"]
        raw_children = children_by_root.get(uid, [])
        valid_children = [c for c in raw_children if c.get("exists") or c.get("is_running")]
        valid_children.sort(
            key=lambda x: (1 if x.get("is_running") else 0, x.get("_last_modified_time", "")),
            reverse=True,
        )
        active_children = [c for c in valid_children if c.get("is_running")]
        r["subagents"] = valid_children
        r["subagent_count"] = len(valid_children)
        r["active_subagent_count"] = len(active_children)
        r["active_subagent_tps"] = round(sum(float(c.get("tps", 0.0) or 0.0) for c in active_children), 1)

        child_times = [c.get("_last_modified_time", "") for c in valid_children if c.get("_last_modified_time")]
        r["_effective_mod_time"] = max([r.get("_last_modified_time", ""), *child_times])

    roots.sort(
        key=lambda x: (
            1 if (x.get("is_running") or x.get("active_subagent_count", 0) > 0) else 0,
            x.get("_effective_mod_time", x.get("_last_modified_time", "")),
        ),
        reverse=True,
    )
    return roots[:limit]

def _load_conversations_from_dir(
    base_dir: str,
    include_steps: bool = False,
    limit: int = 15,
    client_type: str = "app",
    return_raw: bool = False,
    now_dt: datetime | None = None,
    _inspect_cache: dict | None = None,
    _cache_dirty: list[bool] | None = None,
) -> list:

    db_path = os.path.join(base_dir, "conversation_summaries.db")
    brain_dir = os.path.join(base_dir, "brain")
    conv_dir = os.path.join(base_dir, "conversations")

    if not os.path.exists(db_path):
        return []

    try:
        conn = connect_sqlite_ro(db_path)
        cols = _get_summary_columns(conn)
        cur = conn.cursor()
        has_parent = "parent_conversation_id" in cols
        has_depth = "nesting_depth" in cols
        has_agent = "agent_name" in cols
        parent_expr = "COALESCE(parent_conversation_id, '')" if has_parent else "''"
        depth_expr = "COALESCE(nesting_depth, 0)" if has_depth else "0"
        agent_expr = "COALESCE(agent_name, '')" if has_agent else "''"

        if has_parent:

            top_cond = "COALESCE(parent_conversation_id, '') = ''" + (" AND COALESCE(nesting_depth, 0) = 0" if has_depth else "")
            cur.execute(
                f"""
                SELECT conversation_id, title, status, not_fully_idle, last_modified_time, {parent_expr}, {agent_expr}
                FROM conversation_summaries
                WHERE {top_cond}
                ORDER BY not_fully_idle DESC, last_modified_time DESC
                LIMIT ?
                """,
                (limit,),
            )
            top_rows = cur.fetchall()
            rows_by_id = {r[0]: r for r in top_rows}

            cur.execute(
                f"""
                SELECT conversation_id, title, status, not_fully_idle, last_modified_time, {parent_expr}, {agent_expr}
                FROM conversation_summaries
                WHERE COALESCE(parent_conversation_id, '') != '' {"OR COALESCE(nesting_depth, 0) > 0" if has_depth else ""}
                ORDER BY not_fully_idle DESC, last_modified_time DESC
                LIMIT 300
                """
            )
            child_rows = cur.fetchall()
            missing_active_parents = set()
            for r in child_rows:
                cid, _, status, idle_flag, _, pid, _ = r
                rows_by_id.setdefault(cid, r)
                is_child_running = _is_cascade_running(status, idle_flag)
                if is_child_running and pid and pid not in rows_by_id:
                    missing_active_parents.add(pid)

            while missing_active_parents:
                placeholders = ",".join("?" for _ in missing_active_parents)
                cur.execute(
                    f"""
                    SELECT conversation_id, title, status, not_fully_idle, last_modified_time, {parent_expr}, {agent_expr}
                    FROM conversation_summaries
                    WHERE conversation_id IN ({placeholders})
                    """,
                    tuple(missing_active_parents),
                )
                fetched = cur.fetchall()
                missing_active_parents.clear()
                for r in fetched:
                    rows_by_id.setdefault(r[0], r)
                    pid = str(r[5] or "").strip()
                    if pid and pid not in rows_by_id:
                        missing_active_parents.add(pid)

            rows = list(rows_by_id.values())
        else:
            cur.execute(
                """
                SELECT conversation_id, title, status, not_fully_idle, last_modified_time, '' AS parent_id, '' AS agent_name
                FROM conversation_summaries
                ORDER BY not_fully_idle DESC, last_modified_time DESC
                LIMIT ?
                """,
                (limit,),
            )
            rows = cur.fetchall()
        conn.close()
    except Exception:
        return []

    descriptor_cache: dict[str, dict[str, dict]] = {}
    root_ids = {r[0] for r in rows if not str(r[5] or "").strip()}
    for rid in root_ids:
        descriptor_cache[rid] = _read_subagent_descriptors(brain_dir, rid)

    cache_disabled = _is_cache_disabled()
    standalone_cache = (not cache_disabled) and (_inspect_cache is None)
    if standalone_cache:
        cache_obj, resolved_cache_path, needs_rebuild = _get_inspect_cache()
        dirty = [needs_rebuild]
    else:
        cache_obj = _inspect_cache
        resolved_cache_path = ""
        dirty = _cache_dirty if _cache_dirty is not None else [False]

    sessions = []
    for r in rows:
        cid, title, status, idle_flag, mod_time, parent_id, agent_name = r
        parent_id_clean = str(parent_id or "").strip()

        if not parent_id_clean:
            for cand_root, descs in descriptor_cache.items():
                if cid in descs:
                    parent_id_clean = cand_root
                    break

        descs_for_parent: dict[str, dict] = {}
        if parent_id_clean:
            descs = descriptor_cache.get(parent_id_clean)
            if descs is None:
                descs = _read_subagent_descriptors(brain_dir, parent_id_clean)
                descriptor_cache[parent_id_clean] = descs
            descs_for_parent = descs

        is_run = _is_cascade_running(status, idle_flag)
        s_data = inspect_session(
            cid,
            brief=(not include_steps),
            db_path=db_path,
            brain_dir=brain_dir,
            conversations_dir=conv_dir,
            client_type=client_type,
            now_dt=now_dt,
            _inspect_cache=cache_obj,
            _cache_dirty=dirty,
            _preloaded_summary=(title, status, idle_flag, parent_id_clean, agent_name),
            _preloaded_descriptors=descs_for_parent,
        )
        s_data["title"] = title or cid[:8]
        s_data["is_running"] = is_run
        s_data["status_label"] = "RUNNING" if is_run else (status or "IDLE")
        s_data["parent_conversation_id"] = parent_id_clean
        s_data["agent_name"] = str(agent_name or "").strip() or s_data.get("agent_name", "")
        if parent_id_clean:
            info = descs_for_parent.get(cid)
            if info:
                s_data["agent_role"] = info.get("role", "")
                if not s_data["agent_name"]:
                    s_data["agent_name"] = info.get("type_name", "")
        s_data["_last_modified_time"] = str(mod_time or "")
        if is_run and s_data["health"] == "⏸️":
            s_data["health"] = "🟢"
            s_data["health_code"] = "healthy"
            s_data["health_desc"] = "活跃处理中"
        sessions.append(s_data)

    if standalone_cache and dirty[0] and cache_obj is not None:
        _save_inspect_cache(resolved_cache_path, cache_obj)

    if return_raw:
        return sessions
    return _group_sessions_tree(sessions, limit=limit)

def _strip_internal_time_keys(sessions: list[dict]) -> None:

    for s in sessions:
        s.pop("_last_modified_time", None)
        s.pop("_effective_mod_time", None)
        if s.get("subagents"):
            _strip_internal_time_keys(s["subagents"])

def load_conversations(
    include_steps: bool = False,
    data_dir: str | None = None,
    limit: int = 15,
    include_cli: bool = True,
    now_dt: datetime | None = None,
) -> list:

    base_dir = os.path.expanduser(data_dir) if data_dir else DEFAULT_GEMINI_DIR
    is_cli_only = "antigravity-cli" in os.path.basename(base_dir)
    primary_type = "cli" if is_cli_only else "app"

    cache_disabled = _is_cache_disabled()
    cache_obj: dict | None = None
    resolved_cache_path = ""
    dirty = [False]
    if not cache_disabled:
        cache_obj, resolved_cache_path, needs_rebuild = _get_inspect_cache()
        dirty[0] = needs_rebuild

    cli_dir_norm = os.path.normpath(DEFAULT_CLI_DIR)
    base_dir_norm = os.path.normpath(base_dir)
    if include_cli and not is_cli_only and base_dir_norm == os.path.normpath(DEFAULT_GEMINI_DIR) and os.path.exists(cli_dir_norm):
        raw_app = _load_conversations_from_dir(
            base_dir,
            include_steps=include_steps,
            limit=limit,
            client_type=primary_type,
            return_raw=True,
            now_dt=now_dt,
            _inspect_cache=cache_obj,
            _cache_dirty=dirty,
        )
        raw_cli = _load_conversations_from_dir(
            cli_dir_norm,
            include_steps=include_steps,
            limit=limit,
            client_type="cli",
            return_raw=True,
            now_dt=now_dt,
            _inspect_cache=cache_obj,
            _cache_dirty=dirty,
        )
        by_uuid: dict[str, dict] = {}
        for s in raw_app + raw_cli:
            uid = s["uuid"]
            prev = by_uuid.get(uid)

            if prev is None or (s.get("exists") and not prev.get("exists")):
                by_uuid[uid] = s
        sessions = _group_sessions_tree(list(by_uuid.values()), limit=limit)
    else:
        sessions = _load_conversations_from_dir(
            base_dir,
            include_steps=include_steps,
            limit=limit,
            client_type=primary_type,
            now_dt=now_dt,
            _inspect_cache=cache_obj,
            _cache_dirty=dirty,
        )

    if not cache_disabled and dirty[0] and cache_obj is not None:
        _save_inspect_cache(resolved_cache_path, cache_obj)

    _strip_internal_time_keys(sessions)
    return sessions

_MODEL_BYTES_RE = re.compile(rb"(gemini-[\w\.\-]+|claude-[\w\.\-]+|gpt-[\w\.\-]+|[\w\.\-]*(?:argon|carbon|neon)[\w\.\-]*)")
_TRAILING_EFFORT_SUFFIX_RE = re.compile(r"(?:-tiered|-xhigh|-medium|-high|-low|-fast|-trial|-n|-q)+$")
_MODEL_DISPLAY_NAMES = {
    "gemini-4-hydrogen": "Gemini 4 Hydrogen",
    "gemini-4-neon": "Gemini 4 Neon",
    "gemini-4-argon": "Gemini 4 Argon",
    "gemini-4-carbon": "Gemini 4 Carbon",
    "gemini-3.8-flash": "Gemini 3.8 Flash",
    "gemini-3-flash": "Gemini 3 Flash",
    "gemini-3-pro": "Gemini 3 Pro",
    "gemini-2.5-pro": "Gemini 2.5 Pro",
    "gemini-2.5-flash": "Gemini 2.5 Flash",
    "gemini-flash-worker-agy": "Gemini Flash Worker",
    "gemini-pro-orchestrator-g1-pro": "Gemini Pro Orchestrator",
    "claude-sonnet-5-5": "Claude Sonnet 5.5",
    "claude-opus-5-5": "Claude Opus 5.5",
    "claude-sonnet-4-6": "Claude Sonnet 4.6",
    "claude-opus-4-6": "Claude Opus 4.6",
    "claude-opus-4-6-thinking": "Claude Opus 4.6 (Thinking)",
    "gpt-oss-120b": "GPT-OSS 120B",
    "unknown": "Other / Unknown",
}

def normalize_model_key(raw_model: str) -> str:

    cleaned = (raw_model or "").strip().lower()
    if not cleaned or cleaned == "-":
        return "unknown"
    stripped = _TRAILING_EFFORT_SUFFIX_RE.sub("", cleaned)
    return stripped or cleaned

def format_model_display_name(model_key: str) -> str:

    key = (model_key or "").strip().lower()
    if not key or key == "unknown":
        return "Other / Unknown"
    if key in _MODEL_DISPLAY_NAMES:
        return _MODEL_DISPLAY_NAMES[key]
    parts = key.split("-")
    formatted = []
    i = 0
    while i < len(parts):
        p = parts[i]

        if p.isdigit() and i + 1 < len(parts) and parts[i + 1].isdigit():
            formatted.append(f"{p}.{parts[i + 1]}")
            i += 2
            continue
        if p in ("gpt", "oss"):
            formatted.append(p.upper())
        elif p.endswith("b") and p[:-1].isdigit():
            formatted.append(p.upper())
        else:
            formatted.append(p.capitalize())
        i += 1
    return " ".join(formatted)

def _extract_ordered_gen_models(db_path: str) -> list[str]:

    if not db_path or not os.path.exists(db_path):
        return []
    models: list[str] = []
    try:
        conn = connect_sqlite_ro(db_path)
        rows = conn.execute("SELECT data FROM gen_metadata ORDER BY idx ASC").fetchall()
        conn.close()
        for (data,) in rows:
            if isinstance(data, str):
                data = data.encode("latin1", errors="ignore")
            matches = [m.decode("latin1") for m in _MODEL_BYTES_RE.findall(data or b"")]
            picked = ""
            for m in matches:
                if m.endswith("-n") or "-tiered" in m:
                    picked = m
                    break
            if not picked and matches:
                picked = matches[0]
            if picked:
                models.append(picked)
    except Exception:
        return []
    return models

def _match_planner_step_models(planner_count: int, gm_models: list[str], fallback_model: str) -> list[str]:

    if planner_count <= 0:
        return []
    fb = fallback_model if fallback_model and fallback_model != "-" else "unknown"
    if not gm_models:
        return [fb] * planner_count
    trimmed = gm_models
    if len(trimmed) == planner_count + 1 and trimmed[-1] == "gemini-3.8-flash-low":
        trimmed = trimmed[:-1]
    if len(trimmed) == planner_count:
        return list(trimmed)
    n_gm = len(trimmed)
    return [trimmed[min(n_gm - 1, int(i * n_gm / planner_count))] for i in range(planner_count)]

def _merge_stat_bucket(target: dict[str, list], key: str, cost: float, inp: int, cache: int, out: int, calls: int) -> None:

    cur = target.get(key)
    if cur is None:
        target[key] = [cost, inp, cache, out, calls]
    else:
        cur[0] += cost
        cur[1] += inp
        cur[2] += cache
        cur[3] += out
        cur[4] += calls

def _parse_transcript_usage_entry(tf_path: str, db_path: str) -> dict:

    planner_steps = []
    try:
        with open(tf_path, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                if not line.strip() or "PLANNER_RESPONSE" not in line:
                    continue
                try:
                    st = json.loads(line)
                except Exception:
                    continue
                if st.get("type") == "PLANNER_RESPONSE":
                    planner_steps.append(st)
    except Exception:
        return {"days": {}, "hours": {}}

    if not planner_steps:
        return {"days": {}, "hours": {}}

    gm_models = _extract_ordered_gen_models(db_path)
    fallback_model = gm_models[0] if gm_models else "unknown"
    step_models = _match_planner_step_models(len(planner_steps), gm_models, fallback_model)

    days_map: dict[str, dict[str, list]] = {}
    hours_map: dict[str, dict[str, dict[str, list]]] = {}

    for st, raw_model in zip(planner_steps, step_models):
        in_t = int(st.get("input_tokens") or 0)
        cache_t = int(st.get("cache_read_tokens") or 0)
        out_t = int(st.get("output_tokens") or 0)
        if in_t + cache_t + out_t <= 0:
            continue
        created_at = st.get("created_at") or ""
        if not created_at:
            continue
        local_dt = parse_iso_dt(created_at).astimezone()
        date_str = local_dt.strftime("%Y-%m-%d")
        hour_str = str(local_dt.hour)
        cost = calculate_step_cost(raw_model, in_t, cache_t, out_t)
        mkey = normalize_model_key(raw_model)

        day_bucket = days_map.setdefault(date_str, {})
        _merge_stat_bucket(day_bucket, mkey, cost, in_t, cache_t, out_t, 1)

        day_hours = hours_map.setdefault(date_str, {})
        hr_bucket = day_hours.setdefault(hour_str, {})
        _merge_stat_bucket(hr_bucket, mkey, cost, in_t, cache_t, out_t, 1)

    return {"days": days_map, "hours": hours_map}

def _resolve_usage_cache_path(cache_path: object = _UNSET) -> str | None:

    if cache_path is not _UNSET:
        return cache_path
    env_path = os.environ.get("AGYHUB_USAGE_CACHE_PATH", "").strip()
    return os.path.expanduser(env_path) if env_path else DEFAULT_USAGE_CACHE_PATH

def _load_usage_cache(cache_path: str | None) -> dict:

    if not cache_path:
        return {"version": 4, "entries": {}}
    disk_sig = _file_stat_sig(cache_path)
    if disk_sig is None:
        return {"version": 4, "entries": {}}
    if not _is_cache_disabled():
        mem_entry = _USAGE_MEM_CACHE.get(cache_path)
        if mem_entry is not None and mem_entry.get("disk_sig") == disk_sig:
            return mem_entry["data"]
    try:
        with open(cache_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        if isinstance(data, dict) and data.get("version") == 4 and isinstance(data.get("entries"), dict):
            if not _is_cache_disabled():
                _USAGE_MEM_CACHE[cache_path] = {"disk_sig": disk_sig, "data": data}
            return data
    except Exception:
        pass
    return {"version": 4, "entries": {}}

def _save_usage_cache(cache_path: str | None, cache: dict) -> None:

    if not cache_path:
        return
    if _atomic_write_json(cache_path, cache) and not _is_cache_disabled():
        _USAGE_MEM_CACHE[cache_path] = {
            "disk_sig": _file_stat_sig(cache_path),
            "data": cache,
        }

def _discover_transcript_targets(base_dir: str, include_cli: bool) -> list[tuple[str, str, str]]:

    dirs_to_scan = [base_dir]
    cli_dir_norm = os.path.normpath(DEFAULT_CLI_DIR)
    base_dir_norm = os.path.normpath(base_dir)
    if (
        include_cli
        and "antigravity-cli" not in os.path.basename(base_dir_norm)
        and base_dir_norm == os.path.normpath(DEFAULT_GEMINI_DIR)
        and os.path.exists(cli_dir_norm)
    ):
        dirs_to_scan.append(cli_dir_norm)

    by_uuid: dict[str, tuple[str, str, int]] = {}
    for root in dirs_to_scan:
        brain_dir = os.path.join(root, "brain")
        conv_dir = os.path.join(root, "conversations")
        if not os.path.isdir(brain_dir):
            continue
        try:
            with os.scandir(brain_dir) as it:
                for entry in it:
                    if not entry.is_dir():
                        continue
                    uid = entry.name
                    logs_dir = os.path.join(entry.path, ".system_generated", "logs")
                    tf_path = os.path.join(logs_dir, "transcript.jsonl")
                    if not os.path.exists(tf_path):
                        alt_path = os.path.join(logs_dir, "transcript_full.jsonl")
                        if not os.path.exists(alt_path):
                            continue
                        tf_path = alt_path
                    try:
                        mtime_ns = os.stat(tf_path).st_mtime_ns
                    except OSError:
                        continue
                    db_path = os.path.join(conv_dir, f"{uid}.db")
                    prev = by_uuid.get(uid)
                    if prev is None or mtime_ns > prev[2]:
                        by_uuid[uid] = (tf_path, db_path, mtime_ns)
        except OSError:
            continue

    return [(uid, tf_path, db_path) for uid, (tf_path, db_path, _) in by_uuid.items()]

def _build_model_list(model_map: dict[str, list]) -> list[dict]:

    items = []
    for mkey, vals in model_map.items():
        cost, inp, cache, out, calls = vals
        tot = inp + cache + out
        if tot <= 0 and cost <= 0:
            continue
        items.append({
            "model": mkey,
            "display_name": format_model_display_name(mkey),
            "cost_usd": round(cost, 6),
            "total_tokens": int(tot),
            "input_tokens": int(inp),
            "cache_tokens": int(cache),
            "output_tokens": int(out),
            "calls": int(calls),
        })
    items.sort(key=lambda x: (-x["cost_usd"], -x["total_tokens"], x["model"]))
    return items

def _backfill_from_archive(
    archive_path: str | None,
    date_strings: list[str],
    daily_model_map: dict[str, dict[str, list]],
    earliest_local_date: str | None,
) -> None:

    if not archive_path or not os.path.exists(archive_path):
        return
    try:
        with open(archive_path, "r", encoding="utf-8") as f:
            archive = json.load(f)
        if not isinstance(archive, dict):
            return
    except Exception:
        return

    for ds in date_strings:
        if daily_model_map.get(ds):
            continue
        if earliest_local_date and ds >= earliest_local_date:
            continue
        day_node = archive.get(ds)
        if not isinstance(day_node, dict):
            continue
        agy = (day_node.get("clients") or {}).get("antigravity")
        if not isinstance(agy, dict):
            continue
        by_model = agy.get("byModel") or {}
        target = daily_model_map.setdefault(ds, {})
        if isinstance(by_model, dict) and by_model:
            for raw_m, mdata in by_model.items():
                if not isinstance(mdata, dict):
                    continue
                mkey = normalize_model_key(raw_m)
                inp = int(mdata.get("inputTokens") or 0)
                cache = int(mdata.get("cacheReadTokens") or 0)
                out = int(mdata.get("outputTokens") or 0)
                cost = float(mdata.get("estimatedCost") or 0.0)
                calls = int(mdata.get("callCount") or 0)
                if inp + cache + out <= 0 and int(mdata.get("totalTokens") or 0) > 0:
                    inp = int(mdata.get("totalTokens") or 0)
                _merge_stat_bucket(target, mkey, cost, inp, cache, out, calls)
        elif int(agy.get("totalTokens") or 0) > 0 or float(agy.get("estimatedCost") or 0.0) > 0:
            inp = int(agy.get("inputTokens") or 0)
            cache = int(agy.get("cacheReadTokens") or 0)
            out = int(agy.get("outputTokens") or 0)
            cost = float(agy.get("estimatedCost") or 0.0)
            calls = int(agy.get("callCount") or 0)
            if inp + cache + out <= 0:
                inp = int(agy.get("totalTokens") or 0)
            _merge_stat_bucket(target, "unknown", cost, inp, cache, out, calls)

def _load_conversation_meta_map(base_dir: str, include_cli: bool) -> dict[str, dict]:

    dirs_to_scan = [(base_dir, "cli" if "antigravity-cli" in os.path.basename(os.path.normpath(base_dir)) else "app")]
    cli_dir_norm = os.path.normpath(DEFAULT_CLI_DIR)
    base_dir_norm = os.path.normpath(base_dir)
    if (
        include_cli
        and "antigravity-cli" not in os.path.basename(base_dir_norm)
        and base_dir_norm == os.path.normpath(DEFAULT_GEMINI_DIR)
        and os.path.exists(cli_dir_norm)
    ):
        dirs_to_scan.append((cli_dir_norm, "cli"))

    meta: dict[str, dict] = {}
    for root, ctype in dirs_to_scan:
        db_path = os.path.join(root, "conversation_summaries.db")
        if not os.path.exists(db_path):
            continue
        try:
            conn = connect_sqlite_ro(db_path)
            cols = _get_summary_columns(conn)
            has_parent = "parent_conversation_id" in cols
            sql = (
                "SELECT conversation_id, title, parent_conversation_id FROM conversation_summaries"
                if has_parent
                else "SELECT conversation_id, title, '' FROM conversation_summaries"
            )
            for cid, title, pid in conn.execute(sql).fetchall():
                cid_s = str(cid or "").strip()
                if not cid_s:
                    continue
                prev = meta.get(cid_s)
                clean_title = str(title or "").strip()
                clean_pid = str(pid or "").strip()
                if prev is None:
                    meta[cid_s] = {"title": clean_title, "parent": clean_pid, "client_type": ctype}
                else:
                    if not prev["title"] and clean_title:
                        prev["title"] = clean_title
                    if not prev["parent"] and clean_pid:
                        prev["parent"] = clean_pid
            conn.close()
        except Exception:
            continue
    return meta

def _build_session_list(session_map: dict[str, dict], meta_map: dict[str, dict], limit: int = 50) -> list[dict]:

    items = []
    for root_uid, acc in session_map.items():
        tot = acc["inp"] + acc["cache"] + acc["out"]
        if tot <= 0 and acc["cost"] <= 0:
            continue
        info = meta_map.get(root_uid, {})
        title = info.get("title") or root_uid[:8]
        ctype = info.get("client_type") or acc.get("client_type") or "app"
        top_model = max(acc["model_costs"].items(), key=lambda kv: kv[1])[0] if acc["model_costs"] else "unknown"
        items.append({
            "uuid": root_uid,
            "title": title,
            "client_type": ctype,
            "top_model": top_model,
            "top_model_display": format_model_display_name(top_model),
            "cost_usd": round(acc["cost"], 6),
            "total_tokens": int(tot),
            "input_tokens": int(acc["inp"]),
            "cache_tokens": int(acc["cache"]),
            "output_tokens": int(acc["out"]),
            "calls": int(acc["calls"]),
            "subagent_count": len(acc["subagents"]),
        })
    items.sort(key=lambda x: (-x["cost_usd"], -x["total_tokens"], x["uuid"]))
    return items[:limit]

def build_usage_history_payload(
    days: int = 30,
    data_dir: str | None = None,
    include_cli: bool = True,
    cache_path: object = _UNSET,
    archive_path: object = _UNSET,
    now_dt: datetime | None = None,
    include_sessions: bool = True,
) -> dict:

    clamped_days = max(1, min(int(days or 30), 365))
    local_now = now_dt.astimezone() if now_dt is not None else datetime.now().astimezone()
    today_date = local_now.date()
    today_str = today_date.strftime("%Y-%m-%d")
    start_date = today_date - timedelta(days=clamped_days - 1)
    date_objects = [start_date + timedelta(days=i) for i in range(clamped_days)]
    date_strings = [d.strftime("%Y-%m-%d") for d in date_objects]
    date_set = set(date_strings)
    cutoff_epoch = (local_now - timedelta(days=clamped_days + 1)).timestamp()

    base_dir = os.path.expanduser(data_dir) if data_dir else DEFAULT_GEMINI_DIR
    is_default_dir = os.path.normpath(base_dir) == os.path.normpath(DEFAULT_GEMINI_DIR)
    resolved_archive = (DAILY_ARCHIVE_PATH if is_default_dir else None) if archive_path is _UNSET else archive_path
    resolved_cache_path = _resolve_usage_cache_path(cache_path)

    cache = _load_usage_cache(resolved_cache_path)
    entries: dict = cache.setdefault("entries", {})
    dirty = False

    meta_map = _load_conversation_meta_map(base_dir, include_cli=include_cli) if include_sessions else {}
    parent_map = {cid: info["parent"] for cid, info in meta_map.items() if info.get("parent")} if include_sessions else {}

    targets = _discover_transcript_targets(base_dir, include_cli=include_cli)
    daily_model_map: dict[str, dict[str, list]] = {}
    daily_session_map: dict[str, dict[str, dict]] = {}
    today_hourly_map: dict[str, dict[str, list]] = {}
    all_local_dates: set[str] = set()

    for uid, tf_path, db_path in targets:
        try:
            tf_st = os.stat(tf_path)
        except OSError:
            continue
        tf_mtime = tf_st.st_mtime_ns
        tf_size = tf_st.st_size
        cached = entries.get(tf_path)
        if cached is None and tf_st.st_mtime < cutoff_epoch:
            continue
        if os.path.exists(db_path):
            try:
                db_st = os.stat(db_path)
                db_mtime, db_size = db_st.st_mtime_ns, db_st.st_size
            except OSError:
                db_mtime, db_size = 0, 0
        else:
            db_mtime, db_size = 0, 0

        if (
            isinstance(cached, dict)
            and cached.get("tf_mtime") == tf_mtime
            and cached.get("tf_size") == tf_size
            and cached.get("db_mtime") == db_mtime
            and cached.get("db_size") == db_size
        ):
            parsed = cached.get("data") or {}
        else:

            if cached is None and tf_st.st_mtime < cutoff_epoch:
                continue
            parsed = _parse_transcript_usage_entry(tf_path, db_path)
            entries[tf_path] = {
                "tf_mtime": tf_mtime,
                "tf_size": tf_size,
                "db_mtime": db_mtime,
                "db_size": db_size,
                "data": parsed,
            }
            dirty = True

        root_uid = _resolve_root_parent(uid, parent_map) if include_sessions else uid
        is_subagent = include_sessions and (root_uid != uid)
        inferred_cli = "cli" if "antigravity-cli" in tf_path else "app"

        for d_str, models in (parsed.get("days") or {}).items():
            all_local_dates.add(d_str)
            if d_str not in date_set:
                continue
            target_day = daily_model_map.setdefault(d_str, {})
            if include_sessions:
                sess_day = daily_session_map.setdefault(d_str, {})
                s_acc = sess_day.get(root_uid)
                if s_acc is None:
                    s_acc = {
                        "cost": 0.0,
                        "inp": 0,
                        "cache": 0,
                        "out": 0,
                        "calls": 0,
                        "model_costs": {},
                        "subagents": set(),
                        "client_type": inferred_cli,
                    }
                    sess_day[root_uid] = s_acc
                if is_subagent:
                    s_acc["subagents"].add(uid)
            for mkey, vals in models.items():
                _merge_stat_bucket(target_day, mkey, vals[0], vals[1], vals[2], vals[3], vals[4])
                if include_sessions:
                    s_acc["cost"] += vals[0]
                    s_acc["inp"] += vals[1]
                    s_acc["cache"] += vals[2]
                    s_acc["out"] += vals[3]
                    s_acc["calls"] += vals[4]
                    s_acc["model_costs"][mkey] = s_acc["model_costs"].get(mkey, 0.0) + vals[0]

        today_hrs = (parsed.get("hours") or {}).get(today_str)
        if today_hrs:
            for h_str, models in today_hrs.items():
                target_hr = today_hourly_map.setdefault(h_str, {})
                for mkey, vals in models.items():
                    _merge_stat_bucket(target_hr, mkey, vals[0], vals[1], vals[2], vals[3], vals[4])

    if dirty:
        _save_usage_cache(resolved_cache_path, cache)

    earliest_local_date = min(all_local_dates) if all_local_dates else None
    if resolved_archive and clamped_days > 1:
        _backfill_from_archive(resolved_archive, date_strings, daily_model_map, earliest_local_date)

    daily_list = []
    for d_obj, d_str in zip(date_objects, date_strings):
        m_map = daily_model_map.get(d_str, {})
        models = _build_model_list(m_map)
        cost = sum(m["cost_usd"] for m in models)
        inp = sum(m["input_tokens"] for m in models)
        cache_t = sum(m["cache_tokens"] for m in models)
        out = sum(m["output_tokens"] for m in models)
        tot = inp + cache_t + out
        calls = sum(m["calls"] for m in models)
        sessions_list = _build_session_list(daily_session_map.get(d_str, {}), meta_map) if include_sessions else []
        daily_list.append({
            "date": d_str,
            "label": f"{d_obj.month}/{d_obj.day}",
            "cost_usd": round(cost, 4),
            "total_tokens": int(tot),
            "input_tokens": int(inp),
            "cache_tokens": int(cache_t),
            "output_tokens": int(out),
            "calls": int(calls),
            "models": models,
            "sessions": sessions_list,
        })

    hourly_list = []
    for hr in range(24):
        m_map = today_hourly_map.get(str(hr), {})
        models = _build_model_list(m_map)
        cost = sum(m["cost_usd"] for m in models)
        inp = sum(m["input_tokens"] for m in models)
        cache_t = sum(m["cache_tokens"] for m in models)
        out = sum(m["output_tokens"] for m in models)
        tot = inp + cache_t + out
        calls = sum(m["calls"] for m in models)
        hourly_list.append({
            "hour": hr,
            "label": f"{hr:02d}:00",
            "cost_usd": round(cost, 4),
            "total_tokens": int(tot),
            "input_tokens": int(inp),
            "cache_tokens": int(cache_t),
            "output_tokens": int(out),
            "calls": int(calls),
            "models": models,
        })

    return {
        "generated_at": local_now.isoformat(timespec="seconds"),
        "today_date": today_str,
        "days_requested": clamped_days,
        "daily": daily_list,
        "today_hourly": hourly_list,
    }

def get_today_token_stats(
    sessions: list | None = None,
    anchor_path: str | None = None,
    data_dir: str | None = None,
    include_cli: bool = True,
    cache_path: object = _UNSET,
    now_dt: datetime | None = None,
) -> dict:

    target_anchor = anchor_path or COLLECTOR_ANCHOR_PATH
    stats = {
        "total_tokens": 0,
        "cache_tokens": 0,
        "input_tokens": 0,
        "output_tokens": 0,
        "cache_pct": 0.0,
        "cost_usd": 0.0,
        "has_data": False,
        "source": "local_transcripts",
    }

    local_now = now_dt.astimezone() if now_dt is not None else datetime.now().astimezone()
    today_str = local_now.strftime("%Y-%m-%d")

    try:
        today_history = build_usage_history_payload(
            days=1,
            data_dir=data_dir,
            include_cli=include_cli,
            cache_path=cache_path,
            archive_path=None,
            now_dt=local_now,
            include_sessions=False,
        )
        if today_history.get("daily"):
            tb = today_history["daily"][-1]
            tot = int(tb.get("total_tokens", 0))
            if tot > 0:
                cache = int(tb.get("cache_tokens", 0))
                inp = int(tb.get("input_tokens", 0))
                out = int(tb.get("output_tokens", 0))
                stats["total_tokens"] = tot
                stats["cache_tokens"] = cache
                stats["input_tokens"] = inp
                stats["output_tokens"] = out
                stats["cache_pct"] = round((cache / tot * 100.0), 1)
                stats["cost_usd"] = round(float(tb.get("cost_usd", 0.0)), 4)
                stats["has_data"] = True
                stats["source"] = "local_transcripts"
                return stats
    except Exception:
        pass

    if os.path.exists(target_anchor):
        try:
            with open(target_anchor, "r", encoding="utf-8") as f:
                data = json.load(f)

            date_key = data.get("dateKey", "")
            today_node = data.get("today", {})
            if date_key == today_str and today_node:
                tot = today_node.get("totalTokens", 0)
                cache = today_node.get("cacheReadTokens", 0)
                out = today_node.get("outputTokens", 0)
                cost = today_node.get("costUsd", 0.0)
                inp = max(0, tot - cache - out)
                if tot > 0:
                    stats["total_tokens"] = tot
                    stats["cache_tokens"] = cache
                    stats["input_tokens"] = inp
                    stats["output_tokens"] = out
                    stats["cache_pct"] = round((cache / tot * 100.0), 1) if tot > 0 else 0.0
                    stats["cost_usd"] = round(cost, 4)
                    stats["has_data"] = True
                    stats["source"] = "collector-anchor.json"
                    return stats
        except Exception:
            pass

    return stats

def count_recent_503_errors(
    data_dir: str | None = None,
    include_cli: bool = True,
    window_seconds: int = 3600,
    now_dt: datetime | None = None,
) -> dict:

    local_now = now_dt.astimezone() if now_dt is not None else datetime.now().astimezone()
    win_sec = max(60, int(window_seconds))
    cutoff_dt = local_now - timedelta(seconds=win_sec)
    cutoff_epoch = cutoff_dt.timestamp()
    now_epoch = local_now.timestamp()
    base_dir = os.path.expanduser(data_dir) if data_dir else DEFAULT_GEMINI_DIR

    targets = _discover_transcript_targets(base_dir, include_cli=include_cli)
    count = 0
    for _, tf_path, _ in targets:
        if now_dt is None:
            try:
                if os.stat(tf_path).st_mtime < cutoff_epoch - 60:
                    continue
            except OSError:
                continue
        try:
            with open(tf_path, "r", encoding="utf-8", errors="ignore") as f:
                for line in f:
                    if "ERROR_MESSAGE" not in line or "503" not in line:
                        continue
                    try:
                        st = json.loads(line)
                    except Exception:
                        continue
                    if st.get("type") != "ERROR_MESSAGE":
                        continue
                    err_text = str(st.get("error") or st.get("content") or "")
                    if "503" not in err_text:
                        continue
                    ts = st.get("created_at") or ""
                    if not ts:
                        continue
                    dt_epoch = parse_iso_dt(ts).timestamp()
                    if cutoff_epoch <= dt_epoch <= now_epoch + 5:
                        count += 1
        except OSError:
            continue

    return {
        "count": count,
        "window_minutes": win_sec // 60,
        "checked_at": local_now.isoformat(timespec="seconds"),
    }

def _find_session_transcript_file(uuid: str, base_dir: str) -> str | None:

    candidate_roots = [os.path.join(base_dir, "brain", uuid)]
    if os.path.normpath(base_dir) == os.path.normpath(DEFAULT_GEMINI_DIR):
        candidate_roots.append(os.path.join(DEFAULT_CLI_DIR, "brain", uuid))
    for root in candidate_roots:
        logs_dir = os.path.join(root, ".system_generated", "logs")
        for filename in ("transcript_full.jsonl", "transcript.jsonl"):
            path = os.path.join(logs_dir, filename)
            if os.path.isfile(path):
                return path
    return None

def _classify_command_source(cmd: str) -> str:

    low = (cmd or "").lower()
    if any(k in low for k in ("playwright", "e2e", "pytest", "vitest", "jest", "npm test", "npm run test", "swiftc", "test_")):
        return "测试/E2E"
    if any(k in low for k in ("grep", "rg ", "find ", "ls ", "git ", "sed ", "head ", "tail ", "cat ", "wc ")):
        return "搜索/Git/查看"
    if any(k in low for k in ("build", "xcodebuild", "cargo ", "tsc", "vite ", "make ")):
        return "编译/构建"
    return "其他命令"

def _classify_phase_for_planner(tool_calls: list) -> str:

    if not tool_calls:
        return "总结/文字输出"
    names = [str(tc.get("name") or "") for tc in tool_calls if isinstance(tc, dict)]
    if any(n == "run_command" for n in names):
        for tc in tool_calls:
            if not isinstance(tc, dict) or tc.get("name") != "run_command":
                continue
            args = tc.get("arguments") or {}
            cmd = str(args.get("CommandLine") or args.get("command") or "")
            if _classify_command_source(cmd) in ("测试/E2E", "编译/构建"):
                return "测试/构建/排错"
    if any(n in ("edit_file", "write_file", "replace_file_content", "multi_replace_file_content") for n in names):
        return "编码修改"
    if any(n in ("swarm", "read_board", "swarm_wait", "send_message", "invoke_subagent", "manage_task") for n in names):
        return "调度/看板协作"
    return "调研/检索"

def _format_miss_time(ts_str: str) -> str:

    if not ts_str:
        return "--:--:--"
    try:
        return parse_iso_dt(ts_str).astimezone().strftime("%H:%M:%S")
    except Exception:
        return "--:--:--"

def _format_duration_compact(sec: float) -> str:

    total = max(0, int(round(sec)))
    if total >= 3600:
        h = total // 3600
        m = (total % 3600) // 60
        return f"{h}h{m}m" if m > 0 else f"{h}h"
    if total >= 60:
        m = total // 60
        s = total % 60
        return f"{m}m{s}s" if s > 0 else f"{m}m"
    return f"{total}s"

_DIAG_PHASE_EN = {
    "调研/检索": "Research / Search",
    "编码修改": "Code Editing",
    "测试/构建/排错": "Test / Build / Debug",
    "调度/看板协作": "Agent Coordination",
    "总结/文字输出": "Summary / Response",
}

_DIAG_SOURCE_EN = {
    "read_file 读取": "read_file output",
    "后台测试/E2E回传": "Async Test / E2E output",
    "后台其他命令回传": "Async Command output",
    "同步测试/构建输出": "Sync Test / Build output",
    "同步搜索/Git输出": "Sync Search / Git output",
    "同步其他命令输出": "Sync Command output",
    "edit/write 回执": "edit/write receipts",
    "看板/子Agent协作": "Swarm / Subagent msgs",
    "其他系统提示": "Other system prompts",
    "模型思考/回复与参数": "Model output & args",
    "模型思考与输出": "Model output",
    "用户输入": "User prompts",
    "报错信息": "Error logs",
}

_DIAG_CAUSE_EN = {
    "压缩/重开重建": "Context compaction / reset",
    "云端报错/切节点重连": "Cloud error / reconnect",
    "前缀/系统注入变动": "Prefix / system prompt shift",
    "停顿/等待续聊过期": "Idle TTL expiration",
}

def _build_diagnostic_recommendations(
    sources: list[dict],
    cache_miss: dict,
    total_cost: float,
    bloat_hints: list[str] | None = None,
    lang: str = "zh",
) -> list[str]:

    is_en = _normalize_lang(lang) == "en"
    recs: list[str] = []
    source_map = {s["name"]: s for s in sources}

    cause_map = {c["cause"]: c for c in cache_miss.get("by_cause", [])}
    ttl_miss = cause_map.get(_DIAG_CAUSE_EN["停顿/等待续聊过期"] if is_en else "停顿/等待续聊过期")
    err_miss = cause_map.get(_DIAG_CAUSE_EN["云端报错/切节点重连"] if is_en else "云端报错/切节点重连")
    prefix_miss = cause_map.get(_DIAG_CAUSE_EN["前缀/系统注入变动"] if is_en else "前缀/系统注入变动")

    if ttl_miss and ttl_miss["count"] > 0 and ttl_miss["extra_cost_usd"] >= 0.30:
        if is_en:
            recs.append(
                f"Idle rebuilds {ttl_miss['count']}x (+${ttl_miss['extra_cost_usd']:.2f}): run `/compact` or start a new session after long pauses."
            )
        else:
            recs.append(
                f"等待后重算 {ttl_miss['count']} 次（+${ttl_miss['extra_cost_usd']:.2f}）：久停后继续高上下文前先 `/compact` 或开新会话。"
            )
    if prefix_miss and prefix_miss["count"] > 0 and prefix_miss["extra_cost_usd"] >= 0.30:
        if is_en:
            recs.append(
                f"Mid-run prefix rebuilds {prefix_miss['count']}x (+${prefix_miss['extra_cost_usd']:.2f}): keep one model and trim async logs."
            )
        else:
            recs.append(
                f"运行中前缀重建 {prefix_miss['count']} 次（+${prefix_miss['extra_cost_usd']:.2f}）：长任务尽量不切模型、减少大日志异步回传。"
            )
    if err_miss and err_miss["count"] > 0 and err_miss["extra_cost_usd"] >= 0.50:
        if is_en:
            recs.append(
                f"Cloud error rebuilds {err_miss['count']}x (+${err_miss['extra_cost_usd']:.2f}): split work into smaller tasks."
            )
        else:
            recs.append(
                f"云端断流重算 {err_miss['count']} 次（+${err_miss['extra_cost_usd']:.2f}）：拆分小任务可降低单次断流重算损失。"
            )

    bg_e2e_key = _DIAG_SOURCE_EN["后台测试/E2E回传"] if is_en else "后台测试/E2E回传"
    bg_e2e = source_map.get(bg_e2e_key)
    if len(recs) < 2 and bg_e2e and bg_e2e["pct"] >= 20.0:
        if is_en:
            recs.append(f"Async test output takes {bg_e2e['pct']:.0f}% of context; enable concise/quiet test mode.")
        else:
            recs.append(f"后台测试回传占 {bg_e2e['pct']:.0f}% 上下文，建议开启低噪音静默输出。")

    if not recs:
        if bloat_hints:
            recs.append(bloat_hints[0])
        elif cache_miss.get("extra_cost_usd", 0.0) > 0 and total_cost > 0:
            recs.append(
                "Cache hit rate and context size are healthy."
                if is_en
                else "当前缓存命中与上下文体积整体健康。"
            )
        else:
            recs.append(
                "No significant waste detected in this session."
                if is_en
                else "当前会话暂无显著浪费。"
            )
    return recs[:2]

def _collect_descendant_subagents(db_path: str, root_uuid: str) -> list[tuple[str, str]]:

    if not os.path.isfile(db_path):
        return []
    try:
        conn = connect_sqlite_ro(db_path)
        rows = conn.execute(
            "SELECT conversation_id, agent_name, parent_conversation_id FROM conversation_summaries"
        ).fetchall()
        conn.close()
    except Exception:
        return []

    children_map: dict[str, list[tuple[str, str]]] = {}
    for cid, agent_name, parent_id in rows:
        if not parent_id or not cid:
            continue
        label = (str(agent_name or "").strip()) or str(cid)[:8]
        children_map.setdefault(str(parent_id), []).append((str(cid), label))

    descendants: list[tuple[str, str]] = []
    seen: set[str] = {root_uuid}
    queue = list(children_map.get(root_uuid, []))
    while queue:
        cid, label = queue.pop(0)
        if cid in seen:
            continue
        seen.add(cid)
        descendants.append((cid, label))
        queue.extend(children_map.get(cid, []))
    return descendants

def _analyze_single_session_raw(
    uuid: str,
    base_dir: str,
    agent_label: str = "主会话",
    lang: str = "zh",
) -> dict:

    is_en = _normalize_lang(lang) == "en"
    db_path = os.path.join(base_dir, "conversation_summaries.db")
    conversations_dir = os.path.join(base_dir, "conversations")

    title = uuid[:8]
    if os.path.isfile(db_path):
        try:
            conn = connect_sqlite_ro(db_path)
            row = conn.execute(
                "SELECT title FROM conversation_summaries WHERE conversation_id = ?",
                (uuid,),
            ).fetchone()
            conn.close()
            if row and row[0]:
                title = str(row[0])
        except Exception:
            pass

    fallback_model = get_session_model(uuid, conversations_dir=conversations_dir)
    if fallback_model == "-":
        fallback_model = "Gemini 3.1 Pro"

    conv_db = os.path.join(conversations_dir, f"{uuid}.db")
    gm_models = _extract_ordered_gen_models(conv_db) if os.path.isfile(conv_db) else []

    transcript_path = _find_session_transcript_file(uuid, base_dir)
    steps: list[dict] = []
    if transcript_path:
        try:
            with open(transcript_path, "r", encoding="utf-8", errors="ignore") as fh:
                for line in fh:
                    raw = line.strip()
                    if not raw:
                        continue
                    try:
                        steps.append(json.loads(raw))
                    except Exception:
                        continue
        except OSError:
            pass

    planner_indices = [i for i, st in enumerate(steps) if st.get("type") == "PLANNER_RESPONSE"]
    step_models = _match_planner_step_models(len(planner_indices), gm_models, fallback_model)
    planner_model_map = {idx: step_models[pos] for pos, idx in enumerate(planner_indices)}

    bg_task_commands: dict[str, str] = {}
    last_tool_calls: list[dict] = []

    source_buckets: dict[str, dict] = {}
    phase_buckets: dict[str, dict] = {}
    consumer_items: list[dict] = []

    def add_source(name: str, chars: int, label: str = "") -> None:
        if chars <= 0:
            return
        bucket = source_buckets.setdefault(name, {"name": name, "chars": 0, "count": 0})
        bucket["chars"] += chars
        bucket["count"] += 1
        if label and chars >= 800:
            consumer_items.append({"category": name, "label": label, "chars": chars})

    total_cost_usd = 0.0
    total_tokens = 0
    total_input_tokens = 0
    total_cache_tokens = 0
    total_output_tokens = 0

    prev_ctx: int | None = None
    prev_ts: datetime | None = None
    prev_model: str = ""
    last_error_step: int = -999
    last_error_summary: str = ""
    last_planner_step: int = -1
    between_bg_tasks: list[str] = []
    between_board_msg: bool = False
    between_user_input: bool = False
    read_file_counts: dict[str, int] = {}
    read_file_chars: dict[str, int] = {}
    cmd_char_totals: dict[str, int] = {}
    miss_events: list[dict] = []
    cause_totals: dict[str, dict] = {}

    task_id_re = re.compile(r"(?:task id:|with ID:|/)?(task-\d+)", re.IGNORECASE)
    sys_task_re = re.compile(r"(?:sender=[^\s]+/|Task id\s+\"[^\"]+/|Background task\s+(?:[^\s]+/)?|task\s+(?:[^\s]+/)?)(task-\d+)", re.IGNORECASE)

    for idx, st in enumerate(steps):
        stype = str(st.get("type") or "")
        content = str(st.get("content") or "")
        thinking = str(st.get("thinking") or "")
        err_text = str(st.get("error") or "")
        tool_calls = st.get("tool_calls") if isinstance(st.get("tool_calls"), list) else []

        if stype == "USER_INPUT":
            between_user_input = True
            add_source("用户输入", len(content))
            continue

        if stype == "ERROR_MESSAGE":
            last_error_step = idx
            raw_err = (err_text or content).strip()
            for code in ("503", "429", "500", "502", "504", "timeout", "stream"):
                if code in raw_err.lower():
                    last_error_summary = code.upper() if code.isalpha() else code
                    break
            else:
                last_error_summary = "Cloud error" if is_en else "云端异常"
            add_source("报错信息", len(content) + len(err_text))
            continue

        if stype == "PLANNER_RESPONSE":
            last_tool_calls = [tc for tc in tool_calls if isinstance(tc, dict)]
            args_chars = sum(len(json.dumps(tc, ensure_ascii=False)) for tc in last_tool_calls)
            add_source("模型思考/回复与参数", len(content) + len(thinking) + args_chars)

            in_t = int(st.get("input_tokens") or 0)
            cache_t = int(st.get("cache_read_tokens") or 0)
            out_t = int(st.get("output_tokens") or 0)
            ctx_t = in_t + cache_t
            step_tot = in_t + cache_t + out_t
            model_name = planner_model_map.get(idx, fallback_model)

            step_dt = None
            ts_str = str(st.get("created_at") or "")
            if ts_str:
                try:
                    step_dt = parse_iso_dt(ts_str)
                except Exception:
                    step_dt = None

            step_cost = calculate_step_cost(model_name, in_t, cache_t, out_t, now=step_dt)
            total_cost_usd += step_cost
            total_tokens += step_tot
            total_input_tokens += in_t
            total_cache_tokens += cache_t
            total_output_tokens += out_t

            phase_name = _classify_phase_for_planner(last_tool_calls)
            pb = phase_buckets.setdefault(
                phase_name,
                {
                    "name": phase_name,
                    "turns": 0,
                    "tokens": 0,
                    "input_tokens": 0,
                    "cache_tokens": 0,
                    "output_tokens": 0,
                    "cost_usd": 0.0,
                },
            )
            pb["turns"] += 1
            pb["tokens"] += step_tot
            pb["input_tokens"] += in_t
            pb["cache_tokens"] += cache_t
            pb["output_tokens"] += out_t
            pb["cost_usd"] += step_cost

            if prev_ctx is not None and prev_ctx >= 50_000 and cache_t < (prev_ctx * 0.50):
                r_in, r_cache, _ = _resolve_model_rates(model_name, ctx_t, now=step_dt)
                had_err = last_error_step > last_planner_step
                dropped_ctx = ctx_t < (prev_ctx * 0.85)
                rebuilt_t = in_t if dropped_ctx else min(in_t, max(0, prev_ctx - cache_t))
                extra_usd = max(0.0, rebuilt_t * max(0.0, r_in - r_cache) / 1_000_000.0)
                gap_sec = (
                    (step_dt - prev_ts).total_seconds()
                    if (step_dt is not None and prev_ts is not None)
                    else 0.0
                )

                if dropped_ctx:
                    cause = "压缩/重开重建"
                    detail = (
                        f"Context reduced {prev_ctx // 1000}k → {ctx_t // 1000}k"
                        if is_en
                        else f"上下文从 {prev_ctx // 1000}k 缩减至 {ctx_t // 1000}k"
                    )
                elif had_err:
                    cause = "云端报错/切节点重连"
                    err_tag = last_error_summary or ("Cloud error" if is_en else "云端异常")
                    detail = (
                        f"{err_tag} stream retry (ctx {ctx_t // 1000}k)"
                        if is_en
                        else f"{err_tag} 断流后重连重试 (ctx {ctx_t // 1000}k)"
                    )
                elif prev_model and normalize_model_key(prev_model) != normalize_model_key(model_name):
                    cause = "前缀/系统注入变动"
                    detail = (
                        f"Model switch ({normalize_model_key(prev_model)} → {normalize_model_key(model_name)})"
                        if is_en
                        else f"模型切换 ({normalize_model_key(prev_model)} → {normalize_model_key(model_name)})"
                    )
                elif between_user_input or gap_sec >= 180:
                    cause = "停顿/等待续聊过期"
                    gap_label = _format_duration_compact(max(0, gap_sec))
                    if between_board_msg or between_bg_tasks:
                        detail = (
                            f"Idle waiting for subagent/task {gap_label} (ctx {ctx_t // 1000}k)"
                            if is_en
                            else f"休眠等待子Agent/后台 {gap_label} 后唤醒 (ctx {ctx_t // 1000}k)"
                        )
                    else:
                        detail = (
                            f"Idle {gap_label} before resume (ctx {ctx_t // 1000}k)"
                            if is_en
                            else f"等待/停顿 {gap_label} 后续聊 (ctx {ctx_t // 1000}k)"
                        )
                elif between_bg_tasks:
                    cause = "前缀/系统注入变动"
                    gap_label = _format_duration_compact(max(0, gap_sec))
                    detail = (
                        f"Interrupted by async {between_bg_tasks[-1]} ({gap_label})"
                        if is_en
                        else f"收到后台 {between_bg_tasks[-1]} 回传后打断 ({gap_label})"
                    )
                elif between_board_msg:
                    cause = "前缀/系统注入变动"
                    gap_label = _format_duration_compact(max(0, gap_sec))
                    detail = (
                        f"Board/subagent message rebuild ({gap_label})"
                        if is_en
                        else f"收到看板/子Agent消息后重算 ({gap_label})"
                    )
                else:
                    cause = "前缀/系统注入变动"
                    gap_label = _format_duration_compact(max(0, gap_sec))
                    detail = (
                        f"Mid-run route or prefix shift ({gap_label})"
                        if is_en
                        else f"连续执行中路由或前缀变动 ({gap_label})"
                    )

                miss_events.append(
                    {
                        "step_index": int(st.get("step_index") if st.get("step_index") is not None else idx),
                        "time": _format_miss_time(ts_str),
                        "rebuilt_tokens": rebuilt_t,
                        "ctx_tokens": ctx_t,
                        "extra_cost_usd": round(extra_usd, 4),
                        "cause": cause,
                        "detail": detail,
                        "agent_name": agent_label,
                    }
                )
                cb = cause_totals.setdefault(
                    cause, {"cause": cause, "count": 0, "rebuilt_tokens": 0, "extra_cost_usd": 0.0}
                )
                cb["count"] += 1
                cb["rebuilt_tokens"] += rebuilt_t
                cb["extra_cost_usd"] += extra_usd

            if ctx_t > 0:
                prev_ctx = ctx_t
            if step_dt is not None:
                prev_ts = step_dt
            prev_model = model_name
            last_planner_step = idx
            between_bg_tasks = []
            between_board_msg = False
            between_user_input = False
            continue

        if stype == "SYSTEM_MESSAGE":
            chars = len(content)
            m_sys = sys_task_re.search(content)
            if m_sys:
                tid = m_sys.group(1)
                orig_cmd = bg_task_commands.get(tid, "")
                cmd_cat = _classify_command_source(orig_cmd)
                bucket_name = "后台测试/E2E回传" if cmd_cat in ("测试/E2E", "编译/构建") else "后台其他命令回传"
                label = f"{tid}: {orig_cmd[:55]}" if orig_cmd else tid
                between_bg_tasks.append(f"{tid} ({orig_cmd[:24]})" if orig_cmd else tid)
                add_source(bucket_name, chars, label=label)
            elif any(k in content for k in ("[swarm]", "[board]", "Your assignment", "sender=")):
                between_board_msg = True
                add_source("看板/子Agent协作", chars)
            else:
                add_source("其他系统提示", chars)
            continue

        if stype == "GENERIC":
            chars = len(content)

            m_tid = task_id_re.search(content)
            if m_tid:
                tid = m_tid.group(1)
                for tc in last_tool_calls:
                    if tc.get("name") == "run_command":
                        args = tc.get("arguments") or {}
                        bg_task_commands[tid] = str(args.get("CommandLine") or args.get("command") or "")
                        break

            tool_names = [str(tc.get("name") or "") for tc in last_tool_calls]
            if "read_file" in tool_names or "Showing lines " in content:
                target_path = ""
                for tc in last_tool_calls:
                    if tc.get("name") == "read_file":
                        r_args = tc.get("arguments") or {}
                        target_path = str(
                            r_args.get("Path")
                            or r_args.get("AbsolutePath")
                            or r_args.get("file_path")
                            or r_args.get("target_file")
                            or ""
                        )
                        break
                file_label = os.path.basename(target_path) if target_path else "read_file"
                if file_label != "read_file":
                    read_file_counts[file_label] = read_file_counts.get(file_label, 0) + 1
                    read_file_chars[file_label] = read_file_chars.get(file_label, 0) + chars
                add_source("read_file 读取", chars, label=file_label)
            elif "run_command" in tool_names:
                cmd = ""
                for tc in last_tool_calls:
                    if tc.get("name") == "run_command":
                        args = tc.get("arguments") or {}
                        cmd = str(args.get("CommandLine") or args.get("command") or "")
                        break
                cmd_key = (cmd.strip().split()[:2] if cmd.strip() else [("cmd" if is_en else "命令")])
                cmd_prefix = " ".join(cmd_key)[:28]
                cmd_char_totals[cmd_prefix] = cmd_char_totals.get(cmd_prefix, 0) + chars
                cmd_cat = _classify_command_source(cmd)
                if cmd_cat in ("测试/E2E", "编译/构建"):
                    add_source("同步测试/构建输出", chars, label=cmd[:55])
                elif cmd_cat == "搜索/Git/查看":
                    add_source("同步搜索/Git输出", chars, label=cmd[:55])
                else:
                    add_source("同步其他命令输出", chars, label=cmd[:55])
            elif any(n in ("edit_file", "write_file", "replace_file_content", "multi_replace_file_content") for n in tool_names):
                add_source("edit/write 回执", chars)
            elif any(n in ("swarm", "read_board", "swarm_wait", "send_message", "invoke_subagent", "manage_task") for n in tool_names):
                add_source("看板/子Agent协作", chars)
            elif any(n in ("grep_search", "find_by_name", "list_dir", "search_web") for n in tool_names):
                add_source("同步搜索/Git输出", chars)
            else:
                add_source("其他系统提示", chars)

    total_chars = sum(b["chars"] for b in source_buckets.values())
    attributed_chars = sum(b["chars"] for name, b in source_buckets.items() if name != "其他系统提示")
    attributed_pct = round((attributed_chars / total_chars * 100.0), 2) if total_chars > 0 else 100.0

    sources_list = []
    for b in sorted(source_buckets.values(), key=lambda x: x["chars"], reverse=True):
        pct = round((b["chars"] / total_chars * 100.0), 2) if total_chars > 0 else 0.0
        sources_list.append(
            {
                "name": b["name"],
                "chars": b["chars"],
                "count": b["count"],
                "pct": pct,
            }
        )

    phases_list = []
    for pb in sorted(phase_buckets.values(), key=lambda x: x["tokens"], reverse=True):
        pct = round((pb["tokens"] / total_tokens * 100.0), 2) if total_tokens > 0 else 0.0
        phases_list.append(
            {
                "name": pb["name"],
                "turns": pb["turns"],
                "tokens": pb["tokens"],
                "input_tokens": pb["input_tokens"],
                "cache_tokens": pb["cache_tokens"],
                "output_tokens": pb["output_tokens"],
                "cost_usd": round(pb["cost_usd"], 4),
                "pct": pct,
            }
        )

    miss_events_sorted = sorted(miss_events, key=lambda x: x["extra_cost_usd"], reverse=True)
    extra_cost_total = sum(e["extra_cost_usd"] for e in miss_events)
    rebuilt_total = sum(e["rebuilt_tokens"] for e in miss_events)
    waste_pct = round((extra_cost_total / total_cost_usd * 100.0), 2) if total_cost_usd > 0 else 0.0

    by_cause_list = [
        {
            "cause": c["cause"],
            "count": c["count"],
            "rebuilt_tokens": c["rebuilt_tokens"],
            "extra_cost_usd": round(c["extra_cost_usd"], 4),
        }
        for c in sorted(cause_totals.values(), key=lambda x: x["extra_cost_usd"], reverse=True)
    ]

    cache_miss_summary = {
        "total_misses": len(miss_events),
        "rebuilt_tokens": rebuilt_total,
        "extra_cost_usd": round(extra_cost_total, 4),
        "waste_pct_of_total": waste_pct,
        "by_cause": by_cause_list,
        "top_events": miss_events_sorted[:5],
    }

    bloat_hints: list[str] = []
    repeated_reads = [
        (fname, cnt, read_file_chars.get(fname, 0))
        for fname, cnt in read_file_counts.items()
        if cnt >= 3
    ]
    repeated_reads.sort(key=lambda x: x[2], reverse=True)
    if repeated_reads:
        top_f, top_cnt, top_ch = repeated_reads[0]
        extra_files = len(repeated_reads) - 1
        suffix = f" 等 {len(repeated_reads)} 个文件" if extra_files > 0 else ""
        bloat_hints.append(
            f"重复读取：{top_f}{suffix}被 read_file 读取 {top_cnt} 次（占 {top_ch // 1000}K 字符），建议优先用 grep/codegraph 定位。"
        )
    if cmd_char_totals and total_chars > 0:
        top_cmd, top_cmd_ch = max(cmd_char_totals.items(), key=lambda x: x[1])
        if (top_cmd_ch / total_chars) >= 0.12:
            bloat_hints.append(
                f"命令输出大户：「{top_cmd}」累计吐出 {top_cmd_ch // 1000}K 字符（占总上下文 {top_cmd_ch / total_chars * 100:.1f}%）。"
            )

    top_consumers = sorted(consumer_items, key=lambda x: x["chars"], reverse=True)[:5]
    recommendations = _build_diagnostic_recommendations(
        sources_list,
        cache_miss_summary,
        total_cost_usd,
        bloat_hints=bloat_hints,
    )

    return {
        "uuid": uuid,
        "title": title,
        "model": normalize_model_key(fallback_model),
        "agent_label": agent_label,
        "turns": len(planner_indices),
        "total_tokens": total_tokens,
        "input_tokens": total_input_tokens,
        "cache_tokens": total_cache_tokens,
        "output_tokens": total_output_tokens,
        "total_cost_usd": total_cost_usd,
        "source_buckets": source_buckets,
        "phase_buckets": phase_buckets,
        "miss_events": miss_events,
        "consumer_items": consumer_items,
        "read_file_counts": read_file_counts,
        "read_file_chars": read_file_chars,
        "cmd_char_totals": cmd_char_totals,
    }

def analyze_session_diagnostics(
    uuid: str,
    data_dir: str | None = None,
    include_subagents: bool = True,
    lang: str = "zh",
) -> dict:

    is_en = _normalize_lang(lang) == "en"
    base_dir = os.path.expanduser(data_dir) if data_dir else DEFAULT_GEMINI_DIR
    db_path = os.path.join(base_dir, "conversation_summaries.db")

    root_label = "Main" if is_en else "主会话"
    root_raw = _analyze_single_session_raw(uuid, base_dir, agent_label=root_label, lang=lang)
    descendants = _collect_descendant_subagents(db_path, uuid) if include_subagents else []
    sub_raws = [
        _analyze_single_session_raw(cid, base_dir, agent_label=label, lang=lang)
        for cid, label in descendants
    ]
    all_raws = [root_raw] + sub_raws

    turns = sum(r["turns"] for r in all_raws)
    total_tokens = sum(r["total_tokens"] for r in all_raws)
    total_input_tokens = sum(r["input_tokens"] for r in all_raws)
    total_cache_tokens = sum(r["cache_tokens"] for r in all_raws)
    total_output_tokens = sum(r["output_tokens"] for r in all_raws)
    total_cost_usd = sum(r["total_cost_usd"] for r in all_raws)

    merged_sources: dict[str, dict] = {}
    merged_phases: dict[str, dict] = {}
    merged_misses: list[dict] = []
    merged_consumers: list[dict] = []
    merged_rf_counts: dict[str, int] = {}
    merged_rf_chars: dict[str, int] = {}
    merged_cmd_chars: dict[str, int] = {}

    for r in all_raws:
        for name, b in r["source_buckets"].items():
            mb = merged_sources.setdefault(name, {"name": name, "chars": 0, "count": 0})
            mb["chars"] += b["chars"]
            mb["count"] += b["count"]
        for name, pb in r["phase_buckets"].items():
            mp = merged_phases.setdefault(
                name,
                {
                    "name": name,
                    "turns": 0,
                    "tokens": 0,
                    "input_tokens": 0,
                    "cache_tokens": 0,
                    "output_tokens": 0,
                    "cost_usd": 0.0,
                },
            )
            mp["turns"] += pb["turns"]
            mp["tokens"] += pb["tokens"]
            mp["input_tokens"] += pb["input_tokens"]
            mp["cache_tokens"] += pb["cache_tokens"]
            mp["output_tokens"] += pb["output_tokens"]
            mp["cost_usd"] += pb["cost_usd"]
        merged_misses.extend(r["miss_events"])
        merged_consumers.extend(r["consumer_items"])
        for fn, cnt in r["read_file_counts"].items():
            merged_rf_counts[fn] = merged_rf_counts.get(fn, 0) + cnt
        for fn, ch in r["read_file_chars"].items():
            merged_rf_chars[fn] = merged_rf_chars.get(fn, 0) + ch
        for cmd, ch in r["cmd_char_totals"].items():
            merged_cmd_chars[cmd] = merged_cmd_chars.get(cmd, 0) + ch

    total_chars = sum(b["chars"] for b in merged_sources.values())
    attributed_chars = sum(b["chars"] for name, b in merged_sources.items() if name != "其他系统提示")
    attributed_pct = round((attributed_chars / total_chars * 100.0), 2) if total_chars > 0 else 100.0

    sources_list = [
        {
            "name": (_DIAG_SOURCE_EN.get(b["name"], b["name"]) if is_en else b["name"]),
            "chars": b["chars"],
            "count": b["count"],
            "pct": round((b["chars"] / total_chars * 100.0), 2) if total_chars > 0 else 0.0,
        }
        for b in sorted(merged_sources.values(), key=lambda x: x["chars"], reverse=True)
    ]

    phases_list = [
        {
            "name": (_DIAG_PHASE_EN.get(pb["name"], pb["name"]) if is_en else pb["name"]),
            "turns": pb["turns"],
            "tokens": pb["tokens"],
            "input_tokens": pb["input_tokens"],
            "cache_tokens": pb["cache_tokens"],
            "output_tokens": pb["output_tokens"],
            "cost_usd": round(pb["cost_usd"], 4),
            "pct": round((pb["tokens"] / total_tokens * 100.0), 2) if total_tokens > 0 else 0.0,
        }
        for pb in sorted(merged_phases.values(), key=lambda x: x["tokens"], reverse=True)
    ]

    miss_events_sorted = sorted(merged_misses, key=lambda x: x["extra_cost_usd"], reverse=True)
    if is_en:
        miss_events_sorted = [
            {**ev, "cause": _DIAG_CAUSE_EN.get(ev["cause"], ev["cause"])}
            for ev in miss_events_sorted
        ]
    extra_cost_total = sum(e["extra_cost_usd"] for e in merged_misses)
    rebuilt_total = sum(e["rebuilt_tokens"] for e in merged_misses)
    waste_pct = round((extra_cost_total / total_cost_usd * 100.0), 2) if total_cost_usd > 0 else 0.0

    cause_totals: dict[str, dict] = {}
    for ev in merged_misses:
        c = _DIAG_CAUSE_EN.get(ev["cause"], ev["cause"]) if is_en else ev["cause"]
        cb = cause_totals.setdefault(c, {"cause": c, "count": 0, "rebuilt_tokens": 0, "extra_cost_usd": 0.0})
        cb["count"] += 1
        cb["rebuilt_tokens"] += ev["rebuilt_tokens"]
        cb["extra_cost_usd"] += ev["extra_cost_usd"]

    by_cause_list = [
        {
            "cause": c["cause"],
            "count": c["count"],
            "rebuilt_tokens": c["rebuilt_tokens"],
            "extra_cost_usd": round(c["extra_cost_usd"], 4),
        }
        for c in sorted(cause_totals.values(), key=lambda x: x["extra_cost_usd"], reverse=True)
    ]

    cache_miss_summary = {
        "total_misses": len(merged_misses),
        "rebuilt_tokens": rebuilt_total,
        "extra_cost_usd": round(extra_cost_total, 4),
        "waste_pct_of_total": waste_pct,
        "by_cause": by_cause_list,
        "top_events": miss_events_sorted[:5],
    }

    bloat_hints: list[str] = []
    if sub_raws and total_cost_usd > 0:
        sub_cost = sum(r["total_cost_usd"] for r in sub_raws)
        if sub_cost / total_cost_usd >= 0.40:
            top_sub = max(sub_raws, key=lambda r: r["total_cost_usd"])
            if is_en:
                bloat_hints.append(
                    f"Subagents used {sub_cost / total_cost_usd * 100:.0f}% of cost (top: {top_sub['agent_label']} ${top_sub['total_cost_usd']:.2f}); select one above to inspect."
                )
            else:
                bloat_hints.append(
                    f"子 Agent 占总花费 {sub_cost / total_cost_usd * 100:.0f}%（最大开销：{top_sub['agent_label']} ${top_sub['total_cost_usd']:.2f}），可点击上方列表单独下钻。"
                )
    repeated_reads = [
        (fname, cnt, merged_rf_chars.get(fname, 0))
        for fname, cnt in merged_rf_counts.items()
        if cnt >= 3
    ]
    repeated_reads.sort(key=lambda x: x[2], reverse=True)
    if repeated_reads:
        top_f, top_cnt, top_ch = repeated_reads[0]
        extra_files = len(repeated_reads) - 1
        if is_en:
            suffix = f" (+{extra_files} files)" if extra_files > 0 else ""
            bloat_hints.append(
                f"Repeated reads: {top_f}{suffix} read {top_cnt}x ({top_ch // 1000}K chars); locate symbols via grep/codegraph first."
            )
        else:
            suffix = f" 等 {len(repeated_reads)} 个文件" if extra_files > 0 else ""
            bloat_hints.append(
                f"重复读取：{top_f}{suffix}被 read_file 读取 {top_cnt} 次（占 {top_ch // 1000}K 字符），建议优先用 grep/codegraph 定位。"
            )
    if merged_cmd_chars and total_chars > 0:
        top_cmd, top_cmd_ch = max(merged_cmd_chars.items(), key=lambda x: x[1])
        if (top_cmd_ch / total_chars) >= 0.12:
            if is_en:
                bloat_hints.append(
                    f"Heavy command output: \"{top_cmd}\" emitted {top_cmd_ch // 1000}K chars ({top_cmd_ch / total_chars * 100:.1f}% of context)."
                )
            else:
                bloat_hints.append(
                    f"命令输出大户：「{top_cmd}」累计吐出 {top_cmd_ch // 1000}K 字符（占总上下文 {top_cmd_ch / total_chars * 100:.1f}%）。"
                )

    top_consumers = sorted(merged_consumers, key=lambda x: x["chars"], reverse=True)[:5]
    if is_en:
        top_consumers = [
            {**item, "category": _DIAG_SOURCE_EN.get(item["category"], item["category"])}
            for item in top_consumers
        ]
    recommendations = _build_diagnostic_recommendations(
        sources_list,
        cache_miss_summary,
        total_cost_usd,
        bloat_hints=bloat_hints,
        lang=lang,
    )

    return {
        "uuid": uuid,
        "title": root_raw["title"],
        "model": root_raw["model"],
        "subagent_count": len(sub_raws),
        "turns": turns,
        "total_tokens": total_tokens,
        "input_tokens": total_input_tokens,
        "cache_tokens": total_cache_tokens,
        "output_tokens": total_output_tokens,
        "total_cost_usd": round(total_cost_usd, 4),
        "total_chars": total_chars,
        "attributed_pct": attributed_pct,
        "phases": phases_list,
        "sources": sources_list,
        "cache_miss": cache_miss_summary,
        "top_consumers": top_consumers,
        "bloat_hints": bloat_hints,
        "recommendations": recommendations,
    }

def _is_session_actively_working(session: dict) -> bool:

    return bool(session.get("is_running") or (session.get("active_subagent_count", 0) or 0) > 0)

def build_menubar_summary(sessions: list, today_stats: dict, lang: str = "zh") -> dict:

    is_en = _normalize_lang(lang) == "en"
    idle_label = "Idle" if is_en else "待命"
    queue_label = "Queue" if is_en else "排队"
    eof_label = "EOF" if is_en else "断流"
    active_label = "Active" if is_en else "活跃"

    cost_str = fmt_cost(today_stats.get("cost_usd", 0.0))
    running_sessions = [s for s in sessions if _is_session_actively_working(s) and s.get("exists")]

    if not running_sessions:

        existing = [s for s in sessions if s.get("exists")]
        latest_tps = existing[0].get("tps", 0.0) if existing else 0.0
        if latest_tps > 0:
            return {
                "icon": "🟢",
                "text": f"🟢 {latest_tps:.0f}t/s | {cost_str}",
                "status_level": "idle",
                "active_count": 0,
            }
        return {
            "icon": "🟢",
            "text": f"🟢 {idle_label} | {cost_str}",
            "status_level": "idle",
            "active_count": 0,
        }

    alert_sessions = [
        s for s in running_sessions
        if (s.get("is_running") and (s.get("error_code") in ("503", "429", "EOF") or s.get("current_stall", 0) >= 30))
        or any(
            sub.get("is_running") and (sub.get("error_code") in ("503", "429", "EOF") or sub.get("current_stall", 0) >= 30)
            for sub in (s.get("subagents") or [])
        )
    ]
    primary = alert_sessions[0] if alert_sessions else running_sessions[0]
    active_subs = [sub for sub in (primary.get("subagents") or []) if sub.get("is_running")]
    stall_candidates = ([primary.get("current_stall", 0.0)] if primary.get("is_running") else []) + [
        sub.get("current_stall", 0.0) for sub in active_subs
    ]
    effective_stall = max(stall_candidates) if stall_candidates else 0.0
    stall_str = fmt_hms_units(effective_stall)
    err_code = primary.get("error_code") if primary.get("is_running") else next(
        (sub.get("error_code") for sub in active_subs if sub.get("error_code") in ("503", "429", "EOF")),
        None,
    )
    tps = primary.get("tps", 0.0) if primary.get("is_running") else primary.get("active_subagent_tps", 0.0)
    if tps <= 0 and primary.get("is_running"):
        tps = primary.get("active_subagent_tps", 0.0)

    if err_code == "503":
        return {
            "icon": "🔴",
            "text": f"🔴 503 | {queue_label} {stall_str}",
            "status_level": "critical",
            "active_count": len(running_sessions),
        }
    if err_code == "429":
        return {
            "icon": "⚠️",
            "text": f"⚠️ 429 | {queue_label} {stall_str}",
            "status_level": "warning",
            "active_count": len(running_sessions),
        }
    if err_code == "EOF":
        return {
            "icon": "⚠️",
            "text": f"⚠️ {eof_label} | {stall_str}",
            "status_level": "warning",
            "active_count": len(running_sessions),
        }
    if effective_stall >= 90:
        return {
            "icon": "🔴",
            "text": f"🔴 {queue_label} {stall_str} | {cost_str}",
            "status_level": "critical",
            "active_count": len(running_sessions),
        }
    if effective_stall >= 30:
        return {
            "icon": "🟡",
            "text": f"🟡 {queue_label} {stall_str} | {cost_str}",
            "status_level": "slow",
            "active_count": len(running_sessions),
        }

    tps_part = f"{tps:.0f}t/s" if tps >= 10 else (f"{tps:.1f}t/s" if tps > 0 else f"{active_label} {stall_str}")
    return {
        "icon": "🟢",
        "text": f"🟢 {tps_part} | {cost_str}",
        "status_level": "healthy",
        "active_count": len(running_sessions),
    }

def build_json_payload(
    target_uuid: str = "",
    data_dir: str | None = None,
    anchor_path: str | None = None,
    now_dt: datetime | None = None,
    lang: str = "zh",
) -> dict:

    norm_lang = _normalize_lang(lang)
    base_dir = os.path.expanduser(data_dir) if data_dir else DEFAULT_GEMINI_DIR
    sessions = load_conversations(include_steps=True, data_dir=base_dir, limit=15, now_dt=now_dt)
    today_stats = get_today_token_stats(sessions, anchor_path=anchor_path, data_dir=base_dir, now_dt=now_dt)
    menubar = build_menubar_summary(sessions, today_stats, lang=norm_lang)

    active_count = sum(1 for s in sessions if _is_session_actively_working(s))
    total_roundtrips = sum(s.get("interactions", 0) for s in sessions)
    has_alert = any(
        ("🔴" in s.get("health", "") or "⚠️" in s.get("health", ""))
        for s in sessions
        if _is_session_actively_working(s)
    )

    detail_session = None
    if target_uuid:
        db_path = os.path.join(base_dir, "conversation_summaries.db")
        brain_dir = os.path.join(base_dir, "brain")
        conv_dir = os.path.join(base_dir, "conversations")
        detail_session = inspect_session(
            target_uuid,
            brief=False,
            db_path=db_path,
            brain_dir=brain_dir,
            conversations_dir=conv_dir,
            client_type="cli" if "antigravity-cli" in os.path.basename(base_dir) else "app",
            now_dt=now_dt,
        )
        if not detail_session.get("exists") and data_dir is None and os.path.exists(DEFAULT_CLI_DIR):
            cli_detail = inspect_session(
                target_uuid,
                brief=False,
                db_path=os.path.join(DEFAULT_CLI_DIR, "conversation_summaries.db"),
                brain_dir=os.path.join(DEFAULT_CLI_DIR, "brain"),
                conversations_dir=os.path.join(DEFAULT_CLI_DIR, "conversations"),
                client_type="cli",
                now_dt=now_dt,
            )
            if cli_detail.get("exists"):
                detail_session = cli_detail

    if norm_lang == "en":
        for s in sessions:
            _localize_session_dict_en(s)
        if detail_session:
            _localize_session_dict_en(detail_session)

    ts_dt = now_dt.astimezone(timezone.utc) if now_dt is not None else datetime.now(timezone.utc)
    return {
        "timestamp": ts_dt.isoformat(),
        "data_dir": base_dir,
        "lang": norm_lang,
        "active_count": active_count,
        "total_roundtrips": total_roundtrips,
        "has_alert": has_alert,
        "menubar": menubar,
        "today_stats": today_stats,
        "sessions": [s for s in sessions if s.get("exists")],
        "all_sessions": sessions,
        "detail_session": detail_session,
    }

def compute_snapshot_etag(payload: dict) -> str:

    stable = {k: v for k, v in payload.items() if k != "timestamp"}
    encoded = json.dumps(stable, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()[:16]

def handle_daemon_request(
    req: dict,
    default_target: str = "",
    default_data_dir: str | None = None,
    default_anchor_path: str | None = None,
    default_days: int = 30,
) -> dict:

    req_id = req.get("id")
    cmd = str(req.get("cmd") or "").strip()
    req_lang = _normalize_lang(req.get("lang"))

    if cmd == "ping":
        return {"id": req_id, "ok": True, "pong": True}

    if cmd == "snapshot":
        target_uuid = str(req.get("target_uuid") if req.get("target_uuid") is not None else default_target).strip()
        data_dir = (str(req["data_dir"]).strip() or None) if req.get("data_dir") else default_data_dir
        anchor_path = (str(req["anchor_path"]).strip() or None) if req.get("anchor_path") else default_anchor_path
        if_none_match = req.get("if_none_match")
        payload = build_json_payload(target_uuid=target_uuid, data_dir=data_dir, anchor_path=anchor_path, lang=req_lang)
        etag = compute_snapshot_etag(payload)
        if isinstance(if_none_match, str) and if_none_match and if_none_match == etag:
            return {"id": req_id, "ok": True, "unchanged": True, "etag": etag}
        return {"id": req_id, "ok": True, "unchanged": False, "etag": etag, "payload": payload}

    if cmd == "recent_503":
        data_dir = (str(req["data_dir"]).strip() or None) if req.get("data_dir") else default_data_dir
        win_sec = int(req.get("window_seconds") or 3600)
        payload = count_recent_503_errors(data_dir=data_dir, window_seconds=win_sec)
        return {"id": req_id, "ok": True, "payload": payload}

    if cmd == "usage_history":
        data_dir = (str(req["data_dir"]).strip() or None) if req.get("data_dir") else default_data_dir
        days = int(req.get("days") if req.get("days") is not None else default_days)
        payload = build_usage_history_payload(days=days, data_dir=data_dir)
        return {"id": req_id, "ok": True, "payload": payload}

    if cmd == "analyze_session":
        session_id = str(req.get("session_id") or req.get("uuid") or "").strip()
        if not session_id:
            return {"id": req_id, "ok": False, "error": "missing session_id"}
        data_dir = (str(req["data_dir"]).strip() or None) if req.get("data_dir") else default_data_dir
        payload = analyze_session_diagnostics(session_id, data_dir=data_dir, lang=req_lang)
        return {"id": req_id, "ok": True, "payload": payload}

    return {"id": req_id, "ok": False, "error": f"unknown cmd: {cmd}"}

def run_daemon(
    default_target: str = "",
    default_data_dir: str | None = None,
    default_anchor_path: str | None = None,
    default_days: int = 30,
) -> int:

    while True:
        try:
            raw_line = sys.stdin.readline()
        except KeyboardInterrupt:
            break
        if raw_line == "":
            break
        line = raw_line.strip()
        if not line:
            continue

        req_id = None
        try:
            req = json.loads(line)
            if not isinstance(req, dict):
                resp = {"id": None, "ok": False, "error": "request must be a JSON object"}
            else:
                req_id = req.get("id")
                resp = handle_daemon_request(
                    req,
                    default_target=default_target,
                    default_data_dir=default_data_dir,
                    default_anchor_path=default_anchor_path,
                    default_days=default_days,
                )
        except Exception as exc:
            resp = {"id": req_id, "ok": False, "error": str(exc)}

        try:
            sys.stdout.write(json.dumps(resp, ensure_ascii=False) + "\n")
            sys.stdout.flush()
        except BrokenPipeError:
            break
    return 0

def render_rich_overview(sessions: list) -> Panel:
    active_count = sum(1 for s in sessions if s["is_running"])
    total_roundtrips = sum(s["interactions"] for s in sessions)
    has_alert = any("🔴" in s["health"] or "⚠️" in s["health"] for s in sessions if s["is_running"])

    header_title = Text()
    header_title.append(" ⚡ Antigravity 实时性能看板 (AGY-TOP) ", style="bold white on blue")
    header_title.append(f"  [活跃会话: {active_count} | 累计远端交互: {total_roundtrips} 次]  ", style="bold cyan")
    if has_alert:
        header_title.append("🚨 检测到云端排队或异常！", style="bold red")
    else:
        header_title.append("✨ 云端链路正常", style="bold green")

    table = Table(expand=True, box=None, header_style="bold magenta", padding=(0, 1))
    table.add_column("ID", width=8, style="cyan", no_wrap=True)
    table.add_column("标题 / 任务", min_width=16, max_width=24, no_wrap=True)
    table.add_column("打乒乓", width=6, justify="left", style="bold yellow", no_wrap=True)
    table.add_column("状态", width=10, justify="left", no_wrap=True)
    table.add_column("Token/s", width=9, justify="left", no_wrap=True)
    table.add_column("上下文 [缓存%] (总量/账单)", min_width=24, max_width=30, justify="left", no_wrap=True)
    table.add_column("总耗时 (本地)", min_width=18, max_width=24, justify="left", no_wrap=True)
    table.add_column("端点模型", min_width=20, justify="left", no_wrap=True)

    for s in sessions:
        if not s["exists"]:
            continue

        short_id = s["short_id"]
        title = s["title"]
        rounds = f"{s['interactions']}轮"

        ctx = s["context_tokens"]
        tot_tok = s.get("total_tokens_consumed", 0)
        tot_cost = s.get("total_cost_usd", 0.0)
        cost_str = fmt_cost(tot_cost)

        if ctx > 0:
            ctx_fmt = fmt_tokens(ctx)
            tot_fmt = fmt_tokens(tot_tok)
            if ctx > 100000:
                ctx_colored = f"[bold red]{ctx_fmt}[/bold red]"
            elif ctx > 50000:
                ctx_colored = f"[bold yellow]{ctx_fmt}[/bold yellow]"
            else:
                ctx_colored = f"{ctx_fmt}"

            cp = s.get("cache_pct", 0.0)
            if cp >= 90:
                cache_tag = f"[bold green][{cp:.0f}%][/bold green]"
            elif cp >= 70:
                cache_tag = f"[bold yellow][{cp:.0f}%][/bold yellow]"
            elif cp > 0:
                cache_tag = f"[dim][{cp:.0f}%][/dim]"
            else:
                cache_tag = "[dim][0%][/dim]"

            ctx_cell = f"{ctx_colored} {cache_tag} [dim]({tot_fmt} / {cost_str})[/dim]"
        else:
            ctx_cell = "-"

        tps = s.get("tps", 0.0)
        if tps > 0:
            tps_val = f"{tps:.0f} t/s" if tps >= 10 else f"{tps:.1f} t/s"
            if tps >= 80:
                tps_cell = f"[bold green]{tps_val}[/bold green]"
            elif tps >= 30:
                tps_cell = f"[green]{tps_val}[/green]"
            elif tps >= 15:
                tps_cell = f"[yellow]{tps_val}[/yellow]"
            else:
                tps_cell = f"[bold red]{tps_val}[/bold red]"
        else:
            tps_cell = "[dim]-[/dim]"

        tot_act = s.get("total_active_sec", 0.0)
        tot_loc = s.get("total_local_sec", 0.0)
        if tot_act > 0:
            act_txt = fmt_hms_units(tot_act)
            loc_txt = fmt_hms_units(tot_loc)
            total_local_cell = f"[cyan]{act_txt}[/cyan] [dim]({loc_txt})[/dim]"
        else:
            total_local_cell = "[dim]-[/dim]"

        stall = s["current_stall"]
        if s["is_running"]:
            stall_txt = fmt_hms_units(stall)
            if stall > 90:
                time_part = f"[bold red blink]{stall_txt}[/bold red blink]"
            elif stall > 30:
                time_part = f"[bold yellow]{stall_txt}[/bold yellow]"
            else:
                time_part = f"[green]{stall_txt}[/green]"

            if s.get("recent_error") and ("503" in s["recent_error"] or "429" in s["recent_error"]):
                err_code = "503" if "503" in s["recent_error"] else "429"
                status_cell = f"{s['health']} [bold red]{err_code}[/bold red]"
            else:
                status_cell = f"{s['health']} {time_part}"
        else:
            status_cell = "[dim]-[/dim]"

        model_name = s.get("model", "-")
        if s["is_running"]:
            model_cell = f"[bold cyan]{model_name}[/bold cyan]"
        else:
            model_cell = f"[dim]{model_name}[/dim]"

        table.add_row(
            short_id,
            title,
            rounds,
            status_cell,
            tps_cell,
            ctx_cell,
            total_local_cell,
            model_cell
        )

    today_stats = get_today_token_stats(sessions)
    if today_stats.get("has_data") and today_stats.get("total_tokens", 0) > 0:
        tot_str = fmt_tokens(today_stats["total_tokens"])
        cache_str = fmt_tokens(today_stats["cache_tokens"])
        cache_pct = today_stats["cache_pct"]
        in_str = fmt_tokens(today_stats["input_tokens"])
        out_str = fmt_tokens(today_stats["output_tokens"])
        cost_str = fmt_cost(today_stats["cost_usd"])

        metric_bar = Table.grid(expand=True)
        metric_bar.add_column(ratio=1)
        metric_bar.add_row(
            Text.from_markup(
                f" 📈 [bold yellow]今日大盘:[/bold yellow] [bold white]{tot_str}[/bold white]  "
                f"[ [dim]💾 缓存命中:[/dim] [bold green]{cache_str} ({cache_pct:.1f}%)[/bold green]  "
                f"[dim]|  📥 纯新输入:[/dim] [cyan]{in_str}[/cyan]  "
                f"[dim]|  📤 模型输出:[/dim] [magenta]{out_str}[/magenta] ]  "
                f"💰 [dim]预估账单:[/dim] [bold yellow]{cost_str}[/bold yellow]"
            )
        )
        body = Group(metric_bar, Text(""), table)
    else:
        body = table

    return Panel(body, title=header_title, subtitle="[dim]按 Ctrl+C 退出 | 提示: 敲 agy-top <uuid> 查看具体单会话详细时序[/dim]", border_style="blue")

def render_rich_detail(s: dict) -> Panel:
    title_text = Text()
    title_text.append(f" 🔍 会话性能时序诊断: {s['uuid']} ", style="bold white on cyan")
    title_text.append(f" ({s['title']})", style="bold yellow")

    ctx = s["context_tokens"]
    in_t = s["input_tokens"]
    cache_t = s["cache_tokens"]
    cache_pct = (cache_t / ctx * 100) if ctx > 0 else 0
    tot_tok = s.get("total_tokens_consumed", 0)
    tot_c_tok = s.get("total_cache_consumed", 0)
    tot_c_pct = (tot_c_tok / tot_tok * 100) if tot_tok > 0 else 0

    lines = []
    lines.append(f"• **当前状态**: {s['health']} {s['health_desc']} | 运行状态: {'[green]RUNNING[/green]' if s['is_running'] else '[dim]IDLE[/dim]'}")
    lines.append(f"• **实际端点模型 (Endpoint Model)**: [bold green]{s.get('model', '-')}[/bold green] (来源: gen_metadata)")
    lines.append(f"• **远端打乒乓交互总次数**: [bold yellow]{s['interactions']} 次[/bold yellow] (即往返调用 Google 云端大模型次数)")
    lines.append(f"• **当前上下文规模**: [bold cyan]{ctx:,} tokens[/bold cyan] (Prompt: {in_t:,} | Cache 命中: {cache_t:,} / [bold green]{cache_pct:.1f}%[/bold green])")
    tps = s.get("tps", 0.0)
    tps_desc = f"{tps:.1f} tokens/s" if tps > 0 else "-"
    lines.append(f"• **Token 生成平均速率 (TPS)**: [bold green]{tps_desc}[/bold green] (输出 Tokens / 云端生成与思考时间)")
    lines.append(f"• **累计消耗与实际账单**: [bold yellow]{fmt_tokens(tot_tok)}[/bold yellow] ({tot_tok:,} tokens [dim]| 缓存命中: {fmt_tokens(tot_c_tok)} · {tot_c_pct:.1f}%[/dim]) | 累计账单: [bold green]{fmt_cost(s.get('total_cost_usd', 0.0))}[/bold green] (输入+输出+缓存加权)")

    tot_act = s.get("total_active_sec", 0.0)
    tot_loc = s.get("total_local_sec", 0.0)
    tot_rem = s.get("total_remote_sec", 0.0)
    pct_loc = (tot_loc / tot_act * 100) if tot_act > 0 else 0
    pct_rem = (tot_rem / tot_act * 100) if tot_act > 0 else 0

    lines.append("\n[bold cyan]⏱️ 全轮次物理耗时分布 (严格方案 A: 本地与云端双层分立):[/bold cyan]")
    lines.append(f"  • **有效活动总耗时**: [bold white]{format_duration(tot_act)}[/bold white]")
    lines.append(f"  • **1. 本地执行累计**: [bold green]{format_duration(tot_loc)}[/bold green] ({pct_loc:.1f}%) [单测、代码修改、Git、文件读写]")
    lines.append(f"  • **2. 云端往返与思考累计**: [bold yellow]{format_duration(tot_rem)}[/bold yellow] ({pct_rem:.1f}%) [网络传输 + 云端排队 + 模型思考]")
    lines.append("")

    if s["is_running"]:
        lines.append(f"• **当前步等待/排队跳秒**: [bold red]{format_duration(s['current_stall'])}[/bold red]" if s['current_stall'] > 30 else f"• **当前步等待**: [green]{format_duration(s['current_stall'])}[/green]")
    if s["recent_error"]:
        lines.append(f"• **最近捕获异常**: [bold red]{s['recent_error']}[/bold red]")
    lines.append(f"• **最新动作**: [bold]{s['current_phase']}[/bold] -> {s['current_action']}")
    lines.append("\n[bold magenta]最近交互时序流水 (Recent Steps):[/bold magenta]")

    table = Table(expand=True, box=None)
    table.add_column("步数", width=8, justify="right")
    table.add_column("时间", width=12)
    table.add_column("类型", width=18)
    table.add_column("动作摘要", min_width=40)

    for st in s.get("history_steps", []):
        table.add_row(
            str(st["index"]),
            st["time"],
            st["type"],
            st["summary"]
        )

    from rich.console import Group
    from rich.markdown import Markdown
    return Panel(Group(Markdown("\n".join(lines)), table), title=title_text, border_style="cyan")

def render_ansi_overview(sessions: list):
    os.system("clear" if os.name != "nt" else "cls")
    active_count = sum(1 for s in sessions if s["is_running"])
    total_rounds = sum(s["interactions"] for s in sessions)

    print("\033[1;37;44m === Antigravity (AGY) 实时性能看板 (ANSI 模式) === \033[0m")
    print(f"\033[1;36m活跃会话: {active_count} | 累计远端交互: {total_rounds} 次\033[0m")

    today_stats = get_today_token_stats(sessions)
    if today_stats.get("has_data") and today_stats.get("total_tokens", 0) > 0:
        tot_str = fmt_tokens(today_stats["total_tokens"])
        cache_str = fmt_tokens(today_stats["cache_tokens"])
        cache_pct = today_stats["cache_pct"]
        in_str = fmt_tokens(today_stats["input_tokens"])
        out_str = fmt_tokens(today_stats["output_tokens"])
        cost_str = fmt_cost(today_stats["cost_usd"])
        print(f"\033[1;33m📈 今日大盘:\033[0m \033[1;37m{tot_str}\033[0m [\033[2m缓存:\033[0m \033[1;32m{cache_str} ({cache_pct:.1f}%)\033[0m | \033[2m输入:\033[0m \033[36m{in_str}\033[0m | \033[2m输出:\033[0m \033[35m{out_str}\033[0m] \033[2m今日账单:\033[0m \033[1;33m{cost_str}\033[0m\n")
    else:
        print()

    print(f"{'ID':<9} {'标题':<24} {'打乒乓':<8} {'状态':<10} {'Token/s':<9} {'上下文 [缓存%] (总量/账单)':<28} {'总耗时 (本地)':<18} {'端点模型'}")
    print("-" * 135)

    for s in sessions:
        if not s["exists"]:
            continue
        short_id = s["short_id"]
        title = (s["title"][:22] + "..") if len(s["title"]) > 22 else s["title"]
        rounds = f"{s['interactions']}轮"

        ctx = s["context_tokens"]
        tot_tok = s.get("total_tokens_consumed", 0)
        tot_cost = s.get("total_cost_usd", 0.0)
        cost_str = fmt_cost(tot_cost)
        if ctx > 0:
            c_tag = f"[{s.get('cache_pct', 0.0):.0f}%]"
            ctx_str = f"{fmt_tokens(ctx)} {c_tag} ({fmt_tokens(tot_tok)}/{cost_str})"
        else:
            ctx_str = "-"

        tps = s.get("tps", 0.0)
        tps_str = f"{tps:.0f} t/s" if tps > 0 else "-"

        tot_act = s.get("total_active_sec", 0.0)
        tot_loc = s.get("total_local_sec", 0.0)
        tot_time_str = f"{fmt_hms_units(tot_act)} ({fmt_hms_units(tot_loc)})" if tot_act > 0 else "-"

        stall = fmt_hms_units(s["current_stall"])
        if s["is_running"]:
            if s.get("recent_error") and ("503" in s["recent_error"] or "429" in s["recent_error"]):
                err_code = "503" if "503" in s["recent_error"] else "429"
                status_str = f"{s['health']} {err_code}"
            else:
                status_str = f"{s['health']} {stall}"
        else:
            status_str = "-"

        model = s.get("model", "-")

        print(f"{short_id:<9} {title:<24} {rounds:<8} {status_str:<10} {tps_str:<9} {ctx_str:<28} {tot_time_str:<18} {model}")

    print("\n\033[2m按 Ctrl+C 退出 | 提示: agy-top <uuid> 查看具体会话\033[0m")

def main():
    parser = argparse.ArgumentParser(description="Antigravity 会话实时性能与排队监控器 (支持 AGY-Hub --json 模式)")
    parser.add_argument("target", nargs="?", default="", help="会话 UUID，或 latest（查看最近活跃会话）")
    parser.add_argument("--once", "-1", action="store_true", help="单次快照输出，不进入常驻循环刷新")
    parser.add_argument("--json", "-j", action="store_true", help="以 JSON 格式输出结构化监控数据（供 AGY-Hub GUI 调用）")
    parser.add_argument("--daemon", action="store_true", help="以常驻 NDJSON 子进程模式运行（stdin 收命令，stdout 吐单行 JSON）")
    parser.add_argument("--usage-history", action="store_true", help="输出近 N 天逐日/今日分时与分模型用量统计 JSON")
    parser.add_argument("--recent-503", action="store_true", help="输出最近 1 小时 503 报错次数 JSON")
    parser.add_argument("--analyze-session", default="", help="输出指定会话 UUID 的上下文、工作阶段与缓存失效诊断 JSON")
    parser.add_argument("--days", type=int, default=30, help="配合 --usage-history 使用的回溯天数（默认 30）")
    parser.add_argument("--data-dir", default="", help="指定自定义 Antigravity 数据目录（默认 ~/.gemini/antigravity）")
    parser.add_argument("--anchor-path", default="", help="指定自定义 collector-anchor.json 路径")
    parser.add_argument("--lang", default="zh", help="输出语言（zh | en，默认 zh）")
    parser.add_argument("--interval", "-i", type=float, default=1.5, help="动态刷新间隔（秒，默认 1.5s）")
    args = parser.parse_args()

    custom_data_dir = args.data_dir.strip() or None
    custom_anchor = args.anchor_path.strip() or None

    if args.daemon:
        sys.exit(
            run_daemon(
                default_target=args.target.strip(),
                default_data_dir=custom_data_dir,
                default_anchor_path=custom_anchor,
                default_days=args.days,
            )
        )

    if args.usage_history:
        history_payload = build_usage_history_payload(
            days=args.days,
            data_dir=custom_data_dir,
        )
        print(json.dumps(history_payload, ensure_ascii=False))
        return

    if args.recent_503:
        res = count_recent_503_errors(data_dir=custom_data_dir)
        print(json.dumps(res, ensure_ascii=False))
        return

    if args.analyze_session.strip():
        diag = analyze_session_diagnostics(
            args.analyze_session.strip(),
            data_dir=custom_data_dir,
            lang=args.lang,
        )
        print(json.dumps(diag, ensure_ascii=False))
        return

    if args.json:
        payload = build_json_payload(
            target_uuid=args.target.strip(),
            data_dir=custom_data_dir,
            anchor_path=custom_anchor,
            lang=args.lang,
        )
        print(json.dumps(payload, ensure_ascii=False))
        return

    target_uuid = args.target.strip()
    if target_uuid.lower() == "latest":
        sessions = load_conversations(data_dir=custom_data_dir)
        if sessions:
            target_uuid = sessions[0]["uuid"]
        else:
            print("未找到任何本地 Antigravity 会话记录。")
            return
    elif target_uuid and len(target_uuid) < 32:
        sessions = load_conversations(data_dir=custom_data_dir)
        matched = [s["uuid"] for s in sessions if s["uuid"].startswith(target_uuid)]
        if matched:
            target_uuid = matched[0]

    is_detail = bool(target_uuid)

    term_width = None if sys.stdout.isatty() else 160
    term_height = None if sys.stdout.isatty() else 40
    console = Console(width=term_width, height=term_height) if HAVE_RICH else None

    if args.once:
        if is_detail:
            base_dir = os.path.expanduser(custom_data_dir) if custom_data_dir else DEFAULT_GEMINI_DIR
            data = inspect_session(
                target_uuid,
                brief=False,
                db_path=os.path.join(base_dir, "conversation_summaries.db"),
                brain_dir=os.path.join(base_dir, "brain"),
                conversations_dir=os.path.join(base_dir, "conversations"),
            )
            if HAVE_RICH:
                console.print(render_rich_detail(data))
            else:
                print(json.dumps(data, indent=2, ensure_ascii=False))
        else:
            sessions = load_conversations(data_dir=custom_data_dir)
            if HAVE_RICH:
                console.print(render_rich_overview(sessions))
            else:
                render_ansi_overview(sessions)
        return

    try:
        if HAVE_RICH:
            with Live(console=console, screen=True, refresh_per_second=2) as live:
                while True:
                    if is_detail:
                        base_dir = os.path.expanduser(custom_data_dir) if custom_data_dir else DEFAULT_GEMINI_DIR
                        data = inspect_session(
                            target_uuid,
                            brief=False,
                            db_path=os.path.join(base_dir, "conversation_summaries.db"),
                            brain_dir=os.path.join(base_dir, "brain"),
                            conversations_dir=os.path.join(base_dir, "conversations"),
                        )
                        live.update(render_rich_detail(data))
                    else:
                        sessions = load_conversations(data_dir=custom_data_dir)
                        live.update(render_rich_overview(sessions))
                    time.sleep(args.interval)
        else:
            while True:
                if is_detail:
                    base_dir = os.path.expanduser(custom_data_dir) if custom_data_dir else DEFAULT_GEMINI_DIR
                    data = inspect_session(
                        target_uuid,
                        brief=False,
                        db_path=os.path.join(base_dir, "conversation_summaries.db"),
                        brain_dir=os.path.join(base_dir, "brain"),
                        conversations_dir=os.path.join(base_dir, "conversations"),
                    )
                    print(json.dumps(data, indent=2, ensure_ascii=False))
                else:
                    sessions = load_conversations(data_dir=custom_data_dir)
                    render_ansi_overview(sessions)
                time.sleep(args.interval)
    except KeyboardInterrupt:
        pass

if __name__ == "__main__":
    main()
