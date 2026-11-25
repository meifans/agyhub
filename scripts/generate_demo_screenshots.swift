import SwiftUI
import AppKit
import Foundation

@MainActor
enum DemoScreenshotRunner {

    static func makeDemoPayload(lang: AppLanguage.Resolved) -> MonitorPayload {
        let isZH = (lang == .zhHans)
        let t1 = isZH ? "🔥 支付回调流水线重构" : "🔥 Refactor Webhook Pipeline"
        let t2 = isZH ? "⚡ GraphQL 缓存命中率优化" : "⚡ GraphQL Query Cache"
        let t3 = isZH ? "设计系统 Token 审计与收敛" : "Design System Token Audit"
        let t4 = isZH ? "修复 SwiftUI 弹窗缩放闪烁" : "Fix SwiftUI Popover Flicker"
        let t5 = isZH ? "PostgreSQL 分区索引调优" : "PostgreSQL Partition Tuning"
        let t6 = isZH ? "接入 OpenTelemetry 链路追踪" : "OpenTelemetry Trace Exporter"
        let t7 = isZH ? "自动化回归用例补全" : "Regression Suite Coverage"

        let json: [String: Any] = [
            "timestamp": "14:28:36",
            "data_dir": "~/.gemini/antigravity",
            "active_count": 2,
            "total_roundtrips": 318,
            "has_alert": false,
            "menubar": [
                "icon": "🟢",
                "text": "200t/s | $42.85",
                "status_level": "working",
                "active_count": 2
            ],
            "today_stats": [
                "total_tokens": 184_600_000,
                "cache_tokens": 177_840_000,
                "input_tokens": 5_420_000,
                "output_tokens": 1_340_000,
                "cache_pct": 96.3,
                "cost_usd": 42.85,
                "has_data": true,
                "source": "demo"
            ],
            "sessions": [
                [
                    "uuid": "demo-sess-0001-webhook-pipeline",
                    "short_id": "a1b2c3",
                    "client_type": "app",
                    "title": t1,
                    "is_running": true,
                    "interactions": 64,
                    "input_tokens": 3_200,
                    "cache_tokens": 182_800,
                    "output_tokens": 1_840,
                    "context_tokens": 186_000,
                    "cache_pct": 96.2,
                    "tps": 38.0,
                    "total_tokens_consumed": 26_400_000,
                    "total_cost_usd": 4.62,
                    "total_cache_consumed": 25_390_000,
                    "total_input_consumed": 810_000,
                    "total_output_consumed": 200_000,
                    "current_stall": 0.0,
                    "health": "🟢",
                    "health_code": "streaming",
                    "health_desc": isZH ? "生成中" : "Streaming",
                    "current_phase": isZH ? "编码修改" : "Coding",
                    "current_action": isZH ? "更新 Webhook 签名校验逻辑" : "Updating webhook signature verifier",
                    "exists": true,
                    "model": "gemini-4-hydrogen",
                    "total_active_sec": 765.0,
                    "subagent_count": 6,
                    "active_subagent_count": 2,
                    "active_subagent_tps": 94.0,
                    "subagents": [
                        [
                            "uuid": "demo-sub-0001-verifier",
                            "short_id": "9f2a10",
                            "parent_conversation_id": "demo-sess-0001-webhook-pipeline",
                            "agent_name": "webhook_verifier",
                            "agent_role": "Verifier",
                            "title": "webhook_verifier",
                            "is_running": true,
                            "interactions": 14,
                            "context_tokens": 76_000,
                            "cache_pct": 95.0,
                            "tps": 52.0,
                            "total_tokens_consumed": 2_180_000,
                            "total_cost_usd": 0.42,
                            "health": "🟢",
                            "health_code": "streaming",
                            "model": "gemini-4-hydrogen",
                            "exists": true
                        ],
                        [
                            "uuid": "demo-sub-0002-migrator",
                            "short_id": "7c8e41",
                            "parent_conversation_id": "demo-sess-0001-webhook-pipeline",
                            "agent_name": "schema_migrator",
                            "agent_role": "Engineer",
                            "title": "schema_migrator",
                            "is_running": true,
                            "interactions": 11,
                            "context_tokens": 36_000,
                            "cache_pct": 94.0,
                            "tps": 42.0,
                            "total_tokens_consumed": 1_640_000,
                            "total_cost_usd": 0.31,
                            "health": "🟢",
                            "health_code": "streaming",
                            "model": "gemini-4-hydrogen",
                            "exists": true
                        ],
                        [
                            "uuid": "demo-sub-0003-auditor",
                            "short_id": "5e2d52",
                            "parent_conversation_id": "demo-sess-0001-webhook-pipeline",
                            "agent_name": "security_auditor",
                            "agent_role": "Auditor",
                            "title": "security_auditor",
                            "is_running": false,
                            "interactions": 9,
                            "context_tokens": 72_000,
                            "cache_pct": 98.0,
                            "tps": 0.0,
                            "total_tokens_consumed": 1_420_000,
                            "total_cost_usd": 0.24,
                            "health": "⚪",
                            "health_code": "idle",
                            "model": "gemini-4-neon",
                            "exists": true
                        ]
                    ]
                ],
                [
                    "uuid": "demo-sess-0002-graphql-cache",
                    "short_id": "b4c5d6",
                    "client_type": "cli",
                    "title": t2,
                    "is_running": true,
                    "interactions": 38,
                    "context_tokens": 112_000,
                    "cache_pct": 97.4,
                    "tps": 68.0,
                    "total_tokens_consumed": 14_200_000,
                    "total_cost_usd": 2.35,
                    "current_stall": 4.0,
                    "health": "🟢",
                    "health_code": "streaming",
                    "model": "gemini-4-neon",
                    "subagent_count": 3,
                    "active_subagent_count": 0,
                    "active_subagent_tps": 0.0,
                    "exists": true
                ],
                [
                    "uuid": "demo-sess-0003-design-tokens",
                    "short_id": "c7d8e9",
                    "client_type": "app",
                    "title": t3,
                    "is_running": false,
                    "interactions": 52,
                    "context_tokens": 248_000,
                    "cache_pct": 99.1,
                    "tps": 0.0,
                    "total_tokens_consumed": 24_800_000,
                    "total_cost_usd": 3.48,
                    "health": "⚪",
                    "health_code": "idle",
                    "model": "gemini-4-hydrogen",
                    "subagent_count": 2,
                    "active_subagent_count": 0,
                    "exists": true
                ],
                [
                    "uuid": "demo-sess-0004-popover-flicker",
                    "short_id": "d1e2f3",
                    "client_type": "app",
                    "title": t4,
                    "is_running": false,
                    "interactions": 27,
                    "context_tokens": 94_000,
                    "cache_pct": 97.0,
                    "tps": 0.0,
                    "total_tokens_consumed": 8_400_000,
                    "total_cost_usd": 1.42,
                    "health": "⚪",
                    "health_code": "idle",
                    "model": "gemini-4-neon",
                    "subagent_count": 0,
                    "active_subagent_count": 0,
                    "exists": true
                ],
                [
                    "uuid": "demo-sess-0005-pg-partition",
                    "short_id": "e4f5a6",
                    "client_type": "cli",
                    "title": t5,
                    "is_running": false,
                    "interactions": 71,
                    "context_tokens": 310_000,
                    "cache_pct": 98.3,
                    "tps": 0.0,
                    "total_tokens_consumed": 41_200_000,
                    "total_cost_usd": 6.18,
                    "health": "⚪",
                    "health_code": "idle",
                    "model": "gemini-4-hydrogen",
                    "subagent_count": 1,
                    "active_subagent_count": 0,
                    "exists": true
                ],
                [
                    "uuid": "demo-sess-0006-otel-exporter",
                    "short_id": "f7a8b9",
                    "client_type": "app",
                    "title": t6,
                    "is_running": false,
                    "interactions": 31,
                    "context_tokens": 142_000,
                    "cache_pct": 96.4,
                    "tps": 0.0,
                    "total_tokens_consumed": 12_600_000,
                    "total_cost_usd": 2.09,
                    "health": "⚪",
                    "health_code": "idle",
                    "model": "gemini-4-hydrogen",
                    "subagent_count": 0,
                    "active_subagent_count": 0,
                    "exists": true
                ],
                [
                    "uuid": "demo-sess-0007-regression-suite",
                    "short_id": "a9b8c7",
                    "client_type": "app",
                    "title": t7,
                    "is_running": false,
                    "interactions": 19,
                    "context_tokens": 68_000,
                    "cache_pct": 94.8,
                    "tps": 0.0,
                    "total_tokens_consumed": 5_100_000,
                    "total_cost_usd": 0.89,
                    "health": "⚪",
                    "health_code": "idle",
                    "model": "gemini-3.8-flash-n",
                    "subagent_count": 0,
                    "active_subagent_count": 0,
                    "exists": true
                ]
            ]
        ]

        let data = try! JSONSerialization.data(withJSONObject: json)
        return try! JSONDecoder().decode(MonitorPayload.self, from: data)
    }

