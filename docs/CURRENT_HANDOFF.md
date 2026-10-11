# 当前交接

Mac 完整移植及本轮反馈已实现，结果见 PROJECT_STATUS.md 与 qa/MAC_ACCEPTANCE.md。

- 生产基线：39094a7d756d6f20f3b163def3141eadcc5804a0；36 个文件摘要在 `.release/source-manifest.json`。
- 最终 DMG SHA-256：66e57fb8a839a9b24b80b321074e7a5e21220f90a533c19700ca1f51dafc8621。
- 当前 dist 应用已启动：真实额度已连接，登录启动已开启且在最终重建后保持。
- 圆窗只按用户要求改配色、亮度和填实；尺寸、细环与字重未改。菜单为紧凑、适度原生玻璃，五项全显、点击点右上固定，无自绘黑框。正常更新不显示刷新中。
- 根因修复：禁止重建覆盖运行中的目标，原子替换。先退出精确 app 再构建；不得宽匹配杀进程。
- 包已冻结，不为更新文档重建或重签。复核命令：`python3 tests/verify_macos_package.py`。
- 未做系统注销、Intel/macOS 13 真机、多屏、完整睡眠或长期运行。未公证，未创建或推送 Mac 远端。
