# Agyhub 工程实现细节与踩坑记录

> 本文档沉淀自源码清理过程中提取的真实约束、底层协议细节与已踩过的坑，配合 [`AGENTS.md`](../AGENTS.md)、[`INDEX.md`](../INDEX.md) 及 [`docs/adr/`](adr/) 使用。

---

## 1. 桌面端启动、进程树与窗口 / SwiftUI 约束

### 1.1 Antigravity 启动参数与环境变量隔离
- **单实例切号禁令**：常规切换账号（`isParallelLaunch == false`）严禁向 `/usr/bin/open` 传递 `-n` 与 `--user-data-dir`，必须使用原生单实例参数 `["-a", targetApp]`，让 LaunchServices 按主目录 `~/Library/Application Support/Antigravity` 启动，确保 Retina 2x 视口、默认配置加载与 Chromium 单例锁 100% 原生。仅在并排双开非默认 Profile 时才附带 `-n`、`--user-data-dir` 与 `--extensions-dir`。
- **极简 GUI 环境变量白名单**：拉起桌面端时必须构造与 Spotlight / Dock / LaunchServices 一致的白名单，彻底阻断终端或 Agent 会话环境变量（如 `ANTIGRAVITY_AGENT`、`ANTIGRAVITY_LS_ADDRESS` 等）经由 `/usr/bin/open` 泄漏给桌面端与 `language_server`；目标 App `Info.plist` 中的 `LSEnvironment`（如 `MallocNanoZone=0`）仍会由 LaunchServices 自动注入。
- **独立 IDE 严格隔离**：`Antigravity IDE (com.google.antigravity-ide)` 使用独立的 `user-data-dir`、`~/.gemini/antigravity-ide` 与 `state.vscdb` 认证，绝不纳入切号重启或进程清理范围。

### 1.2 优雅退出、进程树清理与孤儿锁
- **优雅退出超时**：等待 Antigravity 退出的超时上限（8.0 秒）必须覆盖 Electron 内部 `killLanguageServer()` 的 5 秒收尾窗口。只能向 `.regular` 策略主应用发 `terminate()`，绝不主动提前杀掉 Helper 进程；仅在超时卡死时再强制清理残留主实例、Helper 与 `language_server`。
- **`language_server` 两层父子扫描**：扫描桌面端主进程树下的 `language_server` PID 时，先收集直属进程，再覆盖其派生的同名子 `language_server`（不包含交互式 Shell 等其他子进程）。
- **孤儿锁与缩放污染清理**：清理 Chromium 孤儿锁（`SingletonLock` / `SingletonSocket` / `SingletonCookie`）必须使用 `attributesOfItem`，以同时兼容指向不存在 PID 的悬空软链接；隔离目录创建与双开前需清除旧逻辑复制残留的含 `per_host_zoom_levels` 的 `Preferences` 文件，防止双开时视口缩放污染。
- **落盘顺序保护**：更新默认主环境 `app_storage.json` 的 `lastLoginUsername`（防止弹出 `"One last thing..."` 引导）必须等旧 Electron 实例完全退出落盘后执行，避免与 `before-quit` 写盘冲突。
- **切号 30 秒保护窗**：主动切号后 30 秒内保持 `app_expected` 目标账号，防止刚拉起的 `language_server` 在旧 `app_storage` 尚未落盘前把预期账号翻回旧值。

### 1.3 AppKit / SwiftUI 窗口与布局踩坑
- **`NSHostingView` 死循环崩溃规避**：`AGYMainWindow` 必须在挂载为 `contentViewController` 之后，**先清空 `sizingOptions` 再设置 `safeAreaRegions`**；若提前访问，会在默认 `sizingOptions` 下触发 `NSHostingView` 初始化并导致 AutoLayout 死循环崩溃。
- **跑马灯宽度隔离**：长标题跑马灯（`ScrollingSessionTitleView`）必须用 `GeometryReader` 隔离测量子节点，阻断 `.fixedSize()` 理想宽度向上传导撑爆弹窗。
- **高容错边缘缩放热区**：因窗口带有 14pt 圆角，外侧透明区域会导致系统原生缩放箭头极难命中。通过透明浮层提供 8pt 边缘 + 16pt 四角热区（非边缘坐标 `hitTest` 返回 `nil` 透传按钮/滚动条事件），使用 `activeAlways` 确保失焦时悬停边框也能亮出箭头；拖拽缩放时严密锚定对边/对角，夹逼到 `minSize`/`maxSize` 时不推动窗口整体位移。
- **失焦唤醒与菜单栏激活**：仅在窗口处于激活 Key 状态且鼠标悬停时才展示账号切换按钮，并在后台窗口被点击置前后的极短时间窗内拦截误触切号。有窗口打开时进程切为 `.regular`（恢复顶部菜单与 `Cmd+Tab`），全部关闭后切回 `.accessory` 常驻菜单栏；点右上角叉号仅隐藏对应窗口，不终止常驻进程。
- **菜单栏三态猫头图标**：待命（闭眼）与工作中（左眯右瞪）启用 macOS 原生 Template 模式以适配亮/暗菜单栏；告警态（睁眼 + 右耳尖红点）保留彩色不走 Template。

