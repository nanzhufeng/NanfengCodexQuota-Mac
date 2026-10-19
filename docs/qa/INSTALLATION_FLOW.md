# v0.1.8 安装引导验收

## 已实现

- DMG／下载目录／App Translocation 首次打开：安装（已有则更新）并打开、暂不安装、取消。
- 安装入口先于设置锁；已安装 App 正常启动不出现安装弹窗。
- 独立暂存并验签，拒绝损坏包、不同证书、符号链接目标。只请求退出目标路径实例，不强杀。
- 同卷原子移动／交换，旧版保留到目标实例启动；不访问设置或登录凭据，不删除隔离属性。隔离测试实测 macOS 复制会把测试标记 0081 规范化为 0281，源标记未变、传入保护位未减少，不承诺复制后的隔离字节完全相同。
- 目标启动显式创建新实例，核验路径与 PID；系统返回错误时可打开隐私与安全性、重试或稍后。
- 设置“关于”中的功能审阅列出入口和保留理由，无新增常驻安装按钮。

## 当前验证

- 2026-10-19：Rust 39 PASS、1 ignored；fmt／clippy PASS。
- Universal arm64／x86_64 构建及 Apple Development 同身份验签通过。
- 原生隔离 QA 24／24 PASS。安装事务 22／22 PASS，另见 `.release/installation-tests.log`。
- 已从实际 DMG 看见更新选择，覆盖安装至 Applications，设置原始字节一致。
- 首次实测发现 LaunchServices 复用安装器而未留下目标进程；改为显式新实例并校验路径／PID后，已从 DMG 再次点击“更新并打开”。旧实例 55566 退出，目标新实例 60946 留在 Applications，源安装器退出，主界面自动打开。
- 最终安装实例显示真实剩余额度 55%，成功时间从 21:08 推进到 21:21；手动刷新按钮进入禁用后恢复。安装程序摘要匹配最终 DMG 候选、严格签名校验通过、运行中签名 validity=0。证据 `.release/install-acceptance/installed.json`。
- 正式偏好（置顶、登录启动、刷新间隔等）保持；相较测试前备份仅 x／y 改变，不将窗口位置保存误报为业务数据丢失。未写 Codex 凭据。

## 复跑

```sh
bash scripts/build-macos.sh --development
xcrun swiftc -parse-as-library -swift-version 5 macos/Installation.swift scripts/test-macos-installation.swift -framework AppKit -framework Security -o .release/installation-tests
.release/installation-tests 'dist/南枫 Codex 额度.app' '.release/frozen-v017/南枫 Codex 额度.app'
python3 scripts/qa-macos.py
```

安装测试仅写独立临时目录；正向覆盖需旧版同证书 fixture。`.release/frozen-v017` 为本轮内部回退快照，不随公开包交付。

## 当前产物与边界

- 本地候选：dist/南枫Codex额度-Mac-v0.1.8-universal.dmg。
- 固定候选哈希与生产文件摘要：`.release/install-acceptance/candidate.json`、`production-manifest.json`。
- 实际主机设置备份：`.release/install-acceptance/settings-before.toml`，不上传。
- 用户已授权发布 v0.1.8，正在上传；公开下载路径待回读。
- 安全系统确认入口不伪装、不代点；本机已经批准的状态不能证明其他 Mac 首次运行免确认。

最终收尾：说明文字改为标题下单行，最小窗口也可完整显示。重新构建并再次从 DMG 更新，精确安装 PID 65077 持续运行、主界面自动打开、实际额度 55%，最近成功 21:41。最终 App 摘要 7fb998a7a3a08b8e02a40ebb5e247c0ea1ec1c83da171358e3515dcddf8a3fb8，DMG 摘要 3cf04ee08ce114cfd0c4cac8205ba8c192637a5db44522b7b32bf28dbfed5e6f。最终本地安装验证 PASS；公开 GitHub 下载仍未执行。

发布来源：源码提交 3d604ee。包在该提交前已完成安装验收，保留冻结时 Git HEAD 75b0c2c／本地改动标记；已逐一核对 14 项生产文件摘要与 3d604ee 完全一致，提交和文档更新没有重签／重打包。
