# Test build 44921171063 attempt 1

- source: custom/mmm @ cccd060859807fc1030affacf3bf4f7c67a91d3a
- run: https://github.com/moadmmad773-boop/Veyra-NRVideo/actions/runs/44921171063
- steps: deps=success build=success package=success publish=skipped

## 1-deps.log

### errors
```
warning: refs/tags/n9.0.1 501bb49457b9dfb25d6a208832e0a6e6cd53108d is not a commit!
warning: refs/tags/v310.7.0 95da6df2b9d4aca1ffad241b54a4b1f4fcfb6c69 is not a commit!
warning: refs/tags/n13.0.19.0 57f8cc0bb68e5f16f3787ea92cea59000f7bf97f is not a commit!
warning: refs/tags/v3.0.2 5ec517a49a1ba8c4ad640361e4eb5227bf0742a5 is not a commit!
```

### tail
```
Official v2.2.0 assets:
  SHA256SUMS.txt	500
  Veyra-2.2.0-AMD-win64-portable.zip	748639635
  Veyra-2.2.0-AMD-win64-setup.exe	618251968
  Veyra-2.2.0-NVIDIA-win64-portable.zip	750110975
  Veyra-2.2.0-NVIDIA-win64-setup.exe	723734889
  Veyra-portable-update-v1.json	1031
Using package: Veyra-2.2.0-NVIDIA-win64-portable.zip
official package restored from cache
PKG_DIR=D:\deps\official-x\Veyra-2.2.0-NVIDIA-win64-portable\versions\2.2.0
PKG_NAME=Veyra-2.2.0-NVIDIA-win64-portable.zip
  dll avcodec-63.dll
  dll avfilter-12.dll
  dll avformat-63.dll
  dll avutil-61.dll
  dll D3Dcompiler_47.dll
  dll dav1d.dll
  dll dolby_vision.dll
  dll msvcp140.dll
  dll Qt6Core.dll
  dll Qt6Gui.dll
  dll Qt6Network.dll
  dll Qt6OpenGL.dll
  dll Qt6Qml.dll
  dll Qt6QmlMeta.dll
  dll Qt6QmlModels.dll
  dll Qt6QmlWorkerScript.dll
  dll Qt6Quick.dll
  dll Qt6QuickControls2.dll
  dll Qt6QuickControls2Basic.dll
  dll Qt6QuickControls2BasicStyleImpl.dll
  dll Qt6QuickControls2FluentWinUI3StyleImpl.dll
  dll Qt6QuickControls2Fusion.dll
  dll Qt6QuickControls2FusionStyleImpl.dll
  dll Qt6QuickControls2Imagine.dll
  dll Qt6QuickControls2ImagineStyleImpl.dll
  dll Qt6QuickControls2Impl.dll
  dll Qt6QuickControls2Material.dll
  dll Qt6QuickControls2MaterialStyleImpl.dll
  dll Qt6QuickControls2Universal.dll
  dll Qt6QuickControls2UniversalStyleImpl.dll
  dll Qt6QuickControls2WindowsStyleImpl.dll
  dll Qt6QuickEffects.dll
  dll Qt6QuickLayouts.dll
  dll Qt6QuickShapes.dll
  dll Qt6QuickTemplates2.dll
  dll Qt6Svg.dll
  dll Qt6Widgets.dll
  dll swresample-7.dll
  dll swscale-10.dll
  dll vcruntime140_1.dll
  dll vcruntime140.dll
warning: refs/tags/n9.0.1 501bb49457b9dfb25d6a208832e0a6e6cd53108d is not a commit!
fetched https://github.com/FFmpeg/FFmpeg@n9.0.1 -> D:\deps\ffsrc
FFmpeg avformat: 157 exports from avformat-63.dll
FFmpeg avcodec: 174 exports from avcodec-63.dll
FFmpeg avutil: 623 exports from avutil-61.dll
FFmpeg swresample: 23 exports from swresample-7.dll
FFmpeg swscale: 40 exports from swscale-10.dll
libavcodec headers major 63, package DLL major 63
FF_ROOT=D:/deps/ffmpeg
warning: refs/tags/v310.7.0 95da6df2b9d4aca1ffad241b54a4b1f4fcfb6c69 is not a commit!
fetched https://github.com/NVIDIA/DLSS@v310.7.0 -> D:\deps\dlss
DLSS_ROOT=D:/deps/dlss
NVOF_ROOT=D:/deps/nvof
warning: refs/tags/n13.0.19.0 57f8cc0bb68e5f16f3787ea92cea59000f7bf97f is not a commit!
fetched https://github.com/FFmpeg/nv-codec-headers@n13.0.19.0 -> D:\deps\nvenc
NVENC_ROOT=D:/deps/nvenc
warning: refs/tags/v3.0.2 5ec517a49a1ba8c4ad640361e4eb5227bf0742a5 is not a commit!
fetched https://github.com/intel/xess@v3.0.2 -> D:\deps\xess
XESS_ROOT=D:/deps/xess
fetched https://github.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK@v2.3.0 -> D:\deps\ffx2
FFX2_ROOT=D:/deps/ffx2/Kits/FidelityFX
fetched https://github.com/GPUOpen-LibrariesAndSDKs/AMF@v1.5.3 -> D:\deps\amf
AMF_ROOT=D:/deps/amf/amf/public
CUDA_INCLUDE=D:/deps/cudart/cuda_cudart-windows-x86_64-12.6.77-archive/include
OPENSSL_ROOT=C:/Program Files/OpenSSL
onnxruntime 1.22.0 (NuGet) sha256 D571E63A2329BAACB713F441E65AD75284DE354DB6E1AC435FE4BEBBB417986A; dll sha256 579B636403983254346A5C1D80BD28F1519CD1E284CD204F8D4FF41F8D711559
ORT_ROOT=D:/deps/ort/onnxruntime-1.22.0
opus-mt onnx/encoder_model_quantized.onnx 51,773,854 bytes sha256 53c354d87ced44b39085fe8a46a25f09ea4578d442dbce9663f3977228f8a04e
opus-mt onnx/decoder_model_quantized.onnx 58,707,418 bytes sha256 94e6bdf90866151787d014b7b77be0adb0f036418ee04d235ec01238aa8426b9
opus-mt tokenizer.json 6,748,848 bytes sha256 109bb62e1c598287f5960616c869e15be54785a3c2906903dafe044241d50b61
opus-mt config.json 1,389 bytes sha256 8135d646cd810090349e8833b7ba593ac3b72d632f8858cb34925bdbcb6a1bea
OPUS_DIR=D:\deps\opus\translation
Dependencies ready.
```

