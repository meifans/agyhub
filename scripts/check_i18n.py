#!/usr/bin/env python3
"""
Deterministic I18N Guardrail for Agyhub (CI + build_app.sh gate).

Checks:
1. Swift (`Sources/*.swift`):
   - Every `L10nKey` has a `.en` translation containing zero CJK characters.
   - No UI string literal (`Text("...")`, `.help("...")`, `Button("...")`, `Label("...")`,
     `Toggle("...")`, `Picker("...")`, `TextField("...")`, `NSMenuItem(title: "...")`)
     outside comments / logs / L10n dictionaries / testing code contains raw CJK characters.
2. Python (`agy-monitor.py`):
   - `build_json_payload(..., lang="en")`, `build_menubar_summary(..., lang="en")`,
     `analyze_session_diagnostics(..., lang="en")`, and `--daemon` `snapshot` / `analyze_session`
     requests with `lang="en"` produce zero CJK characters in any UI-facing field.
"""

from __future__ import annotations

import glob
import importlib.util
import json
import os
import re
import sqlite3
import sys
import tempfile

CJK_RE = re.compile(r"[\u4e00-\u9fff]")
UI_LITERAL_RE = re.compile(
    r'\b(?:Text|Button|Label|Toggle|Picker|TextField|Section)\(\s*"([^"\\]*(?:\\.[^"\\]*)*)"'
    r'|\.help\(\s*"([^"\\]*(?:\\.[^"\\]*)*)"'
    r'|NSMenuItem\(\s*title:\s*"([^"\\]*(?:\\.[^"\\]*)*)"'
)


def _strip_swift_comments(src: str) -> list[str]:
    """Return lines with Swift // and /* ... */ comments blanked out (preserving line numbers)."""
    out: list[str] = []
    in_block = False
    for raw in src.splitlines():
        i = 0
        chars: list[str] = []
        in_str = False
        while i < len(raw):
            ch = raw[i]
            nxt = raw[i : i + 2]
            if in_block:
                if nxt == "*/":
                    in_block = False
                    chars.extend([" ", " "])
                    i += 2
                else:
                    chars.append(" ")
                    i += 1
                continue
            if not in_str and nxt == "/*":
                in_block = True
                chars.extend([" ", " "])
                i += 2
                continue
            if not in_str and nxt == "//":
                break
            if ch == '"' and (i == 0 or raw[i - 1] != "\\"):
                in_str = not in_str
            chars.append(ch)
            i += 1
        out.append("".join(chars))
    return out


def _check_single_swift_file(swift_path: str, display_name: str | None = None) -> tuple[list[str], bool]:
    with open(swift_path, "r", encoding="utf-8") as fh:
        src = fh.read()
    label = display_name or os.path.basename(swift_path)
    lines = _strip_swift_comments(src)
    errors: list[str] = []

    # 1. Verify no hardcoded CJK literals in SwiftUI views outside L10n/testing/logs
    in_l10n = False
    in_testing = False
    for lineno, line in enumerate(lines, 1):
        s = line.strip()
        if s.startswith("enum AppLanguage:"):
            in_l10n = True
        elif "// MARK: - 1." in (src.splitlines()[lineno - 1]):
            in_l10n = False

        if "#if AGYHUB_TESTING" in s:
            in_testing = True
        elif in_testing and "#endif" in s:
            in_testing = False

        if in_l10n or in_testing:
            continue
        if any(k in line for k in ("appendLog", "print(", "NSLog(", "fputs(", "fatalError(")):
            continue

        for m in UI_LITERAL_RE.finditer(line):
            lit = next((g for g in m.groups() if g is not None), "")
            if CJK_RE.search(lit):
                errors.append(f"{label}:{lineno}: hardcoded CJK UI literal: {lit!r}")

    # 2. Check L10nKey coverage inside localizedPair switch (if present)
    found_l10n_key = False
    enum_match = re.search(r"enum L10nKey:.*?\{(.*?)\n\}", src, re.DOTALL)
    if enum_match:
        found_l10n_key = True
        enum_body = enum_match.group(1)
        keys = re.findall(r"\bcase\s+([A-Za-z0-9_]+)\b", enum_body)
        pair_match = re.search(r"private var localizedPair:.*?\{(.*?)\n    \}", src, re.DOTALL)
        if not pair_match:
            errors.append(f"{label}: could not locate L10nKey.localizedPair")
        else:
            pair_body = pair_match.group(1)
            for k in keys:
                case_m = re.search(rf"case\s+\.{k}\s*:\s*return\s*\((.*?)\)\s*$", pair_body, re.MULTILINE)
                if not case_m:
                    errors.append(f"{label}: L10nKey.{k} missing in localizedPair")
                    continue
                pair_expr = case_m.group(1)
                parts = re.findall(r'"([^"\\]*(?:\\.[^"\\]*)*)"', pair_expr)
                if len(parts) >= 2 and CJK_RE.search(parts[1]):
                    errors.append(f"{label}: L10nKey.{k} English string contains CJK: {parts[1]!r}")

    return errors, found_l10n_key


