# Mac 最终验收

- 时间：2026-10-11 18:34 +08:00
- 生产代码：39094a7d756d6f20f3b163def3141eadcc5804a0，36 个生产文件 manifest 与最终包一致。
- Apple Silicon 本机 macOS 26.5.2；arm64 / x86_64 universal 编译、Mac 13+ 部署目标。
- 自动测试：34 PASS / 1 默认忽略；fmt / clippy -D warnings PASS。
- 原生隔离 UI：22 / 22 PASS。新增菜单完整五项、点击点右上锚定、刷新不移动、动作后关闭。
- 圆窗：原尺寸、环半径、环宽和字重保持；只修改白字、深底和红橙黄配色，环与中心原缝隙处 alpha 从 147 修复至 255。后台刷新保留上次更新时间，成功后直接跳转新时间。
- 弹窗：190×166 pt，13 pt 字号、14 pt 图标、28 pt 行高，适度 regular 原生玻璃；内容完整，点击点右上 8 pt 稳定定位，屏幕边界仅作避让；不加黑色硬描边或夸张动效。
- 实际桌面：已用 CUA 核验圆窗和紧凑玻璃完整菜单；最后构建已重新打开。
- 登录启动：旧进程 SecCodeCopyGuestWithAttributes=-67049，新实例 locate=0 / validity=0，用户原始开关真实注册成功；最终构建开关仍开启。未执行系统注销/重登。
- 打包保护：目标在运行时构建被拒绝，已验证可执行文件字节未变；退出后采用新文件原子替换，不再原地破坏运行中 Mach-O。
- 最终 DMG：挂载验签通过，包内 executable 与 dist bundle SHA-256 完全一致；真实只读接口已连接、周剩余 86%、五小时接口未提供。没有模型调用。
- 签名：本地 ad-hoc，非 Developer ID，未 Apple 公证。Mac 仓库未推送。

## 产物

- `dist/南枫 Codex 额度.app`
- `dist/南枫Codex额度-Mac-v0.1.4-universal.dmg`，4706226 bytes
- DMG SHA-256：`66e57fb8a839a9b24b80b321074e7a5e21220f90a533c19700ca1f51dafc8621`
- Executable SHA-256：`6b88797791a2abfb5f0911f0abbeb7f7c3b61e9035435e1a4122817dcc7ada2d`

截图为当前原生运行页面的隔离 fixture，README 已说明；用户真实服务原始 JSON、系统日志和进程身份审计只保留本地。上述哈希后没有重建或重签产物。

## 复核与边界

`python3 tests/verify_macos_package.py` 只复核既有精确包，不生成新包；`python3 scripts/qa-macos.py` 验证隔离 UI，不触发真实登录项注册。仍缺实际下次系统登录、Intel/macOS 13 硬件、多屏、完整睡眠及长期运行证据。
