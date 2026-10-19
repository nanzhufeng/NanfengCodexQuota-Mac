# Project Status

## Verified

- Last verified: 2026-10-19 16:59 +08:00
- Branch: macos-port
- Code baseline: 8d52660；v0.1.7 刷新恢复及静默失败圆窗
- Verification scope: 本地提交及冻结产物；36 个生产文件摘要一致。
- Status: Active

## Current

- 完整 Mac 只读额度悬浮窗；共享 Rust 核心、AppKit 页面、132 pt 圆窗、紧凑玻璃菜单与原图标。最新圆窗／菜单视觉保持原设计。
- v0.1.7：瞬时连接失败或超时同次后台重试一次；查询 12 秒总时限；连续失败 3／10／30 秒恢复，后续等待上限 60 秒。
- 失败、过期与后台刷新均保留成功额度及原更新时间；无成功值时 --%／--:--，悬浮窗不显示中文失败提示。设置页保留准确英文失败状态。
- 本地 Apple Development 同身份 Universal App／DMG 已冻结并验证。用户已安装 v0.1.7，下载包和现装程序字节、签名与冻结包一致；截图确认系统仍拦截首次启动，实际获准运行尚未完成。Agent 未执行安装或安全例外。
- 此前 v0.1.6 用户实际安装成功与签名复盘见 qa/APPLE_DEVELOPMENT_SIGNING.md、qa/SIGNING_RETROSPECTIVE.md。

## In Progress

- 本轮打包上传已完成；用户已安装新版但系统仍拦截，需由用户本人作系统安全确认；Release 现仅保留安装包，校验附件已按要求删除。

## Blocked

- 无源码或构建阻塞；截图当次网络错误无法回溯，当前真实查询正常。

## Tests

| 检查 | 结果 | 范围 |
| --- | --- | --- |
| Rust／进程回归 | 39 PASS，1 ignored | v0.1.7；网络恢复／认证不重试／时限／取消／状态 |
| fmt／clippy | PASS | 本轮变更 |
| Universal／验签 | PASS | arm64＋x86_64；Apple Development |
| 原生隔离 | 24／24 PASS | 最终 App；fixture、成功／失败／恢复、窗口／菜单 |
| 精确 DMG／真实只读查询 | PASS，已连接 | 挂载 App 字节一致，隔离设置 |
| GitHub 发布与下载 | PASS | 正式 Release、两附件字节一致、CI 成功 |
| 用户运行实例替换／长期网络 | NOT RUN | 待授权安装；不以当前查询证明长期稳定 |

## Verification Gaps

- 未复现截图当次网络根因；修复已证实的长退避、瞬时失败不重试和错误显示行为。
- 新版实际安装、多屏／睡眠、下次登录、长时间运行、Intel 硬件仍分开验证。

## Sync & Safety

- main 已推送，v0.1.7 正式 Release 已发布；最初两个附件下载字节一致，后按用户要求精确删除校验附件，现仅保留 DMG；标签对应生产 8d52660。CI 39227895713 对 a380cf9 成功。
- 正式设置、登录项与 Codex 凭据未修改；真实接口仅 initialize 和 account/rateLimits/read。
- 可回滚基线：4faf1da，先前 v0.1.6 记录保留于 Git 与各验收文档。

## Next

1. 经用户允许后，同证书保设置替换安装并核验实际运行版本／路径。
2. 后续若仍出现失败，以安全诊断信号区分上游网络与协议，不扩大成 UI 重设计。

本轮详细红绿证据与产物见 [刷新恢复](qa/REFRESH_RECOVERY.md)。
