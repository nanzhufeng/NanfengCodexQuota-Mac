# Mac v0.1.4 GitHub 发布核验

- 核验时间：2026-10-11 19:28 +08:00
- 仓库：https://github.com/nanzhufeng/NanfengCodexQuota-Mac；PUBLIC，默认分支 main。
- Release：https://github.com/nanzhufeng/NanfengCodexQuota-Mac/releases/tag/v0.1.4
- Release tag / 应用生产提交：8a2a921e2648e800baa3103c10c383720e586d8a；非 Draft，非 Pre-release。
- CI：https://github.com/nanzhufeng/NanfengCodexQuota-Mac/actions/runs/38135352788；格式、Clippy、34 项测试（1 忽略）、两架构编译与打包全部成功。
- 本地最终包：原生隔离 22 / 22，精确 DMG 挂载验签及真实只读额度查询通过。
- README：当前生产版本的常规、关于和悬浮窗原生 fixture 截图；不包含用户真实账户数据。

| 远端附件 | 字节 | SHA-256 |
| --- | --- | --- |
| NanfengCodexQuota-Mac-v0.1.4-universal.dmg | 4709592 | c33f01e9fb4e8ea9be1e5b1cf39e39be300903a6c94683e93d01babe4a50c2f5 |
| NanfengCodexQuota-Mac-v0.1.4-universal.dmg.sha256 | 109 | e0101164571fb786ec4a28059b3e483899156b00ae714f10038248f7f75ff081 |

从 GitHub 重新下载两个附件，逐字节 SHA-256 与短 ASCII 上传路径的本地文件一致；GitHub 的附件名称、大小、uploaded 状态和 digest 也吻合。中文本地产物与英文 Release 附件的映射见 README。

签名边界：本地 ad-hoc，尚未 Developer ID 签名或 Apple 公证；Release 与 README 已如实披露可能受到 Gatekeeper 限制。Intel / macOS 13 真机、实际下次登录、多屏、完整睡眠和长期运行仍未验证。只上传源码与安装包，不提交用户设置、凭据、真实接口样本或本机日志。

最终产物已冻结。发布后文档提交与截图归档不会改变生产文件集合；不为文档重新编译或签名。
