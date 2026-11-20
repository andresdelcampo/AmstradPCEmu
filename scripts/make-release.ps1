<#
.SYNOPSIS
  Build a distributable folder: binaries, license texts, notices and the complete
  corresponding source (GPL), under local\release\.
.DESCRIPTION
  Run scripts\build.ps1 first. Does not include ROMs, disks or VM state.
#>
[CmdletBinding()]
param([string]$Version = (Get-Date -Format 'yyyy.MM.dd'))
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$name = "AmstradPCEmu-$Version"
$out = Join-Path $root "local\release\$name"
$dist = Join-Path $root 'local\dist'
if (!(Test-Path -LiteralPath (Join-Path $dist '86Box.exe'))) { throw 'Build first: local\dist\86Box.exe is missing.' }
if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Recurse -Force }
New-Item -ItemType Directory -Path "$out\local" | Out-Null

# Refresh generated artefacts so the release matches the tree.
python (Join-Path $PSScriptRoot 'export-patch.py') | Out-Null
python (Join-Path $PSScriptRoot 'gen-third-party-notices.py') | Out-Null

# Binaries (mirror the repo layout the launcher expects); skip dev backup executables.
robocopy $dist "$out\local\dist" /E /XF '86Box-before-*.exe' /NFL /NDL /NJH /NJS /NP | Out-Null
$launcher = Join-Path $root 'Amstrad PC1512.exe'
if (!(Test-Path -LiteralPath $launcher)) { throw 'Build first: Amstrad PC1512.exe is missing.' }
Copy-Item -LiteralPath $launcher -Destination $out

# What the launcher and emulator read at run time, relative to the launcher:
# the first-launch VM setup and the cabinet artwork. Tracked files only, without
# source masters, archived art, comparison previews, notes, layout JSON or the
# icon (built into the executables).
New-Item -ItemType Directory -Path "$out\scripts" | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'scripts\prepare-vm.ps1') -Destination "$out\scripts"
foreach ($file in git -C $root ls-files assets/front) {
    if ($file -match '/(archive|masters|previews)/' -or $file -match '\.(md|json|ico)$') { continue }
    $target = Join-Path $out ($file -replace '/', '\')
    New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
    Copy-Item -LiteralPath (Join-Path $root $file) -Destination $target
}

# Empty ROM folders for the user's own firmware.
foreach ($folder in 'machines\pc1512', 'machines\pc1640', 'hdd\st506') {
    New-Item -ItemType Directory -Force -Path "$out\roms\$folder" | Out-Null
}
@'
Put your own ROMs here; they are not included. They are the same files, with
the same names and folders, as in 86Box's ROM set (https://github.com/86Box/roms);
copying the whole roms folder of an 86Box installation also works.

  machines\pc1512\  40043, 40044, 40078                 (8 KB each)
  machines\pc1640\  40043.v3, 40044.v3 (16 KB each), 40100 (32 KB)
  hdd\st506\        wd1002a_wx1-62-000094-032.bin       (8 KB, HD20 hard disk controller)

Only the PC1512 ROMs are needed to start. The PC1640 and HD20 ROMs are only
needed to run those configurations.
'@ | Set-Content -LiteralPath "$out\roms\README.txt" -Encoding ASCII

# Licences and notices.
foreach ($f in 'LICENSE','README.md','UPSTREAM.md','CHANGES.md','THIRD-PARTY-NOTICES.md') {
    Copy-Item -LiteralPath (Join-Path $root $f) -Destination $out
}
Copy-Item -LiteralPath (Join-Path $root 'upstream\86Box\COPYING') -Destination (Join-Path $out 'COPYING-86Box')
Copy-Item -LiteralPath (Join-Path $root 'assets\shaders\COPYING-IBMulator') -Destination $out
Copy-Item -LiteralPath (Join-Path $root 'assets\shaders\NOTICE-IBMulator.md') -Destination $out

# Complete corresponding source: tracked project files + patched 86Box tree.
$src = Join-Path $out 'source'
New-Item -ItemType Directory -Path $src | Out-Null
$project = Join-Path $env:TEMP "$name-project.zip"
git -C $root archive --format=zip -o $project HEAD
Expand-Archive -LiteralPath $project -DestinationPath $src -Force
Remove-Item -LiteralPath $project
robocopy (Join-Path $root 'upstream\86Box') (Join-Path $src 'upstream\86Box') /E /XD .git build /NFL /NDL /NJH /NJS /NP | Out-Null
$zip = Join-Path $root "local\release\$name-source.zip"
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip }
Compress-Archive -Path "$src\*" -DestinationPath $zip -CompressionLevel Optimal
Remove-Item -LiteralPath $src -Recurse -Force
Write-Host "Release folder: $out"
Write-Host "Source archive: $zip"
Write-Host 'Reminder: commit first so the source matches; ROMs, disks and VM state are not included.'
