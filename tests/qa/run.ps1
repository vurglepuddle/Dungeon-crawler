param(
    [ValidateSet('all','legacy','deep','generation','adversarial','save','stairs','reopen','edges','difficulty')]
    [string]$Suite = 'all',
    [int]$Seeds = 3072,
    [int]$AdversarialSeeds = 96,
    [int]$DeepSeeds = 2048,
    [int]$DeepAdversarialSeeds = 96,
    [int]$DifficultySeeds = 128,
    [int]$DeepEdgeSeeds = 16
)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$resultsRoot = Join-Path $PSScriptRoot 'results'
New-Item -ItemType Directory -Force -Path $resultsRoot | Out-Null
$cases = @()
if ($Suite -in @('all','legacy','generation')) { $cases += @{name='generation'; script='generation'; args=@("--seeds=$Seeds") } }
if ($Suite -in @('all','legacy','adversarial')) {
    $cases += @{name='adversarial'; script='adversarial'; args=@("--seeds=$AdversarialSeeds") }
    $cases += @{name='resume_samples'; script='resume_samples'; args=@()}
}
if ($Suite -in @('all','legacy','save')) {
    $cases += @{name='save_fuzz'; script='save_fuzz'; args=@()}
    $cases += @{name='repro_save_type'; script='repro_save_type'; args=@()}
}
if ($Suite -in @('all','legacy','stairs')) { $cases += @{name='replay_stairs'; script='replay_stairs'; args=@()} }
if ($Suite -in @('all','legacy','edges')) { $cases += @{name='edge_policies'; script='edge_policies'; args=@()} }
if ($Suite -in @('all','legacy','reopen')) {
    $cases += @{name='reopen_write'; script='reopen'; args=@('--phase=write')}
    $cases += @{name='reopen_read'; script='reopen'; args=@('--phase=read')}
}
if ($Suite -in @('all','deep','generation')) { $cases += @{name='deep_generation'; script='deep_generation'; args=@("--seeds=$DeepSeeds")} }
if ($Suite -in @('all','deep','adversarial')) {
    $cases += @{name='deep_adversarial'; script='deep_adversarial'; args=@("--seeds=$DeepAdversarialSeeds")}
    $cases += @{name='deep_resume'; script='resume_samples'; args=@('--input=deep_adversarial')}
}
if ($Suite -in @('all','deep','edges','save','reopen')) { $cases += @{name='deep_edges'; script='deep_edges'; args=@("--seeds=$DeepEdgeSeeds")} }
if ($Suite -in @('all','deep','edges')) { $cases += @{name='deep_sidle'; script='deep_sidle'; args=@()} }
if ($Suite -in @('all','deep','edges')) { $cases += @{name='deep_food'; script='deep_food'; args=@("--seeds=$DeepEdgeSeeds")} }
if ($Suite -in @('all','deep','difficulty')) { $cases += @{name='deep_difficulty'; script='deep_difficulty'; args=@("--seeds=$DifficultySeeds")} }
if ($Suite -in @('all','deep','save','reopen')) {
    $cases += @{name='deep_save_write'; script='deep_save'; args=@('--phase=write')}
    $cases += @{name='deep_save_read'; script='deep_save'; args=@('--phase=read')}
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
    $timeoutMs = if ($case.name -in @('generation','adversarial','deep_generation','deep_adversarial','deep_resume')) { 7200000 } else { 1800000 }
    if (-not $process.WaitForExit($timeoutMs)) {
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
