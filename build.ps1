# ================================================================
# DalamudPlugins 本地构建脚本
# 构建 CraftFlow 和 SilverDasher 并打包为 zip 发布文件
# ================================================================
param(
    [string]$CraftFlowVersion = "0.2.3.0",
    [string]$SilverDasherVersion = "0.1.0.0",
    [switch]$UpdatePluginMaster
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ReleaseDir = Join-Path $ScriptDir "release"

# 插件源码路径（相对于本仓库）
$CraftFlowSrc = "D:\deepseek\CraftFlow\CraftFlow"
$SilverDasherSrc = "D:\deepseek\SilverDasher"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  DalamudPlugins 构建脚本" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# 创建 release 目录
if (-not (Test-Path $ReleaseDir)) {
    New-Item -Path $ReleaseDir -ItemType Directory -Force | Out-Null
}

# ----------------------------------------------------------------
# 构建 CraftFlow
# ----------------------------------------------------------------
Write-Host ""
Write-Host "[1/4] 构建 CraftFlow v$CraftFlowVersion ..." -ForegroundColor Yellow

Push-Location $CraftFlowSrc
try {
    dotnet restore CraftFlow.csproj
    dotnet build CraftFlow.csproj -c Release
    if ($LASTEXITCODE -ne 0) { throw "CraftFlow 构建失败" }
    Write-Host "  -> 构建成功" -ForegroundColor Green
} finally {
    Pop-Location
}

Write-Host "[2/4] 打包 CraftFlow ..." -ForegroundColor Yellow
$CraftFlowLatestZip = "$CraftFlowSrc\bin\Release\CraftFlow\latest.zip"
$CraftFlowZip = Join-Path $ReleaseDir "CraftFlow-$CraftFlowVersion.zip"
if (Test-Path $CraftFlowLatestZip) {
    Copy-Item $CraftFlowLatestZip $CraftFlowZip -Force
    Write-Host "  -> 使用 Dalamud SDK 生成的 latest.zip" -ForegroundColor DarkGray
} else {
    # 备选：手动收集 DLL 和 JSON 文件
    $buildBase = "$CraftFlowSrc\bin\Release"
    $files = @(Get-ChildItem $buildBase -File | Where-Object { $_.Extension -in '.dll', '.json', '.pdb' })
    $files += @(Get-ChildItem "$buildBase\CraftFlow" -File)
    Compress-Archive -Path ($files | ForEach-Object { $_.FullName }) -DestinationPath $CraftFlowZip
}
Write-Host "  -> $CraftFlowZip" -ForegroundColor Green

# ----------------------------------------------------------------
# 构建 SilverDasher
# ----------------------------------------------------------------
Write-Host ""
Write-Host "[3/4] 构建 SilverDasher v$SilverDasherVersion ..." -ForegroundColor Yellow

Push-Location $SilverDasherSrc
try {
    dotnet restore SilverDasher.csproj
    dotnet build SilverDasher.csproj -c Release
    if ($LASTEXITCODE -ne 0) { throw "SilverDasher 构建失败" }
    Write-Host "  -> 构建成功" -ForegroundColor Green
} finally {
    Pop-Location
}

Write-Host "[4/4] 打包 SilverDasher ..." -ForegroundColor Yellow
$SilverDasherLatestZip = "$SilverDasherSrc\bin\Release\SilverDasher\latest.zip"
$SilverDasherZip = Join-Path $ReleaseDir "SilverDasher-$SilverDasherVersion.zip"
if (Test-Path $SilverDasherLatestZip) {
    Copy-Item $SilverDasherLatestZip $SilverDasherZip -Force
    Write-Host "  -> 使用 Dalamud SDK 生成的 latest.zip" -ForegroundColor DarkGray
} else {
    # 备选：手动收集 DLL 和 JSON 文件
    $buildBase = "$SilverDasherSrc\bin\Release"
    $files = @(Get-ChildItem $buildBase -File | Where-Object { $_.Extension -in '.dll', '.json', '.pdb' })
    if (Test-Path "$buildBase\SilverDasher") {
        $files += @(Get-ChildItem "$buildBase\SilverDasher" -File)
    }
    Compress-Archive -Path ($files | ForEach-Object { $_.FullName }) -DestinationPath $SilverDasherZip
}
Write-Host "  -> $SilverDasherZip" -ForegroundColor Green

# ----------------------------------------------------------------
# 更新 pluginmaster.json 中的 LastUpdated 时间戳
# ----------------------------------------------------------------
if ($UpdatePluginMaster) {
    Write-Host ""
    Write-Host "更新 pluginmaster.json 时间戳..." -ForegroundColor Yellow
    $pluginMasterPath = Join-Path $ScriptDir "pluginmaster.json"
    $json = Get-Content $pluginMasterPath -Raw | ConvertFrom-Json
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds().ToString()

    foreach ($plugin in $json) {
        if ($plugin.InternalName -eq "CraftFlow") {
            $plugin.AssemblyVersion = $CraftFlowVersion
            $plugin.DownloadLinkInstall = "https://github.com/ijnokmsc/DalamudPlugins/releases/download/v$CraftFlowVersion/CraftFlow-$CraftFlowVersion.zip"
            $plugin.DownloadLinkUpdate = "https://github.com/ijnokmsc/DalamudPlugins/releases/download/v$CraftFlowVersion/CraftFlow-$CraftFlowVersion.zip"
            $plugin.DownloadLinkTesting = "https://github.com/ijnokmsc/DalamudPlugins/releases/download/v$CraftFlowVersion/CraftFlow-$CraftFlowVersion.zip"
            $plugin.LastUpdated = $now
        }
        elseif ($plugin.InternalName -eq "SilverDasher") {
            $plugin.AssemblyVersion = $SilverDasherVersion
            $plugin.DownloadLinkInstall = "https://github.com/ijnokmsc/DalamudPlugins/releases/download/v$SilverDasherVersion/SilverDasher-$SilverDasherVersion.zip"
            $plugin.DownloadLinkUpdate = "https://github.com/ijnokmsc/DalamudPlugins/releases/download/v$SilverDasherVersion/SilverDasher-$SilverDasherVersion.zip"
            $plugin.DownloadLinkTesting = "https://github.com/ijnokmsc/DalamudPlugins/releases/download/v$SilverDasherVersion/SilverDasher-$SilverDasherVersion.zip"
            $plugin.LastUpdated = $now
        }
    }

    $json | ConvertTo-Json -Depth 10 | Set-Content $pluginMasterPath -Encoding UTF8
    Write-Host "  -> pluginmaster.json 已更新" -ForegroundColor Green
}

# ----------------------------------------------------------------
# 完成
# ----------------------------------------------------------------
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  构建完成！" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "发布目录: $ReleaseDir"
Get-ChildItem $ReleaseDir -Filter "*.zip" | ForEach-Object {
    Write-Host "  $($_.Name)  [$('{0:N0}' -f $_.Length) bytes]" -ForegroundColor White
}
Write-Host ""
Write-Host "下一步:"
Write-Host "  1. 在 GitHub 上创建 Release 并上传 zip 文件"
Write-Host "  2. 推送更新后的 pluginmaster.json"
Write-Host "  3. 用户通过 https://raw.githubusercontent.com/ijnokmsc/DalamudPlugins/main/pluginmaster.json 获取更新"
