---
name: windows-deep-cleaner
description: 当用户需要深度清理 Windows C 盘空间时触发。包含了常规清理无法覆盖的顽固残留、休眠文件瘦身、系统更新残留、国内各类软件（微信引擎日志、剪映、WPS、飞书等）隐藏巨无霸缓存的靶向清理逻辑。
---

# Windows C 盘极限瘦身专家 (Deep Cleaner)

当用户说"清理C盘"、"C盘满了"、"扫描并清理垃圾"、"C盘不够大"时，必须调用本 Skill，按以下规范与流程协助用户找出隐形大文件并清理。

常规的 `Temp` 目录清理通常只能释放不到 1GB 空间，而真正的空间杀手往往隐藏在：
1. **系统休眠预留文件 (`hiberfil.sys`)** —— 强制扣除物理内存的 40%~80%（常用 6GB ~ 16GB）
2. **Windows 系统大版本更新残留 (`C:\$WINDOWS.~BT`)** —— 升级备份占用 1.8GB ~ 10GB
3. **微信/腾讯系客户端引擎缓存** —— `AppData\Roaming\Tencent\xwechat\log`（日志常达 1GB+，清空零风险）
4. **AI/IDE 大脑与历史会话缓存** —— `.gemini\brain`（IDE 运行轨迹与多媒体录屏）
5. **全局开发包与客户端缓存** —— `.cache`、`npm-cache`、`.codex`、`Quark`

---

## ⚠️ 关键实战经验：PowerShell 中文编码陷阱

> **在中文 Windows 系统上执行 PowerShell 脚本时，Write-Host 输出或变量名中若包含中文字符，极大概率触发 `TerminatorExpectedAtEndOfString` 解析错误，导致脚本直接崩溃退出。**

**正确做法**：所有 `.ps1` 脚本的 `Write-Host` 输出与路径变量**必须全程使用纯 ASCII / 英文**。
**错误示例**：`$path = "$env:LOCALAPPDATA\微信开发者工具"` → 脚本在 ANSI 编码解析下直接崩溃。
**正确示例**：`$path = Join-Path $env:LOCALAPPDATA ([System.Text.Encoding]::UTF8.GetString(...))` 或直接用环境变量拼接英文路径。

---

## 📍 核心清理目标清单 (重点关注靶点)

### 🔴 第一梯队：系统级巨无霸（单项 1GB ~ 16GB）

1. **Windows 系统休眠文件 (`hiberfil.sys`)**
   - **占用规格**: 约 6GB ~ 16GB（为物理内存容量的 40%~80% 预留快照）
   - **清理策略**: 运行管理员命令 `powercfg -h off`。
   - **无害说明**: 不影响正常“睡眠 (Sleep)”和快速启动，仅关闭开机恢复上一次休眠快照功能。需要恢复随时运行 `powercfg -h on`。

2. **Windows 大版本升级残留 (`C:\$WINDOWS.~BT`)**
   - **占用规格**: 1.8GB ~ 10GB
   - **清理策略**: `Remove-Item "C:\$WINDOWS.~BT" -Recurse -Force`

3. **AI IDE / 智能体会话日志 (`$env:USERPROFILE\.gemini`)**
   - **占用规格**: 3GB ~ 8GB (`antigravity-ide\brain` 存放大量录屏与轨迹日志)
   - **清理策略**: 清空 `antigravity-ide\brain\*`，保留 `config` 配置文件。

---

### 🟡 第二梯队：软件应用引擎与日志（单项 500MB ~ 3GB）

4. **微信客户端引擎日志 (`$env:APPDATA\Tencent\xwechat\log`)**
   - **占用规格**: 800MB ~ 3GB（即使聊天记录保存在 D 盘，C 盘依然会堆积巨量 log 文本）
   - **清理策略**: **完全无害秒清**，清空 `xwechat\log\*`，绝不影响 D 盘的聊天记录和收发文件。

5. **腾讯视频与腾讯会议缓存 (`$env:APPDATA\Tencent\QQLive`, `$env:APPDATA\Tencent\WeMeet`)**
   - **清理策略**: 删除视听缓存与运行 log，不影响账号登录。

6. **WPS Office (办公套件)**
   - **路径**: `$env:APPDATA\kingsoft` -> `wps\addons` (静默插件库 1.5GB+), `office6\cache` (弹窗内核缓存)
   - **处理策略**: 强杀 WPS 进程后清空该子目录。

7. **全局开发包与模型缓存**
   - **路径**: `$env:USERPROFILE\.cache` (pip/huggingface), `$env:LOCALAPPDATA\npm-cache`, `$env:USERPROFILE\.codex`
   - **处理策略**: 删除所有编译/下载缓存（使用对应包管理器时会自动按需拉取）。

8. **视频剪辑软件 (JianyingPro 剪映)**
   - **路径**: `$env:LOCALAPPDATA\JianyingPro\User Data` -> `Download` (素材), `Cache` (缓存)
   - **处理策略**: 强杀进程后强制删除，不影响草稿和导出视频。

9. **飞书 (LarkShell) / 微信主数据库**
   - **处理策略**: 强烈建议引导用户在软件设置中的「存储空间管理」清理过期的图片和视频。

---

## 🛠️ 第一步：执行基准盘点扫描

必须借助 PowerShell 或 Python 脚本对上述靶点进行实时容量盘点：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\Get-DiskHogs.ps1"
```

扫描完毕后，清晰向用户呈现 C 盘剩余空间与各项大户分布。

---

## 🛠️ 第二步：分级决策与执行

获取用户授权后，按以下类别执行脚本：

1. **自动无损缓存清理**：
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\simple_clean.ps1"
   ```

2. **关闭休眠瘦身 (需要管理员权限)**：
   运行内置双击提权脚本 `scripts\Disable_Hibernation_Admin.bat`，或引导用户在管理员终端运行 `powercfg -h off`。

---

## 🛠️ 第三步：验收与汇报

1. 执行完毕后调用 `Get-PSDrive C`，展示最新可用空间。
2. 计算并汇报本次清理的**总释放成果**。
3. 告知用户如何手工撤销（如运行 `powercfg -h on` 重新开启休眠）。
