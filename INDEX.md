# Agyhub 仓库导航 (INDEX)

> **定位**：面向开发者与 AI Agent 的全仓地图。先看这里定位文件、行号与常用命令，再直奔目标源码；底层设计取舍与稳定性红线请看 [`AGENTS.md`](AGENTS.md) 与 [`docs/adr/`](docs/adr/)。

---

## 1. 仓库目录总览

```text
Agyhub/
├── INDEX.md                        # 本导航文档（全仓结构、模块职责与命令速查）
├── AGENTS.md                       # Agent 开发入口、凭证隔离契约与修改红线
├── README.md                       # 英文项目说明
├── README.zh-CN.md                 # 中文项目说明
├── LICENSE                         # MIT 开源协议
├── ADR.md                          # 软链接 -> docs/adr/ADR-001-cli-app-account-isolation.md
├── build_app.sh                    # 原生编译与打包脚本（支持 --universal / --dmg / --version / --sync-tools）
├── agy-monitor.py                  # 本地只读监控引擎（3,747 行，--json / --daemon / 终端 TUI）
├── agy-top                         # 终端看板启动包装脚本（自动优先选用 .venv 中的 Python）
├── requirements.txt                # 可选终端增强依赖（仅 rich>=13.0.0；GUI --json/--daemon 模式零第三方依赖）
├── Sources/                        # macOS 原生状态栏应用源码（6 模块，共 11,553 行）
│   ├── Localization.swift          # 中英文双语引擎与文案表（903 行）
│   ├── Models.swift                # 数据模型、用量统计与轮询/诊断策略（1,410 行）
│   ├── AccountAuthManager.swift    # 账号探测、App/CLI 隔离引擎与周配额管理（2,278 行）
│   ├── MonitorRuntime.swift        # Daemon 长连接客户端、FSEvents 监听与状态中枢（2,291 行）
│   ├── Views.swift                 # SwiftUI 全部视图、弹窗与菜单栏三态矢量图标（3,737 行）
│   └── AppLifecycle.swift          # 无边框毛玻璃窗口控制、AppDelegate 与 @main 入口（934 行）
├── tests/
│   ├── AGYHubTests.swift           # Swift 单元测试套件（3,760 行，72 个用例，-DAGYHUB_TESTING 编译）
│   └── test_agy_monitor.py         # Python 单元测试套件（1,455 行，19 个用例）
├── scripts/
│   ├── check_i18n.py               # 确定性 I18N 门禁（校验 Swift 与 Python 英文输出零中文泄漏）
│   └── generate_telemetry_card.py  # 本地开发遥测卡片生成器（输出 SVG 与 3x PNG 到 assets/）
├── docs/adr/
│   ├── ADR-001-cli-app-account-isolation.md           # 架构决策 001：App 与 CLI 双轨凭证隔离
│   └── ADR-002-low-overhead-incremental-monitoring.md # 架构决策 002：增量缓存与常驻 Daemon 架构
├── assets/                         # 应用图标、头图与中英双语遥测卡片（.icns / .png / .svg）
└── .github/workflows/
    ├── ci.yml                      # CI 流水线（shell 语法、i18n 检查、Swift/Python 单测、应用构建）
    └── release.yml                 # Tag/手动发布流水线（单测、Universal DMG/ZIP 打包、Release 上传）
```

> 注：本地构建会在根目录生成 `build/`、`Agyhub.app/`、`dist/` 等构建产物，不属于源码目录。

---

## 2. `Sources/*.swift` 6 模块速查表

原单文件 `AGYHub.swift` 已按职责拆分为 `Sources/` 下的 6 个 Swift 源码文件（合计 **11,553 行**）：

