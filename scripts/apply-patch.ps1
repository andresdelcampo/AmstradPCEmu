$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$source = Join-Path $root 'upstream\86Box'
$patch = Join-Path $root 'patches\86box-pc1512.patch'
$revision = & git -C $source rev-parse HEAD
if ($LASTEXITCODE -or $revision -ne '978030cd0dc626bab794e74c8ddaa512c1a9fcc9') { throw 'Use the pinned 86Box revision from README.md.' }
$savedPreference = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    & git -C $source apply --reverse --check $patch 2>$null
    $alreadyApplied = $LASTEXITCODE -eq 0
} finally { $ErrorActionPreference = $savedPreference }
if ($alreadyApplied) { Write-Output 'Patch already applied.'; exit 0 }
& git -C $source apply --check $patch
if ($LASTEXITCODE) { throw 'Patch does not apply cleanly. Preserve local changes and inspect the source checkout.' }
& git -C $source apply $patch
if ($LASTEXITCODE) { throw 'Patch application failed.' }
