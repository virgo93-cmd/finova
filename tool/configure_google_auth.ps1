$ErrorActionPreference = 'Stop'

$clientId = Read-Host 'Tempel Google OAuth Client ID'
$secureSecret = Read-Host 'Tempel Google OAuth Client Secret (teks tidak akan terlihat)' -AsSecureString
$clientSecret = [System.Net.NetworkCredential]::new('', $secureSecret).Password

if ([string]::IsNullOrWhiteSpace($clientId) -or [string]::IsNullOrWhiteSpace($clientSecret)) {
  throw 'Client ID dan Client Secret wajib diisi.'
}

$env:SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID = $clientId.Trim()
$env:SUPABASE_AUTH_EXTERNAL_GOOGLE_SECRET = $clientSecret

try {
  npx supabase config push --project-ref bgdgvthrukltamgfysxl
  if ($LASTEXITCODE -ne 0) {
    throw "Supabase config push gagal dengan kode $LASTEXITCODE."
  }
  Write-Host 'Google Auth berhasil dikirim ke Supabase.' -ForegroundColor Green
}
finally {
  Remove-Item Env:SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID -ErrorAction SilentlyContinue
  Remove-Item Env:SUPABASE_AUTH_EXTERNAL_GOOGLE_SECRET -ErrorAction SilentlyContinue
  $clientSecret = $null
  $secureSecret.Dispose()
}