| 文件 | 行数 | 职责定位 | 核心类型 / 符号 |
| :--- | ---: | :--- | :--- |
| [`Sources/Localization.swift`](Sources/Localization.swift) | 903 | 双语本地化引擎（跟随系统 / 简体中文 / English 即时切换） | `AppLanguage`, `EnvironmentValues.agyLanguage`, `L10nKey`, `L10n` |
| [`Sources/Models.swift`](Sources/Models.swift) | 1,410 | 与 `agy-monitor.py` 对齐的解码模型、轮询/诊断/用量纯逻辑策略 | `MonitorPayload`, `MenuBarSummary`, `TodayStats`, `Recent503Stats`, `Recent503Policy`, `PollingSchedulePolicy`, `MonitorPayloadEquivalencePolicy`, `SessionStep`, `SessionPhaseStat`, `SessionSourceStat`, `CacheMissCauseStat`, `CacheMissEvent`, `CacheMissSummary`, `SessionConsumerItem`, `SessionDiagnosticsPayload`, `SessionDiagnosticsPolicy`, `SessionItem`, `UsageRangeOption`, `UsageMetricMode`, `UsageBreakdownDimension`, `UsageModelStat`, `UsageConversationStat`, `UsageDailyBucket`, `UsageHourlyBucket`, `UsageHistoryPayload`, `UsageAnalyticsPolicy`, `AGYProfile`, `Formatters` |
| [`Sources/AccountAuthManager.swift`](Sources/AccountAuthManager.swift) | 2,278 | 本地账号探测、App 与 CLI 双轨凭证隔离引擎、周配额拉取与 OAuth 续期 | `AntigravityLaunchConfig`, `AccountDisplayPolicy`, `AccountSortOrder`, `KeychainDriftPolicy`, `DiscoveredAccount`, `LocalAccountDetector`, `CLIAccountManager`, `WeeklyQuotaBucket`, `QuotaDisplayItem`, `AccountQuotaSummary`, `AccountQuotaManager` |
| [`Sources/MonitorRuntime.swift`](Sources/MonitorRuntime.swift) | 2,291 | 常驻 Python `--daemon` NDJSON 客户端、`FSEvents` 防抖监听与全局状态中枢 | `DebouncedTrigger`, `SessionDirectoryWatcher`, `MonitorDaemonClient`, `AGYHubStore` |
| [`Sources/Views.swift`](Sources/Views.swift) | 3,737 | 全量 SwiftUI 视图组件、诊断/用量图表视图、账号行与菜单栏图标 | `ModernPrimaryButtonStyle`, `ModernSecondaryButtonStyle`, `AccountTargetMode`, `ImpeccableIconButton`, `ImpeccableActionButton`, `ImpeccableIntervalPill`, `SectionCollapseToggleButton`, `MainDashboardWindowChrome`, `MainDashboardView`, `SettingsPopoverView`, `QuotaPillView`, `ProfileRowActionPolicy`, `CompactProfileRowView`, `SessionListFilter`, `SessionLookup`, `SessionDetailSubagentPolicy`, `SessionTitleCleaner`, `SessionTitleMarqueePolicy`, `ScrollingSessionTitleView`, `SessionRowBadgePolicy`, `SessionCapsuleBadge`, `CompactSessionRowView`, `SessionDetailCardView`, `DiagnosticDistributionTab`, `SessionDiagnosticsInlineSection`, `UsageAnalyticsView`, `AGYAppDelegate.HakimiBrandIcon` |
| [`Sources/AppLifecycle.swift`](Sources/AppLifecycle.swift) | 934 | 毛玻璃效果、原生无边框窗口拖拽/缩放控制、`NSApplicationDelegate` 与 `@main` 入口 | `VisualEffectBlurView`, `WindowSizePolicy`, `WindowClosePolicy`, `WindowResizeEdges`, `WindowResizeEdgePolicy`, `WindowResizeEdgeView`, `WindowResizeOverlay`, `ResizeCornerGripView`, `AGYMainWindow`, `WindowActivationGuard`, `WindowLifecycleView`, `WindowLifecycleConfigurator`, `WindowDragArea`, `WindowActivationPolicy`, `AGYAppDelegate`, `AGYHubApp` |

---

## 3. `agy-monitor.py` 内部 5 大逻辑分区地图

[`agy-monitor.py`](agy-monitor.py) 共 **3,747 行**，按功能自上而下分为 5 个逻辑分区（只读解析 `~/.gemini/antigravity/` 与 `~/.gemini/antigravity-cli/` 下的 SQLite/JSONL）：

