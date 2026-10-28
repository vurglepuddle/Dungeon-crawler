$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repo
$builder=Start-Process E:/SD/GODOT/Godot.exe -ArgumentList @('--headless','--path','.', '--quit-after','600','-s','res://tests/build_m4b_gallery.gd') -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput build/m4b_gallery_build.log -RedirectStandardError build/m4b_gallery_build.err
if ($builder.ExitCode -ne 0 -or (Select-String -LiteralPath build/m4b_gallery_build.err -Pattern 'SCRIPT ERROR:' -Quiet)) {throw 'Gallery fixture builder failed'}
New-Item -ItemType Directory -Force build/m4b_shots/after | Out-Null
$process=Start-Process E:/SD/GODOT/Godot.exe -ArgumentList @('--path','.', '-s','res://tests/capture_m4b.gd','--resolution','462x1026','--','--pilot=res://tests/pilot/m4b_gallery.txt','--out=build/m4b_shots/after','--save-path=user://tests/m4b_gallery_only.json','--timeout=180') -WindowStyle Hidden -PassThru -Wait -RedirectStandardOutput build/m4b_after.log -RedirectStandardError build/m4b_after.err
if ($process.ExitCode -ne 0 -or (Select-String -LiteralPath build/m4b_after.err -Pattern 'SCRIPT ERROR:|Invalid gallery fixture' -Quiet)) {throw 'Gallery failed'}
$samples=Get-Content -LiteralPath build/m4b_gallery_samples.json -Raw | ConvertFrom-Json
foreach ($name in $samples.PSObject.Properties.Name) {
    if (-not (Test-Path -LiteralPath "build/m4b_shots/after/$name.png")) {throw "Missing sample $name"}
}
python tests/build_m4b_sheet.py
if ($LASTEXITCODE -ne 0) {throw 'Comparison sheet build failed'}
Write-Output '45 authored visual fixtures captured; comparison sheets complete.'
