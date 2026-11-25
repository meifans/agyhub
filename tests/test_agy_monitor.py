#!/usr/bin/env python3

import importlib.util
import json
import os
import sqlite3
import subprocess
import sys
import tempfile
import time
import unittest
from datetime import datetime, timedelta, timezone
from unittest import mock

REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC = importlib.util.spec_from_file_location("agy_monitor", os.path.join(REPO_DIR, "agy-monitor.py"))
agy_monitor = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(agy_monitor)

def _write_transcript(brain_dir: str, uuid: str, steps: list[dict]) -> None:
    log_dir = os.path.join(brain_dir, uuid, ".system_generated", "logs")
    os.makedirs(log_dir, exist_ok=True)
    with open(os.path.join(log_dir, "transcript.jsonl"), "w", encoding="utf-8") as f:
        for st in steps:
            f.write(json.dumps(st, ensure_ascii=False) + "\n")

class AgyMonitorSubagentTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory(prefix="agy_mon_sub_")
        self.base_dir = os.path.join(self.tmp.name, "antigravity")
        self.brain_dir = os.path.join(self.base_dir, "brain")
        self.conv_dir = os.path.join(self.base_dir, "conversations")
        os.makedirs(self.brain_dir, exist_ok=True)
        os.makedirs(self.conv_dir, exist_ok=True)
        self.db_path = os.path.join(self.base_dir, "conversation_summaries.db")
        self.anchor_path = os.path.join(self.tmp.name, "collector-anchor.json")

        conn = sqlite3.connect(self.db_path)
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
        conn.commit()
        conn.close()

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def _insert_summary(
        self,
        cid: str,
        title: str,
        mod_time: int,
        status: str = "CASCADE_RUN_STATUS_IDLE",
        agent_name: str = "",
        parent_id: str = "",
        depth: int = 0,
        not_fully_idle: int = 0,
    ) -> None:
        conn = sqlite3.connect(self.db_path)
        conn.execute(
            """
            INSERT INTO conversation_summaries (
                conversation_id, title, last_modified_time, status,
                agent_name, parent_conversation_id, nesting_depth, not_fully_idle
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (cid, title, mod_time, status, agent_name, parent_id, depth, not_fully_idle),
        )
        conn.commit()
        conn.close()

    def test_groups_swarm_and_invoke_subagents_under_parent_and_aggregates_working_tps(self) -> None:
        parent_id = "73afac2a-3258-43cf-8cea-2d55f3404557"
        sub_run_1 = "5def2d27-e860-4e6f-9e23-eb2ae3efc515"
        sub_run_2 = "e6bd7b16-f850-4474-8c22-6ef9caa23810"
        sub_idle = "7f5a2c2b-27f1-47ee-bd61-4b3fd8c65c30"
        normal_id = "e24b5cf7-0000-0000-0000-000000000001"

        self._insert_summary(parent_id, "/sp Local Changes Review", 2000, status="CASCADE_RUN_STATUS_IDLE", not_fully_idle=0)
        self._insert_summary(sub_run_1, "", 2005, status="CASCADE_RUN_STATUS_RUNNING", agent_name="verifier", parent_id=parent_id, depth=1, not_fully_idle=1)
        self._insert_summary(sub_run_2, "", 2004, status="CASCADE_RUN_STATUS_RUNNING", agent_name="web-clean", parent_id=parent_id, depth=1, not_fully_idle=1)
        self._insert_summary(sub_idle, "", 2001, status="CASCADE_RUN_STATUS_IDLE", agent_name="monitor", parent_id=parent_id, depth=1, not_fully_idle=0)
        self._insert_summary(normal_id, "Normal Task", 1900, status="CASCADE_RUN_STATUS_IDLE", not_fully_idle=0)

        _write_transcript(
            self.brain_dir,
            parent_id,
            [
                {"step_index": 0, "type": "USER_INPUT", "created_at": "2026-11-14T00:00:00Z", "content": "/sp"},
                {"step_index": 1, "type": "PLANNER_RESPONSE", "created_at": "2026-11-14T00:00:02Z", "input_tokens": 100, "cache_read_tokens": 900, "output_tokens": 120},
            ],
        )
        sub_desc_dir = os.path.join(self.brain_dir, parent_id, ".system_generated", "subagents")
        os.makedirs(sub_desc_dir, exist_ok=True)
        with open(os.path.join(sub_desc_dir, f"{sub_run_1}.json"), "w", encoding="utf-8") as f:
            json.dump({"conversationId": sub_run_1, "subagentDescriptor": {"typeName": "worker", "role": "Swarm Worker (verifier)"}}, f)

        _write_transcript(
            self.brain_dir,
            sub_run_1,
            [
                {"step_index": 0, "type": "USER_INPUT", "created_at": "2026-11-14T00:00:00Z", "content": "verify"},
                {"step_index": 1, "type": "PLANNER_RESPONSE", "created_at": "2026-11-14T00:00:02Z", "input_tokens": 50, "cache_read_tokens": 450, "output_tokens": 200, "tool_calls": [{"name": "run_command", "args": {"CommandLine": "pytest"}}]},
            ],
        )

        _write_transcript(
            self.brain_dir,
            sub_run_2,
            [
                {"step_index": 0, "type": "USER_INPUT", "created_at": "2026-11-14T00:00:00Z", "content": "clean"},
                {"step_index": 1, "type": "PLANNER_RESPONSE", "created_at": "2026-11-14T00:00:05Z", "input_tokens": 80, "cache_read_tokens": 520, "output_tokens": 300, "tool_calls": [{"name": "edit_file", "args": {"Path": "foo.ts"}}]},
            ],
        )

        _write_transcript(
            self.brain_dir,
            sub_idle,
            [
                {"step_index": 0, "type": "USER_INPUT", "created_at": "2026-11-14T00:00:00Z", "content": "watch"},
                {"step_index": 1, "type": "PLANNER_RESPONSE", "created_at": "2026-11-14T00:00:01Z", "input_tokens": 20, "cache_read_tokens": 100, "output_tokens": 50},
            ],
        )
        _write_transcript(
            self.brain_dir,
            normal_id,
            [
                {"step_index": 0, "type": "USER_INPUT", "created_at": "2026-11-14T00:00:00Z", "content": "hi"},
                {"step_index": 1, "type": "PLANNER_RESPONSE", "created_at": "2026-11-14T00:00:01Z", "input_tokens": 10, "cache_read_tokens": 90, "output_tokens": 20},
            ],
        )

        payload = agy_monitor.build_json_payload(data_dir=self.base_dir, anchor_path=self.anchor_path)
        top_sessions = payload["sessions"]
        top_ids = [s["uuid"] for s in top_sessions]

        self.assertEqual(top_ids, [parent_id, normal_id])

        parent = top_sessions[0]
        self.assertEqual(parent["subagent_count"], 3)
        self.assertEqual(parent["active_subagent_count"], 2)
        self.assertAlmostEqual(parent["active_subagent_tps"], 160.0, places=1)

        subs = parent["subagents"]
        self.assertEqual(len(subs), 3)
        by_id = {s["uuid"]: s for s in subs}
        self.assertEqual(by_id[sub_run_1]["agent_name"], "verifier")
        self.assertEqual(by_id[sub_run_1]["agent_role"], "Swarm Worker (verifier)")
        self.assertTrue(by_id[sub_run_1]["is_running"])
        self.assertFalse(by_id[sub_idle]["is_running"])

        self.assertGreaterEqual(payload["active_count"], 1)

    def test_idle_parent_with_not_fully_idle_flag_is_not_marked_running_or_leaking_tps(self) -> None:
        parent_id = "a92ce2cc-0000-0000-0000-000000000001"
        sub_run_id = "fedcc2bd-0000-0000-0000-000000000002"
        now_utc = datetime.now(timezone.utc)
        t0 = (now_utc - timedelta(minutes=6)).strftime("%Y-%m-%dT%H:%M:%SZ")
        t1 = (now_utc - timedelta(minutes=5, seconds=58)).strftime("%Y-%m-%dT%H:%M:%SZ")
        t_sub0 = (now_utc - timedelta(seconds=20)).strftime("%Y-%m-%dT%H:%M:%SZ")
        t_sub1 = (now_utc - timedelta(seconds=10)).strftime("%Y-%m-%dT%H:%M:%SZ")

        self._insert_summary(
            parent_id,
            "页面按钮布局位移问题",
            2000,
            status="CASCADE_RUN_STATUS_IDLE",
            not_fully_idle=1,
        )
        self._insert_summary(
            sub_run_id,
            "",
            2005,
            status="CASCADE_RUN_STATUS_RUNNING",
            agent_name="guardrail-tests",
            parent_id=parent_id,
            depth=1,
            not_fully_idle=1,
        )

        _write_transcript(
            self.brain_dir,
            parent_id,
            [
                {"step_index": 0, "type": "USER_INPUT", "created_at": t0, "content": "fix layout"},
                {"step_index": 1, "type": "PLANNER_RESPONSE", "created_at": t1, "input_tokens": 1000, "cache_read_tokens": 9000, "output_tokens": 300, "content": "dispatched workers"},
            ],
        )
        _write_transcript(
            self.brain_dir,
            sub_run_id,
            [
                {"step_index": 0, "type": "GENERIC", "created_at": t_sub0, "content": "run"},
                {"step_index": 1, "type": "PLANNER_RESPONSE", "created_at": t_sub1, "input_tokens": 500, "cache_read_tokens": 1500, "output_tokens": 150, "tool_calls": [{"name": "run_command", "args": {"CommandLine": "pytest"}}]},
            ],
        )

        payload = agy_monitor.build_json_payload(data_dir=self.base_dir, anchor_path=self.anchor_path, now_dt=now_utc)
        self.assertEqual([s["uuid"] for s in payload["sessions"]], [parent_id])
        parent = payload["sessions"][0]

        self.assertFalse(parent["is_running"])
        self.assertEqual(parent["status_label"], "CASCADE_RUN_STATUS_IDLE")
        self.assertEqual(parent["health_code"], "idle")
        self.assertEqual(parent["active_subagent_count"], 1)
        self.assertAlmostEqual(parent["active_subagent_tps"], 15.0, places=1)
        self.assertEqual(payload["active_count"], 1)
        self.assertIn("15t/s", payload["menubar"]["text"])
        self.assertNotIn("150t/s", payload["menubar"]["text"])

        direct_parent = agy_monitor.inspect_session(
            parent_id,
            db_path=self.db_path,
            brain_dir=self.brain_dir,
            conversations_dir=self.conv_dir,
            now_dt=now_utc,
        )
        self.assertFalse(direct_parent["is_running"])

        zero_tps_sub = {
            **parent,
            "current_stall": 46.0,
            "active_subagent_tps": 0.0,
            "subagents": [{**parent["subagents"][0], "tps": 0.0, "current_stall": 3.0}],
        }
        menubar_zero = agy_monitor.build_menubar_summary([zero_tps_sub], {"cost_usd": 1.0})
        self.assertNotIn("150t/s", menubar_zero["text"])
        self.assertEqual(menubar_zero["status_level"], "healthy")

        legacy_id = "legacy00-0000-0000-0000-000000000003"
        self._insert_summary(legacy_id, "Legacy Blank Status", 3000, status="", not_fully_idle=1)
        legacy_res = agy_monitor.inspect_session(
            legacy_id,
            db_path=self.db_path,
            brain_dir=self.brain_dir,
            conversations_dir=self.conv_dir,
            now_dt=now_utc,
        )
        self.assertTrue(legacy_res["is_running"])

    def test_subagents_do_not_evict_top_level_sessions_under_limit(self) -> None:
        parent_id = "p0000000-0000-0000-0000-000000000001"
        self._insert_summary(parent_id, "Coordinator Parent", 5000)
        _write_transcript(
            self.brain_dir,
            parent_id,
            [{"step_index": 0, "type": "PLANNER_RESPONSE", "created_at": "2026-11-14T00:00:01Z", "input_tokens": 10, "output_tokens": 10}],
        )

        for i in range(20):
            sid = f"c0000000-0000-0000-0000-{i:012d}"
            self._insert_summary(sid, "", 6000 + i, agent_name=f"worker-{i}", parent_id=parent_id, depth=1)
            _write_transcript(
                self.brain_dir,
                sid,
                [{"step_index": 0, "type": "PLANNER_RESPONSE", "created_at": "2026-11-14T00:00:01Z", "input_tokens": 10, "output_tokens": 10}],
            )
        for i in range(14):
            oid = f"o0000000-0000-0000-0000-{i:012d}"
            self._insert_summary(oid, f"Top Session {i}", 4000 - i)
            _write_transcript(
                self.brain_dir,
                oid,
                [{"step_index": 0, "type": "PLANNER_RESPONSE", "created_at": "2026-11-14T00:00:01Z", "input_tokens": 10, "output_tokens": 10}],
            )

        sessions = agy_monitor.load_conversations(include_steps=False, data_dir=self.base_dir, limit=15, include_cli=False)
        existing_top = [s for s in sessions if s["exists"]]
        self.assertEqual(len(existing_top), 15)
        self.assertEqual(existing_top[0]["subagent_count"], 20)

class AgyMonitorUsageAnalyticsTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory(prefix="agy_mon_usage_")
        self.base_dir = os.path.join(self.tmp.name, "antigravity")
        self.brain_dir = os.path.join(self.base_dir, "brain")
        self.conv_dir = os.path.join(self.base_dir, "conversations")
        os.makedirs(self.brain_dir, exist_ok=True)
        os.makedirs(self.conv_dir, exist_ok=True)
        self.cache_path = os.path.join(self.tmp.name, "usage_daily_cache.json")
        self.archive_path = os.path.join(self.tmp.name, "daily-history-archive.json")
        self.anchor_path = os.path.join(self.tmp.name, "collector-anchor.json")

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def _write_conv_models(self, uuid: str, models: list[str]) -> None:
        db_file = os.path.join(self.conv_dir, f"{uuid}.db")
        if os.path.exists(db_file):
            os.remove(db_file)
        conn = sqlite3.connect(db_file)
        conn.execute("CREATE TABLE gen_metadata (idx INTEGER PRIMARY KEY, data BLOB)")
        for idx, m in enumerate(models):
            conn.execute("INSERT INTO gen_metadata (idx, data) VALUES (?, ?)", (idx, m.encode("utf-8")))
        conn.commit()
        conn.close()

    def test_today_stats_only_sums_today_steps_and_never_falls_back_to_lifetime_sessions(self) -> None:
        fixed_now = datetime(2026, 11, 16, 15, 30, 0, tzinfo=timezone.utc).astimezone()
        today_local = fixed_now.strftime("%Y-%m-%d")
        yesterday_utc = "2026-11-15T10:00:00Z"
        today_utc_1 = fixed_now.replace(hour=9, minute=0).astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        today_utc_2 = fixed_now.replace(hour=14, minute=15).astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

        cid = "u0000000-0000-0000-0000-000000000001"
        _write_transcript(
            self.brain_dir,
            cid,
            [
                {"step_index": 0, "type": "PLANNER_RESPONSE", "created_at": yesterday_utc, "input_tokens": 100000, "cache_read_tokens": 9000000, "output_tokens": 50000},
                {"step_index": 1, "type": "PLANNER_RESPONSE", "created_at": today_utc_1, "input_tokens": 1000, "cache_read_tokens": 9000, "output_tokens": 500},
                {"step_index": 2, "type": "PLANNER_RESPONSE", "created_at": today_utc_2, "input_tokens": 2000, "cache_read_tokens": 18000, "output_tokens": 1000},
            ],
        )

        self._write_conv_models(
            cid,
            [
                "gemini-4-argon-high",
                "claude-sonnet-5-5-low",
                "gemini-4-hydrogen-n",
                "gemini-3.8-flash-low",
            ],
        )

        with open(self.anchor_path, "w", encoding="utf-8") as f:
            json.dump({"dailyTotal": {"date": "2026-11-12", "totalTokens": 999999999, "estimatedCost": 99.9}}, f)

        history = agy_monitor.build_usage_history_payload(
            days=7,
            data_dir=self.base_dir,
            include_cli=False,
            cache_path=self.cache_path,
            archive_path=None,
            now_dt=fixed_now,
        )
        self.assertEqual(history["today_date"], today_local)
        self.assertEqual(len(history["daily"]), 7)
        today_bucket = history["daily"][-1]
        self.assertEqual(today_bucket["date"], today_local)

        self.assertEqual(today_bucket["total_tokens"], 31500)
        self.assertEqual(today_bucket["calls"], 2)

        by_model = {m["model"]: m for m in today_bucket["models"]}
        self.assertIn("claude-sonnet-5-5", by_model)
        self.assertIn("gemini-4-hydrogen", by_model)
        self.assertNotIn("gemini-3.8-flash", by_model)
        self.assertEqual(by_model["claude-sonnet-5-5"]["total_tokens"], 10500)
        self.assertEqual(by_model["gemini-4-hydrogen"]["total_tokens"], 21000)

        hourly = {h["hour"]: h for h in history["today_hourly"]}
        self.assertEqual(len(hourly), 24)
        self.assertEqual(hourly[9]["total_tokens"], 10500)
        self.assertEqual(hourly[14]["total_tokens"], 21000)

        fake_sessions = [{"total_tokens_consumed": 999_000_000, "total_cost_usd": 42.26, "total_cache_consumed": 0, "total_input_consumed": 0, "total_output_consumed": 0}]
        today_stats = agy_monitor.get_today_token_stats(
            fake_sessions,
            anchor_path=self.anchor_path,
            data_dir=self.base_dir,
            include_cli=False,
            cache_path=self.cache_path,
            now_dt=fixed_now,
        )
        self.assertEqual(today_stats["total_tokens"], 31500)
        self.assertAlmostEqual(today_stats["cost_usd"], today_bucket["cost_usd"], places=6)

        empty_now = datetime(2026, 11, 20, 12, 0, 0, tzinfo=timezone.utc).astimezone()
        empty_today = agy_monitor.get_today_token_stats(
            fake_sessions,
            anchor_path=self.anchor_path,
            data_dir=self.base_dir,
            include_cli=False,
            cache_path=self.cache_path,
            now_dt=empty_now,
        )
        self.assertEqual(empty_today["total_tokens"], 0)
        self.assertEqual(empty_today["cost_usd"], 0.0)
        self.assertFalse(empty_today["has_data"])

    def test_incremental_cache_hits_and_invalidates_on_transcript_update(self) -> None:
        fixed_now = datetime(2026, 11, 16, 12, 0, 0, tzinfo=timezone.utc).astimezone()
        t1 = fixed_now.replace(hour=10, minute=0).astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        t2 = fixed_now.replace(hour=11, minute=0).astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        cid = "c0000000-0000-0000-0000-000000000002"
        _write_transcript(
            self.brain_dir,
            cid,
            [{"step_index": 0, "type": "PLANNER_RESPONSE", "created_at": t1, "input_tokens": 100, "cache_read_tokens": 900, "output_tokens": 50}],
        )
        self._write_conv_models(cid, ["gemini-4-argon-high"])

        res1 = agy_monitor.build_usage_history_payload(
            days=7,
            data_dir=self.base_dir,
            include_cli=False,
            cache_path=self.cache_path,
            archive_path=None,
            now_dt=fixed_now,
        )
        self.assertTrue(os.path.exists(self.cache_path))
        self.assertEqual(res1["daily"][-1]["total_tokens"], 1050)
        self.assertGreater(len(res1["daily"][-1]["models"]), 0)

        res2 = agy_monitor.build_usage_history_payload(
            days=7,
            data_dir=self.base_dir,
            include_cli=False,
            cache_path=self.cache_path,
            archive_path=None,
            now_dt=fixed_now,
        )
        self.assertEqual(res2["daily"][-1]["total_tokens"], 1050)

        _write_transcript(
            self.brain_dir,
            cid,
            [
                {"step_index": 0, "type": "PLANNER_RESPONSE", "created_at": t1, "input_tokens": 100, "cache_read_tokens": 900, "output_tokens": 50},
                {"step_index": 1, "type": "PLANNER_RESPONSE", "created_at": t2, "input_tokens": 200, "cache_read_tokens": 1800, "output_tokens": 100},
            ],
        )
        self._write_conv_models(cid, ["gemini-4-argon-high", "gemini-4-hydrogen-n"])
        res3 = agy_monitor.build_usage_history_payload(
            days=7,
            data_dir=self.base_dir,
            include_cli=False,
            cache_path=self.cache_path,
            archive_path=None,
            now_dt=fixed_now,
        )
        self.assertEqual(res3["daily"][-1]["total_tokens"], 3150)
        self.assertEqual(agy_monitor.normalize_model_key("gemini-4-argon-trial"), "gemini-4-argon")
        self.assertEqual(agy_monitor.normalize_model_key("gemini-3.8-flash-q"), "gemini-3.8-flash")
        self.assertEqual(agy_monitor.normalize_model_key("claude-sonnet-5-5-low"), "claude-sonnet-5-5")
        self.assertEqual(agy_monitor.normalize_model_key("gemini-4-hydrogen-tiered-xhigh"), "gemini-4-hydrogen")

    def test_official_step_pricing_across_all_models(self) -> None:
        pre_dec = datetime(2026, 11, 17, 8, 0, 0)
        post_dec = datetime(2026, 12, 2, 8, 0, 0)
        post_jan27 = datetime(2027, 1, 2, 8, 0, 0)

        self.assertAlmostEqual(
            agy_monitor.calculate_step_cost("gemini-4-hydrogen-high", 1_000_000, 1_000_000, 1_000_000, now=pre_dec),
            1.50 + 0.075 + 7.50,
            places=6,
        )

        self.assertAlmostEqual(
            agy_monitor.calculate_step_cost("gemini-4-neon", 1_000_000, 1_000_000, 1_000_000, now=pre_dec),
            3.00 + 0.15 + 15.00,
            places=6,
        )

        self.assertAlmostEqual(
            agy_monitor.calculate_step_cost("gemini-4-argon-trial", 1_000_000, 1_000_000, 1_000_000, now=pre_dec),
            2.00 + 0.10 + 10.00,
            places=6,
        )
        self.assertAlmostEqual(
            agy_monitor.calculate_step_cost("gemini-4-carbon", 1_000_000, 1_000_000, 1_000_000, now=post_dec),
            4.00 + 0.20 + 20.00,
            places=6,
        )

        self.assertAlmostEqual(
            agy_monitor.calculate_step_cost("gemini-3.8-flash-n", 1_000_000, 1_000_000, 1_000_000, now=pre_dec),
            0.75 + 0.075 + 3.75,
            places=6,
        )
        self.assertAlmostEqual(
            agy_monitor.calculate_step_cost("gemini-3.8-flash-n", 1_000_000, 1_000_000, 1_000_000, now=post_jan27),
            1.50 + 0.15 + 7.50,
            places=6,
        )

        self.assertAlmostEqual(
            agy_monitor.calculate_step_cost("claude-sonnet-5-5-low", 1_000_000, 1_000_000, 1_000_000, now=pre_dec),
            2.00 + 0.10 + 10.00,
            places=6,
        )
        self.assertAlmostEqual(
            agy_monitor.calculate_step_cost("claude-opus-5-5", 1_000_000, 1_000_000, 1_000_000, now=pre_dec),
            4.00 + 0.20 + 20.00,
            places=6,
        )
        self.assertAlmostEqual(
            agy_monitor.calculate_step_cost("claude-opus-4-6-thinking", 1_000_000, 1_000_000, 1_000_000, now=pre_dec),
            5.00 + 0.50 + 25.00,
            places=6,
        )
        self.assertAlmostEqual(
            agy_monitor.calculate_step_cost("claude-sonnet-4-6", 1_000_000, 1_000_000, 1_000_000, now=pre_dec),
            3.00 + 0.30 + 15.00,
            places=6,
        )

        self.assertAlmostEqual(
            agy_monitor.calculate_step_cost("gpt-oss-120b", 1_000_000, 1_000_000, 1_000_000, now=pre_dec),
            0.09 + 0.009 + 0.36,
            places=6,
        )
        self.assertAlmostEqual(
            agy_monitor.calculate_step_cost("gemini-3-pro", 100_000, 50_000, 10_000, now=pre_dec),
            (100_000 * 1.25 + 50_000 * 0.125 + 10_000 * 10.00) / 1e6,
            places=6,
        )
        self.assertAlmostEqual(
            agy_monitor.calculate_step_cost("gemini-3-pro", 100_000, 150_000, 10_000, now=pre_dec),
            (100_000 * 2.50 + 150_000 * 0.25 + 10_000 * 15.00) / 1e6,
            places=6,
        )

    def test_backfills_pre_transcript_days_from_daily_archive(self) -> None:
        fixed_now = datetime(2026, 11, 16, 12, 0, 0, tzinfo=timezone.utc).astimezone()
        t_recent = datetime(2026, 11, 15, 10, 0, 0, tzinfo=timezone.utc).astimezone().astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        cid = "a0000000-0000-0000-0000-000000000003"
        _write_transcript(
            self.brain_dir,
            cid,
            [{"step_index": 0, "type": "PLANNER_RESPONSE", "created_at": t_recent, "input_tokens": 100, "cache_read_tokens": 900, "output_tokens": 50}],
        )
        self._write_conv_models(cid, ["gemini-3.8-flash-n"])

        archive = {
            "2026-11-10": {
                "clients": {
                    "antigravity": {
                        "totalTokens": 500000,
                        "inputTokens": 5000,
                        "cacheReadTokens": 490000,
                        "outputTokens": 5000,
                        "estimatedCost": 2.5,
                        "callCount": 20,
                        "byModel": {
                            "claude-sonnet-4-6": {
                                "totalTokens": 500000,
                                "inputTokens": 5000,
                                "cacheReadTokens": 490000,
                                "outputTokens": 5000,
                                "estimatedCost": 2.5,
                                "callCount": 20,
                            }
                        },
                    }
                }
            },
            "2026-11-15": {
                "clients": {
                    "antigravity": {
                        "totalTokens": 9999999,
                        "estimatedCost": 99.0,
                    }
                }
            },
        }
        with open(self.archive_path, "w", encoding="utf-8") as f:
            json.dump(archive, f)

        res = agy_monitor.build_usage_history_payload(
            days=10,
            data_dir=self.base_dir,
            include_cli=False,
            cache_path=self.cache_path,
            archive_path=self.archive_path,
            now_dt=fixed_now,
        )
        by_date = {d["date"]: d for d in res["daily"]}
        self.assertEqual(by_date["2026-11-10"]["total_tokens"], 500000)
        self.assertAlmostEqual(by_date["2026-11-10"]["cost_usd"], 2.5, places=4)
        self.assertEqual(by_date["2026-11-10"]["models"][0]["model"], "claude-sonnet-4-6")

        self.assertEqual(by_date["2026-11-15"]["total_tokens"], 1050)

    def test_usage_history_aggregates_conversations_and_rolls_up_subagents(self) -> None:
        fixed_now = datetime(2026, 11, 17, 9, 0, 0, tzinfo=timezone.utc).astimezone()
        today_utc = fixed_now.replace(hour=8, minute=0).astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        yesterday_utc = (fixed_now.replace(hour=8, minute=0) - __import__("datetime").timedelta(days=1)).astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

        parent_id = "p1000000-0000-0000-0000-000000000001"
        sub_id = "s1000000-0000-0000-0000-000000000002"
        other_id = "o1000000-0000-0000-0000-000000000003"

        db_path = os.path.join(self.base_dir, "conversation_summaries.db")
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
        conn.execute("INSERT INTO conversation_summaries VALUES (?, ?, 2000, 'IDLE', '', '', 0, 0)", (parent_id, "Refactor Analytics UI"))
        conn.execute("INSERT INTO conversation_summaries VALUES (?, ?, 2001, 'IDLE', 'verifier', ?, 1, 0)", (sub_id, "", parent_id))
        conn.execute("INSERT INTO conversation_summaries VALUES (?, ?, 1900, 'IDLE', '', '', 0, 0)", (other_id, "Quick Bug Fix"))
        conn.commit()
        conn.close()

        _write_transcript(
            self.brain_dir,
            parent_id,
            [
                {"step_index": 0, "type": "PLANNER_RESPONSE", "created_at": yesterday_utc, "input_tokens": 5000, "cache_read_tokens": 50000, "output_tokens": 500},
                {"step_index": 1, "type": "PLANNER_RESPONSE", "created_at": today_utc, "input_tokens": 1000, "cache_read_tokens": 9000, "output_tokens": 500},
            ],
        )
        self._write_conv_models(parent_id, ["gemini-4-hydrogen-high", "gemini-4-hydrogen-high"])

        _write_transcript(
            self.brain_dir,
            sub_id,
            [
                {"step_index": 0, "type": "PLANNER_RESPONSE", "created_at": today_utc, "input_tokens": 2000, "cache_read_tokens": 18000, "output_tokens": 1000},
            ],
        )
        self._write_conv_models(sub_id, ["gemini-4-hydrogen-high"])

        _write_transcript(
            self.brain_dir,
            other_id,
            [
                {"step_index": 0, "type": "PLANNER_RESPONSE", "created_at": today_utc, "input_tokens": 500, "cache_read_tokens": 4500, "output_tokens": 200},
            ],
        )
        self._write_conv_models(other_id, ["gemini-3.8-flash-n"])

        res = agy_monitor.build_usage_history_payload(
            days=7,
            data_dir=self.base_dir,
            include_cli=False,
            cache_path=self.cache_path,
            archive_path=None,
            now_dt=fixed_now,
        )
        today_sessions = res["daily"][-1]["sessions"]

        self.assertEqual(len(today_sessions), 2)
        self.assertEqual(today_sessions[0]["uuid"], parent_id)
        self.assertEqual(today_sessions[0]["title"], "Refactor Analytics UI")

        self.assertEqual(today_sessions[0]["total_tokens"], 31500)
        self.assertEqual(today_sessions[0]["calls"], 2)
        self.assertEqual(today_sessions[0]["subagent_count"], 1)
        self.assertEqual(today_sessions[0]["top_model"], "gemini-4-hydrogen")
        self.assertEqual(today_sessions[1]["uuid"], other_id)
        self.assertEqual(today_sessions[1]["total_tokens"], 5200)

    def test_count_recent_503_errors_only_counts_last_hour(self) -> None:
        fixed_now = datetime(2026, 11, 19, 11, 45, 0, tzinfo=timezone.utc).astimezone()
        dt_within_1 = (fixed_now - __import__("datetime").timedelta(minutes=15)).astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        dt_within_2 = (fixed_now - __import__("datetime").timedelta(minutes=45)).astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        dt_old = (fixed_now - __import__("datetime").timedelta(minutes=75)).astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

        cid = "e5030000-0000-0000-0000-000000000001"
        _write_transcript(
            self.brain_dir,
            cid,
            [
                {"step_index": 0, "type": "ERROR_MESSAGE", "created_at": dt_old, "error": "API error: UNAVAILABLE (code 503): No capacity"},
                {"step_index": 1, "type": "ERROR_MESSAGE", "created_at": dt_within_1, "error": "API error: UNAVAILABLE (code 503): No capacity"},
                {"step_index": 2, "type": "ERROR_MESSAGE", "created_at": dt_within_2, "error": "API error: UNAVAILABLE (code 503): No capacity"},
                {"step_index": 3, "type": "ERROR_MESSAGE", "created_at": dt_within_1, "error": "API error: 429 rate limit"},
                {"step_index": 4, "type": "PLANNER_RESPONSE", "created_at": dt_within_1, "content": "Mentioned 503 in prose"},
            ],
        )

        res = agy_monitor.count_recent_503_errors(
            data_dir=self.base_dir,
            include_cli=False,
            window_seconds=3600,
            now_dt=fixed_now,
        )
        self.assertEqual(res["count"], 2)
        self.assertEqual(res["window_minutes"], 60)

    def test_stale_error_cleared_after_recovery_and_tps_excludes_error_wait(self) -> None:
        cid = "r1000000-0000-0000-0000-000000000001"
        _write_transcript(
            self.brain_dir,
            cid,
            [
                {"step_index": 0, "type": "USER_INPUT", "created_at": "2026-11-19T05:00:00Z", "content": "hi"},
                {"step_index": 1, "type": "ERROR_MESSAGE", "created_at": "2026-11-19T05:10:00Z", "error": "API error (attempt 7): request failed: stream interrupted"},
                {"step_index": 2, "type": "SYSTEM_MESSAGE", "created_at": "2026-11-19T05:40:00Z", "content": "resumed"},
                {"step_index": 3, "type": "PLANNER_RESPONSE", "created_at": "2026-11-19T05:40:05Z", "input_tokens": 100, "cache_read_tokens": 900, "output_tokens": 500, "tool_calls": [{"name": "read_file"}]},
                {"step_index": 4, "type": "GENERIC", "created_at": "2026-11-19T05:40:06Z", "content": "ok"},
                {"step_index": 5, "type": "PLANNER_RESPONSE", "created_at": "2026-11-19T05:40:10Z", "input_tokens": 100, "cache_read_tokens": 1400, "output_tokens": 400, "content": "done"},
            ],
        )

        res = agy_monitor.inspect_session(
            cid,
            brief=False,
            db_path=os.path.join(self.base_dir, "conversation_summaries.db"),
            brain_dir=self.brain_dir,
            conversations_dir=self.conv_dir,
        )

        self.assertIsNone(res["recent_error"])
        self.assertIsNone(res["error_code"])

        self.assertGreaterEqual(res["tps"], 95.0)
        self.assertLessEqual(res["tps"], 105.0)

    def test_tps_filters_timestamp_flush_spike_steps(self) -> None:
        cid = "s5000000-0000-0000-0000-000000000001"
        _write_transcript(
            self.brain_dir,
            cid,
            [
                {"step_index": 0, "type": "USER_INPUT", "created_at": "2026-11-19T06:00:00Z", "content": "step1"},
                {"step_index": 1, "type": "PLANNER_RESPONSE", "created_at": "2026-11-19T06:00:05Z", "input_tokens": 100, "cache_read_tokens": 900, "output_tokens": 500, "tool_calls": [{"name": "read_file"}]},
                {"step_index": 2, "type": "GENERIC", "created_at": "2026-11-19T06:00:06Z", "content": "ok"},

                {"step_index": 3, "type": "PLANNER_RESPONSE", "created_at": "2026-11-19T06:00:07Z", "input_tokens": 100, "cache_read_tokens": 900, "output_tokens": 22652, "tool_calls": [{"name": "read_file"}]},
                {"step_index": 4, "type": "GENERIC", "created_at": "2026-11-19T06:00:10Z", "content": "ok"},
                {"step_index": 5, "type": "PLANNER_RESPONSE", "created_at": "2026-11-19T06:00:15Z", "input_tokens": 100, "cache_read_tokens": 900, "output_tokens": 500, "content": "done"},
            ],
        )

        res = agy_monitor.inspect_session(
            cid,
            brief=False,
            db_path=os.path.join(self.base_dir, "conversation_summaries.db"),
            brain_dir=self.brain_dir,
            conversations_dir=self.conv_dir,
        )

        self.assertGreaterEqual(res["tps"], 95.0)
        self.assertLessEqual(res["tps"], 105.0)

    def test_analyze_session_context_phases_and_cache_misses(self) -> None:
        cid = "s6000000-0000-0000-0000-000000000001"
        logs_dir = os.path.join(self.brain_dir, cid, ".system_generated", "logs")
        os.makedirs(logs_dir, exist_ok=True)

        _write_transcript(
            self.brain_dir,
            cid,
            [{"step_index": 0, "type": "USER_INPUT", "created_at": "2026-11-20T01:00:00Z", "content": "stub"}],
        )

        big_code_content = "x" * 12000
        big_e2e_log = "E2E PASSED LOG " + ("line\n" * 3000)
        steps = [

            {"step_index": 0, "type": "USER_INPUT", "created_at": "2026-11-20T01:00:00Z", "content": "请排查 E2E 并修改"},
            {
                "step_index": 1,
                "type": "PLANNER_RESPONSE",
                "created_at": "2026-11-20T01:00:05Z",
                "input_tokens": 10000,
                "cache_read_tokens": 0,
                "output_tokens": 300,
                "thinking": "先看源码",
                "tool_calls": [{"name": "read_file", "arguments": {"Path": "/tmp/app.py"}}],
            },
            {"step_index": 2, "type": "GENERIC", "created_at": "2026-11-20T01:00:06Z", "content": big_code_content},

            {
                "step_index": 3,
                "type": "PLANNER_RESPONSE",
                "created_at": "2026-11-20T01:00:10Z",
                "input_tokens": 50000,
                "cache_read_tokens": 10000,
                "output_tokens": 250,
                "tool_calls": [{"name": "run_command", "arguments": {"CommandLine": "npm run test:e2e"}}],
            },
            {
                "step_index": 4,
                "type": "GENERIC",
                "created_at": "2026-11-20T01:00:12Z",
                "content": "Command running in background (task id: /tmp/task-11).",
            },
            {
                "step_index": 5,
                "type": "SYSTEM_MESSAGE",
                "created_at": "2026-11-20T01:00:40Z",
                "content": f"Background task /tmp/task-11 completed with exit code 0.\n{big_e2e_log}",
            },

            {
                "step_index": 6,
                "type": "PLANNER_RESPONSE",
                "created_at": "2026-11-20T01:00:45Z",
                "input_tokens": 70000,
                "cache_read_tokens": 10000,
                "output_tokens": 400,
                "tool_calls": [{"name": "edit_file", "arguments": {"Path": "/tmp/app.py"}}],
            },
            {"step_index": 7, "type": "GENERIC", "created_at": "2026-11-20T01:00:46Z", "content": "Successfully edited /tmp/app.py"},

            {
                "step_index": 7,
                "type": "USER_INPUT",
                "created_at": "2026-11-20T01:02:45Z",
                "content": "继续看看看板状态",
            },
            {
                "step_index": 8,
                "type": "PLANNER_RESPONSE",
                "created_at": "2026-11-20T01:02:46Z",
                "input_tokens": 82000,
                "cache_read_tokens": 0,
                "output_tokens": 200,
                "tool_calls": [{"name": "swarm", "arguments": {"action": "status"}}],
            },
            {"step_index": 9, "type": "GENERIC", "created_at": "2026-11-20T01:02:47Z", "content": "board status ok"},

            {"step_index": 10, "type": "ERROR_MESSAGE", "created_at": "2026-11-20T01:02:55Z", "content": "503 Service Unavailable"},
            {
                "step_index": 11,
                "type": "PLANNER_RESPONSE",
                "created_at": "2026-11-20T01:03:00Z",
                "input_tokens": 85000,
                "cache_read_tokens": 0,
                "output_tokens": 350,
                "tool_calls": [{"name": "read_board", "arguments": {}}],
            },
            {"step_index": 12, "type": "GENERIC", "created_at": "2026-11-20T01:03:01Z", "content": "empty board"},

            {
                "step_index": 13,
                "type": "PLANNER_RESPONSE",
                "created_at": "2026-11-20T01:03:10Z",
                "input_tokens": 55000,
                "cache_read_tokens": 0,
                "output_tokens": 300,
                "content": "排查与修复已完成。",
            },
        ]
        full_path = os.path.join(logs_dir, "transcript_full.jsonl")
        with open(full_path, "w", encoding="utf-8") as fh:
            for item in steps:
                fh.write(json.dumps(item, ensure_ascii=False) + "\n")

        summary_db = os.path.join(self.base_dir, "conversation_summaries.db")
        conn = sqlite3.connect(summary_db)
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS conversation_summaries (
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
            "INSERT INTO conversation_summaries VALUES (?, ?, 10000, 'CASCADE_RUN_STATUS_IDLE', '', '', 0, 0)",
            (cid, "E2E 诊断测试"),
        )
        conn.commit()
        conn.close()
        self._write_conv_models(cid, ["MODEL_CLAUDE_4_5_SONNET"])

        report = agy_monitor.analyze_session_diagnostics(cid, data_dir=self.base_dir)
        self.assertEqual(report["uuid"], cid)
        self.assertEqual(report["title"], "E2E 诊断测试")

        phase_names = {p["name"] for p in report["phases"]}
        self.assertIn("调研/检索", phase_names)
        self.assertIn("编码修改", phase_names)
        self.assertIn("测试/构建/排错", phase_names)
        self.assertIn("调度/看板协作", phase_names)
        self.assertIn("总结/文字输出", phase_names)

        source_map = {s["name"]: s for s in report["sources"]}
        self.assertIn("read_file 读取", source_map)
        self.assertGreaterEqual(source_map["read_file 读取"]["chars"], 12000)
        self.assertIn("后台测试/E2E回传", source_map)
        self.assertGreater(source_map["后台测试/E2E回传"]["chars"], 10000)
        self.assertGreaterEqual(report["attributed_pct"], 95.0)

        miss = report["cache_miss"]
        self.assertEqual(miss["total_misses"], 4)
        self.assertGreater(miss["extra_cost_usd"], 0.0)
        cause_names = {c["cause"] for c in miss["by_cause"]}
        self.assertEqual(
            cause_names,
            {"云端报错/切节点重连", "停顿/等待续聊过期", "压缩/重开重建", "前缀/系统注入变动"},
        )
        self.assertGreaterEqual(len(miss["top_events"]), 4)

        costs = [e["extra_cost_usd"] for e in miss["top_events"]]
        self.assertEqual(costs, sorted(costs, reverse=True))

        details_joined = " | ".join(e["detail"] for e in miss["top_events"])
        self.assertIn("task-11", details_joined)
        self.assertIn("503", details_joined)
        self.assertIn("2m", details_joined)

        self.assertIn("bloat_hints", report)
        self.assertIsInstance(report["bloat_hints"], list)

        self._write_conv_models(cid, ["gemini-3.8-flash"])
        flash_report = agy_monitor.analyze_session_diagnostics(cid, data_dir=self.base_dir)
        self.assertGreater(flash_report["total_cost_usd"], 0.0)

        self.assertGreater(len(report["top_consumers"]), 0)
        self.assertGreater(len(report["recommendations"]), 0)

    def test_analyze_session_aggregates_subagents_when_present(self) -> None:
        parent_id = "p1000000-0000-0000-0000-000000000001"
        child_id = "c1000000-0000-0000-0000-000000000002"

        _write_transcript(
            self.brain_dir,
            parent_id,
            [
                {"step_index": 0, "type": "USER_INPUT", "created_at": "2026-11-20T02:00:00Z", "content": "统筹任务"},
                {
                    "step_index": 1,
                    "type": "PLANNER_RESPONSE",
                    "created_at": "2026-11-20T02:00:05Z",
                    "input_tokens": 10000,
                    "cache_read_tokens": 0,
                    "output_tokens": 100,
                    "tool_calls": [{"name": "swarm", "arguments": {"action": "add"}}],
                },
            ],
        )
        _write_transcript(
            self.brain_dir,
            child_id,
            [
                {"step_index": 0, "type": "USER_INPUT", "created_at": "2026-11-20T02:00:10Z", "content": "执行子任务"},
                {
                    "step_index": 1,
                    "type": "PLANNER_RESPONSE",
                    "created_at": "2026-11-20T02:00:15Z",
                    "input_tokens": 60000,
                    "cache_read_tokens": 0,
                    "output_tokens": 200,
                    "tool_calls": [{"name": "read_file", "arguments": {"Path": "/tmp/sub.py"}}],
                },
                {"step_index": 2, "type": "GENERIC", "created_at": "2026-11-20T02:00:16Z", "content": "y" * 5000},
                {"step_index": 3, "type": "ERROR_MESSAGE", "created_at": "2026-11-20T02:00:20Z", "content": "503"},
                {
                    "step_index": 4,
                    "type": "PLANNER_RESPONSE",
                    "created_at": "2026-11-20T02:00:25Z",
                    "input_tokens": 65000,
                    "cache_read_tokens": 0,
                    "output_tokens": 200,
                    "content": "完成",
                },
            ],
        )

        summary_db = os.path.join(self.base_dir, "conversation_summaries.db")
        conn = sqlite3.connect(summary_db)
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS conversation_summaries (
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
            "INSERT INTO conversation_summaries VALUES (?, ?, 10000, 'CASCADE_RUN_STATUS_IDLE', '', '', 0, 0)",
            (parent_id, "主调度线程"),
        )
        conn.execute(
            "INSERT INTO conversation_summaries VALUES (?, ?, 10001, 'CASCADE_RUN_STATUS_IDLE', 'ci-e2e', ?, 1, 0)",
            (child_id, "子任务", parent_id),
        )
        conn.commit()
        conn.close()
        self._write_conv_models(parent_id, ["MODEL_CLAUDE_4_5_SONNET"])
        self._write_conv_models(child_id, ["MODEL_CLAUDE_4_5_SONNET"])

        report = agy_monitor.analyze_session_diagnostics(parent_id, data_dir=self.base_dir)
        self.assertEqual(report["subagent_count"], 1)
        self.assertEqual(report["turns"], 3)
        self.assertEqual(report["cache_miss"]["total_misses"], 1)
        self.assertEqual(report["cache_miss"]["top_events"][0]["agent_name"], "ci-e2e")

        child_report = agy_monitor.analyze_session_diagnostics(child_id, data_dir=self.base_dir)
        self.assertEqual(child_report["subagent_count"], 0)
        self.assertEqual(child_report["turns"], 2)

class AgyMonitorPerfCacheAndDaemonTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory(prefix="agy_mon_perf_")
        self.base_dir = os.path.join(self.tmp.name, "antigravity")
        self.brain_dir = os.path.join(self.base_dir, "brain")
        self.conv_dir = os.path.join(self.base_dir, "conversations")
        os.makedirs(self.brain_dir, exist_ok=True)
        os.makedirs(self.conv_dir, exist_ok=True)
        self.db_path = os.path.join(self.base_dir, "conversation_summaries.db")
        self.anchor_path = os.path.join(self.tmp.name, "collector-anchor.json")
        self.inspect_cache_path = os.path.join(self.tmp.name, "session_inspect_cache_v1.json")
        self.usage_cache_path = os.path.join(self.tmp.name, "usage_daily_cache.json")

        conn = sqlite3.connect(self.db_path)
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
        conn.commit()
        conn.close()

        self._old_cache_env = os.environ.get("AGYHUB_INSPECT_CACHE_PATH")
        self._old_usage_env = os.environ.get("AGYHUB_USAGE_CACHE_PATH")
        self._old_disable_env = os.environ.get("AGYHUB_DISABLE_CACHE")
        os.environ["AGYHUB_INSPECT_CACHE_PATH"] = self.inspect_cache_path
        os.environ["AGYHUB_USAGE_CACHE_PATH"] = self.usage_cache_path
        os.environ.pop("AGYHUB_DISABLE_CACHE", None)
        if hasattr(agy_monitor, "clear_runtime_caches"):
            agy_monitor.clear_runtime_caches()

    def tearDown(self) -> None:
        if self._old_cache_env is None:
            os.environ.pop("AGYHUB_INSPECT_CACHE_PATH", None)
        else:
            os.environ["AGYHUB_INSPECT_CACHE_PATH"] = self._old_cache_env
        if self._old_usage_env is None:
            os.environ.pop("AGYHUB_USAGE_CACHE_PATH", None)
        else:
            os.environ["AGYHUB_USAGE_CACHE_PATH"] = self._old_usage_env
        if self._old_disable_env is None:
            os.environ.pop("AGYHUB_DISABLE_CACHE", None)
        else:
            os.environ["AGYHUB_DISABLE_CACHE"] = self._old_disable_env
        if hasattr(agy_monitor, "clear_runtime_caches"):
            agy_monitor.clear_runtime_caches()
        self.tmp.cleanup()

    def _insert_summary(
        self,
        cid: str,
        title: str,
        mod_time: int,
        status: str = "CASCADE_RUN_STATUS_IDLE",
        not_fully_idle: int = 0,
    ) -> None:
        conn = sqlite3.connect(self.db_path)
        conn.execute(
            """
            INSERT OR REPLACE INTO conversation_summaries (
                conversation_id, title, last_modified_time, status,
                agent_name, parent_conversation_id, nesting_depth, not_fully_idle
            ) VALUES (?, ?, ?, ?, '', '', 0, ?)
            """,
            (cid, title, mod_time, status, not_fully_idle),
        )
        conn.commit()
        conn.close()

    def _write_conv_model(self, uuid: str, model: str) -> None:
        db_file = os.path.join(self.conv_dir, f"{uuid}.db")
        if os.path.exists(db_file):
            os.remove(db_file)
        conn = sqlite3.connect(db_file)
        conn.execute("CREATE TABLE gen_metadata (idx INTEGER PRIMARY KEY, data BLOB)")
        conn.execute("INSERT INTO gen_metadata (idx, data) VALUES (0, ?)", (model.encode("utf-8"),))
        conn.commit()
        conn.close()

    def test_session_inspect_cache_hits_and_invalidates_on_file_or_model_change(self) -> None:
        cid = "c1000000-0000-0000-0000-000000000001"
        self._insert_summary(cid, "Cache Test", 1000)
        self._write_conv_model(cid, "gemini-4-argon-high")
        _write_transcript(
            self.brain_dir,
            cid,
            [
                {"step_index": 0, "type": "USER_INPUT", "created_at": "2026-11-21T01:00:00Z", "content": "hi"},
                {"step_index": 1, "type": "PLANNER_RESPONSE", "created_at": "2026-11-21T01:00:05Z", "input_tokens": 100, "cache_read_tokens": 900, "output_tokens": 200, "content": "ok"},
            ],
        )

        res1 = agy_monitor.inspect_session(
            cid,
            brief=False,
            db_path=self.db_path,
            brain_dir=self.brain_dir,
            conversations_dir=self.conv_dir,
        )
        self.assertEqual(res1["interactions"], 1)
        self.assertEqual(res1["model"], "gemini-4-argon-high")
        self.assertTrue(os.path.exists(self.inspect_cache_path))
        with open(self.inspect_cache_path, "r", encoding="utf-8") as f:
            disk_cache = json.load(f)
        self.assertEqual(disk_cache.get("schema_version"), 1)

        with mock.patch.object(agy_monitor, "_parse_session_transcript_static", side_effect=AssertionError("should hit mem cache")):
            res2 = agy_monitor.inspect_session(
                cid,
                brief=False,
                db_path=self.db_path,
                brain_dir=self.brain_dir,
                conversations_dir=self.conv_dir,
            )
        self.assertEqual(res2["interactions"], 1)
        self.assertEqual(res2["total_output_consumed"], 200)

        agy_monitor.clear_runtime_caches()
        with mock.patch.object(agy_monitor, "_parse_session_transcript_static", side_effect=AssertionError("should hit disk cache")):
            res3 = agy_monitor.inspect_session(
                cid,
                brief=False,
                db_path=self.db_path,
                brain_dir=self.brain_dir,
                conversations_dir=self.conv_dir,
            )
        self.assertEqual(res3["interactions"], 1)
        self.assertEqual(res3["total_output_consumed"], 200)

        _write_transcript(
            self.brain_dir,
            cid,
            [
                {"step_index": 0, "type": "USER_INPUT", "created_at": "2026-11-21T01:00:00Z", "content": "hi"},
                {"step_index": 1, "type": "PLANNER_RESPONSE", "created_at": "2026-11-21T01:00:05Z", "input_tokens": 100, "cache_read_tokens": 900, "output_tokens": 200, "tool_calls": [{"name": "read_file"}]},
                {"step_index": 2, "type": "GENERIC", "created_at": "2026-11-21T01:00:06Z", "content": "ok"},
                {"step_index": 3, "type": "PLANNER_RESPONSE", "created_at": "2026-11-21T01:00:10Z", "input_tokens": 200, "cache_read_tokens": 1000, "output_tokens": 300, "content": "done"},
            ],
        )
        res4 = agy_monitor.inspect_session(
            cid,
            brief=False,
            db_path=self.db_path,
            brain_dir=self.brain_dir,
            conversations_dir=self.conv_dir,
        )
        self.assertEqual(res4["interactions"], 2)
        self.assertEqual(res4["total_output_consumed"], 500)

        self._write_conv_model(cid, "claude-opus-4-6")
        res5 = agy_monitor.inspect_session(
            cid,
            brief=False,
            db_path=self.db_path,
            brain_dir=self.brain_dir,
            conversations_dir=self.conv_dir,
        )
        self.assertEqual(res5["model"], "claude-opus-4-6")
        self.assertNotAlmostEqual(res5["total_cost_usd"], res4["total_cost_usd"], places=6)

    def test_dynamic_stall_and_health_recomputed_on_cache_hit_never_frozen(self) -> None:
        cid = "d2000000-0000-0000-0000-000000000001"
        self._insert_summary(cid, "Running Stall Test", 2000, status="CASCADE_RUN_STATUS_RUNNING", not_fully_idle=1)
        self._write_conv_model(cid, "gemini-4-hydrogen-n")
        t0 = datetime(2026, 11, 21, 1, 0, 0, tzinfo=timezone.utc)
        _write_transcript(
            self.brain_dir,
            cid,
            [
                {"step_index": 0, "type": "USER_INPUT", "created_at": "2026-11-21T01:00:00Z", "content": "run task"},
            ],
        )

        r_10 = agy_monitor.inspect_session(
            cid,
            brief=False,
            db_path=self.db_path,
            brain_dir=self.brain_dir,
            conversations_dir=self.conv_dir,
            now_dt=t0 + timedelta(seconds=10),
        )
        self.assertAlmostEqual(r_10["current_stall"], 10.0, places=1)
        self.assertEqual(r_10["health_code"], "healthy")

        r_45 = agy_monitor.inspect_session(
            cid,
            brief=False,
            db_path=self.db_path,
            brain_dir=self.brain_dir,
            conversations_dir=self.conv_dir,
            now_dt=t0 + timedelta(seconds=45),
        )
        self.assertAlmostEqual(r_45["current_stall"], 45.0, places=1)
        self.assertEqual(r_45["health_code"], "slow")
        self.assertIn("45秒", r_45["health_desc"])

        agy_monitor.clear_runtime_caches()
        r_100 = agy_monitor.inspect_session(
            cid,
            brief=False,
            db_path=self.db_path,
            brain_dir=self.brain_dir,
            conversations_dir=self.conv_dir,
            now_dt=t0 + timedelta(seconds=100),
        )
        self.assertAlmostEqual(r_100["current_stall"], 100.0, places=1)
        self.assertEqual(r_100["health_code"], "stalled")
        self.assertIn("1分40秒", r_100["health_desc"])

        p_warm = agy_monitor.build_json_payload(
            data_dir=self.base_dir,
            anchor_path=self.anchor_path,
            now_dt=t0 + timedelta(seconds=100),
        )
        os.environ["AGYHUB_DISABLE_CACHE"] = "1"
        agy_monitor.clear_runtime_caches()
        p_cold = agy_monitor.build_json_payload(
            data_dir=self.base_dir,
            anchor_path=self.anchor_path,
            now_dt=t0 + timedelta(seconds=100),
        )
        self.assertEqual(p_warm["menubar"], p_cold["menubar"])
        self.assertEqual(p_warm["sessions"], p_cold["sessions"])

    def test_corrupt_inspect_cache_auto_recovers(self) -> None:
        cid = "b3000000-0000-0000-0000-000000000001"
        self._insert_summary(cid, "Corrupt Recovery", 1500)
        _write_transcript(
            self.brain_dir,
            cid,
            [{"step_index": 0, "type": "PLANNER_RESPONSE", "created_at": "2026-11-21T01:00:05Z", "input_tokens": 10, "output_tokens": 20, "content": "ok"}],
        )

        with open(self.inspect_cache_path, "w", encoding="utf-8") as f:
            f.write("{broken json!!!")

        res = agy_monitor.build_json_payload(data_dir=self.base_dir, anchor_path=self.anchor_path)
        self.assertEqual(len(res["sessions"]), 1)
        self.assertEqual(res["sessions"][0]["output_tokens"], 20)

        with open(self.inspect_cache_path, "r", encoding="utf-8") as f:
            rebuilt = json.load(f)
        self.assertEqual(rebuilt.get("schema_version"), 1)
        self.assertIsInstance(rebuilt.get("sessions"), dict)

        agy_monitor.clear_runtime_caches()
        with open(self.inspect_cache_path, "w", encoding="utf-8") as f:
            json.dump({"schema_version": 999, "sessions": "bad"}, f)
        res2 = agy_monitor.build_json_payload(data_dir=self.base_dir, anchor_path=self.anchor_path)
        self.assertEqual(len(res2["sessions"]), 1)
        with open(self.inspect_cache_path, "r", encoding="utf-8") as f:
            rebuilt2 = json.load(f)
        self.assertEqual(rebuilt2.get("schema_version"), 1)

    def test_disable_cache_env_bypasses_inspect_cache(self) -> None:
        cid = "n4000000-0000-0000-0000-000000000001"
        self._insert_summary(cid, "No Cache", 1200)
        _write_transcript(
            self.brain_dir,
            cid,
            [{"step_index": 0, "type": "PLANNER_RESPONSE", "created_at": "2026-11-21T01:00:05Z", "input_tokens": 10, "output_tokens": 20, "content": "ok"}],
        )
        os.environ["AGYHUB_DISABLE_CACHE"] = "1"
        res = agy_monitor.inspect_session(
            cid,
            brief=False,
            db_path=self.db_path,
            brain_dir=self.brain_dir,
            conversations_dir=self.conv_dir,
        )
        self.assertEqual(res["output_tokens"], 20)
        self.assertFalse(os.path.exists(self.inspect_cache_path))

        os.environ.pop("AGYHUB_DISABLE_CACHE", None)
        agy_monitor.inspect_session(
            cid,
            brief=False,
            db_path=self.db_path,
            brain_dir=self.brain_dir,
            conversations_dir=self.conv_dir,
        )
        self.assertTrue(os.path.exists(self.inspect_cache_path))

        os.environ["AGYHUB_DISABLE_CACHE"] = "1"
        parse_calls = 0
        orig_parse = agy_monitor._parse_session_transcript_static

        def counting_parse(*args, **kwargs):
            nonlocal parse_calls
            parse_calls += 1
            return orig_parse(*args, **kwargs)

        with mock.patch.object(agy_monitor, "_parse_session_transcript_static", side_effect=counting_parse):
            res_cold = agy_monitor.inspect_session(
                cid,
                brief=False,
                db_path=self.db_path,
                brain_dir=self.brain_dir,
                conversations_dir=self.conv_dir,
            )
        self.assertEqual(parse_calls, 1)
        self.assertEqual(res_cold["output_tokens"], 20)

    def test_daemon_ndjson_protocol_and_eof_exit(self) -> None:
        cid = "e5000000-0000-0000-0000-000000000001"
        now_utc = datetime.now(timezone.utc)
        t_recent = (now_utc - timedelta(minutes=10)).strftime("%Y-%m-%dT%H:%M:%SZ")
        self._insert_summary(cid, "Daemon Session", 3000, status="CASCADE_RUN_STATUS_IDLE", not_fully_idle=0)
        self._write_conv_model(cid, "gemini-4-hydrogen-n")
        _write_transcript(
            self.brain_dir,
            cid,
            [
                {"step_index": 0, "type": "USER_INPUT", "created_at": t_recent, "content": "analyze me"},
                {"step_index": 1, "type": "ERROR_MESSAGE", "created_at": t_recent, "error": "API error 503 No capacity"},
                {"step_index": 2, "type": "PLANNER_RESPONSE", "created_at": t_recent, "input_tokens": 100, "cache_read_tokens": 900, "output_tokens": 50, "content": "done"},
            ],
        )

        script_path = os.path.join(REPO_DIR, "agy-monitor.py")
        env = os.environ.copy()
        env["AGYHUB_INSPECT_CACHE_PATH"] = self.inspect_cache_path
        env["AGYHUB_USAGE_CACHE_PATH"] = self.usage_cache_path
        proc = subprocess.Popen(
            [sys.executable, script_path, "--daemon", "--data-dir", self.base_dir, "--anchor-path", self.anchor_path],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
            env=env,
        )
        try:
            def send(obj_or_raw):
                line = obj_or_raw if isinstance(obj_or_raw, str) else json.dumps(obj_or_raw)
                proc.stdin.write(line + "\n")
                proc.stdin.flush()
                out_line = proc.stdout.readline()
                self.assertTrue(out_line, "daemon closed stdout unexpectedly")
                return json.loads(out_line)

            r_ping = send({"id": 1, "cmd": "ping"})
            self.assertEqual(r_ping, {"id": 1, "ok": True, "pong": True})

            r_snap1 = send({"id": "s1", "cmd": "snapshot"})
            self.assertTrue(r_snap1["ok"])
            self.assertFalse(r_snap1["unchanged"])
            etag1 = r_snap1["etag"]
            self.assertTrue(isinstance(etag1, str) and len(etag1) > 0)
            self.assertEqual(len(r_snap1["payload"]["sessions"]), 1)

            r_snap2 = send({"id": "s2", "cmd": "snapshot", "if_none_match": etag1})
            self.assertEqual(r_snap2["id"], "s2")
            self.assertTrue(r_snap2["ok"])
            self.assertTrue(r_snap2["unchanged"])
            self.assertEqual(r_snap2["etag"], etag1)
            self.assertNotIn("payload", r_snap2)

            r_503 = send({"id": 4, "cmd": "recent_503"})
            self.assertTrue(r_503["ok"])
            self.assertEqual(r_503["payload"]["count"], 1)

            r_uh = send({"id": 5, "cmd": "usage_history", "days": 7})
            self.assertTrue(r_uh["ok"])
            self.assertEqual(r_uh["payload"]["days_requested"], 7)
            self.assertEqual(len(r_uh["payload"]["daily"]), 7)

            r_an = send({"id": 6, "cmd": "analyze_session", "session_id": cid})
            self.assertTrue(r_an["ok"])
            self.assertEqual(r_an["payload"]["uuid"], cid)

            r_bad_json = send("{not valid json")
            self.assertFalse(r_bad_json["ok"])
            self.assertIn("error", r_bad_json)

            r_unk = send({"id": 7, "cmd": "nope"})
            self.assertEqual(r_unk["id"], 7)
            self.assertFalse(r_unk["ok"])
            self.assertIn("error", r_unk)

            r_miss = send({"id": 8, "cmd": "analyze_session"})
            self.assertEqual(r_miss["id"], 8)
            self.assertFalse(r_miss["ok"])

            self._insert_summary(cid, "Daemon Session", 4000, status="CASCADE_RUN_STATUS_RUNNING", not_fully_idle=1)
            _write_transcript(
                self.brain_dir,
                cid,
                [
                    {"step_index": 0, "type": "USER_INPUT", "created_at": (datetime.now(timezone.utc) - timedelta(seconds=5)).strftime("%Y-%m-%dT%H:%M:%SZ"), "content": "working"},
                ],
            )
            r_run1 = send({"id": 9, "cmd": "snapshot", "if_none_match": etag1})
            self.assertFalse(r_run1["unchanged"])
            etag_run1 = r_run1["etag"]
            self.assertNotEqual(etag_run1, etag1)
            time.sleep(1.1)
            r_run2 = send({"id": 10, "cmd": "snapshot", "if_none_match": etag_run1})
            self.assertFalse(r_run2["unchanged"])
            self.assertNotEqual(r_run2["etag"], etag_run1)

            proc.stdin.close()
            rc = proc.wait(timeout=5)
            stderr_out = proc.stderr.read()
            self.assertEqual(rc, 0)
            self.assertEqual(stderr_out, "")
        finally:
            for stream in (proc.stdin, proc.stdout, proc.stderr):
                if stream is not None and not stream.closed:
                    try:
                        stream.close()
                    except OSError:
                        pass
            if proc.poll() is None:
                proc.kill()
                proc.wait(timeout=3)

class AgyMonitorI18nGuardrailTests(unittest.TestCase):
    def test_english_mode_backend_and_swift_guardrail_zero_cjk(self) -> None:
        root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        guard_path = os.path.join(root, "scripts", "check_i18n.py")
        spec = importlib.util.spec_from_file_location("check_i18n", guard_path)
        guard = importlib.util.module_from_spec(spec)
        assert spec and spec.loader
        spec.loader.exec_module(guard)

        py_errors = guard.check_python_backend_en(os.path.join(root, "agy-monitor.py"))
        self.assertEqual(py_errors, [], f"Python lang=en CJK leak(s): {py_errors}")
        swift_errors = guard.check_swift_source(os.path.join(root, "AGYHub.swift"))
        self.assertEqual(swift_errors, [], f"Swift static I18N violation(s): {swift_errors}")

    def test_daemon_snapshot_respects_lang_in_etag_and_analyze_session_en(self) -> None:
        with tempfile.TemporaryDirectory(prefix="agy_i18n_daemon_") as tmp:
            base_dir = os.path.join(tmp, "antigravity")
            brain = os.path.join(base_dir, "brain")
            convs = os.path.join(base_dir, "conversations")
            os.makedirs(brain, exist_ok=True)
            os.makedirs(convs, exist_ok=True)
            cid = "d9000000-0000-0000-0000-000000000001"
            db_path = os.path.join(base_dir, "conversation_summaries.db")
            conn = sqlite3.connect(db_path)
            conn.execute(
                """
                CREATE TABLE conversation_summaries (
                    conversation_id TEXT PRIMARY KEY, title TEXT, last_modified_time INTEGER,
                    status TEXT, agent_name TEXT, parent_conversation_id TEXT,
                    nesting_depth INTEGER, not_fully_idle INTEGER
                )
                """
            )
            conn.execute("INSERT INTO conversation_summaries VALUES (?, 'Test', 20000, 'CASCADE_RUN_STATUS_IDLE', '', '', 0, 0)", (cid,))
            conn.commit()
            conn.close()
            _write_transcript(
                brain,
                cid,
                [
                    {"step_index": 0, "type": "USER_INPUT", "created_at": "2026-11-21T01:00:00Z", "content": "hi"},
                    {"step_index": 1, "type": "PLANNER_RESPONSE", "created_at": "2026-11-21T01:00:05Z", "input_tokens": 1000, "cache_read_tokens": 0, "output_tokens": 100, "content": "ok"},
                ],
            )
            r_zh = agy_monitor.handle_daemon_request({"id": 1, "cmd": "snapshot", "lang": "zh"}, default_data_dir=base_dir)
            r_en = agy_monitor.handle_daemon_request({"id": 2, "cmd": "snapshot", "if_none_match": r_zh["etag"], "lang": "en"}, default_data_dir=base_dir)
            self.assertFalse(r_en["unchanged"], "切换语言后不能错误命中旧语言 etag unchanged")
            self.assertEqual(r_en["payload"]["sessions"][0]["health_desc"], "Idle")
            diag_en = agy_monitor.handle_daemon_request({"id": 3, "cmd": "analyze_session", "session_id": cid, "lang": "en"}, default_data_dir=base_dir)
            self.assertTrue(diag_en["ok"])
            self.assertEqual(diag_en["payload"]["phases"][0]["name"], "Summary / Response")


class TelemetryCardGeneratorTests(unittest.TestCase):
    def test_build_svg_includes_updated_timestamp_and_skip_if_empty_guard(self) -> None:
        root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        script_path = os.path.join(root, "scripts", "generate_telemetry_card.py")
        spec = importlib.util.spec_from_file_location("generate_telemetry_card", script_path)
        mod = importlib.util.module_from_spec(spec)
        assert spec and spec.loader
        spec.loader.exec_module(mod)

        en_svg = mod.build_svg("en", 621, 1_788_985_138, 92.1, 238.16, updated_at="2026-11-25 19:54")
        zh_svg = mod.build_svg("zh", 621, 1_788_985_138, 92.1, 238.16, updated_at="2026-11-25 19:54")
        self.assertIn("UPDATED 2026-11-25 19:54", en_svg)
        self.assertIn("更新于 2026-11-25 19:54", zh_svg)

        with tempfile.TemporaryDirectory(prefix="agy_telemetry_empty_") as tmp:
            proc = subprocess.run(
                [
                    sys.executable,
                    script_path,
                    "--output-dir",
                    tmp,
                    "--turns",
                    "0",
                    "--tokens",
                    "0",
                    "--cache-hit",
                    "0",
                    "--cost",
                    "0",
                    "--skip-if-empty",
                    "--skip-png",
                ],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(proc.returncode, 0)
            self.assertFalse(os.path.exists(os.path.join(tmp, "build-telemetry.svg")))


if __name__ == "__main__":
    unittest.main(verbosity=2)
