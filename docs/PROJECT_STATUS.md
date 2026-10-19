# Project Status

## Verified

- Last verified: 2026-10-19（v0.1.8 本地 DMG 安装／自动打开／实际刷新通过）
- Branch: macos-port
- Code baseline: 3d604ee；v0.1.8 安装引导与同证书更新
- Verification scope: 已验收的冻结 v0.1.8 Universal App／DMG；14 项生产文件摘要与 3d604ee 提交一致，公开发布与下载回读通过。
- Status: Active

## Current

- 完整 Mac 只读额度悬浮窗；共享 Rust 核心、AppKit 页面、132 pt 圆窗、紧凑玻璃菜单与原图标。最新圆窗／菜单视觉保持原设计。
- v0.1.7：瞬时连接失败或超时同次后台重试一次；查询 12 秒总时限；连续失败 3／10／30 秒恢复，后续等待上限 60 秒。
- 失败、过期与后台刷新均保留成功额度及原更新时间；无成功值时 --%／--:--，悬浮窗不显示中文失败提示。设置页保留准确英文失败状态。
- Apple Development 同身份 Universal App／DMG 已冻结；v0.1.8 在 Applications 实际更新、自动打开、真实额度刷新、字节及实时签名均已验证。
- 此前 v0.1.6 用户实际安装成功与签名复盘见 qa/APPLE_DEVELOPMENT_SIGNING.md、qa/SIGNING_RETROSPECTIVE.md。

## 本轮本地完成

- v0.1.8 安装入口已实现：原生安装／更新选择、同证书暂存验签与原子替换、目标路径新实例启动、启动失败设置跳转。事务 22 项与原生 24 项通过。
- 最终 v0.1.8 已从 DMG 更新并自动打开，实际成功时间 21:08→21:21→21:24；最终排版包 21:41，目标摘要及实时签名核对通过；非位置偏好保留，x／y 有变化。

- v0.1.8 已正式发布，只有一个 DMG，公开下载与冻结文件相同；系统安全确认由用户本人完成。

## Blocked

- 无源码或构建阻塞；截图当次网络错误无法回溯，当前真实查询正常。

## Tests

| 检查 | 结果 | 范围 |
| --- | --- | --- |
| Rust／进程回归 | 39 PASS，1 ignored | v0.1.8；网络恢复／认证不重试／时限／取消／状态 |
| fmt／clippy | PASS | 本轮变更 |
| Universal／验签 | PASS | arm64＋x86_64；Apple Development |
| 原生隔离 | 24／24 PASS | 最终 App；fixture、成功／失败／恢复、窗口／菜单 |
| 精确 DMG／真实只读查询 | PASS，已连接 | 挂载 App 字节一致，隔离设置 |
| GitHub 发布与下载 | PASS | v0.1.8 单 DMG／匿名公开下载及挂载验签；CI 39263926873 成功 |
| 用户运行实例替换／刷新 | PASS | v0.1.8 DMG 更新、自动打开、真实成功时间推进；长期稳定另验 |

## Verification Gaps

- 未复现截图当次网络根因；修复已证实的长退避、瞬时失败不重试和错误显示行为。
- 多屏／睡眠、下次登录、长时间运行、Intel 硬件、其他 Mac 首次系统确认仍分开验证。

## Sync & Safety

- main 已推送，v0.1.8 正式 Release 已发布，标签生产 3d604ee；仅 DMG，公开回拉及 CI 39263926873（9e34a40）通过。v0.1.7 历史证据保留。
- 正式设置、登录项与 Codex 凭据未修改；真实接口仅 initialize 和 account/rateLimits/read。
- 可回滚基线：4faf1da，先前 v0.1.6 记录保留于 Git 与各验收文档。

## Next

1. 本轮交付完成；后续故障以实际版本、入口和日志为准，不重建已冻结发布包。
2. 后续若仍出现失败，以安全诊断信号区分上游网络与协议，不扩大成 UI 重设计。

本轮详细证据见 [安装引导](qa/INSTALLATION_FLOW.md)；已发布 v0.1.7 见 [刷新恢复](qa/REFRESH_RECOVERY.md)。
