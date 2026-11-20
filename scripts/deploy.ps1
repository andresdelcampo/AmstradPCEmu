[CmdletBinding()]
param(
    [string]$Toolchain = 'C:\msys64\mingw64',
    [string]$Destination = '',
    [string]$FloppySoundSource = 'C:\Emulators\86Box\assets\sounds\fdd',
    [string]$HardDiskSoundSource = 'C:\Emulators\86Box\assets\sounds\hdd'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (!$Destination) { $Destination = Join-Path $root 'local\dist' }
$bin = Join-Path $Toolchain 'bin'
$exe = Join-Path $root 'local\build\src\86Box.exe'
$objdump = Join-Path $bin 'objdump.exe'
# Qt helpers can keep an unchanged runtime DLL mapped after the emulator exits.
# Avoid overwriting identical modules; a genuinely changed locked DLL still fails.
function Copy-RuntimeModule([string]$Source, [string]$Target) {
    if ([IO.File]::Exists($Target) -and ([IO.FileInfo]$Source).Length -eq ([IO.FileInfo]$Target).Length) {
        $sha = [Security.Cryptography.SHA256]::Create()
        try {
            $sourceHash = [BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($Source)))
            $targetHash = [BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($Target)))
            if ($sourceHash -eq $targetHash) { return }
        } finally { $sha.Dispose() }
    }
    Copy-Item -LiteralPath $Source -Destination $Target -Force
}
if (!(Test-Path -LiteralPath $exe)) { throw "Build first: $exe is missing." }
# Keep the original profile table, samples and attribution together. The core
# resolves assets/sounds/fdd relative to the executable's assets directory.
$profiles = Join-Path $FloppySoundSource 'fdd_audio_profiles.cfg'
if (!(Test-Path -LiteralPath $profiles)) {
    throw "Floppy sound profiles missing: $profiles. Supply the 86Box floppy sound assets with -FloppySoundSource."
}
$profileText = Get-Content -LiteralPath $profiles -Raw
# Only the drives the emulator uses are deployed (and so released): a table with
# the "None" profile and that drive's profile, and just the files it references.
function Select-Profile([string]$Text, [string]$InternalName) {
    $pattern = '(?ms)^\[Profile "\d+"\][^\[]*?^internal_name\s*=\s*' + [regex]::Escape($InternalName) + '\s*$.*?(?=^\[|\z)'
    return [regex]::Match($Text, $pattern)
}
function Select-Table([string]$Text, [string]$Section) {
    $header = $Text.Substring(0, $Text.IndexOf('[Profile'))
    $none = (Select-Profile $Text 'none').Value
    return $header + $none.TrimEnd() + "`r`n`r`n" + $Section.TrimEnd() + "`r`n"
}
$panasonic = Select-Profile $profileText 'panasonic_ju4755_40t'
if (!$panasonic.Success) {
    throw "The floppy sound assets do not include Panasonic JU-475-5 40-track audio: $profiles"
}
$fddText = Select-Table $profileText $panasonic.Value
$fddFiles = foreach ($match in [regex]::Matches($panasonic.Value, '(?m)^\w+_file\s*=\s*assets/sounds/fdd/([^\r\n]+)')) {
    $relative = $match.Groups[1].Value.Trim()
    if (!(Test-Path -LiteralPath (Join-Path $FloppySoundSource $relative) -PathType Leaf)) {
        throw "Floppy sound sample missing: $(Join-Path $FloppySoundSource $relative)"
    }
    $relative
}
# The HD20 uses the Miniscribe 8425 (1987, 20 MB, 3600 RPM MFM) recordings.
$hddProfiles = Join-Path $HardDiskSoundSource 'hdd_audio_profiles.cfg'
if (!(Test-Path -LiteralPath $hddProfiles)) {
    throw "Hard disk sound profiles missing: $hddProfiles. Supply the 86Box hard disk sound assets with -HardDiskSoundSource."
}
$hddText = Get-Content -LiteralPath $hddProfiles -Raw
$miniscribe = Select-Profile $hddText 'MINISCRIBE_8425_3600RPM'
if (!$miniscribe.Success) { throw "The hard disk sound assets do not include Miniscribe 8425 audio: $hddProfiles" }
# The upstream table plays the spin-up recording on spin-down although the
# set includes a spin-down recording; use it when present.
$spindown = 'assets/sounds/hdd/1987 Miniscribe 8425/1987_Miniscribe 8425_3600RPM_SPINDOWN.wav'
if (Test-Path -LiteralPath (Join-Path $HardDiskSoundSource ($spindown -replace '^assets/sounds/hdd/', ''))) {
    $fixed = $miniscribe.Value -replace '(?m)^(spindlemotor_stop_file\s*=\s*).*SPINUP\.wav\s*$', "`${1}$spindown"
    $hddText = $hddText.Remove($miniscribe.Index, $miniscribe.Length).Insert($miniscribe.Index, $fixed)
    $miniscribe = [regex]::Match($hddText, [regex]::Escape($fixed))
}
$hddTable = Select-Table $hddText $miniscribe.Value
$hddFiles = foreach ($match in [regex]::Matches($miniscribe.Value, '(?m)^\w+_file\s*=\s*assets/sounds/hdd/([^\r\n]+)')) {
    $relative = $match.Groups[1].Value.Trim()
    if (!(Test-Path -LiteralPath (Join-Path $HardDiskSoundSource $relative) -PathType Leaf)) {
        throw "Hard disk sound sample missing: $(Join-Path $HardDiskSoundSource $relative)"
    }
    $relative
}
New-Item -ItemType Directory -Force -Path $Destination | Out-Null
Copy-Item -LiteralPath $exe -Destination $Destination -Force
# Resolve imported DLLs transitively instead of copying the whole toolchain.
$queue = New-Object 'System.Collections.Generic.Queue[string]'
$queue.Enqueue((Join-Path $Destination '86Box.exe'))
$plugins = Join-Path $Toolchain 'share\qt5\plugins'
foreach ($relative in @('platforms\qwindows.dll', 'platforms\qoffscreen.dll', 'styles\qwindowsvistastyle.dll', 'imageformats\qico.dll')) {
    $source = Join-Path $plugins $relative
    if (Test-Path -LiteralPath $source) {
        $target = Join-Path $Destination $relative
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Copy-RuntimeModule $source $target
        $queue.Enqueue($target)
    }
}
# Freetype is loaded dynamically by the upstream UI; image/audio formats also
# use these libraries outside the executable's immediate import table.
foreach ($name in @('libfreetype-6.dll', 'libsndfile-1.dll')) {
    $source = Join-Path $bin $name
    if (Test-Path -LiteralPath $source) {
        $target = Join-Path $Destination $name
        Copy-RuntimeModule $source $target
        $queue.Enqueue($target)
    }
}
$seen = @{}
while ($queue.Count) {
    $file = $queue.Dequeue()
    if ($seen.ContainsKey($file.ToLowerInvariant())) { continue }
    $seen[$file.ToLowerInvariant()] = $true
    $imports = & $objdump -p $file
    if ($LASTEXITCODE) { throw "Cannot inspect imports: $file" }
    foreach ($line in $imports) {
        if ($line -match 'DLL Name:\s*(\S+)') {
            $name = $Matches[1]
            $source = Join-Path $bin $name
            if (Test-Path -LiteralPath $source) {
                $target = Join-Path $Destination $name
                if (!$seen.ContainsKey($target.ToLowerInvariant())) {
                    Copy-RuntimeModule $source $target
                    $queue.Enqueue($target)
                }
            } elseif (!(Test-Path -LiteralPath (Join-Path $env:SystemRoot "System32\$name")) -and $name -notmatch '^api-ms-') {
                throw "Unresolved runtime dependency $name imported by $file"
            }
        }
    }
}
@('[Paths]', 'Plugins = .') | Set-Content -LiteralPath (Join-Path $Destination 'qt.conf') -Encoding ASCII
Copy-Item -LiteralPath (Join-Path $root 'upstream\86Box\COPYING') -Destination (Join-Path $Destination 'COPYING-86Box') -Force
# Start from an empty sounds folder so drives dropped from the set do not linger.
$sounds = Join-Path $Destination 'assets\sounds'
if (Test-Path -LiteralPath $sounds) { Remove-Item -LiteralPath $sounds -Recurse -Force }
function Copy-Samples([string]$Source, [string]$Target, [string[]]$Files) {
    foreach ($relative in $Files) {
        $to = Join-Path $Target ($relative -replace '/', '\')
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $to) | Out-Null
        Copy-Item -LiteralPath (Join-Path $Source $relative) -Destination $to -Force
    }
}
$soundTarget = Join-Path $sounds 'fdd'
New-Item -ItemType Directory -Force -Path $soundTarget | Out-Null
Copy-Samples $FloppySoundSource $soundTarget $fddFiles
[IO.File]::WriteAllText((Join-Path $soundTarget 'fdd_audio_profiles.cfg'), $fddText)
# 86Box's floppy sound credits (the Panasonic recordings are the project author's).
$credits = Join-Path $FloppySoundSource 'readme.txt'
if (Test-Path -LiteralPath $credits) { Copy-Item -LiteralPath $credits -Destination $soundTarget -Force }
# Project-owned disk insert/eject sounds (Panasonic JU-475-5 recordings).
Copy-Item -LiteralPath (Join-Path $root 'assets\sounds\fdd\amstrad') -Destination $soundTarget -Recurse -Force
$hddTarget = Join-Path $sounds 'hdd'
New-Item -ItemType Directory -Force -Path $hddTarget | Out-Null
Copy-Samples $HardDiskSoundSource $hddTarget $hddFiles
[IO.File]::WriteAllText((Join-Path $hddTarget 'hdd_audio_profiles.cfg'), $hddTable)
New-Item -ItemType Directory -Force -Path (Join-Path $Destination 'shaders') | Out-Null
foreach ($name in @('ibmulator-crt.frag', 'NOTICE-IBMulator.md', 'COPYING-IBMulator')) {
    Copy-Item -LiteralPath (Join-Path $root "assets\shaders\$name") -Destination (Join-Path $Destination 'shaders') -Force
}
Write-Host "Deployed executable and $($seen.Count - 1) runtime modules to $Destination"