    static func makeDemoTelemetrySamples(lang: AppLanguage.Resolved, now: Date) -> [LiveTelemetrySample] {
        let isZH = (lang == .zhHans)
        let s1Title = isZH ? "支付回调流水线重构" : "Refactor Webhook Pipeline"
        let s2Title = isZH ? "GraphQL 缓存命中率优化" : "GraphQL Query Cache"
        let s3Title = isZH ? "设计系统 Token 审计与收敛" : "Design System Token Audit"

        let totalTicks = 42
        let spacing: TimeInterval = 4.0
        let startTime = now.addingTimeInterval(-Double(totalTicks - 1) * spacing)
        var cumulativeTokens = 179_800_000
        var result: [LiveTelemetrySample] = []

        for idx in 0..<totalTicks {
            let progress = Double(idx) / Double(totalTicks - 1)
            let ts = startTime.addingTimeInterval(Double(idx) * spacing)
            var contexts: [AgentContextPoint] = []
            var tickTps: Double = 0.0
            var activeAgents = 0

            let s1Ctx = Int((136_000.0 + 50_000.0 * pow(progress, 0.88)).rounded())
            contexts.append(
                AgentContextPoint(
                    agentId: "demo-sess-0001-webhook-pipeline",
                    label: s1Title,
                    contextTokens: s1Ctx,
                    isRunning: true,
                    tps: 38.0,
                    parentAgentId: nil
                )
            )
            tickTps += 38.0
            activeAgents += 1

            if idx <= 28 {
                let p3 = Double(idx) / 28.0
                let s3Ctx = Int((226_000.0 + 22_000.0 * p3).rounded())
                let s3Running = idx < 28
                contexts.append(
                    AgentContextPoint(
                        agentId: "demo-sess-0003-design-tokens",
                        label: s3Title,
                        contextTokens: s3Ctx,
                        isRunning: s3Running,
                        tps: s3Running ? 46.0 : 0.0,
                        parentAgentId: nil
                    )
                )
                if s3Running {
                    tickTps += 46.0
                    activeAgents += 1
                }
            }

            if idx >= 18 {
                let p2 = Double(idx - 18) / Double(totalTicks - 1 - 18)
                let wave = sin(p2 * .pi * 2.0) * 1_800.0
                let s2Ctx = Int((84_000.0 + 28_000.0 * p2 + wave).rounded())
                contexts.append(
                    AgentContextPoint(
                        agentId: "demo-sess-0002-graphql-cache",
                        label: s2Title,
                        contextTokens: s2Ctx,
                        isRunning: true,
                        tps: 68.0,
                        parentAgentId: nil
                    )
                )
                tickTps += 68.0
                activeAgents += 1
            }

            if idx >= 26 {
                let pSub1 = Double(idx - 26) / Double(totalTicks - 1 - 26)
                let sub1Ctx = Int((4_000.0 + 72_000.0 * pow(pSub1, 0.82)).rounded())
                contexts.append(
                    AgentContextPoint(
                        agentId: "demo-sub-0001-verifier",
                        label: "webhook_verifier",
                        contextTokens: sub1Ctx,
                        isRunning: true,
                        tps: 52.0,
                        parentAgentId: "demo-sess-0001-webhook-pipeline"
                    )
                )
                tickTps += 52.0
                activeAgents += 1
            }

            if idx >= 31 {
                let pSub2 = Double(idx - 31) / Double(totalTicks - 1 - 31)
                let sub2Ctx = Int((3_000.0 + 33_000.0 * pow(pSub2, 0.90)).rounded())
                contexts.append(
                    AgentContextPoint(
                        agentId: "demo-sub-0002-migrator",
                        label: "schema_migrator",
                        contextTokens: sub2Ctx,
                        isRunning: true,
                        tps: 42.0,
                        parentAgentId: "demo-sess-0001-webhook-pipeline"
                    )
                )
                tickTps += 42.0
                activeAgents += 1
            }

            let stepDelta = idx == 0 ? 0 : Int((98_000.0 + tickTps * 140.0).rounded())
            cumulativeTokens += stepDelta
            let cacheRatio = 0.963
            let deltaCache = Int(Double(stepDelta) * cacheRatio)
            let deltaNew = max(0, stepDelta - deltaCache)

            result.append(
                LiveTelemetrySample(
                    id: idx + 1,
                    timestamp: ts,
                    activeAgentCount: activeAgents,
                    totalTps: tickTps,
                    totalTokensCumulative: cumulativeTokens,
                    deltaTokens: stepDelta,
                    cachePct: 96.3,
                    isIdleCacheHold: false,
                    deltaCacheTokens: deltaCache,
                    deltaNewTokens: deltaNew,
                    agentContexts: contexts
                )
            )
        }

        return result
    }

