# Test package: the official Veyra 2.2.0 NVIDIA package with this build's program,
# QML and shaders in place of the official ones. Everything else (Qt, FFmpeg, NGX
# and other runtimes, virtual camera, licenses) is the official package unchanged.
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$build = $env:BUILD
$name = 'Veyra-2.2.0-screen-text-test-NVIDIA'
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
Get-ChildItem $stage | ForEach-Object { Write-Host ("  root {0}" -f $_.Name) }

Copy-Item (Join-Path $build 'veyra_qml_ui.exe') (Join-Path $app 'veyra_qml_ui.exe') -Force
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

Set-Content (Join-Path $stage 'TEST-BUILD-README.txt') -Encoding utf8 @'
Veyra 2.2.0 – test build with "On-screen text (capture card / PS5 subtitles)" live translation
=============================================================================================
Unofficial test build from https://github.com/moadmmad773-boop/Veyra-NRVideo (branch
feature/screen-text-translation), built by GitHub Actions on top of the official Veyra 2.2.0
NVIDIA package. Only veyra_qml_ui.exe, qml/Veyra and shaders/ in versions/2.2.0 differ from the
official package. Start it with Veyra.exe as usual.

Use: Settings -> Live translation settings... -> Caption source -> "On-screen text (capture card /
PS5 subtitles)" -> pick "Translate to" -> turn it on. Windows needs the English OCR language
(Settings -> Time & language -> Language & region -> add English).

Not in this test build (they need private build trees): PS5 Remote Play, Moonlight/Sunshine and
Xbox streaming, NVIDIA Optical Flow guidance, Dolby Vision enhancement-layer RPU parsing, the
deinterlace module. Use the official Veyra 2.2.0 for those.

نسخة تجريبية غير رسمية من Veyra 2.2.0 فيها خيار ترجمة نص الشاشة (الكابتشر / ترجمة PS5).
شغّله من Veyra.exe مثل العادة.
الاستخدام: الإعدادات ← إعدادات الترجمة المباشرة ← مصدر الترجمة ← "On-screen text" ← اختر العربية ← شغّل.
يحتاج ويندوز لغة قراءة النصوص الإنجليزية (الإعدادات ← الوقت واللغة ← اللغة والمنطقة ← إضافة الإنجليزية).
غير موجود في هذه النسخة: PS5 Remote Play وبث Moonlight وXbox. استخدم Veyra الرسمي لهذي الخصائص.
'@

$out = Join-Path $env:STAGE "$name.zip"
Push-Location $env:STAGE
7z a -tzip -mx=5 $out $name | Out-Null
Pop-Location
$size = (Get-Item $out).Length
Write-Host ("package {0} {1:N0} MB sha256 {2}" -f $out, ($size / 1MB), (Get-FileHash $out -Algorithm SHA256).Hash)
if ($size -ge 2GB) { throw 'Package over the 2 GB release asset limit' }
"PACKAGE=$out" | Out-File -FilePath $env:GITHUB_ENV -Append -Encoding utf8