## 2-build.log

### errors
```
D:/a/Veyra-NRVideo/Veyra-NRVideo/src/third_party/gpu-dis/src/gpu/shaders/dis_perfect_area.hlsl:73:25: warning: conversion from larger type 'double' to smaller type 'float', possible loss of data [-Wconversion]
D:/a/Veyra-NRVideo/Veyra-NRVideo/src/third_party/gpu-dis/src/gpu/shaders/dis_perfect_area.hlsl:73:49: warning: conversion from larger type 'double' to smaller type 'float', possible loss of data [-Wconversion]
D:/a/Veyra-NRVideo/Veyra-NRVideo/src/third_party/gpu-dis/src/gpu/shaders/dis_perfect_area.hlsl:102:25: warning: conversion from larger type 'double' to smaller type 'float', possible loss of data [-Wconversion]
D:/a/Veyra-NRVideo/Veyra-NRVideo/src/third_party/gpu-dis/src/gpu/shaders/dis_perfect_area.hlsl:102:49: warning: conversion from larger type 'double' to smaller type 'float', possible loss of data [-Wconversion]
D:/a/Veyra-NRVideo/Veyra-NRVideo/src/third_party/gpu-dis/src/gpu/shaders/dis_perfect_patch_exact.hlsl:311:28: warning: implicit truncation of vector type [-Wconversion]
D:/a/Veyra-NRVideo/Veyra-NRVideo/src/third_party/gpu-dis/src/gpu/shaders/dis_perfect_patch_exact.hlsl:321:39: warning: implicit truncation of vector type [-Wconversion]
D:/a/Veyra-NRVideo/Veyra-NRVideo/src/third_party/gpu-dis/src/gpu/shaders/dis_perfect_patch_exact.hlsl:330:39: warning: implicit truncation of vector type [-Wconversion]
D:/a/Veyra-NRVideo/Veyra-NRVideo/src/third_party/gpu-dis/src/gpu/shaders/dis_perfect_patch_exact.hlsl:340:39: warning: implicit truncation of vector type [-Wconversion]
D:/a/Veyra-NRVideo/Veyra-NRVideo/src/third_party/gpu-dis/src/gpu/shaders/dis_perfect_patch_exact.hlsl:348:39: warning: implicit truncation of vector type [-Wconversion]
```