    static func makeDemoDiagnostics(lang: AppLanguage.Resolved) -> SessionDiagnosticsPayload {
        let isZH = (lang == .zhHans)
        let title = isZH ? "支付回调流水线重构" : "Refactor Webhook Pipeline"
        let srcRead = isZH ? "read_file 输出" : "read_file output"
        let srcModel = isZH ? "模型输出与参数" : "Model output & args"
        let srcSync = isZH ? "同步命令输出" : "Sync Command output"
        let srcSwarm = isZH ? "Swarm / 子Agent 消息" : "Swarm / Subagent msgs"
        let srcEdit = isZH ? "edit/write 工具回执" : "edit/write receipts"
        let causeIdle = isZH ? "长时停顿导致缓存超时" : "Idle TTL expiration"
        let causeCompact = isZH ? "上下文压缩或重开" : "Context compaction / reset"
        let detail1 = isZH ? "停顿 38m14s 后恢复（上下文 164k）" : "Idle 38m14s before resume (ctx 164k)"
        let detail2 = isZH ? "停顿 24m05s 后恢复（上下文 120k）" : "Idle 24m05s before resume (ctx 120k)"

        let json: [String: Any] = [
            "uuid": "demo-sess-0001-webhook-pipeline",
            "title": title,
            "model": "gemini-4-hydrogen",
            "subagent_count": 6,
            "turns": 64,
            "total_tokens": 26_400_000,
            "input_tokens": 810_000,
            "cache_tokens": 25_390_000,
            "output_tokens": 200_000,
            "total_cost_usd": 4.62,
            "total_chars": 912_400,
            "attributed_pct": 100.0,
            "phases": [
                ["name": isZH ? "调研/检索" : "Research", "turns": 24, "tokens": 11_088_000, "input_tokens": 340_000, "cache_tokens": 10_664_000, "output_tokens": 84_000, "cost_usd": 1.94, "pct": 42.0],
                ["name": isZH ? "编码修改" : "Coding", "turns": 22, "tokens": 9_504_000, "input_tokens": 290_000, "cache_tokens": 9_142_000, "output_tokens": 72_000, "cost_usd": 1.66, "pct": 36.0],
                ["name": isZH ? "测试/构建/排错" : "Testing & Debug", "turns": 13, "tokens": 4_224_000, "input_tokens": 130_000, "cache_tokens": 4_062_000, "output_tokens": 32_000, "cost_usd": 0.74, "pct": 16.0],
                ["name": isZH ? "调度/看板协作" : "Orchestration", "turns": 5, "tokens": 1_584_000, "input_tokens": 50_000, "cache_tokens": 1_522_000, "output_tokens": 12_000, "cost_usd": 0.28, "pct": 6.0]
            ],
            "sources": [
                ["name": srcRead, "chars": 494_520, "pct": 54.2, "count": 41],
                ["name": srcModel, "chars": 224_450, "pct": 24.6, "count": 64],
                ["name": srcSync, "chars": 104_010, "pct": 11.4, "count": 19],
                ["name": srcSwarm, "chars": 57_480, "pct": 6.3, "count": 14],
                ["name": srcEdit, "chars": 31_940, "pct": 3.5, "count": 22]
            ],
            "cache_miss": [
                "total_misses": 3,
                "rebuilt_tokens": 412_000,
                "extra_cost_usd": 0.58,
                "waste_pct_of_total": 12.6,
                "by_cause": [
                    [
                        "cause": causeIdle,
                        "count": 2,
                        "rebuilt_tokens": 284_000,
                        "extra_cost_usd": 0.41
                    ],
                    [
                        "cause": causeCompact,
                        "count": 1,
                        "rebuilt_tokens": 128_000,
                        "extra_cost_usd": 0.17
                    ]
                ],
                "top_events": [
                    [
                        "step_index": 42,
                        "time": "14:12:08",
                        "agent_name": "Main",
                        "cause": causeIdle,
                        "detail": detail1,
                        "rebuilt_tokens": 164_000,
                        "ctx_tokens": 164_000,
                        "extra_cost_usd": 0.24
                    ],
                    [
                        "step_index": 29,
                        "time": "13:21:44",
                        "agent_name": "webhook_verifier",
                        "cause": causeIdle,
                        "detail": detail2,
                        "rebuilt_tokens": 120_000,
                        "ctx_tokens": 120_000,
                        "extra_cost_usd": 0.17
                    ]
                ]
            ],
            "top_consumers": [],
            "recommendations": []
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        return try! JSONDecoder().decode(SessionDiagnosticsPayload.self, from: data)
    }

    static func makeDemoUsageHistory(lang: AppLanguage.Resolved) -> UsageHistoryPayload {
        let isZH = (lang == .zhHans)
        let s1 = isZH ? "支付回调流水线重构" : "Refactor Payment Webhook Pipeline"
        let s2 = isZH ? "PostgreSQL 分区索引调优" : "PostgreSQL Partition Index Tuning"
        let s3 = isZH ? "GraphQL 缓存命中率优化" : "Optimize GraphQL Query Cache"
        let s4 = isZH ? "设计系统 Token 审计与收敛" : "Design System Token Audit"

        let days: [(String, String, Double, Double, Double)] = [
            ("2026-11-15", "11-15", 14.20, 6.40, 1.80),
            ("2026-11-16", "11-16", 21.50, 9.80, 2.10),
            ("2026-11-17", "11-17", 18.90, 11.20, 2.40),
            ("2026-11-18", "11-18", 26.40, 12.10, 3.20),
            ("2026-11-19", "11-19", 19.80, 8.60, 1.95),
            ("2026-11-20", "11-20", 29.10, 13.40, 2.85),
            ("2026-11-21", "11-21", 25.40, 14.25, 3.20)
        ]

        var dailyBuckets: [[String: Any]] = []
        for (date, label, hCost, nCost, fCost) in days {
            let totalCost = hCost + nCost + fCost
            let hTok = Int(hCost * 4_200_000)
            let nTok = Int(nCost * 4_500_000)
            let fTok = Int(fCost * 6_000_000)
            let totTok = hTok + nTok + fTok
            let cacheTok = Int(Double(totTok) * 0.968)
            let inTok = Int(Double(totTok) * 0.024)
            let outTok = totTok - cacheTok - inTok

            let models: [[String: Any]] = [
                [
                    "model": "gemini-4-hydrogen",
                    "display_name": "4-hydrogen",
                    "cost_usd": hCost,
                    "total_tokens": hTok,
                    "input_tokens": Int(Double(hTok) * 0.025),
                    "cache_tokens": Int(Double(hTok) * 0.967),
                    "output_tokens": Int(Double(hTok) * 0.008),
                    "calls": Int(hCost * 5.2)
                ],
                [
                    "model": "gemini-4-neon",
                    "display_name": "4-neon",
                    "cost_usd": nCost,
                    "total_tokens": nTok,
                    "input_tokens": Int(Double(nTok) * 0.024),
                    "cache_tokens": Int(Double(nTok) * 0.968),
                    "output_tokens": Int(Double(nTok) * 0.008),
                    "calls": Int(nCost * 6.4)
                ],
                [
                    "model": "gemini-3.8-flash-n",
                    "display_name": "3.8-flash",
                    "cost_usd": fCost,
                    "total_tokens": fTok,
                    "input_tokens": Int(Double(fTok) * 0.022),
                    "cache_tokens": Int(Double(fTok) * 0.970),
                    "output_tokens": Int(Double(fTok) * 0.008),
                    "calls": Int(fCost * 9.0)
                ]
            ]

            let sessions: [[String: Any]] = [
                [
                    "uuid": "demo-sess-0001-webhook-pipeline",
                    "title": s1,
                    "client_type": "app",
                    "top_model": "gemini-4-hydrogen",
                    "top_model_display": "4-hydrogen",
                    "cost_usd": totalCost * 0.36,
                    "total_tokens": Int(Double(totTok) * 0.36),
                    "input_tokens": Int(Double(inTok) * 0.36),
                    "cache_tokens": Int(Double(cacheTok) * 0.36),
                    "output_tokens": Int(Double(outTok) * 0.36),
                    "calls": 64,
                    "subagent_count": 6
                ],
                [
                    "uuid": "demo-sess-0005-pg-partition",
                    "title": s2,
                    "client_type": "cli",
                    "top_model": "gemini-4-hydrogen",
                    "top_model_display": "4-hydrogen",
                    "cost_usd": totalCost * 0.27,
                    "total_tokens": Int(Double(totTok) * 0.27),
                    "input_tokens": Int(Double(inTok) * 0.27),
                    "cache_tokens": Int(Double(cacheTok) * 0.27),
                    "output_tokens": Int(Double(outTok) * 0.27),
                    "calls": 48,
                    "subagent_count": 1
                ],
                [
                    "uuid": "demo-sess-0002-graphql-cache",
                    "title": s3,
                    "client_type": "cli",
                    "top_model": "gemini-4-neon",
                    "top_model_display": "4-neon",
                    "cost_usd": totalCost * 0.21,
                    "total_tokens": Int(Double(totTok) * 0.21),
                    "input_tokens": Int(Double(inTok) * 0.21),
                    "cache_tokens": Int(Double(cacheTok) * 0.21),
                    "output_tokens": Int(Double(outTok) * 0.21),
                    "calls": 38,
                    "subagent_count": 3
                ],
                [
                    "uuid": "demo-sess-0003-design-tokens",
                    "title": s4,
                    "client_type": "app",
                    "top_model": "gemini-4-hydrogen",
                    "top_model_display": "4-hydrogen",
                    "cost_usd": totalCost * 0.16,
                    "total_tokens": Int(Double(totTok) * 0.16),
                    "input_tokens": Int(Double(inTok) * 0.16),
                    "cache_tokens": Int(Double(cacheTok) * 0.16),
                    "output_tokens": Int(Double(outTok) * 0.16),
                    "calls": 29,
                    "subagent_count": 2
                ]
            ]

            dailyBuckets.append([
                "date": date,
                "label": label,
                "cost_usd": totalCost,
                "total_tokens": totTok,
                "input_tokens": inTok,
                "cache_tokens": cacheTok,
                "output_tokens": outTok,
                "calls": Int(totalCost * 6.5),
                "models": models,
                "sessions": sessions
            ])
        }

        var hourlyBuckets: [[String: Any]] = []
        let hourWeights: [Double] = [0, 0, 0, 0, 0, 0, 0, 0, 0.05, 0.12, 0.18, 0.14, 0.06, 0.21, 0.24, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        for h in 0..<24 {
            let w = hourWeights[h]
            let c = 42.85 * w
            let t = Int(184_600_000.0 * w)
            hourlyBuckets.append([
                "hour": h,
                "label": String(format: "%02d:00", h),
                "cost_usd": c,
                "total_tokens": t,
                "input_tokens": Int(Double(t) * 0.025),
                "cache_tokens": Int(Double(t) * 0.967),
                "output_tokens": Int(Double(t) * 0.008),
                "calls": Int(318.0 * w),
                "models": []
            ])
        }

        let payload: [String: Any] = [
            "generated_at": "2026-11-21T14:28:36+08:00",
            "today_date": "2026-11-21",
            "days_requested": 30,
            "daily": dailyBuckets,
            "today_hourly": hourlyBuckets
        ]
        let data = try! JSONSerialization.data(withJSONObject: payload)
        return try! JSONDecoder().decode(UsageHistoryPayload.self, from: data)
    }

    static func makeDemoStore(lang: AppLanguage.Resolved, accountsCollapsed: Bool) -> AGYHubStore {
        let suiteName = "com.antigravity.agyhub.demo.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set(accountsCollapsed, forKey: "agyhub.collapse.accounts")
        defaults.set(false, forKey: "agyhub.collapse.sessions")
        defaults.set(false, forKey: "agyhub.collapse.telemetry")
        defaults.set(TelemetryTimeRange.threeMinutes.rawValue, forKey: "agyhub.telemetry.range")
        defaults.set(-1.0, forKey: DashboardSplitLayoutPolicy.splitFractionDefaultsKey)
        defaults.set(true, forKey: "agyhub.cliIndependentMode")
        defaults.set(true, forKey: "agyhub.cliVaultAuthorized")
        defaults.set(5, forKey: SessionListLayoutPolicy.visibleRowsDefaultsKey)
        defaults.set(false, forKey: SessionRowBadgePolicy.showModelDefaultsKey)

        UserDefaults.standard.set(accountsCollapsed, forKey: "agyhub.collapse.accounts")
        UserDefaults.standard.set(false, forKey: "agyhub.collapse.sessions")
        UserDefaults.standard.set(false, forKey: "agyhub.collapse.telemetry")
        UserDefaults.standard.set(TelemetryTimeRange.threeMinutes.rawValue, forKey: "agyhub.telemetry.range")
        UserDefaults.standard.set(-1.0, forKey: DashboardSplitLayoutPolicy.splitFractionDefaultsKey)

        let fakeHome = "/tmp/agyhub-demo-home-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: fakeHome, withIntermediateDirectories: true)

        let store = AGYHubStore(startMonitoring: false, userDefaults: defaults, homeDir: fakeHome)

        for _ in 0..<4 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.03))
        }
        store.appLanguage = (lang == .zhHans) ? .zhHans : .en
        store.expandedSessionRowLimit = 5
        store.showSessionModelColumn = false
        store.payload = makeDemoPayload(lang: lang)
        store.lastUpdatedTimeStr = "14:28:36"
        store.recent503Count = 0
        store.recent503CheckedAt = Date()
        store.isCLIIndependentMode = true
        store.isCLIVaultAuthorized = true
        store.isCLITokenFileReady = true

