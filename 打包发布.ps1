[CmdletBinding()]
param(
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version = '0.0.3',

    [ValidateRange(1, 2100000000)]
    [int]$AndroidVersionCode = 3,

    [ValidateSet('All', 'Windows', 'Android')]
    [string]$Target = 'All',

    [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSCommandPath
$projectPath = Join-Path $repoRoot 'Broken'
$godotConsole = Join-Path $repoRoot 'tools\godot\Godot_v4.7.2-stable_win64_console.exe'
$toolRoot = Join-Path $projectPath '.android-tools'
$godotUserRoot = Join-Path $toolRoot 'godot-user'
$androidUserRoot = Join-Path $toolRoot 'android-user'
$gradleCache = Join-Path $toolRoot 'gradle-cache'
$javaHome = Join-Path $toolRoot 'jdk17\jdk-17.0.20.1+1'
$androidSdk = Join-Path $toolRoot 'android-sdk'
$guidePath = Get-ChildItem -LiteralPath $projectPath -Filter '*.md' | Select-Object -First 1 -ExpandProperty FullName
$presetPath = Join-Path $projectPath 'export_presets.cfg'
$projectConfigPath = Join-Path $projectPath 'project.godot'

function Require-Path([string]$path, [string]$description) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "$description is missing: $path"
    }
}

function Replace-Required([string]$text, [string]$pattern, [string]$replacement, [string]$description) {
    $options = [Text.RegularExpressions.RegexOptions]::Multiline
    if (-not [regex]::IsMatch($text, $pattern, $options)) {
        throw "Unable to update $description. Check export_presets.cfg."
    }
    return [regex]::Replace($text, $pattern, $replacement, $options)
}

function Write-Utf8NoBom([string]$path, [string]$text) {
    [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
}

function Invoke-Godot([string[]]$godotArguments) {
    & $godotConsole @godotArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Godot command failed: $($godotArguments -join ' ')"
    }
}

function Assert-AndroidPackage([string]$apkPath) {
    $buildTools = Get-ChildItem -LiteralPath (Join-Path $androidSdk 'build-tools') -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if ($null -eq $buildTools) { throw 'Android build-tools were not found.' }
    $aapt = Join-Path $buildTools.FullName 'aapt.exe'
    $apksigner = Join-Path $buildTools.FullName 'apksigner.bat'
    Require-Path $aapt 'aapt'
    Require-Path $apksigner 'apksigner'
    $badging = (& $aapt dump badging $apkPath) -join "`n"
    if ($LASTEXITCODE -ne 0 -or $badging -notmatch "name='com.solaris.broken' versionCode='$AndroidVersionCode' versionName='$Version'") {
        throw 'APK package name or version does not match the requested release.'
    }
    & $apksigner verify --verbose $apkPath
    if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
}

Require-Path $projectPath 'Godot project'
Require-Path $godotConsole 'Godot console'
Require-Path $guidePath 'Guide file'
Require-Path $presetPath 'Export preset'
Require-Path $projectConfigPath 'Project config'

$savedEnvironment = @{
    APPDATA = $env:APPDATA
    LOCALAPPDATA = $env:LOCALAPPDATA
    JAVA_HOME = $env:JAVA_HOME
    ANDROID_HOME = $env:ANDROID_HOME
    ANDROID_SDK_ROOT = $env:ANDROID_SDK_ROOT
    ANDROID_USER_HOME = $env:ANDROID_USER_HOME
    GRADLE_USER_HOME = $env:GRADLE_USER_HOME
}

