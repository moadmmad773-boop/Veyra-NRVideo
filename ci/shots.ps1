# Screenshots of the built program's pages, for reviewing the look without a
# Windows desktop of our own. Runs the packaged program with a private data folder
# (the user's settings are never touched), captures its window with PrintWindow
# (PW_RENDERFULLCONTENT, independent of z-order) and saves PNGs next to the logs.
$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;using System.Runtime.InteropServices;
public class Shot {
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc f, IntPtr p);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  delegate bool EnumProc(IntPtr h, IntPtr p);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  public static IntPtr Largest(uint want) {
    IntPtr best = IntPtr.Zero; long area = 0;
    EnumWindows((h, p) => {
      uint pid; GetWindowThreadProcessId(h, out pid);
      if (pid != want || !IsWindowVisible(h)) return true;
      RECT r; if (!GetWindowRect(h, out r)) return true;
      long a = (long)(r.Right - r.Left) * (r.Bottom - r.Top);
      if (a > area) { area = a; best = h; }
      return true;
    }, IntPtr.Zero);
    return best;
  }
}
"@
$exe = Join-Path $env:PKG_APP 'veyra_qml_ui.exe'
$out = Join-Path $env:LOGS 'shots'
New-Item -ItemType Directory -Force $out | Out-Null
$shots = @(
    @{ name = '1-home'; args = @('--page', 'home') },
    @{ name = '2-settings'; args = @('--page', 'set') },
    @{ name = '3-pro'; args = @('--page', 'pro', '--video-probe', 'hidden') },
    @{ name = '4-pro-colour'; args = @('--page', 'pro', '--tab', 'color', '--video-probe', 'hidden') },
    @{ name = '5-minimal'; args = @('--page', 'min') },
    @{ name = '9-capture'; args = @('--page', 'pro', '--dialog', 'capture', '--video-probe', 'hidden') },
    @{ name = '10-pro-display'; args = @('--page', 'pro', '--tab', 'display', '--video-probe', 'hidden') },
    @{ name = '6-translation'; args = @('--page', 'set', '--dialog', 'translation') },
    @{ name = '7-export'; args = @('--page', 'exp') },
    @{ name = '8-pro-fg'; args = @('--page', 'pro', '--tab', 'fg', '--video-probe', 'hidden') },
    @{ name = '11-home-sky'; args = @('--page', 'home', '--pref-at', '300', 'palette', 'sky') },
    @{ name = '12-menu'; args = @('--page', 'pro', '--menu', 'source', '--video-probe', 'hidden') },
    @{ name = '13-min-dock'; args = @('--page', 'min', '--dock-pinned') },
    @{ name = '14-settings-play'; args = @('--page', 'set', '--pref-at', '300', 'palette', 'frost') }
)
foreach ($s in $shots) {
    $data = Join-Path $env:RUNNER_TEMP ("shot-data-" + $s.name)
    New-Item -ItemType Directory -Force $data | Out-Null
    # --managed-portable first, as the launcher starts it: otherwise the program hands
    # itself over to the launcher and this script would wait on the wrong process.
    $argv = @('--managed-portable', '--data-dir', $data, '--size', '1366x820', '--reduced-motion', '--exit-after', '30000') + $s.args
    $p = Start-Process -FilePath $exe -ArgumentList $argv -PassThru -WorkingDirectory $env:PKG_APP
    $h = [IntPtr]::Zero
    for ($i = 0; $i -lt 40 -and $h -eq [IntPtr]::Zero; $i++) { Start-Sleep -Milliseconds 500; if ($p.HasExited) { break }; $h = [Shot]::Largest([uint32]$p.Id) }
    if ($h -eq [IntPtr]::Zero) {
        Write-Host "shot $($s.name): no window (exited=$($p.HasExited) code=$($p.ExitCode))"
        if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
        continue
    }
    [Shot]::SetForegroundWindow($h) | Out-Null
    Start-Sleep -Seconds 10
    $r = New-Object Shot+RECT
    [Shot]::GetWindowRect($h, [ref]$r) | Out-Null
    $w = $r.Right - $r.Left; $hgt = $r.Bottom - $r.Top
    if ($w -le 0 -or $hgt -le 0) { Write-Host "shot $($s.name): empty window"; continue }
    $bmp = New-Object System.Drawing.Bitmap $w, $hgt
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $dc = $g.GetHdc()
    $ok = [Shot]::PrintWindow($h, $dc, 2)
    $g.ReleaseHdc($dc); $g.Dispose()
    $file = Join-Path $out "$($s.name).png"
    $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
    Write-Host "shot $($s.name): ${w}x${hgt} printwindow=$ok -> $file"
    if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Milliseconds 500
}
# The program's own log (package root\logs), for errors behind a missing window.
$root = Split-Path (Split-Path $env:PKG_APP -Parent) -Parent
Get-ChildItem (Join-Path $root 'logs') -Filter *.log -ErrorAction SilentlyContinue | ForEach-Object {
    Get-Content $_.FullName -Tail 400 | Set-Content (Join-Path $out ("app-" + $_.Name)) -Encoding utf8
}
exit 0
