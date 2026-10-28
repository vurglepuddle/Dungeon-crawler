# Sequential: inherited storage suites intentionally share a test slot.
$ErrorActionPreference='Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
New-Item -ItemType Directory -Force build | Out-Null
$names=@('test_m1','test_m2','test_m3','test_m3_lift','test_m3b_ring',
    'test_ui_layout','test_m3_view','test_music','test_fx','test_m3c','test_m3d')
$results=@()
foreach ($name in $names) {
    $stdout="build/m3d_$name.log"; $stderr="build/m3d_$name.err"
    $process=Start-Process -FilePath E:/SD/GODOT/Godot.exe -ArgumentList `
        '--headless','--audio-driver','Dummy','--path','.','-s',"res://tests/$name.gd" `
        -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $text=Get-Content -LiteralPath $stdout -Raw
    $matches=[regex]::Matches($text,'(\d+) checks[,;] (\d+) failures')
    if ($process.ExitCode -ne 0 -or $matches.Count -eq 0 -or (Select-String -LiteralPath $stderr -Pattern 'SCRIPT ERROR:' -Quiet)) {
        throw "$name failed; see $stdout and $stderr"
    }
    $last=$matches[$matches.Count-1]
    if ([int]$last.Groups[2].Value -ne 0) { throw "$name reported failures; see $stdout and $stderr" }
    $results += [pscustomobject]@{suite=$name;checks=[int]$last.Groups[1].Value;failures=[int]$last.Groups[2].Value}
    $results | ConvertTo-Json | Set-Content -LiteralPath build/m3d_check_results.json
    Write-Output "$name $($last.Value)"
}
$total=($results | Measure-Object -Property checks -Sum).Sum
$results | ConvertTo-Json | Set-Content -LiteralPath build/m3d_check_results.json
Write-Output "$($results.Count) suites; $total checks."
