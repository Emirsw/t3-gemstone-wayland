$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$required = @(
  'Taskfile.yml',
  'docker/Dockerfile',
  'packages/mesa-pvr/source.lock',
  'packages/kpipewire/source.lock',
  'packages/krfb/source.lock',
  'packages/kpipewire/patches/0001-t3-pvr-add-opt-in-shm-capture.patch',
  'packages/krfb/patches/0001-t3-pvr-correct-inverted-pipewire-frames.patch',
  'packages/krfb/patches/0002-t3-pvr-copy-damaged-rows-directly.patch',
  'packages/krfb/patches/0003-t3-pvr-enable-pipewire-damage-tracking.patch',
  'packages/chromium-v4l2-wave5/args.gn',
  'packages/chromium-v4l2-wave5/build.sh',
  'packages/chromium-v4l2-wave5/patches/0001-media-gpu-v4l2-Use-ChromeOS-style-dev-paths-for-all-.patch'
)

foreach ($item in $required) {
  if (-not (Test-Path -LiteralPath (Join-Path $root $item))) {
    throw "Required repository file is missing: $item"
  }
}

$forbidden = Get-ChildItem -LiteralPath $root -Recurse -File |
  Where-Object { $_.Name -match '\.(deb|key|pem)$' }
if ($forbidden) {
  throw "Generated package or secret-like file found in source tree: $($forbidden.FullName -join ', ')"
}

$chromiumPatchCount = @(
  Get-ChildItem -LiteralPath (Join-Path $root 'packages/chromium-v4l2-wave5/patches') `
    -Filter '*.patch' -File
).Count
if ($chromiumPatchCount -ne 4) {
  throw "Expected 4 Chromium Wave5 patches, found $chromiumPatchCount"
}

Write-Host 'Repository structure: OK'