try {
    # Use repository-local templates, SDK, JDK, and debug signing material.
    $env:APPDATA = $godotUserRoot
    $env:LOCALAPPDATA = $androidUserRoot
    $env:JAVA_HOME = $javaHome
    $env:ANDROID_HOME = $androidSdk
    $env:ANDROID_SDK_ROOT = $androidSdk
    $env:ANDROID_USER_HOME = Join-Path $androidUserRoot '.android'
    $env:GRADLE_USER_HOME = $gradleCache

    foreach ($required in @($godotUserRoot, $javaHome, $androidSdk, $gradleCache)) {
        Require-Path $required 'Release tool directory'
    }
    New-Item -ItemType Directory -Force -Path $env:ANDROID_USER_HOME | Out-Null

    $windowsFolder = "dist/releases/Broken-$Version"
    $windowsExportPath = "$windowsFolder/Broken.exe"
    $androidExportPath = "dist/Broken-Android-$Version.apk"

    $projectConfig = Get-Content -LiteralPath $projectConfigPath -Raw
    $projectConfig = Replace-Required $projectConfig '^config/version=".*"$' ('config/version="' + $Version + '"') 'project version'
    Write-Utf8NoBom $projectConfigPath $projectConfig

    $presets = Get-Content -LiteralPath $presetPath -Raw
    $presets = Replace-Required $presets '(?s)(\[preset\.0\].*?^export_path=)[^\r\n]*' ('$1"' + $windowsExportPath + '"') 'Windows export path'
    $presets = Replace-Required $presets '(?s)(\[preset\.0\.options\].*?^application/file_version=)[^\r\n]*' ('$1"' + ${Version} + '.0"') 'Windows file version'
    $presets = Replace-Required $presets '(?s)(\[preset\.0\.options\].*?^application/product_version=)[^\r\n]*' ('$1"' + $Version + '"') 'Windows product version'
    $presets = Replace-Required $presets '(?s)(\[preset\.0\.options\].*?^application/file_description=)[^\r\n]*' ('$1"Broken ' + $Version + '"') 'Windows file description'
    $presets = Replace-Required $presets '(?s)(\[preset\.1\].*?^export_path=)[^\r\n]*' ('$1"' + $androidExportPath + '"') 'Android export path'
    $presets = Replace-Required $presets '(?s)(\[preset\.1\.options\].*?^version/code=)[^\r\n]*' ('${1}' + $AndroidVersionCode) 'Android version code'
    $presets = Replace-Required $presets '(?s)(\[preset\.1\.options\].*?^version/name=)[^\r\n]*' ('$1"' + $Version + '"') 'Android version name'
    Write-Utf8NoBom $presetPath $presets

    if (-not $SkipTests) {
        Invoke-Godot @('--headless', '--path', $projectPath, '--script', 'res://tests/smoke.gd')
        Invoke-Godot @('--headless', '--path', $projectPath, '--script', 'res://tests/ui_smoke.gd')
    }

    if ($Target -in @('All', 'Windows')) {
        $windowsDirectory = Join-Path $projectPath $windowsFolder
        New-Item -ItemType Directory -Force -Path $windowsDirectory | Out-Null
        Invoke-Godot @('--headless', '--path', $projectPath, '--export-release', 'Windows Desktop')
        Copy-Item -LiteralPath $guidePath -Destination (Join-Path $windowsDirectory (Split-Path -Leaf $guidePath)) -Force
        $zipPath = Join-Path $projectPath "dist/Broken-$Version-windows.zip"
        if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
        Compress-Archive -LiteralPath $windowsDirectory -DestinationPath $zipPath
        Write-Host "Windows ZIP: $zipPath"
    }

    if ($Target -in @('All', 'Android')) {
        # The repository contains only debug signing material; this APK is not store-ready.
        Invoke-Godot @('--headless', '--path', $projectPath, '--export-debug', 'Android')
        $apkPath = Join-Path $projectPath $androidExportPath
        Require-Path $apkPath 'Android APK'
        Assert-AndroidPackage $apkPath
        Write-Host "Android APK: $apkPath"
    }
}
finally {
    foreach ($name in $savedEnvironment.Keys) {
        if ($null -eq $savedEnvironment[$name]) {
            Remove-Item "Env:$name" -ErrorAction SilentlyContinue
        }
        else {
            Set-Item "Env:$name" $savedEnvironment[$name]
        }
    }
}
