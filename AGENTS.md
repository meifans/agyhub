# Agyhub 架构与开发指南 (Agent Entrypoint)

Agyhub 是一个面向 macOS 13.0+ 的原生状态栏应用（Swift + SwiftUI，`LSUIElement=true`，Bundle ID `com.antigravity.agyhub`），核心解决两个问题：
1. **多账号隔离与切换**：让桌面端 `Antigravity.app` 与命令行/编辑器 CLI（如 `agy` / `agy acp`）各自使用独立凭证通道，互不覆盖。
2. **本地只读监控与配额展示**：通过常驻 `agy-monitor.py --daemon`（NDJSON）与 `(mtime_ns, size)` 增量缓存、macOS `FSEvents` 目录监听及弹窗可见性自适应降频，低开销实时监控活跃会话、卡顿/排队耗时、Token/费用消耗及各账号周度配额。

---

## 1. 仓库结构

| 文件/目录 | 职责 | 说明 |
| :--- | :--- | :--- |
| [`INDEX.md`](INDEX.md) | 仓库与源码总导航 | 速查目录树、`Sources/*.swift` 6 模块清单、`agy-monitor.py` 分区地图与常用命令 |
| `Sources/*.swift` | 全部应用源码（6 模块） | 按职责拆分为 `Localization.swift`、`Models.swift`、`AccountAuthManager.swift`、`MonitorRuntime.swift`、`Views.swift`、`AppLifecycle.swift`，联合编译 |
| `agy-monitor.py` | 本地只读监控引擎 | 解析 `~/.gemini/antigravity/` 与 `~/.gemini/antigravity-cli/` 的 SQLite/JSONL，提供 `--json`（兼容单次模式）与 `--daemon`（常驻 NDJSON + 增量缓存）输出给 `Sources/MonitorRuntime.swift`（`build_app.sh` 默认仅打包进 `.app/Contents/Resources/`，传入 `--sync-tools` 时才同步到 `~/.gemini/config/tools/`） |
| `agy-top` | 终端单会话启动器 | 配合 UI 在终端打开 `agy-monitor.py` 详情视图 |
| `build_app.sh` | 编译打包脚本 | 使用 `swiftc` 编译 `Sources/*.swift`，生成 `Agyhub.app` 并执行本地 ad-hoc 签名（支持 `--universal`、`--dmg`、`--version`、`--sync-tools`） |
| `tests/AGYHubTests.swift` | Swift TDD 回归测试套件 | 无 Xcode 工程，通过 `-DAGYHUB_TESTING` 直接编译运行全部 Swift 单元测试 |
| `tests/test_agy_monitor.py` | Python TDD 回归测试套件 | 验证增量缓存、`now` 动态重算、损坏恢复与 `--daemon` NDJSON 协议 |
| `docs/adr/ADR-001-cli-app-account-isolation.md` | 架构决策记录 001 | 详述 App 与 CLI 账号隔离的原理、双轨模式与演进 |
| `docs/adr/ADR-002-low-overhead-incremental-monitoring.md` | 架构决策记录 002 | 详述 P0 增量缓存、P1 可见性降频与防重绘、P2 常驻 `--daemon` 与 `FSEvents` 监听方案 |

---

## 2. `Sources/*.swift` 模块导航

完整文件行数与符号速查表见 [`INDEX.md`](INDEX.md)，应用逻辑按职责拆分为以下模块：

1. **数据模型 (`MonitorPayload` / `SessionItem` / `TodayStats`)**：与 `agy-monitor.py` 输出字段严格对齐（含 `client_type` 区分 `cli` 与桌面端会话）。
2. **启动与账号探测 (`AGYProfile` / `AntigravityLaunchConfig` / `LocalAccountDetector`)**：扫描本机浏览器配置与 Antigravity 主应用目录，记录探测日志到 `~/.gemini/antigravity/log/agyhub_accounts.log`。
3. **钥匙串与 CLI 文件凭证引擎 (`CLIAccountManager` / `KeychainDriftPolicy`)**：
   - 判定共享钥匙串当前真正归属，拦截 `agy` 后台静默续期引发的串槽覆盖；
   - 管理独立模式下的 `~/.gemini/antigravity-cli/antigravity-oauth-token` 文件切换与自愈。