| 分区 | 行号范围 | 核心职责 | 关键函数 / 入口 |
| :--- | :--- | :--- | :--- |
| **1. 增量缓存与只读基础** | `L45–L445` | 内存 + 磁盘增量缓存（`~/.cache/agyhub/session_inspect_cache_v1.json`，基于文件 `(mtime_ns, size)` 与 SQLite+WAL 指纹）、原子写盘、SQLite 只读连接、定价阶梯与单位格式化 | `clear_runtime_caches`, `_get_inspect_cache`, `_save_inspect_cache`, `_atomic_write_json`, `_db_fingerprint`, `connect_sqlite_ro`, `calculate_step_cost`, `_localize_session_dict_en` |
| **2. 会话采集与状态机** | `L447–L1445` | 读取会话模型、`transcript.jsonl` 静态解析（命中缓存后按当前 `now` 现场重算 `current_stall` / `health` / `health_code`）、主子 Agent 树聚合与目录扫描 | `get_session_model`, `extract_recent_steps`, `_read_subagent_descriptors`, `_parse_session_transcript_static`, `_apply_dynamic_session_fields`, `inspect_session`, `_group_sessions_tree`, `_load_conversations_from_dir`, `load_conversations` |
| **3. 用量历史统计与 503 计数** | `L1447–L2175` | 按天/按小时/按模型/按会话聚合同族用量与费用（含 `~/.agy-profiles/usage_daily_cache.json` 缓存与归档回填）、今日统计及近 1 小时 `503` 错误计数 | `normalize_model_key`, `format_model_display_name`, `_extract_ordered_gen_models`, `_parse_transcript_usage_entry`, `_load_usage_cache`, `_discover_transcript_targets`, `build_usage_history_payload`, `get_today_token_stats`, `count_recent_503_errors` |
| **4. Cache-Miss 诊断** | `L2177–L3045` | 优先读取未截断的 `transcript_full.jsonl`（含子 Agent 递归聚合），定位 Prompt Cache 失效原因、浪费 Token/费用、工作阶段耗时分布与优化建议 | `_find_session_transcript_file`, `_classify_command_source`, `_classify_phase_for_planner`, `_build_diagnostic_recommendations`, `_collect_descendant_subagents`, `_analyze_single_session_raw`, `analyze_session_diagnostics` |
| **5. `--daemon` 常驻协议与终端输出** | `L3047–L3747` | 状态栏摘要合成、`etag` 计算、NDJSON 常驻服务循环（`ping` / `snapshot` / `recent_503` / `usage_history` / `analyze_session`）、单次 `--json` 出口及终端 Rich/ANSI TUI | `build_menubar_summary`, `build_json_payload`, `compute_snapshot_etag`, `handle_daemon_request`, `run_daemon`, `render_rich_overview`, `render_rich_detail`, `render_ansi_overview`, `main` |

---

## 4. 文档、脚本、测试与资源导航

