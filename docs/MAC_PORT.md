# Mac 移植合同

来源：nanzhufeng/NanfengCodexQuota-Windows，基线 e6e3c5d9c26f498b5a3b7e9148f21340331c8d7a（v0.1.4）。

目标：完整保留只读额度功能与原有设计，交付可运行 macOS 应用。Windows 源码保留作精确保真参考；没有授权发布远端或修改 Codex 登录数据。

| 行为 / 消费者 | 唯一所有者 | Mac 适配与验证 |
| --- | --- | --- |
| 自动与手动额度查询 | Rust CodexClient / Provider / Worker | 桌面 CLI、Homebrew / PATH 发现；真实只读 RPC |
| 成功、失败保留、缺失、过期、退避、取消 | Rust Monitor / Worker | 全部页面、悬浮窗、菜单栏读取同一快照；契约与取消测试 |
| 周额度圆窗 | weekly_quota_render | 复用原绘制像素，Retina 输出；AppKit 系统字形 |
| 常规 / 关于 | AppKit SettingsView | 对照原 1064×704 内容布局、颜色、间距、导航、控件 |
| 置顶、拖动、保存、隐藏、找回、屏幕变化 | AppDelegate / NSPanel | 设置原子保存；可见屏幕夹取、保持负坐标 |
| 托盘、单实例、关闭与重新打开 | AppDelegate / flock | 菜单栏替代 Windows 托盘；第二实例唤回现有进程 |
| 登录启动 | SMAppService.mainApp | 默认关闭，只在用户切换时注册；真实系统状态为准 |
| 图标 / 构建来源 / 交付 | 原始 master / build.rs / build-macos.sh | 原图直接导出 icns；Git Commit 与工作区标志；独立 .app / DMG |

增量顺序：①共享核心与真实查询；②原生 UI 与生命周期；③视觉和行为 QA；④本机打包启动核验。

保护边界：不读取/输出密钥，不发起模型调用，不改 auth.json；QA 使用独立设置目录和假 CLI；不自动启用登录启动。构建与本机服务验收不替代 Intel 硬件、多屏、睡眠和长期运行。

停止门槛：功能实现、定向及原有回归、Mac 构建、视觉对照、真实只读服务和本机产物启动均有证据；无法获得的额外环境验证如实列出。
