# 决策

## 2026-10-11：共享原 Rust 核心，原生 Mac 容器

保留 Windows v0.1.4 的额度解析、Provider、Monitor、Worker、Config 和圆窗绘制。Rust 通过只在 AppKit 主线程调用的 C ABI 暴露快照、配置、刷新和 Retina BGRA；Swift AppKit 管理原生窗口、控件与系统集成。选择静态链接避免另一个常驻桥接进程和 IPC 状态副本。Windows 模块与依赖按 target 隔离。

## 2026-10-11：平台适配保持原设计

常规 / 关于的白底、绿橙配色、布局、圆角、数据顺序、图标原图与 132 pt 圆窗保留。使用 Mac 系统字体和 SF Symbols；菜单栏替代托盘；点击 / 双击菜单栏图标打开主界面，右键打开原有五项菜单。登录启动使用 SMAppService，默认关闭，注册仅由用户开关触发；不创建 LaunchAgent。

## 2026-10-11：独立本地项目，明确发行边界

本地 checkout 为 NanfengCodexQuota-Mac，windows-source remote 仅作来源，未创建或推送远端 Mac 仓库。交付 universal .app 和 DMG；本地 ad-hoc 是运行封装，Developer ID / Apple 公证需完整 App 专属外部配置。macOS 13+ 为最低系统版本；Intel 交叉构建不等于 Intel 真机验收。

## 2026-10-11：限定弹窗与静默刷新

用户要求撤回圆窗视觉优化，圆窗渲染源码精确恢复至 9a1dcde；尺寸、细环、字重和配色保持原样。只保留用户明确要求的后台更新时间静默切换。右键弹窗改用不透明白色原生 Panel，完整显示原五项动作；固定锚定点击位置右上方，仅在屏幕边界作避让，刷新及悬停不重新布局。标准设置页布局与功能不改变。