4. **周配额管理 (`AccountQuotaManager`)**：不直连任何 Google 内部私有接口、不伪造 `User-Agent`、不直接提取或刷新 OAuth Token；仅针对当前活跃的 App 槽位与（开启独立模式且不同邮箱时的）独立 CLI 槽位，经版本门禁（`agy >= 1.1.11`）按 180 秒成功冷却 / 300 秒失败退避调用官方只读命令 `agy -p "/usage" --output-format json --print-timeout 20s`（禁用自动更新）获取 5 小时与周度配额并持久化至 `~/.agy-profiles/quota_cache.json`；被切走的备用账号保持切换前缓存的配额与状态，不在后台探测。
5. **低开销监控管道 (`MonitorDaemonClient` / `SessionDirectoryWatcher` / `PollingSchedulePolicy` / `MonitorPayloadEquivalencePolicy`)**：
   - 维护常驻 `agy-monitor.py --daemon` NDJSON 长连接，异常时指数退避重启并无缝降级单次 `--json`；
   - 通过 `FSEvents` 防抖监听（400ms）感知本地会话写入；
   - 按弹窗/独立窗口显隐与活跃状态动态调度轮询间隔，结合 `etag` / `unchanged` 与展示等价比较跳过无意义 `@Published` 赋值。
6. **状态中枢 (`AGYHubStore`)**：协调可见性自适应刷新、`refreshCLIAccountState()`、`refreshQuotasIfNeeded()` 以及 App 与 CLI 切号动作。
7. **双语本地化与 UI 视图层 (`AppLanguage` / `L10n` / `MainDashboardView` / `CompactProfileRowView` / `SettingsPopoverView`)**：支持「跟随系统 / 简体中文 / English」界面语言切换与 `UserDefaults` 持久化（无需重启即时刷新），覆盖菜单栏弹窗（支持独立窗口固定）、账号列表（`App | CLI` 切换胶囊）、活跃会话、诊断详情、用量趋势、设置页与状态栏菜单。

---

## 3. 核心架构：App 与 CLI 双轨凭证隔离

为避免 `agy` 在后台 1 小时续期时把共享钥匙串覆盖成另一账号，系统采用两条隔离轨道（详见 `docs/adr/ADR-001-cli-app-account-isolation.md`）：

```text
  桌面端 Antigravity.app ──读写──► macOS Keychain ("gemini" / "antigravity")
                                         ▲
                                         │ 授权后捕获进保险箱（供切号与自愈复用）
                                         ▼
                              com.antigravity.agyhub.cli-vault (Keychain 保险箱)
                                         │
                                         ▼ (切号写入 / 缺失自愈)
  CLI / 终端 (SSH_CLIENT=1) ──独占──► ~/.gemini/antigravity-cli/antigravity-oauth-token (0600 纯 JSON)
```

### 关键运行时文件与钥匙串槽位
- **`~/.gemini/antigravity-cli/antigravity-oauth-token`**：唯一运行时 CLI 凭证文件（`0600` 纯 JSON）。只要进程环境变量带 `SSH_CLIENT=1`，`agy` 就完全忽略系统钥匙串，仅读写此文件。
- **Keychain `com.antigravity.agyhub.cli-vault`**：按小写邮箱存储各账号凭证（`go-keyring-base64:` 或纯 JSON），是 App 与 CLI 互切以及 token 文件自愈的唯一备用库；**不额外维护 `.bak` 文件**。
- **`~/.agy-profiles/`**：存放 `profiles.json`、记录最近切换锚点的 `cli_active.json` 与 `app_expected.json`。

