# Gathers everything the test build needs from public sources (no secrets):
# - the official Veyra 2.2.0 NVIDIA package (its FFmpeg/Qt/NGX runtimes are reused as is)
# - FFmpeg n9.0.1 headers + import libraries generated from the package's own FFmpeg DLLs
#   (the same approach as scripts/acceptance/build-recording-handoff.py)
# - NVIDIA DLSS SDK v310.7.0, nv-codec-headers n13.0.19.0, Intel XeSS v3.0.2,
#   AMD FidelityFX SDK v2.3.0 and AMF v1.5.3 headers, CUDA driver headers (cuda.h)
# The NVIDIA Optical Flow SDK needs an NVIDIA Developer sign-in: it is replaced by
# ci/NvOfSessionStub.cpp (NVOF reported unavailable, as on non-NVIDIA GPUs).
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$deps = $env:DEPS
New-Item -ItemType Directory -Force $deps | Out-Null

function Sparse([string]$Url, [string]$Ref, [string]$Dir, [string[]]$Paths) {
    if (Test-Path $Dir) { Remove-Item -Recurse -Force $Dir }
    git clone --quiet --depth 1 --branch $Ref --filter=blob:none --no-checkout $Url $Dir
    git -C $Dir sparse-checkout set --no-cone @Paths
    git -C $Dir checkout --quiet
    Write-Host "fetched $Url@$Ref -> $Dir"
}
function Env([string]$Name, [string]$Value) {
    "$Name=$Value" | Out-File -FilePath $env:GITHUB_ENV -Append -Encoding utf8
    Set-Item -Path "env:$Name" -Value $Value
    Write-Host "$Name=$Value"
}

# --- Official package ---------------------------------------------------------
$assets = gh release view $env:OFFICIAL_TAG -R Likely7/Veyra-NRVideo --json assets --jq '.assets[] | "\(.name)\t\(.size)"'
Write-Host "Official $($env:OFFICIAL_TAG) assets:"; $assets | ForEach-Object { Write-Host "  $_" }
$names = $assets | ForEach-Object { ($_ -split "`t")[0] }
$pick = $names | Where-Object { $_ -match '(?i)nvidia' -and $_ -match '(?i)\.(zip|7z)$' -and $_ -notmatch '(?i)source|sha|symbol|pdb|update|camera' } | Select-Object -First 1
if (-not $pick) { $pick = $names | Where-Object { $_ -match '(?i)portable' -and $_ -match '(?i)\.(zip|7z)$' -and $_ -notmatch '(?i)amd|source' } | Select-Object -First 1 }
if (-not $pick) { throw "No NVIDIA portable package found among the $($env:OFFICIAL_TAG) assets" }
Write-Host "Using package: $pick"
$zipDir = Join-Path $deps 'official'
New-Item -ItemType Directory -Force $zipDir | Out-Null
$zipPath = Join-Path $zipDir $pick
$expected = [int64](($assets | Where-Object { $_.StartsWith("$pick`t") } | Select-Object -First 1) -split "`t")[1]
if ((Test-Path $zipPath) -and (Get-Item $zipPath).Length -eq $expected) { Write-Host 'official package restored from cache' }
else { gh release download $env:OFFICIAL_TAG -R Likely7/Veyra-NRVideo -p $pick -D $zipDir --clobber }
$extract = Join-Path $deps 'official-x'
if (Test-Path $extract) { Remove-Item -Recurse -Force $extract }
7z x (Join-Path $zipDir $pick) "-o$extract" -y | Out-Null
$exe = Get-ChildItem $extract -Recurse -Filter veyra_qml_ui.exe | Select-Object -First 1
if (-not $exe) { throw "veyra_qml_ui.exe not found inside $pick" }
Env PKG_DIR $exe.DirectoryName
Env PKG_NAME $pick
Get-ChildItem $exe.DirectoryName -Filter *.dll | Sort-Object Name | ForEach-Object { Write-Host ("  dll {0}" -f $_.Name) }

