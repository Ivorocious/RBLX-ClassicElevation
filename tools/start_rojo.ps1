# One supervisor per port. The default port is the primary Studio window; see
# docs/ROBLOX_MCP_SETUP.md for running a second window on another port.
param(
    [ValidateRange(0, 20)][int]$MaxRestarts = 5,
    [ValidateRange(1024, 65535)][int]$Port = 34872
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$rojoVersion = '7.7.1'
$rojoExecutable = Join-Path $projectRoot ".tools\rojo-$rojoVersion\rojo.exe"
$logDirectory = Join-Path $projectRoot '.tools\rojo-runtime'
$rojoProcess = $null
$ownsMutex = $false
$mutex = [Threading.Mutex]::new($false, "Local\ProjectClassicElevationRojo$Port")

try {
    try { $ownsMutex = $mutex.WaitOne(0) }
    catch [Threading.AbandonedMutexException] { $ownsMutex = $true }
    if (-not $ownsMutex) {
        Write-Output "A Rojo supervisor is already running for port $Port. Check localhost:$Port."
        return
    }

    $existingResponse = $null
    try { $existingResponse = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/api/rojo" -TimeoutSec 3 }
    catch { }
    if ($existingResponse) {
        $responseText = if ($existingResponse.Content -is [byte[]]) {
            [Text.Encoding]::UTF8.GetString($existingResponse.Content)
        } else { [string]$existingResponse.Content }
        if ($responseText.Contains('ProjectClassicElevation') -and $responseText.Contains($rojoVersion)) {
            Write-Output "ProjectClassicElevation Rojo $rojoVersion is already running at localhost:$Port."
            return
        }
        throw "Port $Port is serving something else; no process was stopped."
    }

    $portProbe = [Net.Sockets.TcpClient]::new()
    try {
        try { $portProbe.Connect('127.0.0.1', $Port) } catch { }
        if ($portProbe.Connected) { throw "Port $Port is occupied but not ready; no duplicate server was started." }
    } finally { $portProbe.Dispose() }

    if (-not (Test-Path -LiteralPath $rojoExecutable -PathType Leaf)) {
        throw "The pinned Rojo $rojoVersion executable is missing."
    }
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    $supervisorLog = Join-Path $logDirectory "supervisor-$Port.log"
    $recentExits = 0
    while ($true) {
        $runId = "$Port-" + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff')
        $stdoutLog = Join-Path $logDirectory "$runId-stdout.log"
        $stderrLog = Join-Path $logDirectory "$runId-stderr.log"
        $runTimer = [Diagnostics.Stopwatch]::StartNew()
        $rojoProcess = Start-Process -FilePath $rojoExecutable `
            -ArgumentList @('serve', 'default.project.json', '--port', "$Port") `
            -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog
        $message = "$runId started Rojo PID $($rojoProcess.Id) on port $Port; logs: $stdoutLog and $stderrLog"
        Add-Content -LiteralPath $supervisorLog -Value $message
        Write-Output $message
        $rojoProcess.WaitForExit()
        $exitCode = $rojoProcess.ExitCode
        $rojoProcess.Dispose()
        $rojoProcess = $null
        if ($runTimer.Elapsed.TotalSeconds -ge 60) { $recentExits = 0 }
        $recentExits++
        $message = "Rojo exited with code $exitCode after $([int]$runTimer.Elapsed.TotalSeconds)s."
        Add-Content -LiteralPath $supervisorLog -Value $message
        Write-Output $message
        if ($recentExits -gt $MaxRestarts) { throw "Rojo repeatedly exited; restart limit reached. See $logDirectory." }
        Write-Output 'Restarting Rojo in 3 seconds; Studio may need Connect again.'
        Start-Sleep -Seconds 3
    }
} finally {
    # Only the child created by this supervisor belongs to this session.
    if ($rojoProcess) {
        if (-not $rojoProcess.HasExited) { $rojoProcess.Kill() }
        $rojoProcess.Dispose()
    }
    if ($ownsMutex) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