### 不可破坏的稳定性契约
修改 `CLIAccountManager`、`AccountQuotaManager` 或 `AGYHubStore` 时必须守住以下底线：
1. **唯一写盘口**：写 `~/.gemini/antigravity-cli/antigravity-oauth-token` 必须经由 `CLIAccountManager.writeValidatedTokenFile(_:toPath:)`（剥离 `go-keyring-base64:` 前缀、校验 `id_token_email` 与非空 `access_token`、`.atomic` 原子替换、固定 `0o600` 权限）。
2. **禁止先删后等**：`switchCLITokenFile` 在目标账号未缓存或缓存损坏时，**必须保留当前有效 token 文件不动**；终端重登命令统一使用 `SSH_CLIENT=1 <agy> acp --login`（实测即使已有文件仍会触发新 OAuth 登录，完成后再原子覆写，中途取消不影响在用会话）。
3. **缺失/损坏自愈**：`isCLIIndependentMode == true` 且已授权保险箱时，`detectActiveCLIProfile` 通过 `ensureCLITokenFileIfNeeded` 自动检查文件健康度；若缺失或为 0 字节/坏 JSON，按 `cli_active.json` → 优先候选邮箱 → `cli-vault` 已有槽位 顺序自动补写回盘；无法补出时在 UI 提示条展示橙色缺失警告。
4. **零内部 API 直连**：`AccountQuotaManager` 严禁直接请求 `daily-cloudcode-pa.googleapis.com`、`oauth2.googleapis.com` 或读取钥匙串中的 OAuth token 发起网络请求；一切活跃配额查询一律委托给经版本校验的官方 `agy -p "/usage"` 命令行进程，且不得替闲置备用账号探测或回写 Token 文件。
5. **App 切号免视口破坏**：`switchToProfile` 通过“仅向 `.regular` 主应用发优雅退出请求并等 `Helper`/`language_server` 彻底退出（8s 窗口）→ 热写共享钥匙串并同步 `app_storage.json` → 净化为 macOS 原生 GUI 环境变量后 `open -a /Applications/Antigravity.app` 单实例拉起”，严禁传递 `--user-data-dir`、`-n` 或泄露父进程脏环境变量。
6. **开源零密钥与严禁后台代刷 Token（关联 `ADR-001` 7.4 节）**：严禁在源码、测试或脚本中硬编码任何 OAuth 密钥，也严禁以临时 `HOME` + `SSH_CLIENT=1` 等方式在后台拉起官方 `agy` 进程替备用账号探测或刷新 Token；被切走的闲置备用账号保持切换前缓存在 `~/.agy-profiles/quota_cache.json` 的配额与状态，切回激活后自动更新。

---

## 4. 低开销增量监控架构 (`--daemon` + `FSEvents` + 增量缓存)

为消除每 5 秒 fork Python 进程与全量重扫历史会话的开销，监控链路采用三层增量设计（详见 `docs/adr/ADR-002-low-overhead-incremental-monitoring.md`）：

- **Python 侧增量缓存 (`agy-monitor.py`)**：
  - 基于文件 `(mtime_ns, size)` 与模型 DB `(mtime_ns, size, wal_mtime_ns, wal_size)` 实现进程内内存缓存 + `~/.cache/agyhub/session_inspect_cache_v1.json` 原子磁盘缓存（`schema_version=1`，损坏自动重建，支持 `AGYHUB_DISABLE_CACHE=1` 禁用与 `AGYHUB_INSPECT_CACHE_PATH` 覆盖）。
  - **动静分离契约**：仅缓存静态解析字段与 `last_step_created_at` 原始时间戳；每次命中后必须结合当前 `now` 与 DB 实时状态现场重算 `current_stall`、`health`、`health_code`、`health_desc`。