# --- FFmpeg 9.0.1: headers + import libs for the package's DLLs ---------------
$ff = Join-Path $deps 'ffmpeg'
Sparse 'https://github.com/FFmpeg/FFmpeg' 'n9.0.1' (Join-Path $deps 'ffsrc') @('/libavcodec/*.h', '/libavformat/*.h', '/libavutil/*.h', '/libswresample/*.h', '/libswscale/*.h', '/libavfilter/*.h')
foreach ($d in 'include', 'lib', 'share/ffmpeg') { New-Item -ItemType Directory -Force (Join-Path $ff $d) | Out-Null }
foreach ($lib in 'libavcodec', 'libavformat', 'libavutil', 'libswresample', 'libswscale', 'libavfilter') {
    $to = Join-Path $ff "include/$lib"
    New-Item -ItemType Directory -Force $to | Out-Null
    Copy-Item (Join-Path $deps "ffsrc/$lib/*.h") $to
}
Set-Content (Join-Path $ff 'include/libavutil/avconfig.h') @(
    '/* Generated for the Veyra CI test build (FFmpeg configure output for x86-64). */',
    '#ifndef AVUTIL_AVCONFIG_H', '#define AVUTIL_AVCONFIG_H',
    '#define AV_HAVE_BIGENDIAN 0', '#define AV_HAVE_FAST_UNALIGNED 1', '#endif /* AVUTIL_AVCONFIG_H */')
Set-Content (Join-Path $ff 'include/libavutil/ffversion.h') @(
    '#ifndef AVUTIL_FFVERSION_H', '#define AVUTIL_FFVERSION_H', '#define FFMPEG_VERSION "9.0.1"', '#endif')
