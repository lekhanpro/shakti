<# Creates honest source snapshots without changing Git history or the working tree. #>
[CmdletBinding()]
param(
  [ValidateSet('Create','List','Extract')][string]$Action = 'List',
  [ValidateRange(1,4)][int]$Week = 1,
  [string]$Archive,
  [string]$Destination,
  [string]$Repository = (Split-Path $PSScriptRoot -Parent)
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = (Resolve-Path -LiteralPath $Repository).Path
$store = Join-Path $root 'output/review-checkpoints'
function Get-Sha([byte[]]$Bytes) {
  $hash = [System.Security.Cryptography.SHA256]::Create()
  try { return ([BitConverter]::ToString($hash.ComputeHash($Bytes))).Replace('-','').ToLowerInvariant() }
  finally { $hash.Dispose() }
}
function Test-Allowed([string]$Path) {
  if ($Path -match '(^|/)(\.git|node_modules|\.next|\.dart_tool|\.gradle|build|coverage|tmp|output|\.vercel|\.idea|\.vscode|\.supabase)(/|$)') { return $false }
  if ($Path -match '(^|/)(\.env($|\.)|key\.properties$|local\.properties$|credentials|secrets|service[-_]?account|google-services\.json$)' -or $Path -match '\.(jks|keystore|pem|key|p12|pfx|apk|aab|zip|log|db|sqlite|mp3|m4a|aac|wav)$') { return $false }
  if ($Path -match '(^|/)(consent|participants|field-evidence|raw-evidence)(/|$)') { return $false }
  return $true
}
if ($Action -eq 'List') {
  if (Test-Path -LiteralPath $store) { Get-ChildItem -LiteralPath $store -Filter '*.zip' | Select-Object Name,Length,LastWriteTimeUtc }
  return
}
if ($Action -eq 'Extract') {
  if (!$Archive -or !$Destination) { throw 'Extract requires Archive and a new Destination directory.' }
  $archivePath = (Resolve-Path -LiteralPath $Archive).Path
  $target = [IO.Path]::GetFullPath($Destination)
  if (Test-Path -LiteralPath $target) { throw 'Destination already exists; choose a new review-copy directory.' }
  $zip = [IO.Compression.ZipFile]::OpenRead($archivePath)
  try {
    $manifestEntry = $zip.GetEntry('checkpoint-manifest.json')
    if (!$manifestEntry) { throw 'Archive has no checkpoint manifest.' }
    $reader = [IO.StreamReader]::new($manifestEntry.Open())
    try { $manifest = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
    $expected = @{}
    foreach ($file in $manifest.files) {
      if ($expected.ContainsKey($file.path)) { throw 'Duplicate manifest path.' }
      $expected[$file.path] = $file.sha256
    }
    # Validate every member before creating a destination. Reject traversal and duplicates.
    $seen = @{}
    foreach ($entry in $zip.Entries) {
      $name = $entry.FullName
      if ($seen.ContainsKey($name)) { throw 'Duplicate archive entry.' }
      $seen[$name] = $true
      if ($name -match '(^|[/\\])\.\.([/\\]|$)|[:\\]' -or $name.StartsWith('/')) { throw 'Unsafe archive entry.' }
      $resolved = [IO.Path]::GetFullPath((Join-Path $target $name))
      if (!$resolved.StartsWith($target.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Archive path escapes destination.' }
      if ($name -eq 'checkpoint-manifest.json') { continue }
      if (!(Test-Allowed $name) -or !$expected.ContainsKey($name)) { throw 'Unexpected or excluded archive entry.' }
      $memory = [IO.MemoryStream]::new()
      $stream = $entry.Open()
      try { $stream.CopyTo($memory); $actual = Get-Sha $memory.ToArray() } finally { $stream.Dispose(); $memory.Dispose() }
      if ($actual -ne $expected[$name]) { throw "Checksum mismatch: $name" }
    }
    if ($seen.Count -ne ($expected.Count + 1)) { throw 'Archive is missing manifest files.' }
    New-Item -ItemType Directory -Path $target | Out-Null
    foreach ($entry in $zip.Entries) {
      $path = Join-Path $target $entry.FullName
      [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path)) | Out-Null
      [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $path, $false)
    }
    Write-Output "Verified review copy: $target"
  } finally { $zip.Dispose() }
  return
}
$repoCheck = & git -C $root rev-parse --show-toplevel
if ($LASTEXITCODE -ne 0 -or [IO.Path]::GetFullPath($repoCheck) -ne [IO.Path]::GetFullPath($root)) { throw 'Repository must be its Git root.' }
$head = & git -C $root rev-parse HEAD
if ($LASTEXITCODE -ne 0) { throw 'Cannot read Git HEAD.' }
$dirty = [bool](& git -C $root status --porcelain)
$paths = @(& git -C $root -c core.quotepath=false ls-files --cached --others --exclude-standard | Sort-Object -Unique)
if ($LASTEXITCODE -ne 0) { throw 'Cannot enumerate repository files.' }
$stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
[IO.Directory]::CreateDirectory($store) | Out-Null
$archivePath = Join-Path $store "week-$Week-$stamp.zip"
$zip = [IO.Compression.ZipFile]::Open($archivePath, [IO.Compression.ZipArchiveMode]::Create)
$records = @()
try {
  foreach ($relative in $paths) {
    if (!(Test-Allowed $relative)) { continue }
    $path = Join-Path $root $relative
    if (!(Test-Path -LiteralPath $path -PathType Leaf)) { continue } # deleted tracked files stay deleted
    $item = Get-Item -LiteralPath $path
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked file requires review: $relative" }
    if ($item.Length -gt 25MB) { throw "Oversized source file requires review: $relative" }
    $bytes = [IO.File]::ReadAllBytes($path)
    if ($relative -match '\.(dart|kt|kts|ts|tsx|js|json|yaml|yml|toml|sql|md|ps1|properties|xml|txt)$') {
      $content = [Text.Encoding]::UTF8.GetString($bytes)
      if ($content -match '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{30,}|eyJ[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{15,}') { throw "Possible embedded credential; review $relative before snapshotting." }
    }
    $entry = $zip.CreateEntry($relative, [IO.Compression.CompressionLevel]::Optimal)
    $stream = $entry.Open()
    try { $stream.Write($bytes,0,$bytes.Length) } finally { $stream.Dispose() }
    $records += [ordered]@{path=$relative;sha256=(Get-Sha $bytes);bytes=$bytes.Length}
  }
  $manifest = [ordered]@{format=1;week=$Week;capturedUtc=$stamp;gitHead=$head;hasUncommittedChanges=$dirty;meaning='Current source review snapshot; not a historical week reconstruction';files=$records}
  $entry = $zip.CreateEntry('checkpoint-manifest.json')
  $writer = [IO.StreamWriter]::new($entry.Open(), [Text.UTF8Encoding]::new($false))
  try { $writer.Write(($manifest | ConvertTo-Json -Depth 6)) } finally { $writer.Dispose() }
} catch {
  $zip.Dispose()
  # Preserve failed output for diagnosis; it has no valid manifest and cannot be extracted by this script.
  throw
} finally { $zip.Dispose() }
$hash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Output "Checkpoint: $archivePath"
Write-Output "SHA256: $hash"
Write-Output "Files: $($records.Count); Git HEAD: $head; uncommitted changes: $dirty"
