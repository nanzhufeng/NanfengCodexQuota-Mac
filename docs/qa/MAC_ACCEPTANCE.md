# Mac 最终验收

- 时间：2026-10-11 18:55 +08:00
- 生产代码：227deee26fe77aa34d14250146b4b3a73c39cadb，36 个生产文件 manifest 与最终包一致。
- Apple Silicon 本机 macOS 26.5.2；arm64 / x86_64 universal 编译、Mac 13+ 部署目标。
- 自动测试：34 PASS / 1 默认忽略；fmt / clippy -D warnings PASS。
- 原生隔离 UI：22 / 22 PASS。新增菜单完整五项、点击点右上锚定、刷新不移动、动作后关闭。
- 圆窗：原尺寸、环半径、环宽和字重保持；只修改白字、深底和红橙黄配色，环与中心原缝隙处 alpha 从 147 修复至 255。后台刷新保留上次更新时间，成功后直接跳转新时间。
- 弹窗：190×166 pt，13 pt 字号、14 pt 图标、28 pt 行高，适度 regular 原生玻璃；内容完整，点击点右上 8 pt 稳定定位，屏幕边界仅作避让；不加黑色硬描边或夸张动效；已去掉矩形窗口级阴影，只在透明宿主绘制圆角阴影，向外自然消退。
- 实际桌面：已用 CUA 核验圆窗和紧凑玻璃完整菜单；最终构建已重新打开；CUA 截图包含完整透明留边及自然阴影，确认没有原截图中的外层矩形硬框。
- 登录启动：旧进程 SecCodeCopyGuestWithAttributes=-67049，新实例 locate=0 / validity=0，用户原始开关真实注册成功；最终构建开关仍开启。未执行系统注销/重登。
- 打包保护：目标在运行时构建被拒绝，已验证可执行文件字节未变；退出后采用新文件原子替换，不再原地破坏运行中 Mach-O。
- 最终 DMG：挂载验签通过，包内 executable 与 dist bundle SHA-256 完全一致；真实只读接口已连接、周剩余 85%、五小时接口未提供。没有模型调用。
- 签名：本地 ad-hoc，非 Developer ID，未 Apple 公证。Mac 仓库未推送。

## 产物

- `dist/南枫 Codex 额度.app`
- `dist/南枫Codex额度-Mac-v0.1.4-universal.dmg`，4709591 bytes
- DMG SHA-256：`2b2f963be86836ff28fc2ab1367c293b46b7d746eb067d3741945034bb52f62f`
- Executable SHA-256：`e03399ea7717ab5fa7f4bd0a33d52c09a0dab6ba26c937b708937346b8bafc87`

截图为当前原生运行页面的隔离 fixture，README 已说明；用户真实服务原始 JSON、系统日志和进程身份审计只保留本地。上述哈希后没有重建或重签产物。

## 复核与边界

`python3 tests/verify_macos_package.py` 只复核既有精确包，不生成新包；`python3 scripts/qa-macos.py` 验证隔离 UI，不触发真实登录项注册。仍缺实际下次系统登录、Intel/macOS 13 硬件、多屏、完整睡眠及长期运行证据。

本轮修正只涉及 ContextMenu 与其原生 QA 的表面坐标验证。可见菜单 190×166 pt 保持；阴影透明留边不计入内容尺寸。Mac 弹窗通用标准已按用户要求保存为长期记忆更新说明，状态待应用；未直接编辑生成的 memory_summary.md / MEMORY.md。
