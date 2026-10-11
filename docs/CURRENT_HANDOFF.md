# 当前交接

v0.1.6 按用户明确要求复用南枫 AI 同一张 Apple Development 证书；生产提交 f86f6c5，证据见 qa/APPLE_DEVELOPMENT_SIGNING.md。

- 34 Rust／1 忽略、5 配置门禁、fmt／clippy、Universal、原生 23 项、最终 DMG 只读查询通过，签名证书逐字节一致。
- 实际 Gatekeeper 仍 rejected；不能声称首次拦截已解决。应用内设计未改。
- 未覆盖 Applications，现装版与新交付版分开；不自动安全例外，不删 quarantine，不启动开发版抢占实例。
- 用户明确南枫 AI 最初从 GitHub 安装；最近本地覆盖记录不能替代初次安装来源，先前相反推断已撤回。
- 新生产与冻结清单对应；GitHub 交付状态随后追加。旧 Release 附件保持原哈希。

GitHub v0.1.6 两附件已 uploaded／重新下载字节一致，标签精确对应 f86f6c5，CI 38139475206 成功。DMG SHA-256：6b34eaab942f540aa5c8ffab1194e024541557d5eb6f6abdf70c733762daf56e。用户级 App 专属配置保存所授权的开发证书 SHA1 与 Team ID，仓库不含密钥或配置。
