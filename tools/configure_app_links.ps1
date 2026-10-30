param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^([0-9A-Fa-f]{2}:){31}[0-9A-Fa-f]{2}$')]
    [string]$AndroidSha256,
    [string]$AndroidPackage = 'com.example.dlinii_app',
    [ValidatePattern('^[A-Z0-9]{10}$')]
    [string]$AppleTeamId,
    [string]$AppleBundleId = 'com.dlinii.dliniiApp'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
$android = @(@{
    relation = @('delegate_permission/common.handle_all_urls')
    target = @{
        namespace = 'android_app'
        package_name = $AndroidPackage
        sha256_cert_fingerprints = @($AndroidSha256.ToUpperInvariant())
    }
})
$androidJson = ConvertTo-Json -InputObject $android -Depth 8
foreach ($relative in @('web/.well-known', '.well-known')) {
    $folder = Join-Path $projectRoot $relative
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $folder 'assetlinks.json'), $androidJson, $utf8)
    if ($AppleTeamId) {
        $apple = @{ applinks = @{ apps = @(); details = @(@{
            appIDs = @("$AppleTeamId.$AppleBundleId")
            components = @(@{ '/' = '/s*' }, @{ '/' = '/'; '?' = @{ lat = '?*'; lng = '?*' } })
        }) } }
        [System.IO.File]::WriteAllText((Join-Path $folder 'apple-app-site-association'), (ConvertTo-Json $apple -Depth 10), $utf8)
    }
}
Write-Output 'Association files generated. Deploy them under https://dlinii.vercel.app/.well-known/ and verify the installed signed app.'
