$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repo
$inventory=Start-Process E:/SD/GODOT/Godot.exe -ArgumentList @('--headless','--path','.', '-s','res://tests/list_m5a_art.gd') -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput build/m5a_art_inventory.log -RedirectStandardError build/m5a_art_inventory.err
if ($inventory.ExitCode -ne 0 -or (Select-String -LiteralPath build/m5a_art_inventory.err -Pattern 'SCRIPT ERROR:' -Quiet)) {throw 'Runtime art inventory failed'}
python tests/stage_m5a.py
if ($LASTEXITCODE -ne 0) {throw 'Staging failed'}
$pack=Join-Path $repo 'build/m5a_resources.pck'
$process=Start-Process E:/SD/GODOT/Godot.exe -ArgumentList @('--headless','--path','build/m5a_export_stage','--export-pack','Android',$pack) `
    -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput build/m5a_export_pack.log -RedirectStandardError build/m5a_export_pack.err
if ($process.ExitCode -ne 0) {throw 'Resource-pack export failed'}
$script=Join-Path $repo 'tests/probe_m5a_pack.gd'
$process=Start-Process E:/SD/GODOT/Godot.exe -ArgumentList @('--headless','--audio-driver','Dummy','--path','build/m5a_pack_probe','--main-pack',$pack,'-s',$script) `
    -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput build/m5a_pack_test.log -RedirectStandardError build/m5a_pack_test.err
Get-Content -LiteralPath build/m5a_pack_test.log -Tail 1
if ($process.ExitCode -ne 0 -or (Select-String -LiteralPath build/m5a_pack_test.err -Pattern 'SCRIPT ERROR:' -Quiet)) {throw 'Packaged full tour failed'}
