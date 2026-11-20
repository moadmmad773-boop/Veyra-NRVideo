# Test package: the official Veyra 2.2.0 NVIDIA package with this build's program,
# QML and shaders in place of the official ones. Everything else (Qt, FFmpeg, NGX
# and other runtimes, virtual camera, licenses) is the official package unchanged.
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$build = $env:BUILD
$name = 'MMM-2.2.0-NVIDIA'
$stage = Join-Path $env:STAGE $name
if (Test-Path $env:STAGE) { Remove-Item -Recurse -Force $env:STAGE }
New-Item -ItemType Directory -Force $stage | Out-Null
# The portable package: Veyra.exe (launcher) + current-version.txt at the root, the
# program in versions/<version>/. Keep that layout; only the program folder changes.
$root = Split-Path (Split-Path $env:PKG_DIR -Parent) -Parent
if (-not (Test-Path (Join-Path $root 'current-version.txt'))) { $root = $env:PKG_DIR }
Copy-Item (Join-Path $root '*') $stage -Recurse -Force
$app = Join-Path $stage ([IO.Path]::GetRelativePath($root, $env:PKG_DIR))
Write-Host "package root $root; program folder $app"
"PKG_APP=$app" | Out-File -FilePath $env:GITHUB_ENV -Append -Encoding utf8
Get-ChildItem $stage | ForEach-Object { Write-Host ("  root {0}" -f $_.Name) }

Copy-Item (Join-Path $build 'veyra_qml_ui.exe') (Join-Path $app 'veyra_qml_ui.exe') -Force
# The launcher, rebuilt with the M$M! icon and named after it (same program as Veyra.exe).
$launcher = 'M$M!.exe'
if ($root -ne $env:PKG_DIR) {
    Copy-Item (Join-Path $build 'veyra_portable_launcher.exe') (Join-Path $stage $launcher) -Force
    Remove-Item (Join-Path $stage 'Veyra.exe') -Force -ErrorAction SilentlyContinue
}
# The program loads its QML from disk: replace Veyra's own QML (Qt's modules stay).
$builtQml = Join-Path $build 'qml'
foreach ($module in Get-ChildItem $builtQml -Directory) {
    $target = Join-Path $app "qml/$($module.Name)"
    if (Test-Path $target) { Remove-Item -Recurse -Force $target }
    Copy-Item $module.FullName $target -Recurse
}
$shaders = Join-Path $app 'shaders'
New-Item -ItemType Directory -Force $shaders | Out-Null
$built = Get-ChildItem (Join-Path $build 'shaders') -Filter *.dxil
$built | ForEach-Object { Copy-Item $_.FullName (Join-Path $shaders $_.Name) -Force }
Write-Host "shaders replaced: $($built.Count)"

# Every DLL the new program imports must be in the package (OpenSSL is the one
# this build may take from the runner).
$deps = dumpbin /nologo /dependents (Join-Path $app 'veyra_qml_ui.exe')
$dlls = foreach ($line in $deps) { if ($line -match '^\s+(\S+\.dll)\s*$') { $Matches[1] } }
foreach ($dll in $dlls) {
    if (Test-Path (Join-Path $app $dll)) { continue }
    if (Test-Path (Join-Path $env:SystemRoot "System32/$dll")) { continue }
    $found = Get-ChildItem $env:OPENSSL_ROOT, (Join-Path $env:QT_ROOT_DIR 'bin') -Recurse -Filter $dll -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { Copy-Item $found.FullName (Join-Path $app $dll); Write-Host "added $dll from $($found.DirectoryName)" }
    else { Write-Host "WARNING: $dll not found for the package" }
}

Set-Content (Join-Path $stage 'M$M!-README.txt') -Encoding utf8 @'
M$M! 2.2.0 (NVIDIA) - personal test build
==========================================
Based on Veyra 2.2.0 by Likely7 (GPL-3.0, https://github.com/Likely7/Veyra-NRVideo), built by
GitHub Actions from https://github.com/moadmmad773-boop/Veyra-NRVideo (branch custom/mmm):
sky blue look, the M$M! name and logo, and the live translation source "On-screen text
(capture card / PS5 subtitles)". Start it with M$M!.exe.

Not in this build (they need private build trees): PS5 Remote Play, Moonlight/Sunshine and
Xbox streaming, NVIDIA Optical Flow guidance, Dolby Vision enhancement-layer RPU parsing, the
deinterlace module.

M$M! - نسخة شخصية تجريبية مبنية على Veyra 2.2.0 (للمطوّر Likely7، رخصة GPL-3.0).
شغّلها من M$M!.exe. فيها اللون الأزرق الفاتح والاسم والشعار الجديد وخيار ترجمة نص الشاشة.
غير موجود فيها: PS5 Remote Play وبث Moonlight وXbox.
'@

$out = Join-Path $env:STAGE "$name.zip"
Push-Location $env:STAGE
7z a -tzip -mx=5 $out $name | Out-Null
Pop-Location
$size = (Get-Item $out).Length
Write-Host ("package {0} {1:N0} MB sha256 {2}" -f $out, ($size / 1MB), (Get-FileHash $out -Algorithm SHA256).Hash)
if ($size -ge 2GB) { throw 'Package over the 2 GB release asset limit' }
"PACKAGE=$out" | Out-File -FilePath $env:GITHUB_ENV -Append -Encoding utf8

# Update: only the changed files, to unzip over an existing copy of this package.
$updName = 'MMM-update'
$upd = Join-Path $env:STAGE $updName
$updApp = Join-Path $upd ([IO.Path]::GetRelativePath($stage, $app))
New-Item -ItemType Directory -Force (Join-Path $updApp 'qml'), (Join-Path $updApp 'shaders') | Out-Null
Copy-Item (Join-Path $app 'veyra_qml_ui.exe') $updApp
foreach ($module in Get-ChildItem $builtQml -Directory) { Copy-Item (Join-Path $app "qml/$($module.Name)") (Join-Path $updApp 'qml') -Recurse }
Copy-Item (Join-Path $shaders '*.dxil') (Join-Path $updApp 'shaders')
if (Test-Path (Join-Path $stage $launcher)) { Copy-Item (Join-Path $stage $launcher) $upd }
Copy-Item (Join-Path $stage 'M$M!-README.txt') $upd
$updZip = Join-Path $env:STAGE "$updName.zip"
Push-Location $upd
7z a -tzip -mx=7 $updZip * | Out-Null
Pop-Location
Write-Host ("update {0} {1:N1} MB" -f $updZip, ((Get-Item $updZip).Length / 1MB))
"UPDATE=$updZip" | Out-File -FilePath $env:GITHUB_ENV -Append -Encoding utf8
