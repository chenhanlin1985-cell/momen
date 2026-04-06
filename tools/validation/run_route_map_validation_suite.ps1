$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$godot = Join-Path $repoRoot "Godot\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_mono_win64_console.exe"

if (-not (Test-Path $godot)) {
    throw "Godot console not found: $godot"
}

$scripts = @(
    "res://tools/validation/validate_route_map_graph_integrity_runner.gd",
    "res://tools/validation/validate_route_map_copy_runner.gd",
    "res://tools/validation/validate_route_map_ui_runner.gd",
    "res://tools/validation/validate_route_map_runtime_runner.gd",
    "res://tools/validation/validate_route_map_action_determinism_runner.gd",
    "res://tools/validation/validate_route_map_regression_suite_runner.gd",
    "res://tools/validation/validate_route_map_long_chain_runner.gd"
)

foreach ($script in $scripts) {
    Write-Host "==> $script"
    & $godot --headless --path $repoRoot --script $script
    if ($LASTEXITCODE -ne 0) {
        throw "Route-map validation failed: $script"
    }
}

Write-Host "run_route_map_validation_suite.ps1: OK"
