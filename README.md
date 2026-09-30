# 🧹 Windows C 盘极限深度瘦身专家 (Windows Deep Cleaner)

> **工业级 Windows 系统盘瘦身规范与靶向清理工具包**  
> 专门针对 `AppData` 顽固缓存、30万+ Windows Update 超长路径碎片、系统级休眠以及被 `TrustedInstaller` 锁死的幽灵目录 —— 找回被常规清理工具遗忘的 15GB ~ 35GB+ 宝贵空间。

[English Version](./README_EN.md) | **中文说明**

---

## ✨ 为什么常规清理工具“扫不出几个 G”？

传统的 Windows 清理工具（如系统磁盘清理、清除 `%temp%`）通常只能挤出几百 MB 空间。真正的“空间杀手”隐藏在系统底层与深层应用沙箱中：

1. **Windows Update 30万+碎片积压**：`SoftwareDistribution\Download` 经常堆积 5GB ~ 10GB 累积更新，且目录深度超过 260 字符（MAX_PATH），常规脚本会直接静默跳过。
2. **多盘迁移幽灵锁死**：曾把“新应用保存位置”改到其他盘后，留下的 `WindowsApps` / `DeliveryOptimization` 被 `TrustedInstaller` 锁死，管理员右键直接报“拒绝访问”。
3. **身在 D 盘，魂在 C 盘**：常用软件（微信、飞书、剪映、IDE、浏览器）主体装在 D 盘，但其 CEF 渲染内核、离线 Service Worker、运行时日志全部默认塞在 `C:\Users\...\AppData`。
4. **系统休眠硬扣快照**：`hiberfil.sys` 默认强行划走物理内存容量的 40% ~ 80%（6GB ~ 16GB）。

---

## 📁 目录结构与工具清单

```
windows-deep-cleaner/
├── SKILL.md                          # AI 智能体执行指令 (符合 CODEX 标准的刚性规范)
├── README.md                         # 项目中文说明
└── scripts/
    ├── Get-DiskHogs.ps1              # 第一步：深层只读盘点（元数据快速扫描，不改不删）
    ├── simple_clean.ps1              # 第二步：无损应用缓存清理（AppData / IDE / 日志）
    ├── Clean_WinUpdate_Force.bat     # 强力拔除数十万超长路径 Windows Update 补丁碎片 (纯英文防闪退)
    ├── Clean_D_Root_Locked_Folders.bat # 强力夺权并清空被 TrustedInstaller 锁死的多盘应用目录
    ├── Antigravity_Clean.ps1         # 12 大项全量系统深度清理核心逻辑
    └── Antigravity_Clean.bat         # 12 大项系统全量清理一键运行入口 (自动提权)
```

---

## 🎯 核心清理靶点与处理方式

| 目标分类 | 典型路径 | 占用规格 | 安全清理策略与说明 |
|---|---|---|---|
| **Windows Update 碎片** | `C:\Windows\SoftwareDistribution\Download` | **3GB ~ 10GB** | 停止更新服务，调用底层 `rd /s /q` 击穿超长路径秒删 |
| **多盘锁死目录** | `D:\WindowsApps`, `D:\DeliveryOptimization` | **2GB ~ 20GB** | `takeown` 夺权 + `icacls` 赋权后彻底移除残留 |
| **Edge 浏览器离线包** | `%LOCALAPPDATA%\Microsoft\Edge\...\CacheStorage` | **2GB ~ 5GB+** | 清空 Service Worker 离线包，不影响书签与登录凭证 |
| **微信 xwechat 日志** | `%APPDATA%\Tencent\xwechat\log` | **800MB ~ 3GB** | 仅清空运行 text 日志，聊天记录与文件 100% 毫发无损 |
| **微信开发者工具** | `%LOCALAPPDATA%\微信开发者工具\User Data` | **1.5GB ~ 3GB** | 清理临时构建解包与历史基础库，不影响工程源码 |
| **企业微信 (WXWork)** | `%APPDATA%\Tencent\WXWork` | **1GB ~ 3GB** | 清理 CEF 渲染与小程序离线包，保留聊天记录 |
| **代码编辑器崩溃 Dump**| `%APPDATA%\Code` (`Crashpad`, `WebStorage`) | **500MB ~ 2GB** | 清空崩溃转储与垃圾缓存，配置和扩展完全保留 |
| **系统休眠文件** | `C:\hiberfil.sys` | **6GB ~ 16GB** | 管理员执行 `powercfg -h off` 一次性释放并永不复发 |

---

## 🚀 推荐清理工作流（四步闭环）

### 第一步：只读基准盘点（先看谁在吃空间，不盲目删除）
在终端运行：
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Get-DiskHogs.ps1
```
> 严格记录各卷容量与真实占用，区分“逻辑大小”与“卷物理增量”，杜绝盲目承诺。

### 第二步：拔除超大系统级更新碎片（需管理员）
双击运行 **`scripts\Clean_WinUpdate_Force.bat`**：
自动停止更新服务，使用 Windows 原生底层指令清空数十万个长路径下载碎片并自动重启服务。

### 第三步：清理被锁死的多盘系统残留（如 D:\WindowsApps）
若曾在其他盘保存过 Windows 商店应用且删不掉：
1. 先在 **Windows 设置 -> 系统 -> 存储 -> 保存新内容的地方** 将“新应用”改回 C 盘；
2. 双击运行 **`scripts\Clean_D_Root_Locked_Folders.bat`**，秒级夺权并连根拔除。

### 第四步：全量系统日常清理
双击运行 **`scripts\Antigravity_Clean.bat`**，一键完成 12 项无损垃圾与应用缓存清理。

---

## 🛡️ 刚性安全红线 (Safety Guardrails)

1. **严禁破坏系统与应用 ACL 权限**：清理仅针对具体缓存文件执行 `Remove-Item`，**绝不重置或修改 `AppData` 的权限继承**，严防导致 Electron / Chromium 应用（如 Gemini、DeepSeek 桌面端）因低权限沙箱读不到 `icudtl.dat` 而崩溃。
2. **严禁触碰核心生产力数据**：
   - 绝不碰微信 / 飞书 / 企业微信的核心聊天数据库与接收文件；
   - 绝不将剪映的工程草稿、用户已导入素材误当成缓存删除；
   - 绝不粗暴清空 WPS `wps\addons`（可能含有正在使用的正规插件）。
3. **规避 PowerShell 中文编码陷阱**：所有 `.ps1` 脚本的 `Write-Host` 输出与路径变量全程采用纯 ASCII / 英文，彻底杜绝中文 Windows 上的 `TerminatorExpectedAtEndOfString` 语法崩溃。
4. **批处理 `/k` 防闪退保障**：所有管理员提权批处理均采用保持窗口模式，即使出错也会完整保留错误日志，拒绝瞬间闪退。

---

## 📜 许可证

MIT License - 自由使用、分发与修改。欢迎提 PR 与 Issue！
