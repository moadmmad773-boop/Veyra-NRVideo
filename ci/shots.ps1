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
    @{ name = '3-pro'; args = @('--page', 'pro') },
    @{ name = '4-pro-colour'; args = @('--page', 'pro', '--tab', 'color') },
    @{ name = '5-minimal'; args = @('--page', 'min') },
    @{ name = '6-translation'; args = @('--page', 'set', '--dialog', 'translation') },
    @{ name = '7-export'; args = @('--page', 'exp') },
    @{ name = '8-pro-fg'; args = @('--page', 'pro', '--tab', 'fg') }
)
foreach ($s in $shots) {
    $data = Join-Path $env:RUNNER_TEMP ("shot-data-" + $s.name)
    New-Item -ItemType Directory -Force $data | Out-Null
    $argv = @('--data-dir', $data, '--size', '1366x820', '--reduced-motion', '--exit-after', '30000') + $s.args
    $p = Start-Process -FilePath $exe -ArgumentList $argv -PassThru -WorkingDirectory $env:PKG_APP
    $h = [IntPtr]::Zero
    for ($i = 0; $i -lt 40 -and $h -eq [IntPtr]::Zero; $i++) { Start-Sleep -Milliseconds 500; if ($p.HasExited) { break }; $h = [Shot]::Largest([uint32]$p.Id) }
    if ($h -eq [IntPtr]::Zero) { Write-Host "shot $($s.name): no window (exited=$($p.HasExited) code=$($p.ExitCode))"; continue }
    [Shot]::SetForegroundWindow($h) | Out-Null
    Start-Sleep -Seconds 7
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
    $log = Get-ChildItem $data -Recurse -Filter *.log -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($log) { Copy-Item $log.FullName (Join-Path $out "$($s.name).log") }
}
exit 0