foreach ($name in 'avformat', 'avcodec', 'avutil', 'swresample', 'swscale') {
    $dll = Get-ChildItem $env:PKG_DIR -Filter "$name-*.dll" | Select-Object -First 1
    if (-not $dll) { throw "FFmpeg $name DLL missing from the official package" }
    $exports = dumpbin /nologo /exports $dll.FullName
    $symbols = foreach ($line in $exports) { if ($line -match '^\s+\d+\s+[0-9A-Fa-f]+\s+[0-9A-Fa-f]{8}\s+(\S+)') { $Matches[1] } }
    if ($symbols.Count -lt 10) { throw "Too few exports read from $($dll.Name)" }
    $def = Join-Path $ff "lib/$name.def"
    Set-Content $def (@("LIBRARY $($dll.BaseName)", 'EXPORTS') + $symbols)
    lib /nologo /machine:x64 "/def:$def" "/name:$($dll.Name)" "/out:$(Join-Path $ff "lib/$name.lib")" | Out-Null
    Write-Host ("FFmpeg {0}: {1} exports from {2}" -f $name, $symbols.Count, $dll.Name)
}
$major = (Select-String -Path (Join-Path $ff 'include/libavcodec/version_major.h') -Pattern 'define LIBAVCODEC_VERSION_MAJOR\s+(\d+)').Matches[0].Groups[1].Value
$dllMajor = ((Get-ChildItem $env:PKG_DIR -Filter 'avcodec-*.dll' | Select-Object -First 1).BaseName -split '-')[1]
Write-Host "libavcodec headers major $major, package DLL major $dllMajor"
if ($major -ne $dllMajor) { throw "FFmpeg header/DLL version mismatch ($major vs $dllMajor)" }
Set-Content (Join-Path $ff 'share/ffmpeg/FindFFMPEG.cmake') @'
# Veyra CI test build: FFmpeg 9.0.1 headers with import libraries generated from
# the official package's FFmpeg DLLs (the DLLs themselves are reused at run time).
get_filename_component(_veyra_ff_root "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)
set(FFMPEG_INCLUDE_DIRS "${_veyra_ff_root}/include")
set(FFMPEG_LIBRARY_DIRS "${_veyra_ff_root}/lib")
set(FFMPEG_LIBRARIES "")
foreach(_c avformat avcodec swresample swscale avutil)
  set(FFMPEG_lib${_c}_LIBRARY "${_veyra_ff_root}/lib/${_c}.lib")
  list(APPEND FFMPEG_LIBRARIES "${_veyra_ff_root}/lib/${_c}.lib")
endforeach()
set(FFMPEG_FOUND TRUE)
'@
Env FF_ROOT ($ff -replace '\\', '/')

# --- NVIDIA DLSS SDK 310.7.0 (the version Veyra pins) -------------------------
Sparse 'https://github.com/NVIDIA/DLSS' 'v310.7.0' (Join-Path $deps 'dlss') @('/include/', '/lib/Windows_x86_64/x64/')
if (-not (Test-Path (Join-Path $deps 'dlss/lib/Windows_x86_64/x64/nvsdk_ngx_s.lib'))) { throw 'nvsdk_ngx_s.lib missing' }
Env DLSS_ROOT ((Join-Path $deps 'dlss') -replace '\\', '/')

# --- NVOF: stand-in (see header) ----------------------------------------------
$nvof = Join-Path $deps 'nvof'
New-Item -ItemType Directory -Force (Join-Path $nvof 'NvOFInterface'), (Join-Path $nvof 'Common/NvOFBase') | Out-Null
Set-Content (Join-Path $nvof 'NvOFInterface/nvOpticalFlowCommon.h') '// CI stand-in: NvOfSession.cpp is replaced by ci/NvOfSessionStub.cpp'
Copy-Item (Join-Path $env:GITHUB_WORKSPACE 'ci/ci/NvOfSessionStub.cpp') (Join-Path $env:GITHUB_WORKSPACE 'src/src/ngx/NvOfSession.cpp') -Force
Env NVOF_ROOT ($nvof -replace '\\', '/')

# --- Headers: NVENC, XeSS, FidelityFX 2, AMF ----------------------------------
Sparse 'https://github.com/FFmpeg/nv-codec-headers' 'n13.0.19.0' (Join-Path $deps 'nvenc') @('/include/')
Env NVENC_ROOT ((Join-Path $deps 'nvenc') -replace '\\', '/')
Sparse 'https://github.com/intel/xess' 'v3.0.2' (Join-Path $deps 'xess') @('/inc/')
Env XESS_ROOT ((Join-Path $deps 'xess') -replace '\\', '/')
Sparse 'https://github.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK' 'v2.3.0' (Join-Path $deps 'ffx2') @('/Kits/FidelityFX/api/include/', '/Kits/FidelityFX/framegeneration/include/', '/Kits/FidelityFX/upscalers/include/')
Env FFX2_ROOT ((Join-Path $deps 'ffx2/Kits/FidelityFX') -replace '\\', '/')
Sparse 'https://github.com/GPUOpen-LibrariesAndSDKs/AMF' 'v1.5.3' (Join-Path $deps 'amf') @('/amf/public/include/')
Env AMF_ROOT ((Join-Path $deps 'amf/amf/public') -replace '\\', '/')

# --- CUDA driver headers (cuda.h) for NVIDIA VFG / video SR: best effort -----
$cudaInclude = ''
try {
    $redist = Invoke-RestMethod 'https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.6.3.json'
    $rel = $redist.cuda_cudart.'windows-x86_64'.relative_path
    $cz = Join-Path $deps 'cudart.zip'
    Invoke-WebRequest "https://developer.download.nvidia.com/compute/cuda/redist/$rel" -OutFile $cz
    7z x $cz "-o$(Join-Path $deps 'cudart')" -y | Out-Null
    $h = Get-ChildItem (Join-Path $deps 'cudart') -Recurse -Filter cuda.h | Select-Object -First 1
    if ($h) { $cudaInclude = $h.DirectoryName -replace '\\', '/' }
} catch { Write-Host "cuda.h not fetched: $_ (NVIDIA VFG stays unavailable in this build)" }
Env CUDA_INCLUDE $cudaInclude

# --- OpenSSL (portable update signature check) --------------------------------
$ssl = @('C:/Program Files/OpenSSL', 'C:/Program Files/OpenSSL-Win64') | Where-Object { Test-Path "$_/include/openssl/evp.h" } | Select-Object -First 1
if (-not $ssl) {
    choco install openssl --no-progress -y | Out-Null
    $ssl = @('C:/Program Files/OpenSSL', 'C:/Program Files/OpenSSL-Win64') | Where-Object { Test-Path "$_/include/openssl/evp.h" } | Select-Object -First 1
}
if (-not $ssl) { throw 'OpenSSL not available' }
Env OPENSSL_ROOT $ssl
Write-Host 'Dependencies ready.'
