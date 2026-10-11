# Mac 开发与发行

| 所有者 | 职责 / 消费者 |
| --- | --- |
| discovery / codex / provider | 发现 Codex.app、ChatGPT 内置 CLI、PATH、Homebrew；只读 RPC、缺失/认证/网络/协议/超时分类 |
| monitor / limits | 唯一额度事实、缺失不变零、失败保留、过期；所有页面共用 |
| worker | 单请求在途、60 秒默认刷新、30–600 秒设置、失败退避、退出取消与精确子进程回收 |
| config / mac_core | Application Support 原子设置；损坏或新版本文件阻止覆盖；C ABI 主线程唯一句柄 |
| weekly_quota_render | 原 Windows 圆窗的同一像素算法；1× / Retina 2× BGRA 输出，不重画设计 |
| macos/Core.swift / Controls.swift / SettingsView.swift / WidgetView.swift | C ABI 桥、共享控件、两页仪表和悬浮窗 |
| macos/AppDelegate.swift / ContextMenu.swift / QA.swift | Mac 生命周期、菜单栏、SMAppService、flock、位置与隔离 QA |
| scripts/build-macos.sh | 两架构静态链接、原图导出 icns、.app / DMG、签名与公证边界 |

`mac_core` 的 C ABI 仅允许主线程串行调用。其 CString 由 quota_string_free 释放，句柄退出时只释放一次；Rust Worker 内部线程负责 I/O，不阻塞 UI。Mac UI 与原图同内容区对比，Mac 系统字形及标准窗口框是平台适配。

核心自动测试覆盖解析、缺失窗口、分数百分比、失败保留与恢复、过期、配置保真、Retina alpha，以及 Mac 退出时取消并回收精确 CLI 子进程。真实服务测试保持默认忽略；本轮独立只读验证有单独记录。

`qa-macos.py` 运行精确 .app 内可执行文件，设置与 CLI 都在每次唯一的临时目录。实际 NSButton 动作、NSWindow 导航和生命周期验证后退出；不改正式设置，不创建登录项。图像是当前原生 View 渲染；接触表只用于 QA，不冒充多个独立页面。原 Windows 截图保存在 `docs/images/windows-*.png`。

## 发行

`--local` 生成两架构通用本地包，以 ad-hoc 封装；这不是发行证书或公证完成。`--development` 使用用户明确指定的 Apple Development 证书，要求 SIGN_IDENTITY 与 EXPECTED_TEAM_ID 两项完整，核验开发证书类型及 Team ID；不要求公证 profile，不自动选择证书。开发签名不能作为通过 Gatekeeper 的证据。`--distribute` 必须使用完整环境命名空间：

- `NANFENG_CODEX_QUOTA_MAC_SIGN_IDENTITY`
- `NANFENG_CODEX_QUOTA_MAC_EXPECTED_TEAM_ID`
- `NANFENG_CODEX_QUOTA_MAC_NOTARY_PROFILE`

全部未配置时才读取用户级仓库外 `.config/nanfeng-signing/NanfengCodexQuota-Mac.json` 的 identity、expectedTeamId、notaryProfile。任意部分缺失即停止，不能自动选择替代身份。脚本不导出私钥、不改访问控制、不提示或记录口令。Developer ID 证书与 Team ID 都须匹配，然后验证签名、提交公证并 staple / validate DMG。

正式安装按用户操作将应用复制至 Applications。应用不自动注册登录启动；SMAppService.mainApp 在开关触发时执行，失败回滚展示，待批准时打开系统设置。当前系统授权与设置文件值有差异时，以系统状态为准。

最低系统 macOS 13；本机为 Apple Silicon。Intel 已交叉编译并嵌入 universal，不代表 Intel 硬件或 macOS 13 真机验证。多屏、系统睡眠、长时间运行和真实登录启动仍独立列为验证缺口。

打包会检查精确 dist 可执行文件是否仍在运行；在运行时拒绝替换。lipo 先写独立文件，再原子移动到 bundle，避免修改正在执行的 Mach-O 映射。运行中的旧实例若代码身份失效，不能用磁盘验签结果替代进程身份验收。
