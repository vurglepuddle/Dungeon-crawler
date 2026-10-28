param(
    [ValidateSet('all','generation','adversarial','save','stairs','reopen','edges')]
    [string]$Suite = 'all',
    [int]$Seeds = 3072,
    [int]$AdversarialSeeds = 96
)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$resultsRoot = Join-Path $PSScriptRoot 'results'
New-Item -ItemType Directory -Force -Path $resultsRoot | Out-Null
$cases = @()
if ($Suite -in @('all','generation')) { $cases += @{name='generation'; script='generation'; args=@("--seeds=$Seeds") } }
if ($Suite -in @('all','adversarial')) {
    $cases += @{name='adversarial'; script='adversarial'; args=@("--seeds=$AdversarialSeeds") }
    $cases += @{name='resume_samples'; script='resume_samples'; args=@()}
}
if ($Suite -in @('all','save')) {
    $cases += @{name='save_fuzz'; script='save_fuzz'; args=@()}
    $cases += @{name='repro_save_type'; script='repro_save_type'; args=@()}
}
if ($Suite -in @('all','stairs')) { $cases += @{name='replay_stairs'; script='replay_stairs'; args=@()} }
if ($Suite -in @('all','edges')) { $cases += @{name='edge_policies'; script='edge_policies'; args=@()} }
if ($Suite -in @('all','reopen')) {
    $cases += @{name='reopen_write'; script='reopen'; args=@('--phase=write')}
    $cases += @{name='reopen_read'; script='reopen'; args=@('--phase=read')}
}
$results = @()
foreach ($case in $cases) {
    $stdout = Join-Path $resultsRoot ($case.name+'.log')
    $stderr = Join-Path $resultsRoot ($case.name+'.err')
    $arguments = @('--headless','--path',$projectRoot,'-s',('res://tests/qa/'+$case.script+'.gd'))
    if ($case.args.Count -gt 0) { $arguments += '--'; $arguments += $case.args }
    $process = Start-Process -FilePath 'E:/SD/GODOT/Godot.exe' -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $processHandle = $process.Handle
    $process.Id | Set-Content -LiteralPath (Join-Path $resultsRoot ($case.name+'.pid'))
    if (-not $process.WaitForExit(1800000)) {
        $process.Kill()
        throw ('QA process timed out: '+$case.name)
    }
    $scriptErrors = @(Select-String -LiteralPath $stderr -Pattern 'SCRIPT ERROR|Failed to load script|QA .*FAIL|QA CONFIRMED').Count
    $passed = $process.ExitCode -eq 0 -and $scriptErrors -eq 0
    $results += @{name=$case.name; exit_code=$process.ExitCode; script_errors=$scriptErrors; passed=$passed}
    Write-Output ($case.name+': passed='+$passed+', exit='+$process.ExitCode+', errors='+$scriptErrors)
}
$results | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $resultsRoot 'runner.json')
if (@($results | Where-Object { -not $_.passed }).Count -gt 0) { exit 1 }
exit 0
