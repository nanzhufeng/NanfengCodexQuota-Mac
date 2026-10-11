# Mac 最终验收

- 时间：2026-10-11 19:25 +08:00
- 生产代码：8a2a921e2648e800baa3103c10c383720e586d8a，36 个生产文件 manifest 与最终包一致。
- Apple Silicon 本机 macOS 26.5.2；arm64 / x86_64 universal 编译、Mac 13+ 部署目标。
- 自动测试：34 PASS / 1 默认忽略；fmt / clippy -D warnings PASS。
- 原生隔离 UI：22 / 22 PASS。新增菜单完整五项、点击点右上锚定、刷新不移动、动作后关闭。
- 圆窗：按最新反馈将环外缘从 54.6 pt 扩展到 57.6 pt，内缘仍为 47.4 pt；暗底仅在内缘交叠，避免露出外沿。132 pt 画布、文字布局和字重、白字、深底与红橙黄配色保持，环与中心原缝隙处 alpha 仍为 255。后台刷新保留上次更新时间，成功后直接跳转新时间。
- 弹窗：190×166 pt，13 pt 字号、14 pt 图标、28 pt 行高，适度 regular 原生玻璃；内容完整，点击点右上 8 pt 稳定定位，屏幕边界仅作避让；不加黑色硬描边或夸张动效；已去掉矩形窗口级阴影，只在透明宿主绘制圆角阴影，向外自然消退。
- 实际桌面：已用 CUA 核验圆窗和紧凑玻璃完整菜单；最终构建已重新打开；CUA 截图包含完整透明留边及自然阴影，确认没有原截图中的外层矩形硬框。
- 登录启动：旧进程 SecCodeCopyGuestWithAttributes=-67049，新实例 locate=0 / validity=0，用户原始开关真实注册成功；最终构建开关仍开启。未执行系统注销/重登。
- 打包保护：目标在运行时构建被拒绝，已验证可执行文件字节未变；退出后采用新文件原子替换，不再原地破坏运行中 Mach-O。
- 最终 DMG：挂载验签通过，包内 executable 与 dist bundle SHA-256 完全一致；真实只读接口已连接、周剩余 85%、五小时接口未提供。没有模型调用。
- 签名：本地 ad-hoc，非 Developer ID，未 Apple 公证。Mac 独立公共仓库 main 已推送，Release 上传待最终 CI。

## 产物

- `dist/南枫 Codex 额度.app`
- `dist/南枫Codex额度-Mac-v0.1.4-universal.dmg`，4709592 bytes
- DMG SHA-256：`c33f01e9fb4e8ea9be1e5b1cf39e39be300903a6c94683e93d01babe4a50c2f5`
- Executable SHA-256：`454a2776028651efb32133ea9e4d38576c519a9f5113efda49291bab9b4e0e01`

截图为当前原生运行页面的隔离 fixture，README 已说明；用户真实服务原始 JSON、系统日志和进程身份审计只保留本地。上述哈希后没有重建或重签产物。

## 复核与边界

`python3 tests/verify_macos_package.py` 只复核既有精确包，不生成新包；`python3 scripts/qa-macos.py` 验证隔离 UI，不触发真实登录项注册。仍缺实际下次系统登录、Intel/macOS 13 硬件、多屏、完整睡眠及长期运行证据。

本轮修正只涉及 ContextMenu 与其原生 QA 的表面坐标验证。可见菜单 190×166 pt 保持；阴影透明留边不计入内容尺寸。Mac 弹窗通用标准已按用户要求保存为长期记忆更新说明，状态待应用；未直接编辑生成的 memory_summary.md / MEMORY.md。

本轮只修改共享圆窗渲染与相关 Mac 像素回归。87% 相同数据下，原底部外沿像素 RGBA=(19,9,6,84)，拓宽后=(255,135,30,255)；环外 alpha=69，仅为透明阴影，中心像素完全相同。像素证据见本地 `ring-pixel-verification.json`。实际最终 CUA 圆窗已核验；菜单实现未改。