- **常驻 `--daemon` NDJSON 协议**：
  - 支持命令：`snapshot`（带 `if_none_match` 对比基于剔除 `timestamp` 载荷计算的 16 位 SHA-256 `etag`，未变更返回 `unchanged: true`）、`recent_503`、`usage_history`、`analyze_session`、`ping`；单条异常返回 `{"id": ..., "ok": false, "error": ...}` 不崩溃，stdin EOF / `BrokenPipeError` 退出码 `0`。
  - 原有 `--json`、`--recent-503`、`--usage-history`、`--analyze-session` CLI 模式完全向后兼容，并作为 `MonitorDaemonClient` 异常退避窗口（1s~30s）的无缝降级路径。
- **Swift 侧可见性降频与防抖 (`Sources/Models.swift` & `Sources/MonitorRuntime.swift`)**：
  - `SessionDirectoryWatcher`（`CoreServices` `FSEventStream`，无需额外链接参数）监听 `~/.gemini/antigravity/brain` 与 `~/.gemini/antigravity-cli/brain` 并做 400ms 防抖；
  - `PollingSchedulePolicy` 根据 `AGYHubStore.isDashboardVisible` 执行三态轮询（可见 `5.0s` / 收起有活跃会话 `15.0s` / 收起空闲 `60.0s`，切回可见立即刷新）；
  - `MonitorPayloadEquivalencePolicy` 结合 `unchanged: true` 与忽略 `timestamp` 的展示等价比较，跳过无实质变化的 `@Published` 赋值。

---

## 5. 常用开发、测试与发布命令

在仓库根目录执行：

```bash
# 1. 编译并运行全部 TDD 测试（必须先跑通）
swiftc -DAGYHUB_TESTING Sources/*.swift tests/AGYHubTests.swift \
  -parse-as-library \
  -sdk "$(xcrun --show-sdk-path --sdk macosx)" \
  -target "$(uname -m)-apple-macos13.0" \
  -framework SwiftUI -framework AppKit -framework Security -framework ServiceManagement \
  -o /tmp/agyhub_tests && /tmp/agyhub_tests && rm -f /tmp/agyhub_tests
python3 tests/test_agy_monitor.py

# 2. 编译打包 Agyhub.app（可选 --sync-tools 同步 agy-monitor.py 到 ~/.gemini/config/tools/，可选 --universal --dmg）
./build_app.sh

# 3. 更新并重启本机运行中的 /Applications/Agyhub.app（使用 env -i 避免终端/Agent 环境变量带入）
pkill -x Agyhub || true
rm -rf /Applications/Agyhub.app && cp -R ./Agyhub.app /Applications/
env -i HOME="$HOME" USER="$USER" LOGNAME="$LOGNAME" SHELL="${SHELL:-/bin/zsh}" TMPDIR="${TMPDIR:-/tmp}" SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-}" __CF_USER_TEXT_ENCODING="${__CF_USER_TEXT_ENCODING:-0x1F5:0x0:0x0}" COMMAND_MODE=unix2003 PATH=/usr/bin:/bin:/usr/sbin:/sbin open /Applications/Agyhub.app
```

---

## 6. 修改规范（给后续 Agent）

- **TDD 优先**：修改业务逻辑前，先在 `tests/AGYHubTests.swift` 新增/更新失败用例验证红灯，再修改 `Sources/*.swift` 对应模块至全量绿灯；涉及测试时必须保证 `MemoryVault` 隔离，不要污染本机真实 Keychain 或 `~/` 目录。
- **跨进程契约**：若增删 `MonitorPayload` / `SessionItem` 字段，必须同步核对 `agy-monitor.py` 的 JSON 输出键名与默认值。
- **独立 mode 测试编译**：测试代码依赖 `-DAGYHUB_TESTING` 屏蔽 `AGYHubApp` 的 `@main` 入口，新增 `AGYHubStore` 静态逻辑测试时保持 `nonisolated` 或适配 `@MainActor` 调用方式。
