$ErrorActionPreference='Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
New-Item -ItemType Directory -Force build/m5b_shots | Out-Null
$p=Start-Process E:/SD/GODOT/Godot.exe -ArgumentList @('--headless','--path','.', '-s','res://tests/build_m5b_gallery.gd') -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput build/m5b_gallery_build.log -RedirectStandardError build/m5b_gallery_build.err
if ($p.ExitCode -ne 0 -or (Select-String build/m5b_gallery_build.err -Pattern 'SCRIPT ERROR:' -Quiet)) {throw 'Gallery builder failed'}
$p=Start-Process E:/SD/GODOT/Godot.exe -ArgumentList @('--path','.', '-s','res://tests/capture_m5b.gd','--resolution','462x1026','--','--pilot=res://tests/pilot/m5b_gallery.txt','--out=build/m5b_shots','--save-path=user://tests/m5b_gallery_only.json','--profile-path=user://tests/m5b_gallery_profile.json','--timeout=180') -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput build/m5b_gallery.log -RedirectStandardError build/m5b_gallery.err
if ($p.ExitCode -ne 0 -or (Select-String build/m5b_gallery.err -Pattern 'SCRIPT ERROR:|Invalid gallery' -Quiet)) {throw 'Gallery failed'}
python tests/build_m5b_sheet.py
