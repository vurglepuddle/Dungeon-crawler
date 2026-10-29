param([switch]$OnlyNew)
$ErrorActionPreference='Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
New-Item -ItemType Directory -Force build/m5b_shots/real | Out-Null
# Build historical M5a plans once. Only its UI-created skip now opts into metals.
foreach ($builder in @('build_m5a_pilots','build_m5b_pilots')) {
 $p=Start-Process E:/SD/GODOT/Godot.exe -ArgumentList @('--headless','--path','.','--quit-after','1800','-s',"res://tests/$builder.gd") -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput "build/m5b_$builder.log" -RedirectStandardError "build/m5b_$builder.err"
 if ($p.ExitCode -ne 0 -or (Select-String "build/m5b_$builder.err" -Pattern 'SCRIPT ERROR:' -Quiet)) {throw 'Pilot builder failed'}
}
if (-not $OnlyNew) { & "$PSScriptRoot/run_m5a_pilots.ps1" }
$p=Start-Process E:/SD/GODOT/Godot.exe -ArgumentList @('--path','.','--resolution','462x1026','--','--pilot=res://tests/pilot/m5b_metals.txt','--out=build/m5b_shots/real','--save-path=user://tests/m5b_metals.json','--profile-path=user://tests/m5b_metals_profile.json','--timeout=360') -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput build/m5b_metals.log -RedirectStandardError build/m5b_metals.err
if ($p.ExitCode -ne 0 -or (Select-String build/m5b_metals.err -Pattern 'SCRIPT ERROR:|Can.t save PNG' -Quiet)) {throw 'Metal-key pilot failed'}
Write-Output 'M5b real-tap metal run passed (muted).'