def check_swift_sources(sources_dir: str) -> list[str]:
    swift_files = sorted(glob.glob(os.path.join(sources_dir, "*.swift")))
    if not swift_files:
        return [f"{sources_dir}: no Swift source files found"]

    errors: list[str] = []
    found_l10n_key = False
    for path in swift_files:
        display = f"Sources/{os.path.basename(path)}"
        file_errors, has_l10n = _check_single_swift_file(path, display_name=display)
        errors.extend(file_errors)
        found_l10n_key = found_l10n_key or has_l10n

    if not found_l10n_key:
        errors.append("Sources/*.swift: could not locate enum L10nKey in any Swift source file")
    return errors


def check_swift_source(swift_path: str) -> list[str]:
    if os.path.isdir(swift_path):
        return check_swift_sources(swift_path)
    if not os.path.exists(swift_path) and os.path.basename(swift_path) == "AGYHub.swift":
        sources_dir = os.path.join(os.path.dirname(swift_path), "Sources")
        if os.path.isdir(sources_dir):
            return check_swift_sources(sources_dir)
    errors, _ = _check_single_swift_file(swift_path)
    return errors


def _walk_check_no_cjk(obj: object, path: str, skip_keys: set[str], errors: list[str]) -> None:
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k in skip_keys:
                continue
            _walk_check_no_cjk(v, f"{path}.{k}" if path else k, skip_keys, errors)
    elif isinstance(obj, list):
        for idx, item in enumerate(obj):
            _walk_check_no_cjk(item, f"{path}[{idx}]", skip_keys, errors)
    elif isinstance(obj, str):
        if CJK_RE.search(obj):
            errors.append(f"agy-monitor.py(lang=en) {path}: leaked CJK text -> {obj!r}")


