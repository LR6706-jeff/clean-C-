# 🧹 Windows C盘深度清理专家 (Windows Deep Cleaner Skill)

> 专门针对 AppData 目录中“顽固大户”的 AI 辅助清理工具 —— 找回那些被常规清理工具遗忘的空间。

[English Version](./README_EN.md) | **中文说明**

---

## ✨ 核心优势

传统的 Windows 清理工具（如磁盘清理、`%temp%`）通常只能释放不到 1GB 的空间。真正的“空间杀手”隐藏在 `AppData` 目录中：静默下载的插件、巨大的 GPU 渲染缓存、AI 客户端的二进制包以及各类软件残留。

**实战战果**：在典型开发机上，单次执行即可找回 **5GB+** 被浪费的空间。

---

## 📁 目录结构

```
windows-deep-cleaner/
├── SKILL.md                  # AI 智能体指令 (如果你是在 IDE 里使用 AI，这是给它的指南)
└── scripts/
    ├── Get-DiskHogs.ps1      # 第一步：深层扫描并列出占用前 20 的“大户”
    ├── simple_clean.ps1      # 第二步：靶向清理 AppData (WPS、AI客户端、代码编辑器、残留包)
    ├── Antigravity_Clean.ps1 # 全量系统清理 (包含 Windows 更新缓存、系统日志、缩略图等)
    └── Antigravity_Clean.bat # 一键启动入口 (自动申请管理员权限)
```

---

## 🎯 清理靶点

| 软件/类别 | 路径 | 脚本处理方式 |
|---|---|---|
| **WPS Office** | `%APPDATA%\kingsoft\wps\addons` | ✅ 清理强制下载的广告/插件包 (需先强杀进程) |
| **Perplexity** | `%LOCALAPPDATA%\Perplexity\*Cache*` | ✅ 清理渲染缓存 |
| **IMA Copilot** | `%LOCALAPPDATA%\ima.copilot\*Cache*` | ✅ 清理缓存与日志 |
| **VS Code** | `%APPDATA%\Code\**\Cache,GPUCache,logs` | ✅ 清理编译与扩展缓存 (配置安全) |
| **微信开发者工具** | `%LOCALAPPDATA%\微信开发者工具\User Data\*\Cache` | ✅ 清理项目编译中间件 |
| **Flash_Center** | `%LOCALAPPDATA%\Flash_Center` | ✅ 连根拔起 |
| **剪映 (JianyingPro)**| `%LOCALAPPDATA%\JianyingPro\User Data\Cache` | ✅ 清理素材缓存 (不影响草稿) |
| **Notion** | `%APPDATA%\Notion` | ✅ 清理离线缓存 |
| **微信/飞书/QQ** | `%APPDATA%\Tencent`, `%APPDATA%\LarkShell` | ⚠️ 建议使用 App 自带存储管理，脚本不触碰 |

---

## 🚀 如何使用

### 选项 A：全量系统清理 (最推荐)
右键点击 `scripts\Antigravity_Clean.bat`，选择 **以管理员身份运行**。它会自动执行 Windows 全量清理（包含更新补丁缓存、回收站等 12 个类别）。

### 选项 B：靶向 AppData 清理 (如果你想清除 AppData 里的缓存)
在 PowerShell 中运行：
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\simple_clean.ps1
```

### 选项 C：先看看谁在吃空间 (只扫描不删除)
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Get-DiskHogs.ps1
```

---

## ⚠️ 避坑指南：PowerShell 编码问题

如果你在中文 Windows 上自己写 PowerShell 脚本，请记住：**`Write-Host` 输出中严禁包含中文字符**，否则会触发 `TerminatorExpectedAtEndOfString` 错误导致脚本崩溃。

本项目的 `scripts/` 目录下所有 `.ps1` 文件均已通过**全英文输出**规避了此问题。

---

## 🛡️ 安全原则

- **绝不**触碰聊天记录（WeChat/Lark/QQ）。
- **绝不**清理设置文件（settings.json）。
- 所有脚本在清理前都会尝试 `Stop-Process` 强杀对应进程，防止文件占用报错。

---

## 📜 许可证

MIT License - 你可以自由地分享、修改和使用。欢迎 Star 关注！
