# v0.1.6 同 Apple Development 证书签名

2026-10-11，用户明确要求复用南枫 AI 的证书。生产提交 f86f6c5；仅打包／签名流程和版本元数据变化，圆窗与菜单布局未改。

## 已验证

- 与 `/Applications/南枫 AI Desktop.app` 叶证书字节一致，SHA-256 `e427918fedfc3842938551595bd6d3cd77666fc3a3a2ccdb67a43bc26684e7f3`。Team ID 为 457B263L9J。未导出私钥／修改访问控制。
- 配置由 App 专属环境变量或仓库外用户配置提供；开发模式要求身份与 Team ID 完整，不自动选择替代证书。5 个配置门禁检查通过。
- fmt／clippy 通过；Rust 34 通过、1 忽略；arm64／x86_64 构建及签名严格核验通过；原生 23／23；挂载最终 DMG 应用与本地可执行字节一致、真实只读额度查询通过。
- DMG 4711049 bytes，SHA-256 `6b34eaab942f540aa5c8ffab1194e024541557d5eb6f6abdf70c733762daf56e`。签名来自包内 codesign 读回，不再硬编码 ad-hoc。

## 未通过／未运行

- 换签名后实际 `spctl --assess --type execute` 返回 3／rejected。Apple Development 不等于 Developer ID 公证；没有声称免首次拦截。
- 用户原始南枫 AI 来自 GitHub；最近本地覆盖记录不能证明首次安装来源。实际下载 v1.0.20 DMG 核验确认同开发证书、无 stapled ticket、默认 Gatekeeper rejected；首次如何获准打开尚无证据。
- v0.1.6 未覆盖用户 Applications、未改隔离标记／安全设置／登录启动；下载版的正常启动及应用列表尚未验收。旧 v0.1.5 不重签或替换远端附件。

## GitHub 交付

[v0.1.6 Release](https://github.com/nanzhufeng/NanfengCodexQuota-Mac/releases/tag/v0.1.6) 为非草稿／非预发布；标签精确对应生产 f86f6c59907e4d526fb54b9639097c8a019aa07f。稳定 ASCII 文件名的 Universal DMG 与 SHA-256 两个附件均 uploaded；从远端重新下载两者，逐字节与冻结本地附件一致。

[CI 38139475206](https://github.com/nanzhufeng/NanfengCodexQuota-Mac/actions/runs/38139475206) 已 success，针对包含生产提交的 main 29b52bf；云端不拥有本机开发证书，其本地签名构建不代替本机开发签名证据。

## 用户实际启动确认（2026-10-11 20:41 +08:00）

用户确认现在可以。只读核验 Applications 现装 v0.1.6 使用开发证书，程序字节与冻结发布包一致，且从 Applications 路径运行。实际安装启动本项通过；`spctl` 当前仍 rejected，其结果保留为独立静态评估，不再据此称用户无法启动。详细失败与防复发记录见 [复盘](SIGNING_RETROSPECTIVE.md)。
