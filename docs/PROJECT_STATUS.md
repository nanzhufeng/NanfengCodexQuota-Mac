# Project Status

## Verified

- Last verified: 2026-10-11 19:25 +08:00
- Branch: macos-port
- Code baseline: 8a2a921e2648e800baa3103c10c383720e586d8a
- Verification scope: COMMIT；生产源码 36 个文件与冻结包逐项一致；验收脚本、截图与报告随后归档，不改变应用。
- Status: Active

## Current

- Mac 原生版本已实现原 Windows v0.1.4 的完整功能和设计；Rust 共享核心、AppKit 窗口与控件、Retina 原像素圆窗、原图标。
- Universal .app / DMG 已生成，本机直接启动显示真实额度；最终 DMG 内应用已验签并跑通只读真实链路。
- 两页 UI、刷新间隔、置顶、隐藏找回、位置保存、单实例和失败恢复通过隔离原生行为测试；菜单五项完整，右上锚点与位置稳定。
- 圆窗按最新要求将彩色环仅向外加宽 3 pt，收回外沿暗底；画布、内缘、文字布局/字重与配色保持，环内缝隙仍填实。菜单采用适度原生玻璃及紧凑密度，已移除多余的窗口级矩形硬边，保留沿玻璃圆角自然衰减的阴影。
- 登录启动拒绝问题已修复：旧实例身份失效，新实例校验及真实注册通过。构建门禁阻止替换运行中的精确应用。

## In Progress

- 当前包原生 22 项及精确 DMG 复核通过；GitHub 8a2a921 云端检查运行中，通过后发布 v0.1.4。用户要求的 Mac 弹窗通用标准已写入长期记忆更新说明，待记忆系统合并。

## Blocked

- 无。

## Tests

| 检查 | 结论 | 时间 / 平台 / 范围 | 证据 |
| --- | --- | --- | --- |
| Rust 单测与 Mac 集成 | PASS：34，通过；1 默认忽略 | 2026-10-11 / 本机 Mac / 本轮源码 | cargo test --all-targets --locked |
| fmt / clippy | PASS | 2026-10-11 / Mac / 本轮源码 | cargo fmt --all --check；cargo clippy --all-targets --locked -- -D warnings |
| 两架构构建 | PASS | 2026-10-11 / arm64 + x86_64 交叉构建 | scripts/build-macos.sh --local |
| 隔离原生 UI | PASS：22 / 22 | 2026-10-11 / 最终 .app / fixture | scripts/qa-macos.py |
| 视觉对照 | PASS：两页、最小布局、圆窗、失败及缺失状态 | 2026-10-11 / 1064×711、900×640 pt | 本地联系表与 docs/images/mac-*.png |
| 精确包与真实服务 | PASS：已连接，最终包查询周剩余 85% | 2026-10-11 / 最终 DMG 挂载应用 | tests/verify_macos_package.py；docs/qa/MAC_ACCEPTANCE.md |
| 直接本机启动与菜单 | PASS | 2026-10-11 / dist 应用 / CUA | 菜单五档、取消和两页导航、关于提交 |
| 登录启动注册 | PASS | 2026-10-11 / 实际用户开关 / 新实例签名有效 | 真实注册成功，最终构建保留开启状态；实际下次登录尚未执行 |
| Developer ID / 公证 | NOT RUN | 本次为本地 ad-hoc | 无正式发行身份使用 |
| Intel 硬件 / 多屏 / 睡眠 / 长期运行 | NOT RUN | 不以编译或合成事件替代 | 待独立环境验收 |

## Verification Gaps

- 下次系统真实登录后的自动启动、Intel 设备与 macOS 13 真机、多屏、完整睡眠和长期运行。
- 未 Developer ID 签名、公证；Mac 独立公共仓库及 main 已创建，最终提交云端检查运行中。

## Sync & Safety

- Sync checked at: 2026-10-11 19:25 +08:00；归档验收前观察。
- Docs: OK；本项目合同、README、状态与验收对应同一产物。
- Git: 当前生产代码已本地 checkpoint；本轮边缘修复与验收文档已归档。
- Remote: PUBLIC；origin 为 nanzhufeng/NanfengCodexQuota-Mac，main 已推送；windows-source 仅作来源。Release 正在准备。
- Rollback: 8a2a921e2648e800baa3103c10c383720e586d8a；本机已验证的 Mac 代码 checkpoint；Windows 来源为 e6e3c5d9c26f498b5a3b7e9148f21340331c8d7a。
- Secrets/config risk: NONE；定向源码扫描 0 个密钥命中；QA 隔离设置，不提交真实额度原始样本，不复制凭据、不调用模型。

## Next

1. 用户在本机使用当前 .app / DMG；下一次正常登录验证自动启动。
2. 完成 GitHub v0.1.4 Release 上传及远端附件校验；Developer ID / 公证仍为独立发行边界。