### tail
```
PASS translation shown when ready
PASS stays while it has not had the original's time
PASS taken down as long after the original as it came after it
PASS next line waits until the current one had its time
PASS then switches without a gap
PASS next line switches at once when the current one had its time
PASS a very late line stays at most the lag limit after its original
PASS and does not hold up the next line
PASS clearing takes the line down at once
PASS nothing left waiting after clearing
PASS a translation of a cleared line is dropped
PASS a line read after clearing is shown
PASS first line shown
PASS a line whose end was never told keeps its own lag
PASS then gives way to the next
PASS a translation after its line left is still taken
PASS and shown
PASS for at least the minimum time on screen
PASS then for as long as its line was up
PASS a line that left long ago is dropped
PASS a short line stays long enough to read
PASS an older line's reply never replaces a newer waiting one
PASS nor a newer shown one
PASS only the newest waiting line is kept
PASS a backlog is skipped to the newest line
PASS a line still on screen stays
ALL PASSED (0 failed)
PASS a cue in front
PASS a cue after the name
PASS a cue alone after the name
PASS a cue at the end
PASS brackets without letters are not a cue
PASS no cues
PASS cues from the Arabic list
PASS a name split off
PASS a two-word name
PASS a colon later is not a name
PASS known names and titles
PASS roles are translated
PASS roles
PASS names in Arabic letters
PASS letter by letter
PASS a language tag
PASS a misread language matched
PASS a two-word language
PASS the tag in Arabic
PASS not a tag
PASS terms kept
PASS the kept terms
PASS a line without terms
PASS a term put back (Arabic digits)
PASS a paragraph sentence by sentence
PASS one sentence
PASS harsh words softened
PASS slang spelt out
PASS offline: name and cues out, sentence by sentence
PASS put back together
PASS an instruction label is not a speaker
PASS a cue-only line needs no translator
PASS a language tag in front
PASS only kept terms: nothing to translate
PASS network engines get the whole line
PASS offline: an unknown cue is translated too
PASS and put back
ALL PASSED (0 failed)
PASS a word as one piece, then </s>
PASS the best-scoring cut (one piece beats go+ing)
PASS whitespace collapsed, punctuation its own piece
PASS an unknown character is <unk>
PASS consecutive unknowns are fused
PASS a language token found by its text
PASS decoded: specials left out, U+2581 to spaces
ALL PASSED (0 failed)
PASS on-screen text source selectable
PASS picture not read while translation is off
PASS enabled source asks the engine to read the picture
PASS auto source reads English in the centred bottom band
2026-11-21T15:56:04.680Z t=7612 [INFO ] [live-translation] request provider=1 source=1 http=200 error=0 ms=78 chars=21 line=current
PASS on-screen line translated through the selected service
PASS right-to-left reply decoded
PASS the line is shown with its translation
PASS a line gone from the picture keeps its translation a moment (time to read it)
PASS then its translation is taken down
PASS a repeated line is shown at once from the recent translations without a new request
PASS an OCR error clears the line and shows as the status
PASS custom region kept inside the picture
PASS disabling stops reading the picture
PASS the last read is offered as a preview
2026-11-21T15:56:08.249Z t=7612 [INFO ] [live-translation] request provider=1 source=1 http=200 error=0 ms=1568 chars=22 line=earlier
PASS the first line's translation is shown although it came after the line left
2026-11-21T15:56:08.515Z t=7612 [INFO ] [live-translation] request provider=1 source=1 http=200 error=0 ms=188 chars=20 line=current
PASS then the second line's translation follows
PASS the first request was not aborted and the second waited for it
PASS a line that comes back is shown from the recent translations
2026-11-21T15:56:14.152Z t=7612 [INFO ] [live-translation] request provider=1 source=1 http=200 error=0 ms=1558 chars=23 line=earlier
2026-11-21T15:56:14.417Z t=7612 [INFO ] [live-translation] request provider=1 source=1 http=200 error=0 ms=187 chars=17 line=current
PASS a translator behind the dialogue goes on with the line on screen now
2026-11-21T15:56:17.403Z t=7612 [INFO ] [live-translation] request provider=3 source=1 http=429 error=299 ms=640 chars=51 line=current
2026-11-21T15:56:18.954Z t=7612 [INFO ] [live-translation] request provider=2 source=1 http=200 error=0 ms=1300 chars=51 line=current
GOOGLE PASS 2.85 s status=\u5b9e\u65f6\u7ffb\u8bd1\u8fd0\u884c\u4e2d chars=43 arabic=34
PASS M$M! build starts with VI Translator's offline translator
2026-11-21T15:56:19.330Z t=7648 [INFO ] [opus-mt] model loaded vocab=62802 unk=2 pad=62801 eos=0 prefix=4 specials=3 threads=1 enc_inputs=2 dec_inputs=3
2026-11-21T15:56:19.610Z t=7612 [INFO ] [live-translation] request provider=4 source=1 parts=1 ms=201 chars=51 line=current ok=true
OFFLINE PASS 0.65 s arabic=29
2026-11-21T15:56:20.032Z t=7612 [INFO ] [live-translation] request provider=4 source=1 parts=1 ms=198 chars=52 line=current ok=true
OFFLINE PASS 2.88 s arabic=36
2026-11-21T15:56:23.034Z t=7612 [INFO ] [live-translation] request provider=4 source=1 parts=1 ms=134 chars=25 line=current ok=true
OFFLINE PASS 2.96 s arabic=16
2026-11-21T15:56:26.209Z t=7612 [INFO ] [live-translation] request provider=4 source=1 parts=1 ms=134 chars=42 line=current ok=true
OFFLINE PASS 2.00 s arabic=26
2026-11-21T15:56:28.446Z t=7612 [INFO ] [live-translation] request provider=4 source=1 parts=2 ms=185 chars=41 line=current ok=true
OFFLINE PASS 2.52 s arabic=22
2026-11-21T15:56:31.166Z t=7612 [INFO ] [live-translation] request provider=4 source=1 parts=1 ms=158 chars=39 line=current ok=true
OFFLINE PASS 2.53 s arabic=25
OFFLINE PASS 2.42 s arabic=10
2026-11-21T15:56:36.498Z t=7612 [INFO ] [live-translation] request provider=4 source=1 parts=1 ms=135 chars=32 line=current ok=true
OFFLINE PASS 1.44 s arabic=28
PASS every line translated into Arabic offline
SKIP Live Captions unavailable on this Windows build
veyra_live_translation_tests exit 77
```

