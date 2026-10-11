# 当前交接

Mac 完整移植及本轮反馈已实现，结果见 PROJECT_STATUS.md 与 qa/MAC_ACCEPTANCE.md。

- 生产基线：227deee26fe77aa34d14250146b4b3a73c39cadb；36 个文件摘要在 `.release/source-manifest.json`。
- 最终 DMG SHA-256：2b2f963be86836ff28fc2ab1367c293b46b7d746eb067d3741945034bb52f62f。
- 当前 dist 应用已启动：真实额度已连接，登录启动已开启且在最终重建后保持。
- 圆窗只按用户要求改配色、亮度和填实；尺寸、细环与字重未改。菜单为紧凑、适度原生玻璃，五项全显、点击点右上固定，去掉多余矩形硬框，保留自然过渡的圆角阴影。正常更新不显示刷新中。
- 根因修复：禁止重建覆盖运行中的目标，原子替换。先退出精确 app 再构建；不得宽匹配杀进程。
- 包已冻结，不为更新文档重建或重签。复核命令：`python3 tests/verify_macos_package.py`。
- 未做系统注销、Intel/macOS 13 真机、多屏、完整睡眠或长期运行。未公证，未创建或推送 Mac 远端。

- Mac 弹窗通用 UI 标准：用户已授权记录，更新说明位于 `~/.codex/memories/extensions/ad_hoc/notes/20261011-macos-popup-common-ui-standard.md`，状态待记忆系统应用；禁止把取消阴影的中间版本记作标准。
