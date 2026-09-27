# 🧹 Windows C盘深度清理专家 (Windows Deep Cleaner Skill)

> 专门针对 AppData 目录中“顽固大户”的 AI 辅助清理工具 —— 找回那些被常规清理工具遗忘的空间。

[English Version](./README_EN.md) | **中文说明**

---

## ✨ 核心优势

传统的 Windows 清理工具（如磁盘清理、`%temp%`）通常只能释放不到 1GB 的空间。真正的“空间杀手”隐藏在 `AppData` 目录与深层更新缓存中：Edge 巨额 Service Worker 离线包、微信开发者工具历史构建、VS Code 崩溃转储、静默下载的插件与数十万更新补丁碎片。

**实战战果**：在典型重度开发机上，单次深度执行实测找回 **15GB ~ 23GB+** 宝贵空间（直接从爆红脱困）。

---

## 📁 目录结构

```
windows-deep-cleaner/
├── SKILL.md                   # AI 智能体指令 (给各类 AI IDE / Agent 的全流程指南)
└── scripts/
    ├── Get-DiskHogs.ps1       # 第一步：深层精准直扫（高价值靶点直查 + Top大户扫描）
    ├── simple_clean.ps1       # 第二步：靶向清理 AppData (WPS、AI客户端、代码编辑器、IDE日志)
    ├── Clean_WinUpdate_Force.bat # 强力拔除 30万+ Windows Update 补丁碎片 (底层指令，纯英文防闪退)
    ├── Antigravity_Clean.ps1  # 全量系统清理 (包含系统日志、缩略图、临时文件等 12 项)
    └── Antigravity_Clean.bat  # 系统全量清理一键入口 (自动申请管理员权限)
```

---

## 🎯 清理靶点

| 软件/类别 | 路径 | 脚本处理方式 |
|---|---|---|
| **Edge 浏览器** | `%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Service Worker\CacheStorage` | ✅ 清空离线缓存包 (单项常达 3GB~5GB+，不影响书签登录) |
| **Windows Update 碎片** | `C:\Windows\SoftwareDistribution\Download` | ✅ 强制移除数十万超长路径补丁碎片 (需管理员) |
| **微信开发者工具** | `%LOCALAPPDATA%\微信开发者工具\User Data` | ✅ 清理临时构建包与过期基础库 (工程源码100%安全) |
| **企业微信 (WXWork)** | `%APPDATA%\Tencent\WXWork` | ✅ 清理 CEF 浏览器内核与小程序运行包 (聊天记录完好) |
| **VS Code** | `%APPDATA%\Code` (`Crashpad`, `WebStorage`, `logs`) | ✅ 清理数百兆崩溃转储与渲染缓存 (配置完全保留) |
| **IDE 历史旧备份** | `%USERPROFILE%\.gemini\antigravity-backup` | ✅ 移除过往升级遗留安装包 (常达 1.5GB) |
| **WPS Office** | `%APPDATA%\kingsoft\wps\addons` | ✅ 清理强制下载的广告/插件包 (需先强杀进程) |
| **Perplexity / IMA / Quark** | `%LOCALAPPDATA%\...` | ✅ 清理桌面客户端内嵌缓存与日志 |
| **微信 xwechat 日志** | `%APPDATA%\Tencent\xwechat\log` | ✅ 清空日志文本，绝不触碰聊天记录与文件 |

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