## 3-package.log

### errors
```
WARNING: api-ms-win-core-processenvironment-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-file-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-handle-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-errorhandling-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-processthreads-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-processthreads-l1-1-3.dll not found for the package
WARNING: api-ms-win-core-sysinfo-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-memory-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-libraryloader-l1-2-0.dll not found for the package
WARNING: api-ms-win-core-heap-l2-1-0.dll not found for the package
WARNING: api-ms-win-shcore-obsolete-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-toolhelp-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-synch-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-kernel32-legacy-l1-1-5.dll not found for the package
WARNING: api-ms-win-ntuser-sysparams-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-synch-l1-2-0.dll not found for the package
WARNING: api-ms-win-core-file-l2-1-0.dll not found for the package
WARNING: api-ms-win-core-namedpipe-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-processthreads-l1-1-1.dll not found for the package
WARNING: api-ms-win-core-psapi-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-string-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-job-l2-1-0.dll not found for the package
WARNING: api-ms-win-core-largeinteger-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-rtlsupport-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-synch-l1-2-1.dll not found for the package
WARNING: api-ms-win-core-profile-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-localization-l1-2-0.dll not found for the package
WARNING: api-ms-win-core-com-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-registry-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-file-l1-2-2.dll not found for the package
WARNING: api-ms-win-core-file-l2-1-2.dll not found for the package
WARNING: api-ms-win-core-sysinfo-l1-2-0.dll not found for the package
WARNING: api-ms-win-core-threadpool-l1-2-0.dll not found for the package
WARNING: api-ms-win-core-util-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-debug-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-interlocked-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-heap-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-fibers-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-datetime-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-console-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-timezone-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-winrt-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-winrt-error-l1-1-1.dll not found for the package
```

