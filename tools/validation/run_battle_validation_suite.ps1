$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$godot = Join-Path $repoRoot "Godot\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_mono_win64_console.exe"

if (-not (Test-Path $godot)) {
    throw "Godot console not found: $godot"
}

$scripts = @(
    "res://tools/validation/validate_all_battle_integrity_runner.gd",
    "res://tools/validation/validate_all_battle_failure_flow_runner.gd",
    "res://tools/validation/validate_battle_softlock_runner.gd",
    "res://tools/validation/validate_battle_end_to_end_runner.gd",
    "res://tools/validation/validate_battle_result_state_cleanup_runner.gd",
    "res://tools/validation/validate_battle_save_restore_runner.gd",
    "res://tools/validation/validate_battle_view_sync_runner.gd",
    "res://tools/validation/validate_pollution_counterplay_runner.gd",
    "res://tools/validation/validate_enemy_specific_card_bonus_runner.gd"
)

foreach ($script in $scripts) {
    Write-Host "==> $script"
    & $godot --headless --path $repoRoot --script $script
    if ($LASTEXITCODE -ne 0) {
        throw "Battle validation failed: $script"
    }
}

Write-Host "run_battle_validation_suite.ps1: OK"
Write-Host "Tip: run res://tools/validation/estimate_battle_balance_runner.gd separately when you need a slower balance audit."
