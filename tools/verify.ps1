$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$project = Get-Content -LiteralPath (Join-Path $projectRoot 'default.project.json') -Raw | ConvertFrom-Json
if ($project.tree.'$className' -ne 'DataModel') { throw 'Expected DataModel root' }
$paths = @(
 $project.tree.ReplicatedStorage.CastleFightShared.'$path',
 $project.tree.ServerScriptService.CastleFightServer.'$path',
 $project.tree.StarterPlayer.StarterPlayerScripts.CastleFightClient.'$path'
)
foreach ($path in $paths) {
 if (-not $path -or -not (Test-Path -LiteralPath (Join-Path $projectRoot $path))) { throw "Missing sync path: $path" }
}
foreach ($name in @('GameConfig','UnitConfig','BuildingConfig','CombatConfig')) {
 $path = Join-Path $projectRoot "src/shared/Config/$name.luau"
 $source = [IO.File]::ReadAllText($path)
 # Luau permits line comments and blank lines before its header directive.
 $hasStrictHeader = $false
 foreach ($headerLine in ($source -split '\r?\n')) {
  $trimmedHeader = $headerLine.Trim()
  if ($trimmedHeader -eq '--!strict') { $hasStrictHeader = $true; break }
  if ($trimmedHeader.Length -eq 0 -or $trimmedHeader.StartsWith('--')) { continue }
  break
 }
 if (-not $hasStrictHeader) { throw "Missing strict directive: $name" }
 if ($source -notmatch 'table.freeze') { throw "Expected frozen config: $name" }
}
$files = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'src') -Filter '*.luau' -Recurse
foreach ($file in $files) {
 $bytes = [IO.File]::ReadAllBytes($file.FullName)
 if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) { throw "Unexpected BOM: $($file.Name)" }
}
Write-Output "PASS: JSON, 3 sync paths, 4 strict configs, $($files.Count) Luau files without BOM."
