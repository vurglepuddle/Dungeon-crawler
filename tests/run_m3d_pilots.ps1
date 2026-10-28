# Separate processes and isolated save/settings slots. Previous milestone
# screenshots remain intact; baseline captures go to m3d_regression_shots.
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repo
New-Item -ItemType Directory -Force build/m3d_shots,build/m3d_regression_shots | Out-Null
$runs = @(
    @('m3d_gallery','m3d_gallery'), @('m3d_gate','m3d_gate'), @('m3d_death','m3d_death'),
	@('m3d_save_a','m3d_survey_pair'), @('m3d_save_b','m3d_survey_pair'),
	@('m3d_fade_save_a','m3d_fade_pair'), @('m3d_fade_save_b','m3d_fade_pair'),
    @('m3c_gallery','m3d_old_gallery'), @('m3_return','m3d_return'),
    @('m3_keep','m3d_keep'), @('m3_room','m3d_room'),
    @('m3_save_a','m3d_restore_pair'), @('m3_save_b','m3d_restore_pair'),
    @('m3b_ring','m3d_ring'), @('m3b_ring_save_a','m3d_ring_pair'), @('m3b_ring_save_b','m3d_ring_pair'),
    @('m3c_audio_a','m3d_audio_pair'), @('m3c_audio_b','m3d_audio_pair'),
    @('m3c_heavy','m3d_heavy'), @('m3c_hands','m3d_hands')
)
$results = @()
foreach ($run in $runs) {
    $pilotName=$run[0]
    $outDir=Join-Path $repo $(if ($pilotName.StartsWith('m3d_')) {'build/m3d_shots'} else {'build/m3d_regression_shots'})
    $args=@('--path','.', '--resolution','462x1026','--',
        "--pilot=res://tests/pilot/$pilotName.txt", "--out=$outDir",
        "--save-path=user://tests/$($run[1]).json", '--timeout=100')
    $stdout="build/m3d_$pilotName.log"
    $stderr="build/m3d_$pilotName.err"
    $process=Start-Process -FilePath E:/SD/GODOT/Godot.exe -ArgumentList $args `
        -WindowStyle Normal -Wait -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $results += [pscustomobject]@{pilot=$pilotName;exit=$process.ExitCode;log=$stdout}
    $results | ConvertTo-Json | Set-Content -LiteralPath build/m3d_pilot_results.json
    Write-Output "$pilotName exit $($process.ExitCode)"
    if ($process.ExitCode -ne 0) { throw "Pilot failed: $pilotName; see $stdout and $stderr" }
}
Write-Output "$($results.Count) windowed pilots passed."
