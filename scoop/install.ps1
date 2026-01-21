$env:SCOOP = "C:\applications\Scoop"
$env:SCOOP_GLOBAL = "C:\applications\Scoop\global"

# 1. 永久设置变量
[Environment]::SetEnvironmentVariable("SCOOP", $env:SCOOP, "User")
[Environment]::SetEnvironmentVariable("SCOOP_GLOBAL", $env:SCOOP_GLOBAL, "User")

# 2. 安装
irm get.scoop.sh | iex