        let now = Date()
        let p1 = AGYProfile(
            name: "alex.dev@example.com",
            email: "alex.dev@example.com",
            tier: "Google AI Ultra",
            userDataDir: "\(fakeHome)/.agy-profiles/alex",
            notes: lang == .zhHans ? "主力桌面 App 账号" : "Primary Desktop App",
            isDefault: true,
            createdAt: "2026-10-01",
            lastUsedAt: now.timeIntervalSince1970
        )
        let p2 = AGYProfile(
            name: "cli.worker@example.com",
            email: "cli.worker@example.com",
            tier: "Google AI Ultra",
            userDataDir: "\(fakeHome)/.agy-profiles/cli-worker",
            notes: lang == .zhHans ? "独立 CLI 自动化账号" : "Isolated CLI Worker",
            isDefault: false,
            createdAt: "2026-10-12",
            lastUsedAt: now.timeIntervalSince1970 - 600
        )
        let p3 = AGYProfile(
            name: "sandbox.qa@example.com",
            email: "sandbox.qa@example.com",
            tier: "Google AI Pro",
            userDataDir: "\(fakeHome)/.agy-profiles/sandbox",
            notes: lang == .zhHans ? "备用验证账号" : "Backup QA Profile",
            isDefault: false,
            createdAt: "2026-11-01",
            lastUsedAt: now.timeIntervalSince1970 - 3600
        )

