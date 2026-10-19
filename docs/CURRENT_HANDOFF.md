# 当前交接

用户目标：按通用 Mac 安装标准落地，并安装验证成功。**v0.1.8 本地交付已完成**；全项目见 PROJECT_STATUS.md，安装证据见 qa/INSTALLATION_FLOW.md。

- macos/Installation.swift 提供 DMG／下载目录／AppTranslocation 的原生安装或更新选择、暂不安装、取消。暂存验签、同证书替换、精确请求旧实例退出、原子交换，旧版保留到启动。系统安全确认仍由用户本人，不能由 App 替代。
- 原安装器复用问题已修：强制目标路径新实例，核验路径／PID再结束。关于页标题下小字功能审阅，无新增常驻按钮。
- 当前 /Applications/南枫 Codex 额度.app 是最终 v0.1.8；从最终 DMG 点击更新后自动打开，源安装器退出。实际已连接额度55%，最近成功21:41；此前连续成功21:08→21:21→21:24。运行 PID65077仅作历史值，接续需重核。
- 精确安装与候选可执行摘要一致、严格签名通过、live validity=0。现装非位置偏好保留，仅x/y相较备份变化；没有读取或修改Codex登录文件。
- fmt／clippy、Rust39 PASS／1 ignored、Universal、原生24／24、安装事务22 PASS。后者覆盖首次／更新／取消、损坏包／不同签名／符号链接拒绝、隔离保护位保留和临时目录清理。
- 最终包 dist/南枫Codex额度-Mac-v0.1.8-universal.dmg，摘要见 .release/install-acceptance/candidate.json；生产摘要 production-manifest.json，验收 installed.json。旧0.1.7 app／DMG备份 .release/frozen-v017；设置备份 .release/install-acceptance/settings-before.toml。
- 用户已要求打包上传 GitHub：v0.1.8 正在发布，源码提交3d604ee，冻结 DMG单附件；公开下载回读待执行。不要把本机同身份更新当成全新Mac首次下载免确认。
- 源码与安装测试已提交3d604ee；当前发布同步 README 最新原生截图与安装说明，冻结包不重建。待正式 Release、公开回拉摘要及 CI 完成后更新状态；不上传校验文件。
- 长期规则已写产品标准Skill；记忆更新说明20261019-191940-mac-installation-guidance-standard.md已提交待系统合并。
