# 当前交接

当前 v0.1.5 恢复普通 Mac 应用身份，发布及系统安全限制见 PROJECT_STATUS.md 与 qa/INSTALL_STARTUP.md。

- 生产提交：0e01d765956c701ed2aefa96a9b732101effa243；36 个文件摘要在 `.release/source-manifest.json`。
- DMG SHA-256：ca481995971e1b172fbb6bac0cc5cddc7932f27a6b6edc509c029a84aab77156；GitHub v0.1.5 重新下载字节一致，CI 0e01d76 成功。
- regular AppKit / LSUIElement=false / utilities 分类；原生 23 项和真实只读查询通过，圆窗、菜单和设置布局未改。
- Gatekeeper 明确 rejected。Developer ID 与公证条件不足，用户安全确认未完成；不得再称下载版“确定没问题”。
- 不自动覆盖 Applications；用户需更新安装并亲自作安全决定，然后现场核验系统应用列表。当前无开发目录实例抢占，后续不得再自动启动开发版造成安装路径混淆。
- 保留用户设置和 Codex 登录；不删 quarantine、不关闭系统门禁、不重置全局应用索引。
- 两条长期记忆更新说明已保存：Mac 弹窗通用 UI 标准、Mac 下载版安装启动验收，均交由记忆系统合并。
- 产物已冻结，后续文档不触发重建或重签。
