# 南枫 Codex 额度 · Mac

- 开始先读 `docs/PROJECT_STATUS.md`、`docs/MAC_PORT.md`；接续任务再读 `docs/CURRENT_HANDOFF.md`。
- 唯一产品是只读额度悬浮窗：只发送 initialize 和 account/rateLimits/read，不创建对话，不调用模型，不复制或输出登录凭据。
- Rust 是额度、失败保留、过期、刷新与配置的唯一所有者；AppKit 只消费 `mac_core` 快照并处理 Mac 平台操作。
- 原 Windows 源码、截图及包装脚本保留作来源参考；Mac 的公开构建入口是 `scripts/build-macos.sh`。
- 日常：`cargo fmt --all --check`、`cargo clippy --all-targets --locked -- -D warnings`、`cargo test --all-targets --locked`。
- 原生 QA：`python3 scripts/qa-macos.py`；仅使用隔离目录与 fixture CLI，不注册真实登录启动服务。
- 所有图标衍生自 `assets/app-icon-master.png`，不裁切、加底或重绘。
- 发行前运行 universal 构建、原生 QA、真实只读服务、精确产物启动验证；本地 ad-hoc 签名与 Developer ID / 公证分开报告。
- 不自动安装到 Applications，不自动启用登录启动，不改 Codex 配置和凭据，不推送或发布未经请求的远端项目。
