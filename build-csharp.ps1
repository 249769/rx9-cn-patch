$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallerDir = Join-Path $Root 'installer'
$SourceScript = Join-Path $InstallerDir 'install-rx9-cn.ps1'
$BuildDir = Join-Path $Root 'build-csharp'
$DistDir = Join-Path $Root 'dist'
$SourceCs = Join-Path $BuildDir 'Rx9CnHelpInstaller.cs'
$TargetExe = Join-Path $DistDir 'RX9-CN-Help-Installer.exe'

if (-not (Test-Path -LiteralPath $SourceScript -PathType Leaf)) {
    throw "Missing installer script: $SourceScript"
}

New-Item -ItemType Directory -Path $BuildDir, $DistDir -Force | Out-Null

$utf8NoBom = New-Object System.Text.UTF8Encoding($false, $true)
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
$scriptText = [IO.File]::ReadAllText($SourceScript, $utf8NoBom)
$payloadBytes = $utf8Bom.GetPreamble() + $utf8NoBom.GetBytes($scriptText)
$payload = [Convert]::ToBase64String($payloadBytes)

$cs = @"
using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Windows.Forms;

internal static class Rx9CnHelpInstaller
{
    private const string PayloadBase64 = "$payload";

    [STAThread]
    private static int Main(string[] args)
    {
        string tempDir = Path.Combine(Path.GetTempPath(), "rx9-cn-help-installer-" + Guid.NewGuid().ToString("N"));
        try
        {
            Directory.CreateDirectory(tempDir);
            string scriptPath = Path.Combine(tempDir, "install-rx9-cn.ps1");
            File.WriteAllBytes(scriptPath, Convert.FromBase64String(PayloadBase64));

            string arguments = "-STA -NoProfile -ExecutionPolicy Bypass -File " + Quote(scriptPath);
            foreach (string arg in args)
            {
                arguments += " " + Quote(arg);
            }

            ProcessStartInfo startInfo = new ProcessStartInfo();
            startInfo.FileName = "powershell.exe";
            startInfo.Arguments = arguments;
            startInfo.UseShellExecute = false;
            startInfo.CreateNoWindow = true;

            using (Process process = Process.Start(startInfo))
            {
                process.WaitForExit();
                return process.ExitCode;
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                "RX 9 CN Help Installer failed to start:\r\n\r\n" + ex.Message,
                "RX 9 CN Help Installer",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
            return 1;
        }
        finally
        {
            try
            {
                if (Directory.Exists(tempDir))
                {
                    Directory.Delete(tempDir, true);
                }
            }
            catch
            {
            }
        }
    }

    private static string Quote(string value)
    {
        if (value == null)
        {
            return "\"\"";
        }

        return "\"" + value.Replace("\\", "\\\\").Replace("\"", "\\\"") + "\"";
    }
}
"@

$ascii = New-Object System.Text.ASCIIEncoding
[IO.File]::WriteAllText($SourceCs, $cs, $ascii)

if (Test-Path -LiteralPath $TargetExe -PathType Leaf) {
    Remove-Item -LiteralPath $TargetExe -Force
}

$cscCandidates = @(
    "$env:SystemRoot\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "$env:SystemRoot\Microsoft.NET\Framework\v4.0.30319\csc.exe",
    "$env:SystemRoot\Microsoft.NET\Framework64\v3.5\csc.exe",
    "$env:SystemRoot\Microsoft.NET\Framework\v3.5\csc.exe"
)

$csc = $cscCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if (-not $csc) {
    throw 'Could not find csc.exe.'
}

& $csc /nologo /target:winexe /platform:anycpu /optimize+ /reference:System.Windows.Forms.dll /out:$TargetExe $SourceCs

if (-not (Test-Path -LiteralPath $TargetExe -PathType Leaf)) {
    throw "Build did not produce $TargetExe"
}

$hash = Get-FileHash -LiteralPath $TargetExe -Algorithm SHA256
Write-Host "Built: $TargetExe"
Write-Host "SHA256: $($hash.Hash)"
