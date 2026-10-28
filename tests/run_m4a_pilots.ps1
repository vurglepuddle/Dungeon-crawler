param([switch]$OnlyNew)
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repo
New-Item -ItemType Directory -Force build/m4a_shots,build/m4a_regression_shots | Out-Null
$runs=@(
    @('m4a_light','light'), @('m4a_burn','burn'), @('m4a_travel','travel'), @('m4a_deep','deep'), @('m4a_spent_coat','spent_coat'), @('m4a_items','items'), @('m4a_save_a','deep_pair'), @('m4a_save_b','deep_pair'), @('m3f_owner','owner'), @('m3e_tour','tour'), @('m3e_dodge','dodge'),
    @('m3e_save_a','capability_pair'), @('m3e_save_b','capability_pair'), @('m3e_sidle','sidle')
)
if (-not $OnlyNew) {
    $runs+=@(
        @('m3d_gallery','gallery'), @('m3d_gate','gate'), @('m3d_death','death'),
        @('m3d_save_a','survey_pair'), @('m3d_save_b','survey_pair'),
        @('m3d_fade_save_a','fade_pair'), @('m3d_fade_save_b','fade_pair'),
        @('m3c_gallery','old_gallery'), @('m3_return','return'), @('m3_keep','keep'), @('m3_room','room'),
        @('m3_save_a','restore_pair'), @('m3_save_b','restore_pair'),
        @('m3b_ring','ring'), @('m3b_ring_save_a','ring_pair'), @('m3b_ring_save_b','ring_pair'),
        @('m3c_audio_a','audio_pair'), @('m3c_audio_b','audio_pair'), @('m3c_heavy','heavy'), @('m3c_hands','hands')
    )
}
$results=@()
foreach ($run in $runs) {
    $name=$run[0]
    $out=Join-Path $repo $(if ($name.StartsWith('m4a_')) {'build/m4a_shots'} else {'build/m4a_regression_shots'})
    # Autopilot owns muting. Do not pass --with-sound or change the master bus.
    $arguments=@('--path','.', '--resolution','462x1026','--',
        "--pilot=res://tests/pilot/$name.txt", "--out=$out", "--save-path=user://tests/m4a_$($run[1]).json", '--timeout=240')
    $process=Start-Process E:/SD/GODOT/Godot.exe -ArgumentList $arguments -WindowStyle Normal -Wait -PassThru `
        -RedirectStandardOutput "build/m4a_$name.log" -RedirectStandardError "build/m4a_$name.err"
    $results += [pscustomobject]@{pilot=$name;exit=$process.ExitCode}
    $results | ConvertTo-Json | Set-Content -LiteralPath build/m4a_pilot_results.json
    Write-Output "$name exit $($process.ExitCode)"
    if ($process.ExitCode -ne 0 -or (Select-String -LiteralPath "build/m4a_$name.err" -Pattern 'SCRIPT ERROR:' -Quiet)) {throw "Pilot failed: $name"}
}
Write-Output "$($results.Count) muted windowed pilots passed."
