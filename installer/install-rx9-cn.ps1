param(
    [switch]$Restore
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$PatchName = 'RX 9 中文帮助入口安装器'
$ExeRelativePath = 'win64\iZotope RX 9 Audio Editor.exe'
$HelpRelativePath = 'HTML Help\en'
$EntryRelativePath = 'HTML Help\en\index.html'
$GuideRelativeDir = 'HTML Help\en\rx9-cn-guide'
$BackupRelativePath = '.rx9-cn-patch-backup\HTML Help\en\index.html'
$MarkerRelativePath = '.rx9-cn-patch-backup\install-info.json'

function Show-Info {
    param([string]$Message)
    [System.Windows.Forms.MessageBox]::Show($Message, $PatchName, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
}

function Show-Warn {
    param([string]$Message)
    [System.Windows.Forms.MessageBox]::Show($Message, $PatchName, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
}

function Show-ErrorBox {
    param([string]$Message)
    [System.Windows.Forms.MessageBox]::Show($Message, $PatchName, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
}

function Get-FullPath {
    param([string]$Path)
    return [System.IO.Path]::GetFullPath($Path)
}

function Test-PathInside {
    param(
        [string]$BasePath,
        [string]$ChildPath
    )
    $base = Get-FullPath $BasePath
    $child = Get-FullPath $ChildPath
    if (-not $base.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $base = $base + [System.IO.Path]::DirectorySeparatorChar
    }
    return $child.StartsWith($base, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-Rx9Root {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $false
    }
    $exePath = Join-Path $Path $ExeRelativePath
    $helpPath = Join-Path $Path $HelpRelativePath
    return ((Test-Path -LiteralPath $exePath -PathType Leaf) -and (Test-Path -LiteralPath $helpPath -PathType Container))
}

function Get-UniqueExistingDirs {
    param([string[]]$Paths)
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $result = New-Object 'System.Collections.Generic.List[string]'
    foreach ($path in $Paths) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }
        try {
            $full = Get-FullPath $path
            if ((Test-Path -LiteralPath $full -PathType Container) -and $seen.Add($full)) {
                $result.Add($full) | Out-Null
            }
        } catch {
        }
    }
    return $result.ToArray()
}

function Get-InstallCandidates {
    $candidates = New-Object 'System.Collections.Generic.List[string]'
    $common = @(
        'D:\tool\Zotope\RX 9 Audio Editor',
        'C:\Program Files\iZotope\RX 9 Audio Editor',
        'C:\Program Files (x86)\iZotope\RX 9 Audio Editor'
    )
    foreach ($path in $common) {
        if (Test-Rx9Root $path) {
            $candidates.Add($path) | Out-Null
        }
    }

    $uninstallRoots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($root in $uninstallRoots) {
        try {
            $items = Get-ItemProperty -Path $root -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -like '*RX 9*' -or $_.DisplayName -like '*iZotope RX*' }
            foreach ($item in $items) {
                foreach ($candidate in @($item.InstallLocation, $item.DisplayIcon, $item.UninstallString)) {
                    if ([string]::IsNullOrWhiteSpace($candidate)) {
                        continue
                    }
                    $clean = $candidate.Trim('"')
                    if ($clean -match '\.exe') {
                        $clean = Split-Path -Parent $clean
                        if ((Split-Path -Leaf $clean) -ieq 'win64') {
                            $clean = Split-Path -Parent $clean
                        }
                    }
                    if (Test-Rx9Root $clean) {
                        $candidates.Add($clean) | Out-Null
                    }
                }
            }
        } catch {
        }
    }

    return Get-UniqueExistingDirs $candidates.ToArray()
}

function Select-Rx9Root {
    $candidates = Get-InstallCandidates
    foreach ($candidate in $candidates) {
        $message = "检测到 RX 9 安装目录：`r`n`r`n$candidate`r`n`r`n是否使用此目录安装中文帮助入口？"
        $answer = [System.Windows.Forms.MessageBox]::Show($message, $PatchName, [System.Windows.Forms.MessageBoxButtons]::YesNoCancel, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($answer -eq [System.Windows.Forms.DialogResult]::Yes) {
            return $candidate
        }
        if ($answer -eq [System.Windows.Forms.DialogResult]::Cancel) {
            return $null
        }
    }

    while ($true) {
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = '请选择 RX 9 Audio Editor 根目录，例如 D:\tool\Zotope\RX 9 Audio Editor'
        $dialog.ShowNewFolderButton = $false
        if (Test-Path -LiteralPath 'D:\tool\Zotope\RX 9 Audio Editor' -PathType Container) {
            $dialog.SelectedPath = 'D:\tool\Zotope\RX 9 Audio Editor'
        } elseif (Test-Path -LiteralPath 'C:\Program Files\iZotope' -PathType Container) {
            $dialog.SelectedPath = 'C:\Program Files\iZotope'
        }

        $result = $dialog.ShowDialog()
        if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
            return $null
        }
        if (Test-Rx9Root $dialog.SelectedPath) {
            return $dialog.SelectedPath
        }
        Show-Warn "这个目录不像 RX 9 根目录。请选择包含以下文件的目录：`r`n`r`n$ExeRelativePath"
    }
}

function Write-Utf8File {
    param(
        [string]$Path,
        [string]$Content
    )
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

$EntryHtml = @'
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta http-equiv="refresh" content="0; url=rx9-cn-guide/index.html">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>RX 9 中文使用教程</title>
  <style>
    body { font-family: "Microsoft YaHei", "Segoe UI", Arial, sans-serif; margin: 40px; line-height: 1.7; color: #20242a; }
    a { color: #0b65c2; }
  </style>
</head>
<body>
  <h1>RX 9 中文使用教程</h1>
  <p>正在打开中文教程。如果没有自动跳转，请点击 <a href="rx9-cn-guide/index.html">这里</a>。</p>
</body>
</html>
'@

$GuideHtml = @'
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>RX 9 中文使用教程</title>
  <style>
    :root {
      color-scheme: light;
      --ink: #17202a;
      --muted: #5d6875;
      --line: #d9e1ea;
      --panel: #f5f8fb;
      --accent: #0d6b78;
      --accent-dark: #084c56;
      --warn: #8a4b00;
      --warn-bg: #fff7e8;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: "Microsoft YaHei", "Segoe UI", Arial, sans-serif;
      color: var(--ink);
      background: #ffffff;
      line-height: 1.72;
      font-size: 16px;
    }
    header {
      padding: 44px 24px 30px;
      background: linear-gradient(135deg, #102b31, #0d6b78);
      color: #ffffff;
    }
    header .wrap, main {
      max-width: 1080px;
      margin: 0 auto;
    }
    h1 {
      margin: 0 0 12px;
      font-size: 34px;
      letter-spacing: 0;
    }
    header p {
      max-width: 760px;
      margin: 0;
      color: #d8edf0;
      font-size: 17px;
    }
    main {
      padding: 28px 24px 56px;
    }
    nav {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
      gap: 10px;
      margin: 0 0 28px;
    }
    nav a {
      display: block;
      padding: 10px 12px;
      border: 1px solid var(--line);
      border-radius: 6px;
      color: var(--accent-dark);
      text-decoration: none;
      background: #ffffff;
    }
    section {
      border-top: 1px solid var(--line);
      padding: 26px 0 8px;
    }
    h2 {
      margin: 0 0 12px;
      font-size: 24px;
    }
    h3 {
      margin: 22px 0 8px;
      font-size: 18px;
    }
    p { margin: 8px 0 12px; }
    ul, ol { padding-left: 22px; }
    li { margin: 5px 0; }
    table {
      border-collapse: collapse;
      width: 100%;
      margin: 14px 0 22px;
      font-size: 15px;
    }
    th, td {
      border: 1px solid var(--line);
      padding: 9px 10px;
      vertical-align: top;
    }
    th {
      background: var(--panel);
      text-align: left;
    }
    code {
      font-family: Consolas, "Cascadia Mono", monospace;
      background: #eef3f6;
      padding: 1px 5px;
      border-radius: 4px;
    }
    .note {
      border-left: 4px solid var(--accent);
      background: var(--panel);
      padding: 12px 14px;
      margin: 14px 0;
    }
    .warn {
      border-left: 4px solid var(--warn);
      background: var(--warn-bg);
      padding: 12px 14px;
      margin: 14px 0;
    }
    .workflow {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 12px;
      margin: 14px 0 20px;
    }
    .step {
      border: 1px solid var(--line);
      border-radius: 6px;
      padding: 12px;
      background: #ffffff;
    }
    .step strong { color: var(--accent-dark); }
    footer {
      margin-top: 30px;
      padding-top: 18px;
      border-top: 1px solid var(--line);
      color: var(--muted);
      font-size: 14px;
    }
  </style>
</head>
<body>
  <header>
    <div class="wrap">
      <h1>RX 9 中文使用教程</h1>
      <p>这是为个人工作流整理的中文入门与常用处理指南。它不替代官方文档，重点帮助你快速找到常见音频问题对应的模块和操作顺序。</p>
    </div>
  </header>

  <main>
    <nav aria-label="目录">
      <a href="#quick-start">快速开始</a>
      <a href="#interface">界面与选择</a>
      <a href="#repair-flow">常用修复流程</a>
      <a href="#modules">模块中文速查</a>
      <a href="#chains">推荐处理链</a>
      <a href="#batch">批量处理</a>
      <a href="#settings">设置建议</a>
      <a href="#tips">注意事项</a>
    </nav>

    <section id="quick-start">
      <h2>快速开始</h2>
      <ol>
        <li>打开音频文件后，先听一遍问题最明显的片段，确认是噪声、爆音、齿音、混响、风声还是音量问题。</li>
        <li>用时间选择、频率选择或套索工具圈出需要处理的区域。只处理问题区域通常比整段处理更自然。</li>
        <li>打开右侧模块，先用较轻的参数预览，确认没有明显失真后再渲染。</li>
        <li>每次只解决一个主要问题，处理后重新试听，再决定是否继续下一步。</li>
        <li>重要文件建议另存为新文件，保留原始素材。</li>
      </ol>
      <div class="note">一个稳定顺序是：先修复破损和突发噪声，再降底噪，最后处理响度、淡入淡出和导出格式。</div>
    </section>

    <section id="interface">
      <h2>界面与选择</h2>
      <h3>波形和频谱</h3>
      <p>波形适合看音量和剪切；频谱适合看噪声、口水音、爆音、哼声、风声和突发干扰。颜色越亮通常代表能量越强。</p>
      <h3>常用选择工具</h3>
      <table>
        <tr><th>工具</th><th>适合场景</th><th>提示</th></tr>
        <tr><td>时间选择</td><td>整段语句、停顿、背景噪声采样</td><td>先框时间，再用模块预览。</td></tr>
        <tr><td>时间/频率选择</td><td>只处理某个频段里的噪声</td><td>适合电流声、口水音、尖锐干扰。</td></tr>
        <tr><td>套索/画笔</td><td>频谱中形状不规则的问题</td><td>选区宁可稍小，避免伤到主体声音。</td></tr>
        <tr><td>魔棒</td><td>选择同类频谱区域</td><td>用于连续音调、哨声或窄带噪声。</td></tr>
      </table>
    </section>

    <section id="repair-flow">
      <h2>常用修复流程</h2>
      <div class="workflow">
        <div class="step"><strong>1. 先诊断</strong><br>试听问题片段，观察频谱形态，判断问题类型。</div>
        <div class="step"><strong>2. 小范围预览</strong><br>选中 2 到 5 秒问题区域，先用轻参数。</div>
        <div class="step"><strong>3. 渲染并复听</strong><br>听主体声音是否变薄、发闷、起水声或金属感。</div>
        <div class="step"><strong>4. 分层处理</strong><br>多个轻处理通常比一次重处理更自然。</div>
      </div>
      <h3>推荐处理顺序</h3>
      <ol>
        <li>De-click / Mouth De-click：先去点击、口水音、轻微爆点。</li>
        <li>De-clip：如果波形已经削顶，先修复削波。</li>
        <li>De-hum：处理 50/60 Hz 及其倍频的嗡声。</li>
        <li>Voice De-noise 或 Spectral De-noise：处理持续底噪。</li>
        <li>De-reverb / Dialogue De-reverb：减少房间混响。</li>
        <li>Loudness / Normalize / Gain：最后统一音量。</li>
      </ol>
    </section>

    <section id="modules">
      <h2>模块中文速查</h2>
      <table>
        <tr><th>英文模块</th><th>中文理解</th><th>用途</th></tr>
        <tr><td>Repair Assistant</td><td>修复助手</td><td>自动分析语音、音乐或其他素材，生成建议处理链。</td></tr>
        <tr><td>Voice De-noise</td><td>人声降噪</td><td>适合访谈、旁白、播客中的持续背景噪声。</td></tr>
        <tr><td>Spectral De-noise</td><td>频谱降噪</td><td>适合更精细的噪声学习和宽频底噪处理。</td></tr>
        <tr><td>Dialogue Isolate</td><td>对白分离</td><td>突出人声，压低环境声或背景声。</td></tr>
        <tr><td>Dialogue De-reverb</td><td>对白去混响</td><td>减少房间反射，让人声更靠前。</td></tr>
        <tr><td>De-click</td><td>去点击声</td><td>处理唱片噼啪声、数字点击、短促杂音。</td></tr>
        <tr><td>Mouth De-click</td><td>去口水音</td><td>处理嘴唇、舌头和口腔产生的细碎声。</td></tr>
        <tr><td>De-clip</td><td>削波修复</td><td>恢复过载录音中的削顶波形。</td></tr>
        <tr><td>De-hum</td><td>去嗡声</td><td>处理电源嗡声、接地噪声和稳定倍频。</td></tr>
        <tr><td>De-plosive</td><td>去爆破音</td><td>减轻 P、B 等气流冲击造成的低频爆音。</td></tr>
        <tr><td>De-ess</td><td>去齿音</td><td>控制 S、Sh、Z 等刺耳高频。</td></tr>
        <tr><td>De-wind</td><td>去风声</td><td>减轻户外录音中的低频风噪。</td></tr>
        <tr><td>Spectral Repair</td><td>频谱修复</td><td>手动修复频谱中的局部干扰、咳嗽、碰撞声。</td></tr>
        <tr><td>Music Rebalance</td><td>音乐再平衡</td><td>调整人声、贝斯、打击乐和其他乐器比例。</td></tr>
        <tr><td>Ambience Match</td><td>环境声匹配</td><td>让不同剪辑之间的背景环境更连贯。</td></tr>
        <tr><td>Loudness</td><td>响度</td><td>按平台或交付标准匹配 LUFS、True Peak 等指标。</td></tr>
        <tr><td>Normalize</td><td>标准化</td><td>把峰值或整体音量调整到目标水平。</td></tr>
        <tr><td>Gain</td><td>增益</td><td>手动提升或降低音量。</td></tr>
        <tr><td>Fade</td><td>淡入淡出</td><td>修整开头、结尾或剪辑接缝。</td></tr>
      </table>
    </section>

    <section id="chains">
      <h2>推荐处理链</h2>
      <h3>访谈/旁白</h3>
      <ol>
        <li>Mouth De-click：清理口水音，强度从轻到中等。</li>
        <li>De-plosive：只框选爆破音位置，避免整段声音变薄。</li>
        <li>Voice De-noise：让噪声降低 3 到 8 dB，先别追求完全安静。</li>
        <li>Dialogue De-reverb：轻微减少房间感。</li>
        <li>Loudness 或 Normalize：最后统一响度。</li>
      </ol>
      <h3>老录音/磁带/唱片</h3>
      <ol>
        <li>De-click 或 De-crackle：先去噼啪和细碎裂纹声。</li>
        <li>De-hum：处理稳定嗡声。</li>
        <li>Spectral De-noise：学习一段只有噪声的片段，再降底噪。</li>
        <li>EQ 或 Gain：轻微校正音色和音量。</li>
      </ol>
      <h3>户外录音</h3>
      <ol>
        <li>De-wind：先处理低频风噪。</li>
        <li>Voice De-noise：处理稳定环境噪声。</li>
        <li>Spectral Repair：手动清理鸟鸣、碰撞、车辆鸣笛等局部干扰。</li>
      </ol>
      <div class="warn">降噪过重会产生水声、金属感和人声发虚。遇到这种情况，降低 Reduction 或 Strength，再分多次轻处理。</div>
    </section>

    <section id="batch">
      <h2>批量处理</h2>
      <p>如果很多文件有相同问题，可以先在一个代表性文件上建立 Module Chain，再用 Batch Processor 应用到整批文件。</p>
      <ol>
        <li>选择一个典型文件，完成处理链并保存预设。</li>
        <li>打开 Batch Processor，添加待处理文件。</li>
        <li>选择刚保存的模块链预设。</li>
        <li>输出到新文件夹，避免覆盖原文件。</li>
        <li>抽查几条结果，确认没有过度处理。</li>
      </ol>
    </section>

    <section id="settings">
      <h2>设置建议</h2>
      <table>
        <tr><th>设置区域</th><th>建议</th></tr>
        <tr><td>Audio</td><td>选择稳定的音频驱动。若播放卡顿，适当增大缓冲区。</td></tr>
        <tr><td>Display</td><td>根据屏幕调整频谱显示颜色和亮度，让问题区域更容易识别。</td></tr>
        <tr><td>Keyboard</td><td>为常用动作设置快捷键，例如播放、渲染、撤销、缩放。</td></tr>
        <tr><td>Plug-ins</td><td>只扫描可信插件目录，减少启动和扫描时间。</td></tr>
        <tr><td>Misc</td><td>处理重要项目时开启自动保存或保持手动另存习惯。</td></tr>
      </table>
    </section>

    <section id="tips">
      <h2>注意事项</h2>
      <ul>
        <li>修复前先保存原始文件副本，尤其是采访、录音棚素材和客户交付文件。</li>
        <li>每次处理后都用耳机和外放各听一遍，确认没有新伪影。</li>
        <li>人声处理不要只看频谱，最终判断以听感为准。</li>
        <li>无法确定参数时，先从轻处理开始，逐步增加强度。</li>
        <li>导出前确认采样率、位深、声道数和目标平台要求一致。</li>
      </ul>
    </section>

    <footer>
      <p>本教程为个人使用的原创中文指南，只安装在本机 RX 9 帮助入口中。安装器不包含 RX 9 原厂程序或官方文档副本。</p>
    </footer>
  </main>
</body>
</html>
'@

$UsageMd = @'
# RX 9 中文帮助入口安装器使用指南

## 作用

这个安装器会把 RX 9 的本地帮助入口替换为中文使用教程。

它不会修改 RX 9 主程序 EXE、DLL、授权文件或模型文件，也不包含原厂程序。

## 安装

1. 关闭 RX 9。
2. 运行 `RX9-CN-Help-Installer.exe`。
3. 选择 RX 9 根目录，例如：
   `D:\tool\Zotope\RX 9 Audio Editor`
4. 安装完成后，从 RX 9 的帮助入口打开即可进入中文教程。

## 恢复

首次安装时会备份原帮助入口到：

`.rx9-cn-patch-backup\HTML Help\en\index.html`

再次运行安装器时：

- 点“是”：重新安装或更新中文教程
- 点“否”：恢复原帮助入口
- 点“取消”：退出

## 范围说明

当前汉化范围为帮助入口和中文教程。主程序界面文字未修改，因为 RX 9 安装目录中未发现可编辑的外置语言文件。
'@

function Install-Patch {
    param([string]$Root)

    $rootFull = Get-FullPath $Root
    $entryTarget = Join-Path $rootFull $EntryRelativePath
    $guideTarget = Join-Path $rootFull $GuideRelativeDir
    $guideIndexTarget = Join-Path $guideTarget 'index.html'
    $backupTarget = Join-Path $rootFull $BackupRelativePath
    $markerTarget = Join-Path $rootFull $MarkerRelativePath
    $usageTarget = Join-Path $rootFull 'RX9-汉化包使用指南.md'

    foreach ($target in @($entryTarget, $guideTarget, $guideIndexTarget, $backupTarget, $markerTarget, $usageTarget)) {
        if (-not (Test-PathInside $rootFull $target)) {
            throw "安全检查失败：目标路径不在 RX 9 安装目录内。`r`n$target"
        }
    }

    if (-not (Test-Rx9Root $rootFull)) {
        throw "目录验证失败：未找到 $ExeRelativePath"
    }

    $backupDir = Split-Path -Parent $backupTarget
    if (-not (Test-Path -LiteralPath $backupDir -PathType Container)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }

    if (-not (Test-Path -LiteralPath $backupTarget -PathType Leaf)) {
        Copy-Item -LiteralPath $entryTarget -Destination $backupTarget -Force
    }

    if (-not (Test-Path -LiteralPath $guideTarget -PathType Container)) {
        New-Item -ItemType Directory -Path $guideTarget -Force | Out-Null
    }

    Write-Utf8File -Path $entryTarget -Content $EntryHtml
    Write-Utf8File -Path $guideIndexTarget -Content $GuideHtml
    Write-Utf8File -Path $usageTarget -Content $UsageMd

    $info = [ordered]@{
        patch = 'rx9-cn-help-entry'
        installedAt = (Get-Date).ToString('s')
        root = $rootFull
        changedFiles = @($EntryRelativePath, (Join-Path $GuideRelativeDir 'index.html'), 'RX9-汉化包使用指南.md')
        backup = $BackupRelativePath
    } | ConvertTo-Json -Depth 4
    Write-Utf8File -Path $markerTarget -Content $info

    Show-Info "安装完成。`r`n`r`n现在可以在 RX 9 中打开帮助入口查看中文教程。"
}

function Restore-Patch {
    param([string]$Root)

    $rootFull = Get-FullPath $Root
    $entryTarget = Join-Path $rootFull $EntryRelativePath
    $backupTarget = Join-Path $rootFull $BackupRelativePath

    foreach ($target in @($entryTarget, $backupTarget)) {
        if (-not (Test-PathInside $rootFull $target)) {
            throw "安全检查失败：目标路径不在 RX 9 安装目录内。`r`n$target"
        }
    }

    if (-not (Test-Path -LiteralPath $backupTarget -PathType Leaf)) {
        throw "没有找到原帮助入口备份：`r`n$backupTarget"
    }

    Copy-Item -LiteralPath $backupTarget -Destination $entryTarget -Force
    Show-Info "已恢复原帮助入口。`r`n`r`n中文教程文件会保留在目录中，不影响原帮助入口。"
}

try {
    $root = Select-Rx9Root
    if ([string]::IsNullOrWhiteSpace($root)) {
        Show-Warn '已取消。'
        exit 0
    }

    $backupPath = Join-Path (Get-FullPath $root) $BackupRelativePath

    if ($Restore) {
        Restore-Patch -Root $root
        exit 0
    }

    if (Test-Path -LiteralPath $backupPath -PathType Leaf) {
        $choice = [System.Windows.Forms.MessageBox]::Show(
            "检测到已经安装过中文帮助入口。`r`n`r`n选择[是]：重新安装或更新中文教程。`r`n选择[否]：恢复原帮助入口。`r`n选择[取消]：退出。",
            $PatchName,
            [System.Windows.Forms.MessageBoxButtons]::YesNoCancel,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        if ($choice -eq [System.Windows.Forms.DialogResult]::No) {
            Restore-Patch -Root $root
            exit 0
        }
        if ($choice -eq [System.Windows.Forms.DialogResult]::Cancel) {
            exit 0
        }
    }

    Install-Patch -Root $root
} catch {
    Show-ErrorBox "操作失败：`r`n`r`n$($_.Exception.Message)`r`n`r`n如果目录位于 Program Files，请右键安装器并选择[以管理员身份运行]。"
    exit 1
}
