$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repo
$inventory=Start-Process E:/SD/GODOT/Godot.exe -ArgumentList @('--headless','--path','.', '-s','res://tests/list_m4b_art.gd') -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput build/m4b_art_inventory.log -RedirectStandardError build/m4b_art_inventory.err
if ($inventory.ExitCode -ne 0 -or (Select-String -LiteralPath build/m4b_art_inventory.err -Pattern 'SCRIPT ERROR:' -Quiet)) {throw 'Runtime art inventory failed'}
python tests/stage_m4b.py
if ($LASTEXITCODE -ne 0) {throw 'Staging failed'}
$pack=Join-Path $repo 'build/m4b_resources.pck'
$process=Start-Process E:/SD/GODOT/Godot.exe -ArgumentList @('--headless','--path','build/m4b_export_stage','--export-pack','Android',$pack) `
    -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput build/m4b_export_pack.log -RedirectStandardError build/m4b_export_pack.err
if ($process.ExitCode -ne 0) {throw 'Resource-pack export failed'}
$script=Join-Path $repo 'tests/probe_m4b_pack.gd'
$process=Start-Process E:/SD/GODOT/Godot.exe -ArgumentList @('--headless','--audio-driver','Dummy','--path','build/m4b_pack_probe','--main-pack',$pack,'-s',$script) `
    -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput build/m4b_pack_test.log -RedirectStandardError build/m4b_pack_test.err
Get-Content -LiteralPath build/m4b_pack_test.log -Tail 1
if ($process.ExitCode -ne 0 -or (Select-String -LiteralPath build/m4b_pack_test.err -Pattern 'SCRIPT ERROR:' -Quiet)) {throw 'Packaged full tour failed'}