---

## 2. 账号探测、Keychain 隔离与周配额接口

### 2.1 日志时间解析与钥匙串安全边界
- **glog 行内真实时间戳**：解析 CLI 日志及 `language_server.log` 时使用行内时间戳（`I/W/E/F + MMDD HH:MM:SS` 及微秒，兼容 `"ERROR: logging before google.Init: "` 前缀与跨年 180 天回退），避免拿文件 `mtime` 误判登录时间；CLI 日志扫描需排除无头/文件 token 存储模式日志。
- **逆向分块扫描**：只读扫描桌面端 `language_server.log` 时从尾向前最多分块扫描 16MB，防止海量日常日志将 `"Auth succeeded"` 推到 128KB 窗外导致漏判。
- **Keychain 零弹窗与安全写盘**：
  - 探测是否存在及读取最后修改时间时，只检索属性元数据（绝不访问 `kSecReturnData`），避免触发 `SecurityAgent` 密码弹窗；
  - 写入十六进制凭证通过 `/usr/bin/security -i` 标准输入管道完成，命令行参数零暴露并剥离控制字符防注入；
  - 写入 CLI 独立 token 文件（`~/.gemini/antigravity-cli/antigravity-oauth-token`）必须走唯一写盘入口：剥离 `go-keyring-base64:` 前缀、校验 `id_token_email` 与 `access_token` 后，以 `0600` 权限创建同目录临时文件再 `rename` 原子替换。
- **切号写入核验**：捕获入库与写回共享钥匙串前，必须核对载荷内置 `id_token_email` 与目标槽位一致，且切号回写前先将共享钥匙串当前最新凭证按内置真实邮箱存回对应槽位，杜绝串槽毒化。

### 2.2 周配额拉取、缓存与原生只读续期
- **请求头与分组解析**：调用 `retrieveUserQuotaSummary` 必须携带 `Antigravity Hub 2.31.2+` 的 `User-Agent`，否则后端不会返回 `Gemini 4 Argon` 配额组；解析分组时 `"Gemini 4 Argon"` 也包含 `"gemini"` 字样，必须优先于普通 Gemini 匹配（Claude/GPT `3p-weekly` 不再误映射为 Argon）。`Ultra` 账号配额共享统一仅展示 Gemini，普通/Pro 账号分别展示 Gemini 与 Argon。
- **多源凭据优先级与 401 回退**：收集同一邮箱在 CLI token 文件、系统共享钥匙串、保险箱中的全部候选凭据，按 `expiry` 新鲜度排序并按 `access_token` 去重；请求返回 401 时依次回退下一来源；回写刷新后的 token 时故意不改写共享钥匙串 `mtime`，以免触发外部漂移误判。
- **本地配额持久化与原生续期**：
  - 最近一次成功拉取的非敏感配额数字与重置时间原子持久化至 `~/.agy-profiles/quota_cache.json`（`0600`），重启后立即恢复，避免未刷新前显示 `Expired`；
  - 仅针对当前活跃 App 或活跃独立 CLI 槽位，通过官方只读零 Token 命令 `agy models` 触发原生续期（后台常规刷新 30 分钟冷却，用户主动强刷或点击 `Expired` 胶囊立即放行）；严禁替闲置备用账号拉起 `agy` 或构造临时 `HOME`。

---

## 3. Daemon 通信、FSEvents 与 Python 采集规则

