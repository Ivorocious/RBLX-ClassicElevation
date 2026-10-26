param([switch]$ReadKey)
$ErrorActionPreference = 'Stop'
$keyPath = Join-Path (Split-Path $PSScriptRoot -Parent) '.tools\roblox-upload-key.dpapi'
if ($ReadKey) {
    $secureKey = ConvertTo-SecureString (Get-Content -LiteralPath $keyPath -Raw).Trim()
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    try {
        [Console]::Write([Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer))
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
} else {
    $secureKey = Read-Host 'Paste your Roblox Assets API key (input is hidden)' -AsSecureString
    if ($secureKey.Length -eq 0) { throw 'No key entered.' }
    New-Item -ItemType Directory -Force -Path (Split-Path $keyPath -Parent) | Out-Null
    $secureKey | ConvertFrom-SecureString | Set-Content -LiteralPath $keyPath
    Write-Host 'Saved an encrypted key for this Windows user. You can return to Codex.'
}