        store.profiles = [p1, p2, p3]
        store.activeProfileName = p1.name
        store.appStorageEmail = p1.name
        store.expectedAppEmail = p1.name
        store.activeCLIProfileName = p2.name
        store.savedCLISlots = [p1.name, p2.name, p3.name]

        store.accountQuotas = [
            p1.name: AccountQuotaSummary(
                email: p1.name,
                isUltra: true,
                geminiQuota: WeeklyQuotaBucket(remainingFraction: 0.92, resetTime: now.addingTimeInterval(3 * 86400 + 3600), resetTimeStr: nil),
                argonQuota: nil,
                geminiFiveHourQuota: WeeklyQuotaBucket(remainingFraction: 0.84, resetTime: now.addingTimeInterval(2 * 3600 + 1800), resetTimeStr: nil),
                lastFetched: now
            ),
            p2.name: AccountQuotaSummary(
                email: p2.name,
                isUltra: true,
                geminiQuota: WeeklyQuotaBucket(remainingFraction: 0.88, resetTime: now.addingTimeInterval(5 * 86400 + 3600), resetTimeStr: nil),
                argonQuota: nil,
                geminiFiveHourQuota: WeeklyQuotaBucket(remainingFraction: 0.91, resetTime: now.addingTimeInterval(4 * 3600 + 900), resetTimeStr: nil),
                lastFetched: now
            ),
            p3.name: AccountQuotaSummary(
                email: p3.name,
                isUltra: false,
                geminiQuota: WeeklyQuotaBucket(remainingFraction: 1.0, resetTime: now.addingTimeInterval(6 * 86400 + 3600), resetTimeStr: nil),
                argonQuota: nil,
                geminiFiveHourQuota: WeeklyQuotaBucket(remainingFraction: 1.0, resetTime: now.addingTimeInterval(5 * 3600), resetTimeStr: nil),
                lastFetched: now
            )
        ]