### 3.1 Swift 端 Daemon、内存池与 FSEvents 细节
- **禁止在常驻队列循环内使用未池化的 `JSONSerialization`**：自定义 `DispatchQueue` 默认采用 `autoreleaseFrequency: .inherit`，不会自动弹出 autoreleasepool；在 `MonitorDaemonClient.readStdoutLoop` 等常驻 `while` 循环或后台全局队列中调用 `JSONSerialization.jsonObject` 会导致 ObjC `NSDictionary`/`CFString`/`NSArray`/`NSNumber` 树永久滞留线程 autoreleasepool（过夜可膨胀至十余 GB）。Daemon NDJSON 读取与解包必须使用纯 Swift `Decodable` 信封（`DaemonIdProbe` / `DaemonResponseEnvelope`），`readerQueue` 显式开启 `.workItem` 且单行处理与后台 `DispatchQueue.global` 回调均包裹 `autoreleasepool`。
- **可见性感知 `FSEvents` 节流与 CLI 状态冷却**：弹窗收起（`isDashboardVisible == false`）时，后台 Agent 连续写入 `brain/` 会密集触发 FSEvents，需通过 `PollingSchedulePolicy.shouldAttemptFSEventFetch` 对隐藏态 FSEvents 做至少 `4.0s` 节流；`refreshCLIAccountState` 与快照拉取解耦，常规轮询受可见 `10s` / 隐藏 `30s` 冷却约束（主动操作传 `force: true` 放行），并复用单次 `app_storage.json` (`Decodable`) 与 `language_server.log` 扫描结果、用哈希集合去重 `cli.log` 避免对海量历史日志做 `O(N)` `standardizedFileURL` 系统调用。
- **内存/磁盘诊断日志有界化**：`LocalAccountDetector._discoveryLogs` 仅保留最新 1000 条，`agyhub_accounts.log` 超过 1MB 时自动裁剪保留尾部 256KB；未配置外部 OAuth 凭据时的提示在单进程生命周期内仅记录一次。
- **防止 64KB 管道死锁**：`MonitorDaemonClient` 启动 `agy-monitor.py --daemon` 后必须持续排空 `stderr`，防止子进程写满 64KB 管道缓冲区引发死锁；收到 EOF 后清理当前代进程并唤醒全部悬而未决的等待者。
- **`agy-monitor.py` 定位优先级**：优先使用打包在 `Agyhub.app/Contents/Resources/` 内的版本，其次检查 `~/.gemini/config/tools/agy-monitor.py`，最后回退当前工作目录。
- **FSEvents 兼容后建目录**：`SessionDirectoryWatcher` 仅对已存在目录注册 `FSEventStream`，同时定期探测尚不存在的候选目录并在创建后自动纳管。

### 3.2 `agy-monitor.py` 解析与统计口径
- **底层端点模型识别**：`get_session_model` 优先读取较小的 `gen_metadata` 记录（跳过含整段 prompt 的大包），优先匹配真实后端端点标识（如 `gemini-3.8-flash-n`、`-tiered`），排除前端配置的 `-medium/-low/-high` 档位后缀；对齐用量统计序列时仅过滤末尾自动命名用的 `flash-low` 行。
- **速率与状态机校准**：
  - 对步骤时间戳做单调递增校准，防止排队消息时间戳早于前置事件导致时差暴增；
  - 排除上一轮助手最终回答待命（无未决工具调用）及报错后等待恢复的空闲时间；
  - 过滤 `> 500 t/s` 的 1 秒整秒落盘抖动或批量写入造成的物理不可能尖峰；
  - 优先使用最近 5 次正常生成步计算当前 TPS，避免被历史长等待摊薄；
  - 仅在最近一次正常模型输出之后仍未恢复时，才展示基础设施故障（`503 / EOF / 429`）。
- **全树聚合与双端去重**：采集时先捞满 `limit` 个顶层主会话，再补拉所有活跃子 Agent 及其祖先会话（防止子 Agent 挤占列表配额或父会话截断漏监控）；当 App 与 CLI DB 同时存在同步元数据行时，优先保留真实存在日志文件的那一方。
- **用量扫描与 Cache Miss 诊断**：
  - 既未命中缓存且 `mtime` 早于统计窗口的陈旧归档文件可直接跳过；今日外部锚点仅当日期严格等于今日时采信；
  - 显著 Cache Miss 判定为「上一轮已存在 `>= 50k` 缓存上下文，且本轮 `cache_read_tokens` 丢失超过 `50%`」，避免把正常读入新文件导致 `input_tokens` 变大误报为缓存失效。