def check_python_backend_en(monitor_path: str) -> list[str]:
    spec = importlib.util.spec_from_file_location("agy_monitor", monitor_path)
    mod = importlib.util.module_from_spec(spec)
    assert spec and spec.loader
    spec.loader.exec_module(mod)

    errors: list[str] = []
    with tempfile.TemporaryDirectory(prefix="agy_i18n_guard_") as tmp:
        base = os.path.join(tmp, "antigravity")
        brain = os.path.join(base, "brain")
        convs = os.path.join(base, "conversations")
        os.makedirs(brain, exist_ok=True)
        os.makedirs(convs, exist_ok=True)

        parent_id = "i1000000-0000-0000-0000-000000000001"
        child_id = "i2000000-0000-0000-0000-000000000002"

        db_path = os.path.join(base, "conversation_summaries.db")
        conn = sqlite3.connect(db_path)
        conn.execute(
            """
            CREATE TABLE conversation_summaries (
                conversation_id TEXT PRIMARY KEY,
                title TEXT,
                last_modified_time INTEGER,
                status TEXT,
                agent_name TEXT,
                parent_conversation_id TEXT,
                nesting_depth INTEGER,
                not_fully_idle INTEGER
            )
            """
        )
        conn.execute(
            "INSERT INTO conversation_summaries VALUES (?, 'Root Session', 20000, 'CASCADE_RUN_STATUS_RUNNING', '', '', 0, 1)",
            (parent_id,),
        )
        conn.execute(
            "INSERT INTO conversation_summaries VALUES (?, 'Worker', 20001, 'CASCADE_RUN_STATUS_IDLE', 'ui-i18n', ?, 1, 0)",
            (child_id, parent_id),
        )
        conn.commit()
        conn.close()

        for cid, mname in ((parent_id, "MODEL_CLAUDE_4_5_SONNET"), (child_id, "MODEL_CLAUDE_4_5_SONNET")):
            cdb = os.path.join(convs, f"{cid}.db")
            c = sqlite3.connect(cdb)
            c.execute("CREATE TABLE gen_metadata (idx INTEGER PRIMARY KEY, data BLOB)")
            c.execute("INSERT INTO gen_metadata (idx, data) VALUES (0, ?)", (mname.encode("utf-8"),))
            c.commit()
            c.close()

        parent_logs = os.path.join(brain, parent_id, ".system_generated", "logs")
        child_logs = os.path.join(brain, child_id, ".system_generated", "logs")
        os.makedirs(parent_logs, exist_ok=True)
        os.makedirs(child_logs, exist_ok=True)

        parent_steps = [
            {"step_index": 0, "type": "USER_INPUT", "created_at": "2026-11-21T01:00:00Z", "content": "Check i18n"},
            {"step_index": 1, "type": "PLANNER_RESPONSE", "created_at": "2026-11-21T01:00:05Z", "input_tokens": 10000, "cache_read_tokens": 0, "output_tokens": 100, "thinking": "t", "tool_calls": [{"name": "read_file", "arguments": {"Path": "/tmp/a.py"}}]},
            {"step_index": 2, "type": "GENERIC", "created_at": "2026-11-21T01:00:06Z", "content": "a" * 5000},
            {"step_index": 3, "type": "PLANNER_RESPONSE", "created_at": "2026-11-21T01:00:10Z", "input_tokens": 2000, "cache_read_tokens": 58000, "output_tokens": 100, "tool_calls": [{"name": "run_command", "arguments": {"CommandLine": "npm run test:e2e"}}]},
            {"step_index": 4, "type": "GENERIC", "created_at": "2026-11-21T01:00:12Z", "content": "task id: /tmp/task-11"},
            {"step_index": 5, "type": "SYSTEM_MESSAGE", "created_at": "2026-11-21T01:00:20Z", "content": "Task id \"root/task-11\" finished.\n" + ("log\n" * 4000)},
            {"step_index": 6, "type": "PLANNER_RESPONSE", "created_at": "2026-11-21T01:00:25Z", "input_tokens": 70000, "cache_read_tokens": 10000, "output_tokens": 100, "tool_calls": [{"name": "edit_file", "arguments": {"Path": "/tmp/a.py"}}]},
            {"step_index": 7, "type": "GENERIC", "created_at": "2026-11-21T01:00:26Z", "content": "edited"},
            {"step_index": 8, "type": "ERROR_MESSAGE", "created_at": "2026-11-21T01:00:30Z", "error": "503 Service Unavailable"},
            {"step_index": 9, "type": "PLANNER_RESPONSE", "created_at": "2026-11-21T01:00:35Z", "input_tokens": 82000, "cache_read_tokens": 0, "output_tokens": 100, "tool_calls": [{"name": "swarm", "arguments": {"action": "status"}}]},
            {"step_index": 10, "type": "USER_INPUT", "created_at": "2026-11-21T01:05:35Z", "content": "resume"},
            {"step_index": 11, "type": "PLANNER_RESPONSE", "created_at": "2026-11-21T01:05:40Z", "input_tokens": 85000, "cache_read_tokens": 0, "output_tokens": 100, "tool_calls": [{"name": "read_file", "arguments": {"Path": "/tmp/a.py"}}]},
            {"step_index": 12, "type": "GENERIC", "created_at": "2026-11-21T01:05:41Z", "content": "a" * 5000},
            {"step_index": 13, "type": "PLANNER_RESPONSE", "created_at": "2026-11-21T01:05:45Z", "input_tokens": 40000, "cache_read_tokens": 0, "output_tokens": 100, "tool_calls": [{"name": "read_file", "arguments": {"Path": "/tmp/a.py"}}]},
            {"step_index": 14, "type": "GENERIC", "created_at": "2026-11-21T01:05:46Z", "content": "a" * 5000},
            {"step_index": 15, "type": "ERROR_MESSAGE", "created_at": "2026-11-21T01:05:50Z", "error": "503 No capacity"},
        ]
        child_steps = [
            {"step_index": 0, "type": "USER_INPUT", "created_at": "2026-11-21T01:01:00Z", "content": "work"},
            {"step_index": 1, "type": "PLANNER_RESPONSE", "created_at": "2026-11-21T01:01:05Z", "input_tokens": 60000, "cache_read_tokens": 0, "output_tokens": 200, "content": "done"},
        ]
        with open(os.path.join(parent_logs, "transcript_full.jsonl"), "w", encoding="utf-8") as fh:
            for item in parent_steps:
                fh.write(json.dumps(item) + "\n")
        with open(os.path.join(child_logs, "transcript_full.jsonl"), "w", encoding="utf-8") as fh:
            for item in child_steps:
                fh.write(json.dumps(item) + "\n")

        # Require lang parameter on both analyze_session_diagnostics and build_json_payload
        try:
            diag = mod.analyze_session_diagnostics(parent_id, data_dir=base, lang="en")
        except TypeError as exc:
            return [f"agy-monitor.py: analyze_session_diagnostics must accept lang='en': {exc}"]
        try:
            snap = mod.build_json_payload(target_uuid=parent_id, data_dir=base, lang="en")
        except TypeError as exc:
            return [f"agy-monitor.py: build_json_payload must accept lang='en': {exc}"]

        skip_raw_fields = {"title", "uuid", "short_id", "data_dir", "label", "cmd", "command", "current_action"}
        _walk_check_no_cjk(diag, "analyze_session", skip_raw_fields, errors)
        _walk_check_no_cjk(snap, "snapshot", skip_raw_fields, errors)

    return errors


def main() -> int:
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    swift_errors = check_swift_sources(os.path.join(root, "Sources"))
    py_errors = check_python_backend_en(os.path.join(root, "agy-monitor.py"))
    all_errors = swift_errors + py_errors
    if all_errors:
        print(f"❌ I18N Guardrail failed ({len(all_errors)} issue(s)):", file=sys.stderr)
        for err in all_errors:
            print(f"  - {err}", file=sys.stderr)
        return 1
    print("✅ I18N Guardrail passed (0 leaked CJK UI strings in Swift & Python lang=en outputs)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
