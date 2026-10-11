# Project Status

## Verified
- Last verified: 2026-10-11 +08:00
- Branch: macos-port
- Code baseline: e6e3c5d9c26f498b5a3b7e9148f21340331c8d7a
- Verification scope: WORKTREE；Mac 移植进行中
- Status: Active

## Current
- 已取得 Windows v0.1.4 原源码与常规、关于截图，确定复用 Rust 核心和圆窗绘制。

## In Progress
- Mac CLI 发现、AppKit 两页 UI、菜单栏、窗口生命周期与独立打包。

## Blocked
- 无。

## Tests
- Mac build / unit / integration / UI / real service: NOT RUN。

## Verification Gaps
- 所有 Mac 行为尚待本轮验证。

## Sync & Safety
- Sync checked at: 2026-10-11 +08:00；克隆后无改动，现为本地移植工作区。
- Docs: OK；范围与来源见 MAC_PORT.md。
- Git: DIRTY；本次移植文档。
- Remote: LOCAL ONLY；windows-source 只作来源，未发布 Mac 仓库。
- Rollback: e6e3c5d9c26f498b5a3b7e9148f21340331c8d7a；原始来源，不代表 Mac 稳定版本。
- Secrets/config risk: NONE；尚未读取登录或修改用户配置。

## Next
1. 先验证共享核心在 macOS 上的只读查询。
