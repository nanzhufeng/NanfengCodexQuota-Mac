# 当前交接

v0.1.6 同 Apple Development 证书交付已闭环，用户确认可以；全项目状态见 PROJECT_STATUS.md，失败链与下次门禁见 qa/SIGNING_RETROSPECTIVE.md。

- 只读核验 Applications v0.1.6、开发证书、程序与冻结包字节一致，并从该路径运行。静态 spctl 仍 rejected，不能再次代替实际启动结论。
- 生产 f86f6c59907e4d526fb54b9639097c8a019aa07f；GitHub v0.1.6 两附件下载相同、CI 38139475206 成功。后续仅文档更新不重签／重打包。
- 已撤回“南枫 AI 最初本地安装”“同证书方案未试也无效”的推断；用户首次南枫 AI 来自 GitHub。
- 不重启或改写现运行程序，不改用户数据／凭据／登录项，不自动安全例外。长期规则更新说明交由记忆系统合并。
