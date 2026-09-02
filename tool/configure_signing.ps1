$ErrorActionPreference = 'Stop'

$storePasswordSecure = Read-Host 'Masukkan password keystore Finova' -AsSecureString
$keyPasswordSecure = Read-Host 'Masukkan password key alias finova-upload (biasanya sama)' -AsSecureString

$storePassword = [System.Net.NetworkCredential]::new('', $storePasswordSecure).Password
$keyPassword = [System.Net.NetworkCredential]::new('', $keyPasswordSecure).Password

if ([string]::IsNullOrWhiteSpace($storePassword) -or [string]::IsNullOrWhiteSpace($keyPassword)) {
    throw 'Password tidak boleh kosong.'
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$keyFile = Join-Path $projectRoot 'keystore\finova-upload.jks'
if (-not (Test-Path -LiteralPath $keyFile)) {
    throw "Signing key tidak ditemukan: $keyFile"
}

$propertiesPath = Join-Path $projectRoot 'android\key.properties'
$content = @(
    "storePassword=$storePassword"
    "keyPassword=$keyPassword"
    'keyAlias=finova-upload'
    'storeFile=../../keystore/finova-upload.jks'
) -join [Environment]::NewLine

[System.IO.File]::WriteAllText($propertiesPath, $content, [System.Text.UTF8Encoding]::new($false))
Write-Host 'Konfigurasi signing tersimpan lokal di android\key.properties.' -ForegroundColor Green
Write-Host 'Jangan membagikan atau mengunggah file tersebut.' -ForegroundColor Yellow
