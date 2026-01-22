# ======================== 1. 路径预设 ========================
$env:SCOOP        = "C:\applications\Scoop"
$env:SCOOP_GLOBAL = "$env:SCOOP\global"
$env:DENO_DIR     = "$env:SCOOP\persist\deno"
$env:PNPM_HOME    = "$env:SCOOP\persist\pnpm"
$env:npm_config_store_dir = "$env:SCOOP\persist\pnpm\store"

# ====================== 2. 设置用户变量 ======================
Write-Host "--- 正在将配置同步至系统环境变量 ---" -ForegroundColor Cyan

$pathMap = @{
    "SCOOP"                = $env:SCOOP
    "SCOOP_GLOBAL"         = $env:SCOOP_GLOBAL
    "DENO_DIR"             = $env:DENO_DIR
    "PNPM_HOME"            = $env:PNPM_HOME
    "npm_config_store_dir" = $env:npm_config_store_dir
}

foreach ($name in $pathMap.Keys) {
    [Environment]::SetEnvironmentVariable($name, $pathMap[$name], "User")
}

# ======================== 3. 安装scoop ========================  
irm get.scoop.sh | iex
