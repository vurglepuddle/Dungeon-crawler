# Windowed real-input regressions. Every close/reopen pair uses separate
# processes sharing a dedicated slot. No player saves/preferences are touched.
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repo
$shotDir = Join-Path $repo 'build/m3c_shots'
New-Item -ItemType Directory -Force -Path $shotDir | Out-Null
$runs = @(
    @('m3c_gallery','m3c_gallery'), @('m3_return','m3c_return'),
    @('m3_keep','m3c_keep'), @('m3_room','m3c_room'),
    @('m3_save_a','m3c_restore_pair'), @('m3_save_b','m3c_restore_pair'),
    @('m3b_ring','m3c_ring'),
    @('m3b_ring_save_a','m3c_ring_pair'), @('m3b_ring_save_b','m3c_ring_pair'),
    @('m3c_audio_a','m3c_audio_pair'), @('m3c_audio_b','m3c_audio_pair'),
    @('m3c_heavy','m3c_heavy'), @('m3c_hands','m3c_hands')
)
$results = @()
foreach ($run in $runs) {
    $pilotName = $run[0]
    $args = @('--path','.', '--resolution','462x1026', '--',
        "--pilot=res://tests/pilot/$pilotName.txt", "--out=$shotDir",
        "--save-path=user://tests/$($run[1]).json", '--timeout=90')
    $stdout = "build/m3c_$pilotName.log"
    $stderr = "build/m3c_$pilotName.err"
    $process = Start-Process -FilePath E:/SD/GODOT/Godot.exe -ArgumentList $args `
        -WindowStyle Normal -Wait -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $results += [pscustomobject]@{pilot=$pilotName; exit=$process.ExitCode; log=$stdout}
    $results | ConvertTo-Json | Set-Content -LiteralPath build/m3c_pilot_results.json
    Write-Output "$pilotName exit $($process.ExitCode)"
    if ($process.ExitCode -ne 0) { throw "Pilot failed: $pilotName; see $stdout and $stderr" }
}
Write-Output "$($results.Count) windowed pilots passed."
