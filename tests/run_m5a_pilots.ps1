param([switch]$OnlyNew,[string]$FromPilot="")
$ErrorActionPreference='Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
New-Item -ItemType Directory -Force build/m5a_shots | Out-Null
$runs=@(@('m5a_fall','fall'),@('m5a_skip_winding','skip'),@('m5a_death','death'),@('m5a_save_a','save_pair'),@('m5a_save_b','save_pair'))
if (-not $OnlyNew) {
    $runs+=@(@('m4c_lock','legacy_lock'),@('m4c_pry','legacy_pry'),@('m4a_deep','legacy_deep'),@('m4a_save_a','legacy_save'),@('m4a_save_b','legacy_save'),@('m3d_death','legacy_death'))
}
$results=@()
if ($FromPilot -ne '') {
    $names=@($runs | ForEach-Object {$_[0]})
    $index=[array]::IndexOf($names,$FromPilot)
    if ($index -lt 0) {throw 'Unknown pilot'}
    $retained=@($names | Select-Object -First $index)
    foreach ($row in (Get-Content build/m5a_pilot_results.json -Raw | ConvertFrom-Json)) {
        if ($row.pilot -in $retained) {$results+=$row}
    }
    $runs=@($runs | Select-Object -Skip $index)
}
foreach ($run in $runs) {
    $name=$run[0]
    # Fall and UI skip share ONLY the disposable unlock profile. Every save is isolated.
    $profile=if ($name -in @('m5a_fall','m5a_skip_winding')) {'unlock_pair'} else {$run[1]}
    $arguments=@('--path','.', '--resolution','462x1026','--',
        "--pilot=res://tests/pilot/$name.txt",'--out=build/m5a_shots',
        "--save-path=user://tests/m5a_$($run[1]).json", "--profile-path=user://tests/m5a_$($profile)_profile.json",'--timeout=360')
    $p=Start-Process E:/SD/GODOT/Godot.exe -ArgumentList $arguments -WindowStyle Hidden -Wait -PassThru `
        -RedirectStandardOutput "build/m5a_$name.log" -RedirectStandardError "build/m5a_$name.err"
    $results+=[pscustomobject]@{pilot=$name;exit=$p.ExitCode}
    $results | ConvertTo-Json | Set-Content -LiteralPath build/m5a_pilot_results.json
    Write-Output "$name exit $($p.ExitCode)"
    if ($p.ExitCode -ne 0 -or (Select-String -LiteralPath "build/m5a_$name.err" -Pattern 'SCRIPT ERROR:' -Quiet)) {throw "Pilot failed: $name"}
}
Write-Output "$($results.Count) muted pilots passed."
