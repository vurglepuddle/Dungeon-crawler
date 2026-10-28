param([ValidateRange(1,10000)][int]$Seeds=300,[string]$FromSuite="")
$ErrorActionPreference='Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
New-Item -ItemType Directory -Force build | Out-Null
$names=@('test_m1','test_m2','test_m3','test_m3_lift','test_m3b_ring','test_ui_layout',
    'test_m3_view','test_music','test_fx','test_m3c','test_m3d','test_m3e','test_m3e_ui','test_m3f','test_m4a','test_m4a_depth','test_m4b')
$results=@()
if ($FromSuite -ne '') {
    $index=[array]::IndexOf($names,$FromSuite)
    if ($index -lt 0) {throw 'Unknown suite'}
    $retained=@($names | Select-Object -First $index)
    foreach ($row in (Get-Content -LiteralPath build/m4b_check_results.json -Raw | ConvertFrom-Json)) {
        if ($row.suite -in $retained) {$results += [pscustomobject]@{suite=$row.suite;checks=[int]$row.checks;failures=[int]$row.failures}}
    }
    $names=@($names | Select-Object -Skip $index)
}
foreach ($name in $names) {
    $arguments=@('--headless','--audio-driver','Dummy','--path','.','-s',"res://tests/$name.gd")
    if ($name -in @('test_m3e','test_m4a_depth')) { $arguments+=@('--',"--seeds=$Seeds") }
    $stdout="build/m4b_$name.log"; $stderr="build/m4b_$name.err"
    $process=Start-Process E:/SD/GODOT/Godot.exe -ArgumentList $arguments -WindowStyle Hidden -Wait -PassThru `
        -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $captures=[regex]::Matches((Get-Content -LiteralPath $stdout -Raw),'(\d+) checks[,;] (\d+) failures')
    if ($process.ExitCode -ne 0 -or $captures.Count -eq 0 -or (Select-String -LiteralPath $stderr -Pattern 'SCRIPT ERROR:' -Quiet)) {throw "$name failed; see $stdout and $stderr"}
    $last=$captures[$captures.Count-1]
    if ([int]$last.Groups[2].Value -ne 0) {throw "$name reported failures"}
    $results += [pscustomobject]@{suite=$name;checks=[int]$last.Groups[1].Value;failures=[int]$last.Groups[2].Value}
    $results | ConvertTo-Json | Set-Content -LiteralPath build/m4b_check_results.json
    Write-Output "$name $($last.Value)"
}
Write-Output "$($results.Count) suites; $(($results | Measure-Object -Property checks -Sum).Sum) checks."
