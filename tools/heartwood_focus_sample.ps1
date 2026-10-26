param([int]$Seconds = 8)
$ErrorActionPreference = 'Stop'
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class HeartwoodFocusReader {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
}
'@
$studioIds = @(Get-Process -Name RobloxStudioBeta -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
$samples = @()
$timer = [Diagnostics.Stopwatch]::StartNew()
while ($timer.Elapsed.TotalSeconds -lt $Seconds) {
    [uint32]$foregroundId = 0
    $window = [HeartwoodFocusReader]::GetForegroundWindow()
    [void][HeartwoodFocusReader]::GetWindowThreadProcessId($window, [ref]$foregroundId)
    $samples += [pscustomobject]@{utc=[DateTime]::UtcNow.ToString('o'); elapsed=$timer.Elapsed.TotalSeconds; processId=$foregroundId; studioForeground=$studioIds -contains $foregroundId}
    Start-Sleep -Milliseconds 100
}
[pscustomobject]@{scope='Read-only Windows foreground process sampling; no focus action'; studioProcessIds=$studioIds; samples=$samples; allStudioForeground=(@($samples | Where-Object {-not $_.studioForeground}).Count -eq 0)} | ConvertTo-Json -Depth 6
