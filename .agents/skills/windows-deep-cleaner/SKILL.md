---
name: windows-deep-cleaner
description: 当用户需要深度清理 Windows C 盘空间时触发。包含了常规清理无法覆盖的顽固残留、国内各类软件（剪映、WPS、飞书、微信等）隐藏巨大缓存的靶向清理逻辑。
---

# Windows C 盘极限瘦身专家 (Deep Cleaner)

当用户说"清理C盘"、"C盘满了"、"扫描并清理垃圾"时，必须调用本 Skill，按以下规范与流程协助用户找出隐形大文件并清理。常规的 `Temp` 目录清理通常只释放不到 1GB 空间，而真正的空间杀手往往隐藏在 `AppData` 目录和特定的软件缓存中。

---

## ⚠️ 关键实战经验：PowerShell 中文编码陷阱

> **在中文 Windows 系统上执行 PowerShell 脚本时，Write-Host 输出中若包含中文字符，极大概率触发 `TerminatorExpectedAtEndOfString` 解析错误，导致脚本直接崩溃退出。**

**正确做法**：所有 `.ps1` 脚本的 `Write-Host` 输出**必须全程使用英文**。变量名同理。
**错误示例**：`Write-Host "当前 C 盘可用空间: $afterGB GB"` → 直接报错。
**正确示例**：`Write-Host "C: free now: $afterGB GB"`

本 Skill 的所有脚本 (`scripts/` 目录) 均已遵循此原则，可安全运行。

---

## 📍 核心清理目标清单 (重点关注靶点)

过去实战中，我们发现以下几个软件是吃 C 盘空间的绝对大户：

1. **飞书 (Lark) / 微信 / QQ 等大型协同IM**
   - **路径**: `$env:APPDATA\LarkShell` (常达 10GB+), `$env:APPDATA\Tencent`
   - **处理策略**: 强烈建议用户使用软件本身的「存储空间管理」入口去清除，不要粗暴使用脚本删文件以免丢失重要聊天记录。

2. **视频剪辑软件 (JianyingPro 剪映)**
   - **路径**: `$env:LOCALAPPDATA\JianyingPro\User Data`
   - **子路径**: `Download` (特效素材), `Cache` (图片缓存)
   - **处理策略**: 若用户首肯，可直接通过 `Remove-Item` 强制删掉这两个子目录，释放 GB 级别空间，且不影响草稿和最终视频。

3. **WPS Office (办公套件)**
   - **路径**: `$env:APPDATA\kingsoft`
   - **子路径**: `wps\addons` (后台静默下载的插件、模板), `office6\cache` (浏览器弹窗内核缓存)
   - **处理策略**: WPS 的 `addons` 文件夹是个"垃圾场"，常常膨胀到 1.5GB 以上。强制关掉 WPS 进程后，清理该目录绝对安全。

4. **AI 桌面客户端 (Perplexity / IMA Copilot 等)**
   - **路径**: `$env:LOCALAPPDATA\Perplexity`, `$env:LOCALAPPDATA\ima.copilot`
   - **处理策略**: 删除所有包含 `Cache` 或 `logs` 的子目录。不影响账号登录，云端数据不丢失。

5. **代码全家桶 (VS Code / Trae / CodeBuddy)**
   - **路径**: `$env:APPDATA\Code`, `$env:APPDATA\CodeBuddy CN`, `$env:USERPROFILE\.vscode`
   - **处理策略**: 不要碰主目录（含配置），仅清空以 `Cache`, `Code Cache`, `CachedData`, `CachedExtensionVSIXs`, `GPUCache`, `logs` 为名的子文件夹。

6. **流氓软件与已卸载程序的残留**
   - **高频靶点**: `Flash_Center` (`$env:LOCALAPPDATA\Flash_Center` 常通过捆绑静默安装拉取 800MB+ 广告插件)、RoxyBrowser。
   - **处理策略**: 使用 `Stop-Process` 强杀后连根拔起。

7. **Notion**
   - **路径**: `$env:APPDATA\Notion`
   - **处理策略**: 删除整个文件夹可释放 500MB+ 的离线缓存，下次打开会重新让用户登录，云端数据不丢失。

---

## 🛠️ 第一步：执行基准盘点扫描

在进行任何破坏性操作之前，**必须**使用你的 `write_to_file` 工具或直接调用本 Skill 的 `scripts/Get-DiskHogs.ps1`，借助 `run_command` 运行它，将盘点结果展示给用户。

```powershell
# 运行方式
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\Get-DiskHogs.ps1"
```

扫描完毕后，对照上方**核心清单**逐条向用户解释：
- ✅ **可秒清**：WPS addons、AI 客户端 Cache、VS Code GPUCache/logs 等
- ⚠️ **需用户去 App 内手动清**：飞书、微信、QQ（防止丢失聊天记录）

---

## 🛠️ 第二步：用户决策与执行清理

获得用户授权后，按以下规则编写或调用清理脚本：

**使用本 Skill 内置脚本（推荐）**：
```powershell
# 靶向清理 AppData 大户 (WPS, AI客户端, 代码编辑器, 微信开发者工具, Flash残留)
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\simple_clean.ps1"

# 完整系统级清理 12 个类别 (需管理员权限，会自动提权)
scripts\Antigravity_Clean.bat
```

**防崩溃原则**（若自行编写脚本）:
- 国内软件常驻后台非常顽固，务必在脚本中增加前置的 `Stop-Process -Name "xxx" -Force` 进行进程强杀。
- **脚本全程使用英文输出**，禁止在 `Write-Host` 中出现中文字符（参见顶部编码陷阱说明）。

---

## 🛠️ 第三步：验收与总结

1. 执行完清理脚本后，务必再调用一次 `Get-PSDrive C`，拉取最新的 C 盘剩余空间。
2. 向用户计算并汇报本次清理的**总释放成果**。
3. 对于无法脚本清理的大块（如飞书、微信），明确告知用户应在对应 App 的"存储管理"中手动处理。
