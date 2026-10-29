param([int]$Seeds=200,[switch]$OnlyNew)
$ErrorActionPreference='Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
if (-not $OnlyNew) { & "$PSScriptRoot/run_m5a_checks.ps1" -Seeds 32 -DeepSeeds 32 }
$results=@()
foreach ($name in @('test_m5b','test_m5b_ui')) {
 $godotArgs=@('--headless','--audio-driver','Dummy','--path','.','-s',"res://tests/$name.gd")
 if ($name -eq 'test_m5b') {$godotArgs+=@('--',"--seeds=$Seeds")}
 $p=Start-Process E:/SD/GODOT/Godot.exe -ArgumentList $godotArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput "build/m5b_$name.log" -RedirectStandardError "build/m5b_$name.err"
 $processHandle=$p.Handle
 if (-not $p.WaitForExit(540000)) {Stop-Process -Id $p.Id; throw "$name exceeded nine-minute limit"}
 $p.Refresh()
 $matches=[regex]::Matches((Get-Content "build/m5b_$name.log" -Raw),'(\d+) checks[,;] (\d+) failures')
 if ($p.ExitCode -ne 0 -or $matches.Count -eq 0 -or (Select-String "build/m5b_$name.err" -Pattern 'SCRIPT ERROR:' -Quiet)) {throw "$name failed"}
 $m=$matches[$matches.Count-1]
 if ([int]$m.Groups[2].Value -ne 0) {throw "$name reported failures"}
 $results+=[pscustomobject]@{suite=$name;checks=[int]$m.Groups[1].Value;failures=[int]$m.Groups[2].Value}
 Write-Output "$name $($m.Value)"
}
$results | ConvertTo-Json | Set-Content build/m5b_check_results.json
