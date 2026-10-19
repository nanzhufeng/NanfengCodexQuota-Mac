# 当前交接

用户目标：按通用 Mac 安装标准落地，并安装验证成功。**v0.1.8 本地安装验收及 GitHub 正式交付均已完成**；全项目见 PROJECT_STATUS.md，安装证据见 qa/INSTALLATION_FLOW.md。

- macos/Installation.swift 提供 DMG／下载目录／AppTranslocation 的原生安装或更新选择、暂不安装、取消。暂存验签、同证书替换、精确请求旧实例退出、原子交换，旧版保留到启动。系统安全确认仍由用户本人，不能由 App 替代。
- 原安装器复用问题已修：强制目标路径新实例，核验路径／PID再结束。关于页标题下小字功能审阅，无新增常驻按钮。
- 当前 /Applications/南枫 Codex 额度.app 是最终 v0.1.8；从最终 DMG 点击更新后自动打开，源安装器退出。实际已连接额度55%，最近成功21:41；此前连续成功21:08→21:21→21:24。运行 PID65077仅作历史值，接续需重核。
- 精确安装与候选可执行摘要一致、严格签名通过、live validity=0。现装非位置偏好保留，仅x/y相较备份变化；没有读取或修改Codex登录文件。
- fmt／clippy、Rust39 PASS／1 ignored、Universal、原生24／24、安装事务22 PASS。后者覆盖首次／更新／取消、损坏包／不同签名／符号链接拒绝、隔离保护位保留和临时目录清理。
- 最终包 dist/南枫Codex额度-Mac-v0.1.8-universal.dmg，摘要见 .release/install-acceptance/candidate.json；生产摘要 production-manifest.json，验收 installed.json。旧0.1.7 app／DMG备份 .release/frozen-v017；设置备份 .release/install-acceptance/settings-before.toml。
- v0.1.8 已发布，源码标签3d604ee、单 DMG；远端 digest与匿名公开下载SHA相同，回拉挂载App严格验签、六文件及现装程序均匹配。Release417366014／asset656456949。不要把本机同身份更新当成全新Mac首次下载免确认。
- 源码与安装测试已提交3d604ee，README当前截图／说明提交9e34a40；云端CI39263926873成功。后续仅提交最终交付文档，不重建冻结包、不上传校验文件。
- 长期规则已写产品标准Skill；记忆更新说明20261019-191940-mac-installation-guidance-standard.md已提交待系统合并。

发布地址：https://github.com/nanzhufeng/NanfengCodexQuota-Mac/releases/tag/v0.1.8。内部发布与下载证据 .release/v018/；没有再次代点系统确认。当前无剩余必需交付动作，后续不要为修改文档重签包。
