---
name: windows-deep-cleaner
description: 排查 Windows C 盘空间占用并清理已确认的缓存、升级暂存和卸载残留。适用于 C 盘满、清理后仍占用很大、查找隐藏大文件，以及核实实际释放空间。
---

# Windows C 盘空间排查与深度清理

先找出大项，再按用户授权处理，最后核实释放量。用户说“刚清过”“还是很满”时，比较清理后仍存在的占用，不要重复执行一轮小缓存删除就结束。只询问原因时先报告占用，不把排查自动扩大为删除。

## 先盘点完整空间

使用 [scripts/Get-DiskHogs.ps1](scripts/Get-DiskHogs.ps1) 或 Python 只读脚本做元数据扫描，输出路径放在当前工作区：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\Get-DiskHogs.ps1"
```

脚本记录卷容量、剩余空间、根目录占用、各级目录、大文件、访问失败及跳过的链接。不读取文件内容，不删除文件，不修改权限。通过当前环境实际可用的命令工具运行；读取受限时按环境的权限流程处理，不要把“拒绝访问”或空结果当作 0 字节。

盘点应覆盖下列类别，并先解释最大的几项：

| 类别 | 重点位置 | 判断要点 |
|---|---|---|
| 升级及旧系统 | `C:\$WINDOWS.~BT`、`C:\$WINDOWS.~WS`、`C:\Windows.old` | 普通缓存清理可能漏掉；走系统清理流程 |
| 回收站 | `C:\$Recycle.Bin` | 删除到回收站仍占空间；检查大型 ISO、安装包 |
| 当前系统 | `Windows`、`WinSxS`、`Installer`、`SoftwareDistribution` | 单列正常系统占用；不手动删除组件库、安装缓存或更新数据库 |
| 软件安装 | 两个 `Program Files`、`ProgramData`、`AppData\Local\Programs` | 占用大不代表是垃圾；不用的应用走卸载流程 |
| 用户数据 | `AppData\Local`、`Roaming`、`LocalLow`、下载、文档、桌面 | 拆出具体软件、下载包、缓存及真实数据 |
| 隐藏开发目录 | `.cache`、`.gemini`、`.codex`、`.vscode`、`.bun`、浏览器运行时 | 确认所属产品和用途；不能按名称把整个目录视为缓存 |

**区分三种数字：** 文件逻辑大小、系统清理工具预计可释放量、卷剩余空间的实际增量。硬链接、压缩、受保护内容会造成差异；不要把父子目录相加，也不要承诺“目录多大就能释放多大”。列出扫描盲区。实际占用与扫描和数差异较大时，再检查硬链接、保留存储或还原点。

---

## 关键实战陷阱与技术规范

### 1. PowerShell 中文编码解析陷阱
在中文 Windows 系统上执行 PowerShell 脚本时，代码或输出中若直接包含中文字符，极易触发 `TerminatorExpectedAtEndOfString` 解析错误导致崩溃。
**规范**：脚本中的逻辑与输出必须保持纯 ASCII / 英文，或使用环境变量安全拼接。

### 2. Windows Update 30万+超长路径碎片删除
`C:\Windows\SoftwareDistribution\Download` 经常积压数十万更新补丁碎片，目录嵌套深度超 260 字符（MAX_PATH）。
**规范**：PowerShell 的 `Remove-Item` 会因路径越限静默跳过；必须停止 `wuauserv` 与 `bits` 服务，调用 Windows 原生底层 `rd /s /q` 强制秒删：
```cmd
net stop wuauserv & net stop bits
rd /s /q "C:\Windows\SoftwareDistribution\Download"
mkdir "C:\Windows\SoftwareDistribution\Download"
net start bits & net start wuauserv
```

### 3. 多盘锁死目录夺权（TrustedInstaller 拒绝访问）
用户曾将“新应用保存位置”改到其他盘（如 D 盘）时，系统会生成 `WindowsApps`、`DeliveryOptimization` 等目录，所有权锁定给 `TrustedInstaller`，普通管理员无法删除。
**规范**：必须先在 Windows 设置中将“新应用”改回 C 盘，再通过管理员终端执行夺权三步法：
```cmd
takeown /F "目标路径" /A /R /D Y
icacls "目标路径" /grant administrators:F /T /C /Q
rd /s /q "目标路径"
```

---

## 应用数据的处理边界

| 应用或目录 | 可调查的项目 | 不应默认执行的操作 |
|---|---|---|
| 飞书、微信、QQ、腾讯会议等 | 应用内存储管理、已确认的媒体缓存 | 整删聊天目录、数据库、附件或未同步数据 |
| 剪映 `JianyingPro\User Data` | 已确认可重下的 `Download` 素材、`Cache` | 把项目、草稿或用户素材当成缓存 |
| WPS `kingsoft` | `office6\cache`、核实用途后的插件下载缓存 | 宣称 `wps\addons` 全部“绝对安全”并整删；可能有在用插件 |
| Code、Trae、CodeBuddy 等 | `Cache`、`Code Cache`、`CachedData`、`CachedExtensionVSIXs`、`GPUCache`、日志 | 整删配置、扩展、工作区状态或备份；SDK/浏览器运行时可能是当前依赖 |
| 应用 updater、安装包 | 核实应用已更新且没有安装任务后，清理过期下载 | 删除正在应用的更新或用户仍需保留的安装包 |
| Notion 等离线应用 | 应用内清理、已同步的可再生缓存 | 默认整删数据目录；可能丢失未同步编辑和登录状态 |
| 不再使用的软件 | 确认归属，运行官方卸载程序，再核对专属残留 | 仅因名字像广告软件就强杀和整删 |

同名不代表同一产品。例如 `.gemini` 可能存放 Antigravity、CLI、浏览器配置和任务产物，并不等同于 Gemini 桌面应用的安装目录。卸载一个应用不授权删除所有同名目录。

---

## 执行及防止误删

- **明确授权**：依据已有会话授权处理明确的清理项；新增个人数据删除、卸载其他应用等范围需先说明具体对象。不要反复索要已给出的同一授权。
- **边界验证**：递归删除前验证解析后的绝对路径就是已确认目标，检查重解析点；不要跟随链接越界。使用同一 PowerShell 会话和 `-LiteralPath`，不要把枚举结果拼接成另一种 shell 的删除命令。
- **保护在用文件**：在用文件先正常关闭对应应用；只在必要且不损失未保存工作时终止其进程。删除失败要记录剩余项，不因命令输出了“完成”就算成功。
- **严禁乱改系统权限**：**清理任务绝对不应重置或扩大 `AppData`、用户目录、系统目录的 ACL，严禁删除系统运行库**。若应用出现闪退或找不到核心文件，应依据错误日志诊断沙箱权限或运行时，严禁凭时间先后主观认定清理造成故障。
- **垃圾就地隔离**：诊断文件和临时备份优先放在工作区所在非 C 盘；完成后清理本次生成的大型临时转储，保留必要的精简报告。

---

## 完成条件

1. 清理前后用相同来源读取 C 盘真实剩余空间（如 `Get-CimInstance Win32_LogicalDisk` 或 `Get-PSDrive C`）；读取失败明确说明，不能把空值四舍五入成 0。
2. 检查目标目录或清理项目是否仍存在、还占多少。系统清理提示需重启时，报告待完成状态，不强制重启。
3. 报告：处理了什么、实际释放多少、现在剩余多少、还有哪些大项未处理及原因。区分缓存、正常安装占用、个人数据和正在使用的升级文件。
4. 仅打开清理窗口、看到预计释放量或发出删除命令，都不等于已清理完成。大项仍在时继续排查，或明确给出具体待办；不能把几十 MB 的缓存清理说成“C 盘已清理干净”。
