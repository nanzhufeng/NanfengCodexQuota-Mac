# Project Status

## Verified

- Last verified: 2026-10-11 20:41 +08:00
- Branch: macos-port
- Code baseline: f86f6c5；v0.1.6 Apple Development 签名增量
- Verification scope: COMMIT；生产源码 36 个文件与冻结包逐项一致；验收脚本、截图与报告随后归档，不改变应用。
- Status: Active

## Current

- v0.1.6 已按用户明确指令使用南枫 AI 的同一张 Apple Development 证书打包；叶证书 SHA-256 完全相同。34 Rust 通过／1 忽略、5 配置门禁、fmt／clippy、Universal 构建、原生 23 项及最终 DMG 真实只读查询通过。用户已确认可用；现装 v0.1.6 的版本、开发签名、程序字节与 Applications 运行路径均已核验。静态 `spctl` 仍 rejected，单独保留该结果，不再等同于实际打不开。Agent 未执行安装或安全例外。详细证据见 [开发证书验签](qa/APPLE_DEVELOPMENT_SIGNING.md)。下方 v0.1.5 是此前交付记录。

- Mac 原生版本已实现原 Windows v0.1.4 的完整功能和设计；Rust 共享核心、AppKit 窗口与控件、Retina 原像素圆窗、原图标。
- v0.1.5 Universal .app / DMG 已生成，恢复普通应用身份；原生隔离及真实只读链路通过。默认 Gatekeeper 评估仍拒绝，未完成用户下载版获准启动验收。
- 两页 UI、刷新间隔、置顶、隐藏找回、位置保存、单实例和失败恢复通过隔离原生行为测试；菜单五项完整，右上锚点与位置稳定。
- 圆窗按最新要求将彩色环仅向外加宽 3 pt，收回外沿暗底；画布、内缘、文字布局/字重与配色保持，环内缝隙仍填实。菜单采用适度原生玻璃及紧凑密度，已移除多余的窗口级矩形硬边，保留沿玻璃圆角自然衰减的阴影。
- 登录启动拒绝问题已修复：旧实例身份失效，新实例校验及真实注册通过。构建门禁阻止替换运行中的精确应用。

## In Progress

- v0.1.6 同开发证书包已发布；两附件重新下载字节一致，标签对应生产 f86f6c5，CI 38139475206 成功。用户实际安装启动已确认通过；静态安全评估单独记录。详细复盘见 qa/SIGNING_RETROSPECTIVE.md。

- v0.1.5 原生 23 项及精确 DMG 复核通过；0e01d76 CI 与 Release 附件校验通过。安装后的应用列表显示及首次安全确认需由用户完成，不能继续宣称下载启动已无问题。用户要求的 Mac 弹窗通用标准已写入长期记忆更新说明，待记忆系统合并。

## Blocked

- 无当前安装启动阻塞。未完成 Developer ID 公证及广泛设备免提示分发验证，保留为独立边界。

## Tests

| 检查 | 结论 | 时间 / 平台 / 范围 | 证据 |
| --- | --- | --- | --- |
| Rust 单测与 Mac 集成 | PASS：34，通过；1 默认忽略 | 2026-10-11 / 本机 Mac / 本轮源码 | cargo test --all-targets --locked |
| fmt / clippy | PASS | 2026-10-11 / Mac / 本轮源码 | cargo fmt --all --check；cargo clippy --all-targets --locked -- -D warnings |
| 两架构构建 | PASS | 2026-10-11 / arm64 + x86_64 交叉构建 | scripts/build-macos.sh --local |
| 隔离原生 UI | PASS：23 / 23 | 2026-10-11 / 最终 .app / fixture | scripts/qa-macos.py |
| 视觉对照 | PASS：两页、最小布局、圆窗、失败及缺失状态 | 2026-10-11 / 1064×711、900×640 pt | 本地联系表与 docs/images/mac-*.png |
| 精确包与真实服务 | PASS：已连接，最终包查询周剩余 85% | 2026-10-11 / 最终 DMG 挂载应用 | tests/verify_macos_package.py；docs/qa/MAC_ACCEPTANCE.md |
| 直接本机启动与菜单 | PASS | 2026-10-11 / dist 应用 / CUA | 菜单五档、取消和两页导航、关于提交 |
| 登录启动注册 | PASS | 2026-10-11 / 实际用户开关 / 新实例签名有效 | 真实注册成功，最终构建保留开启状态；实际下次登录尚未执行 |
| Gatekeeper / 正式身份 | FAIL：默认评估 rejected；可用 Developer ID 为 0 | v0.1.5 / 本机 / 非用户批准状态 | 下载启动问题见 docs/qa/INSTALL_STARTUP.md |
| Intel 硬件 / 多屏 / 睡眠 / 长期运行 | NOT RUN | 不以编译或合成事件替代 | 待独立环境验收 |
| GitHub CI 与附件 | PASS：0e01d76 CI；v0.1.5 两个附件下载字节一致 | 2026-10-11 / GitHub | docs/qa/INSTALL_STARTUP.md |
| v0.1.6 安装启动 | PASS：用户确认可用，现装版本／签名／包字节及实际运行路径一致 | Applications；spctl 静态评估仍独立 rejected | qa/SIGNING_RETROSPECTIVE.md；系统应用列表视觉未另验 |

## Verification Gaps

- 下次系统真实登录后的自动启动、Intel 设备与 macOS 13 真机、多屏、完整睡眠和长期运行。
- 未 Developer ID 签名、公证；Mac 独立公共仓库 main 及 v0.1.5 Release 已发布；0e01d76 云端构建检查通过，默认门禁仍未通过。

## Sync & Safety

- Sync checked at: 2026-10-11 20:03 +08:00；归档验收前观察。
- Docs: OK；本项目合同、README、状态与验收对应同一产物。
- Git: 当前生产代码已本地 checkpoint；本轮边缘修复与验收文档已归档。
- Remote: PUBLIC；origin 为 nanzhufeng/NanfengCodexQuota-Mac，main 已推送；windows-source 仅作来源。v0.1.5 Release 已发布；未公证及人工安全确认边界明确披露。
- Rollback: 0e01d765956c701ed2aefa96a9b732101effa243；本机已验证的 Mac 代码 checkpoint；Windows 来源为 e6e3c5d9c26f498b5a3b7e9148f21340331c8d7a。
- Secrets/config risk: NONE；定向源码扫描 0 个密钥命中；QA 隔离设置，不提交真实额度原始样本，不复制凭据、不调用模型。

## Next

1. 后续签名与安装问题遵循 [复盘门禁](qa/SIGNING_RETROSPECTIVE.md)，先执行已授权的参考方案再下结论。
2. 系统应用列表视觉、下次登录、多屏／睡眠及其他 Mac 分发体验仍需按实际需求独立验证。