| 路径 | 用途说明 |
| :--- | :--- |
| [`AGENTS.md`](AGENTS.md) | 必读开发指南：App/CLI 双轨隔离契约、6 条不可破坏的稳定性底线、低开销监控链路说明与修改规范 |
| [`docs/adr/ADR-001-cli-app-account-isolation.md`](docs/adr/ADR-001-cli-app-account-isolation.md) | 解释为什么共享钥匙串会被 `agy` 续期覆写，以及 `SSH_CLIENT=1` + `cli-vault` 物理隔离方案（根目录 [`ADR.md`](ADR.md) 软链指向此文件） |
| [`docs/adr/ADR-002-low-overhead-incremental-monitoring.md`](docs/adr/ADR-002-low-overhead-incremental-monitoring.md) | 解释 P0 增量缓存、P1 可见性降频与等价防重绘、P2 常驻 `--daemon` + `FSEvents` 优化方案与实测对比 |
| [`scripts/check_i18n.py`](scripts/check_i18n.py) | 确定性 I18N 检查脚本：扫描 `Sources/*.swift` 的 `L10nKey` 与 UI 字面量，并校验 `agy-monitor.py` 在 `lang="en"` 下的输出零中文字符 |
| [`scripts/generate_telemetry_card.py`](scripts/generate_telemetry_card.py) | 读取本地 Antigravity 会话日志生成脱敏开发统计卡（需要时调用本地 Chrome 无头渲染 3x PNG，可选自动探测 `~/Library/Fonts/LXGWWenKai*.ttf`） |
| [`tests/AGYHubTests.swift`](tests/AGYHubTests.swift) | Swift 回归测试（3,760 行，72 个测试函数），通过 `-DAGYHUB_TESTING` 屏蔽 `@main` 并使用内存保险箱隔离本机环境 |
| [`tests/test_agy_monitor.py`](tests/test_agy_monitor.py) | Python 回归测试（1,455 行，19 个用例），覆盖子 Agent 聚合、用量统计、增量缓存、`now` 重算、`--daemon` 协议与 I18N 门禁 |
| [`assets/`](assets/) | `app-icon.png`、`AppIcon.icns`、`header-cat.png`、中英文遥测图 `build-telemetry.svg/.png` 与 `build-telemetry-zh.svg/.png` |
| [`build_app.sh`](build_app.sh) | 编译 `Sources/*.swift` 生成 `Agyhub.app`、打包 `agy-monitor.py`、ad-hoc 签名及生成 `dist/` 安装包 |
| [`agy-top`](agy-top) | 在终端快速启动 `agy-monitor.py` 实时看板 |
| [`.github/workflows/ci.yml`](.github/workflows/ci.yml) / [`release.yml`](.github/workflows/release.yml) | GitHub Actions 自动化测试与双架构发布流水线 |

---

## 5. 常用命令速查

所有命令均在仓库根目录执行：

### 5.1 运行单元测试
```bash
# Swift 全量单元测试（72 个用例，编译期屏蔽 @main）
swiftc -DAGYHUB_TESTING Sources/*.swift tests/AGYHubTests.swift \
  -parse-as-library \
  -sdk "$(xcrun --show-sdk-path --sdk macosx)" \
  -target "$(uname -m)-apple-macos13.0" \
  -framework SwiftUI -framework AppKit -framework Security -framework ServiceManagement \
  -o /tmp/agyhub_tests && /tmp/agyhub_tests && rm -f /tmp/agyhub_tests

# Python 全量单元测试（19 个用例）
python3 tests/test_agy_monitor.py
```

### 5.2 I18N 门禁与语法检查
```bash
# 校验 SwiftUI 与 agy-monitor.py 英文输出零中文泄漏
python3 scripts/check_i18n.py

# Shell 脚本语法检查
bash -n agy-top && bash -n build_app.sh
```

### 5.3 编译应用与构建 Universal DMG
```bash
# 仅构建当前机器架构的 Agyhub.app（内含脚本会先跑 check_i18n.py）
./build_app.sh

# 构建 Apple Silicon + Intel 双架构 Universal Binary，并生成 dist/ 下的 .dmg、.zip 与 SHA256SUMS.txt
./build_app.sh --universal --dmg --version 1.0.0

# 验证签名与通用二进制架构
lipo -info ./Agyhub.app/Contents/MacOS/Agyhub
codesign -v --deep --strict ./Agyhub.app
```

### 5.4 本地覆盖安装并干净重启 `/Applications/Agyhub.app`
```bash
# 使用 env -i 清理终端或 Agent 注入的环境变量，防止污染原生启动态
pkill -x Agyhub || true
rm -rf /Applications/Agyhub.app && cp -R ./Agyhub.app /Applications/
env -i HOME="$HOME" USER="$USER" LOGNAME="$LOGNAME" SHELL="${SHELL:-/bin/zsh}" \
  TMPDIR="${TMPDIR:-/tmp}" SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-}" \
  __CF_USER_TEXT_ENCODING="${__CF_USER_TEXT_ENCODING:-0x1F5:0x0:0x0}" \
  COMMAND_MODE=unix2003 PATH=/usr/bin:/bin:/usr/sbin:/sbin open /Applications/Agyhub.app
```

### 5.5 生成 README 遥测卡片
```bash
# 自动汇总本地匹配会话生成中英文 SVG 与 3x PNG 到 assets/（加 --skip-png 仅更新 SVG）
python3 scripts/generate_telemetry_card.py
```