### tail
```
package root D:\deps\official-x\Veyra-2.2.0-NVIDIA-win64-portable; program folder D:\stage\MMM-2.2.0-NVIDIA\versions\2.2.0
  root versions
  root current-version.txt
  root portable-package.txt
  root portable-update-trust.json
  root START-HERE.txt
  root Veyra.exe
offline translator 124 MB
shaders replaced: 72
WARNING: api-ms-win-core-processenvironment-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-file-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-handle-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-errorhandling-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-processthreads-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-processthreads-l1-1-3.dll not found for the package
WARNING: api-ms-win-core-sysinfo-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-memory-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-libraryloader-l1-2-0.dll not found for the package
WARNING: api-ms-win-core-heap-l2-1-0.dll not found for the package
WARNING: api-ms-win-shcore-obsolete-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-toolhelp-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-synch-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-kernel32-legacy-l1-1-5.dll not found for the package
WARNING: api-ms-win-ntuser-sysparams-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-synch-l1-2-0.dll not found for the package
WARNING: api-ms-win-core-file-l2-1-0.dll not found for the package
WARNING: api-ms-win-core-namedpipe-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-processthreads-l1-1-1.dll not found for the package
WARNING: api-ms-win-core-psapi-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-string-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-job-l2-1-0.dll not found for the package
WARNING: api-ms-win-core-largeinteger-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-rtlsupport-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-synch-l1-2-1.dll not found for the package
WARNING: api-ms-win-core-profile-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-localization-l1-2-0.dll not found for the package
WARNING: api-ms-win-core-com-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-registry-l1-1-0.dll not found for the package
added libcrypto-3-x64.dll from C:\Program Files\OpenSSL
WARNING: api-ms-win-core-file-l1-2-2.dll not found for the package
WARNING: api-ms-win-core-file-l2-1-2.dll not found for the package
WARNING: api-ms-win-core-sysinfo-l1-2-0.dll not found for the package
WARNING: api-ms-win-core-threadpool-l1-2-0.dll not found for the package
WARNING: api-ms-win-core-util-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-debug-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-interlocked-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-heap-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-fibers-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-datetime-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-console-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-timezone-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-winrt-l1-1-0.dll not found for the package
WARNING: api-ms-win-core-winrt-error-l1-1-1.dll not found for the package
package D:\stage\MMM-2.2.0-NVIDIA.zip 763 MB sha256 EE3E7D3C2C6B89DF02CA6982FF36BDA9A364319646A149E3BFD286E1F2998810
update D:\stage\MMM-update.zip 85.7 MB
```

## 4-shots.log

### errors
```
```

### tail
```
shot 1-home: 1366x820 printwindow=True -> D:\logs\shots\1-home.png
shot 2-settings: 1366x820 printwindow=True -> D:\logs\shots\2-settings.png
shot 3-pro: 1366x820 printwindow=True -> D:\logs\shots\3-pro.png
shot 4-pro-colour: 1366x820 printwindow=True -> D:\logs\shots\4-pro-colour.png
shot 5-minimal: 1366x666 printwindow=True -> D:\logs\shots\5-minimal.png
shot 9-capture: 1366x820 printwindow=True -> D:\logs\shots\9-capture.png
shot 10-pro-display: 1366x820 printwindow=True -> D:\logs\shots\10-pro-display.png
shot 6-translation: 1366x820 printwindow=True -> D:\logs\shots\6-translation.png
shot 7-export: 1366x820 printwindow=True -> D:\logs\shots\7-export.png
shot 8-pro-fg: 1366x820 printwindow=True -> D:\logs\shots\8-pro-fg.png
shot 11-home-sky: 1366x820 printwindow=True -> D:\logs\shots\11-home-sky.png
shot 12-menu: 1366x820 printwindow=True -> D:\logs\shots\12-menu.png
shot 13-min-dock: 1366x666 printwindow=True -> D:\logs\shots\13-min-dock.png
shot 14-settings-play: 1366x820 printwindow=True -> D:\logs\shots\14-settings-play.png
shot 15-export-dialog: 1366x820 printwindow=True -> D:\logs\shots\15-export-dialog.png
```

## 5-offline-samples.log

### errors
```
```

### tail
```
OK 0.65 s | We need to get out of here before the cops show up. | يجب أن نخرج من هنا قبل أن تأتي الشرطة
OK 2.88 s | Jason: [laughs] C'mon, you know I'd never leave you. | جيسون: [يضحك] هيا، أنت تعرف أنني لن أتركك أبداً
OK 2.96 s | Press X to open the door. | اضغط على X لفتح الباب.
OK 2.00 s | Lucia: Where the hell were you last night? | لوسيا: أين كنتِ الليلة الماضية؟
OK 2.52 s | I don't trust him. He's hiding something. | أنا لا أثق به إنه يخفي شيئاً
OK 2.53 s | Follow the car, but keep your distance. | اتبع السيارة، ولكن ابق بعيداً
OK 2.42 s | [phone ringing] | [رنين الهاتف]
OK 1.44 s | Cop: Hands where I can see them! | الشرطي: ضع يديك حيث أستطيع رؤيتهما
```