        let samples = makeDemoTelemetrySamples(lang: lang, now: now)
        store.liveTelemetrySamples = samples
        store.telemetryTimelineAnchor = now.addingTimeInterval(-54.0)
        store.telemetryFamilyByRoot = LiveTelemetryPolicy.updatedPinnedFamilies(existing: [:], from: samples)
        store.sessionDiagnosticsByUUID["demo-sess-0001-webhook-pipeline"] = makeDemoDiagnostics(lang: lang)
        store.usageHistory = makeDemoUsageHistory(lang: lang)

        return store
    }

    static func captureView<V: View>(
        _ rootView: V,
        width: CGFloat,
        height: CGFloat,
        outputPath: String,
        onSettle: (() -> Void)? = nil
    ) {
        let padding: CGFloat = 24
        let canvasW = width + padding * 2
        let canvasH = height + padding * 2

        let framed = ZStack {
            Color(nsColor: NSColor(calibratedRed: 0.955, green: 0.962, blue: 0.975, alpha: 1.0))
            rootView
                .frame(width: width, height: height)
                .background(Color(nsColor: .windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.black.opacity(0.14), radius: 14, x: 0, y: 6)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .frame(width: canvasW, height: canvasH)

        let hostingView = NSHostingView(rootView: framed)
        hostingView.frame = NSRect(x: 0, y: 0, width: canvasW, height: canvasH)
        hostingView.appearance = NSAppearance(named: .aqua)

        let window = NSWindow(
            contentRect: NSRect(x: -5000, y: -5000, width: canvasW, height: canvasH),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.appearance = NSAppearance(named: .aqua)
        window.isOpaque = true
        window.backgroundColor = NSColor(calibratedRed: 0.955, green: 0.962, blue: 0.975, alpha: 1.0)
        window.contentView = hostingView
        window.display()

        for i in 0..<10 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
            if i == 5 {
                onSettle?()
            }
            hostingView.layoutSubtreeIfNeeded()
        }

        let scale: CGFloat = 2.0
        let pixelW = Int(canvasW * scale)
        let pixelH = Int(canvasH * scale)
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelW,
            pixelsHigh: pixelH,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            fatalError("Failed to create NSBitmapImageRep")
        }
        rep.size = NSSize(width: canvasW, height: canvasH)

        hostingView.cacheDisplay(in: hostingView.bounds, to: rep)

        guard let pngData = rep.representation(using: .png, properties: [:]) else {
            fatalError("Failed to encode PNG")
        }
        try! pngData.write(to: URL(fileURLWithPath: outputPath))
        window.orderOut(nil)
        print("✅ Generated \(outputPath) (\(pixelW)x\(pixelH)px)")
    }

    static func runAll(outputDir: String, targetLangFilter: String = "all") {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)

        let trackedKeys = [
            "agyhub.collapse.accounts",
            "agyhub.collapse.sessions",
            "agyhub.collapse.telemetry",
            "agyhub.telemetry.range",
            DashboardSplitLayoutPolicy.splitFractionDefaultsKey,
            "agyhub.usage.selectedRange",
            "agyhub.usage.metricMode",
            "agyhub.usage.breakdownDimension"
        ]
        var savedDefaults: [String: Any?] = [:]
        for key in trackedKeys {
            savedDefaults[key] = UserDefaults.standard.object(forKey: key)
        }
        defer {
            for (key, val) in savedDefaults {
                if let v = val {
                    UserDefaults.standard.set(v, forKey: key)
                } else {
                    UserDefaults.standard.removeObject(forKey: key)
                }
            }
        }

        UserDefaults.standard.set(UsageRangeOption.last7Days.rawValue, forKey: "agyhub.usage.selectedRange")
        UserDefaults.standard.set(UsageMetricMode.cost.rawValue, forKey: "agyhub.usage.metricMode")
        UserDefaults.standard.set(UsageBreakdownDimension.model.rawValue, forKey: "agyhub.usage.breakdownDimension")

        let allPairs: [(AppLanguage.Resolved, String)] = [
            (.en, ""),
            (.zhHans, "-zh")
        ]
        let pairs: [(AppLanguage.Resolved, String)]
        switch targetLangFilter {
        case "en":
            pairs = [(.en, "")]
        case "zh", "zh-cn", "zh_CN":
            pairs = [(.zhHans, "-zh")]
        default:
            pairs = allPairs
        }

        for (lang, suffix) in pairs {
            let dashStore = makeDemoStore(lang: lang, accountsCollapsed: false)
            captureView(
                MainDashboardView(store: dashStore, isStandaloneWindow: false)
                    .environment(\.agyLanguage, lang),
                width: 520,
                height: 605,
                outputPath: "\(outputDir)/screenshot-dashboard\(suffix).png"
            )

            let detailStore = makeDemoStore(lang: lang, accountsCollapsed: true)
            detailStore.selectedSessionUUID = "demo-sess-0001-webhook-pipeline"
            detailStore.sessionNavigationStack = ["demo-sess-0001-webhook-pipeline"]
            captureView(
                MainDashboardView(store: detailStore, isStandaloneWindow: false)
                    .environment(\.agyLanguage, lang),
                width: 520,
                height: 605,
                outputPath: "\(outputDir)/screenshot-detail\(suffix).png"
            )

            let usageStore = makeDemoStore(lang: lang, accountsCollapsed: true)
            usageStore.isUsageDashboardPresented = true
            let demoUsage = makeDemoUsageHistory(lang: lang)
            captureView(
                MainDashboardView(store: usageStore, isStandaloneWindow: false)
                    .environment(\.agyLanguage, lang),
                width: 520,
                height: 598,
                outputPath: "\(outputDir)/screenshot-usage\(suffix).png",
                onSettle: {
                    usageStore.usageHistory = demoUsage
                }
            )
        }
    }
}

@main
struct DemoScreenshotMain {
    static func main() {
        var outDir = FileManager.default.currentDirectoryPath + "/assets"
        var langFilter = "all"

        let args = Array(CommandLine.arguments.dropFirst())
        var idx = 0
        while idx < args.count {
            let arg = args[idx]
            if arg == "--output-dir", idx + 1 < args.count {
                outDir = args[idx + 1]
                idx += 2
            } else if arg == "--lang", idx + 1 < args.count {
                langFilter = args[idx + 1].lowercased()
                idx += 2
            } else if !arg.hasPrefix("-") {
                outDir = arg
                idx += 1
            } else {
                idx += 1
            }
        }

        try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
        MainActor.assumeIsolated {
            DemoScreenshotRunner.runAll(outputDir: outDir, targetLangFilter: langFilter)
        }
    }
}
