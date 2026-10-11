# 下载版安装启动问题与 v0.1.5

- 核验时间：2026-10-11 20:03 +08:00
- 用户 v0.1.4 下载包与 Applications 内程序字节一致、seal 校验成功，但 Gatekeeper 明确 rejected。复制成功不等于获准启动；此前回答“安装成功”过早。
- v0.1.4 LSUIElement=true / accessory，用户期待正常应用列表入口，该隐藏代理配置不符合预期。
- v0.1.5 恢复 LSUIElement=false / regular / utilities；实际 NSRunningApplication 角色检查通过。系统应用列表的实际安装后显示仍待用户现场确认，不能由角色元数据替代。
- 当前生产提交：0e01d765956c701ed2aefa96a9b732101effa243；34 项 Rust 测试通过（1 默认忽略）、23 项原生隔离检查通过、精确 DMG 挂载验签与真实只读查询通过。
- CI：https://github.com/nanzhufeng/NanfengCodexQuota-Mac/actions/runs/38136694106；success。
- Release：https://github.com/nanzhufeng/NanfengCodexQuota-Mac/releases/tag/v0.1.5；非 draft、非 pre-release，两个附件重新下载后字节一致。
- DMG：NanfengCodexQuota-Mac-v0.1.5-universal.dmg；4709194 bytes；SHA-256：ca481995971e1b172fbb6bac0cc5cddc7932f27a6b6edc509c029a84aab77156
- 签名：ad-hoc；Developer ID Application 可用身份为 0，未苹果公证。v0.1.5 的 spctl 默认评估也明确 rejected，不能承诺直接启动。

需要用户本人完成：下载 v0.1.5 并复制替换到 Applications，尝试正常打开；若确认来源和文件校验一致，按苹果官方说明在系统设置 → 隐私与安全性中自行作“仍要打开”的安全决定，再验证安装路径、真实界面和系统应用列表。自动化不代点该决定，不删除 quarantine 或禁用门禁，不绕过下载版的正常启动链路。

官方步骤：https://support.apple.com/zh-cn/102445。完全免该确认需正规 Developer ID 签名与公证；这不是代码调整可以替代的条件。
