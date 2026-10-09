# Muzik Teorisi: analyze + APK build + adb ile telefona kurulum.
# Once kablosuz (Tailscale, scripts\phone-adb.target), yoksa USB dener.
# Log: build\phone_install_log.txt
$ErrorActionPreference = 'Continue'
$proj = Split-Path $PSScriptRoot -Parent
$ws = Split-Path $proj -Parent
$log = Join-Path $proj 'build\phone_install_log.txt'
New-Item -ItemType Directory -Force -Path (Join-Path $proj 'build') | Out-Null
Set-Content -Path $log -Value "=== $(Get-Date -Format s) ===" -Encoding UTF8

function Log([string]$m) { Write-Host $m; Add-Content -Path $log -Value $m -Encoding UTF8 }
function Run([string]$title, [scriptblock]$cmd) {
    Log ">>> $title"
    & $cmd 2>&1 | ForEach-Object { "$_" } | ForEach-Object { Log $_ }
    return $LASTEXITCODE
}

Push-Location $proj
try {
    [void](Run 'flutter pub get' { flutter pub get })
    [void](Run 'flutter analyze' { flutter analyze })

    $code = Run 'flutter build apk (arm64)' { flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons }
    $apk = Join-Path $proj 'build\app\outputs\flutter-apk\app-arm64-v8a-release.apk'
    if (-not (Test-Path $apk)) { $apk = Join-Path $proj 'build\app\outputs\flutter-apk\app-release.apk' }
    if ($code -ne 0 -or -not (Test-Path $apk)) { Log 'SONUC: BUILD HATASI'; exit 1 }
    Log "APK: $apk"

    $targetFile = Join-Path $ws 'scripts\phone-adb.target'
    if (Test-Path $targetFile) {
        $target = Get-Content $targetFile | Where-Object { $_ -match '^\s*\d+\.\d+\.\d+\.\d+' } | Select-Object -First 1
        if ($target) {
            $target = $target.Trim()
            if ($target -notmatch ':') { $target = "${target}:5555" }
            [void](Run "adb connect $target" { adb connect $target })
        }
    }

    $devices = (adb devices 2>&1 | Out-String)
    Log $devices
    if ($devices -notmatch "`tdevice") {
        Log 'SONUC: CIHAZ YOK (kablosuz baglanamadi, USB de takili degil)'
        exit 2
    }

    $code = Run 'adb install -r' { adb install -r $apk }
    if ($code -ne 0) { Log 'SONUC: KURULUM HATASI'; exit 3 }
    Log 'SONUC: KURULDU'
} finally {
    Pop-Location
}
