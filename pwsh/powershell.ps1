# 用于收集缺失项的数组
$MissingTools = @()

# ====================== 条件探测加载 ======================

# --- Oh My Posh ---
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/amro.omp.json" | Invoke-Expression
} else {
    $MissingTools += [PSCustomObject]@{ 类型 = "命令"; 名称 = "oh-my-posh" }
}

# --- PSReadLine (内置) ---
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle InlineView
Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" } -ExtraPromptLineCount 1
Set-PSReadlineKeyHandler -Key Tab -Function Complete

# --- PSCompletions ---
if (Get-Module -ListAvailable -Name PSCompletions) {
    Import-Module PSCompletions -Force
    # 核心修复：强制开启 UI 增强并屏蔽输出
    psc menu config enable_menu_enhance 1 *>$null
} else {
    $MissingTools += [PSCustomObject]@{ 类型 = "模块"; 名称 = "PSCompletions" }
}

# --- NVIM (Alias) ---
if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Set-Alias vim nvim
} else {
    $MissingTools += [PSCustomObject]@{ 类型 = "命令"; 名称 = "nvim" }
}

# ====================== 美化输出缺失信息 ======================

if ($MissingTools.Count -gt 0) {
    Write-Host "`n── 待完善环境 ──────────────────────────" -ForegroundColor Yellow
    foreach ($item in $MissingTools) {
        $LabelColor = if ($item.类型 -eq "模块") { "Cyan" } else { "Magenta" }
        Write-Host "  [ ] " -NoNewline -ForegroundColor Gray
        Write-Host ("{0,-15}" -f $item.名称) -NoNewline -ForegroundColor White
        Write-Host " <" -NoNewline -ForegroundColor Gray
        Write-Host $item.类型 -NoNewline -ForegroundColor $LabelColor
        Write-Host ">" -ForegroundColor Gray
    }
    Write-Host "────────────────────────────────────────" -ForegroundColor Yellow
    Write-Host " Tip: 请在安装完成后重启或执行 . `$profile` `n" -ForegroundColor DarkGray
}

# aichat
function ?? {
    param([Parameter(Mandatory=$true)][string]$msg)
    
    # --- 所有的配置都封装在方法内部 ---
    $baseUrl = "https://open.bigmodel.cn/api/paas/v4/" 
    $model   = "glm-4.5-flash"
    # 从系统环境变量读取 Key，防止上传 GitHub 泄露(下面这个不知道谁的O.O)
    $apiKey  = "7a2566d5ed754f2c8052cea0b60e49c8.HwCL52O2v2wAzrDE" 
    
    # 1. 检查 API Key
    if (-not $apiKey) {
        Write-Host " [!] 错误: 未检测到 API Key。" -ForegroundColor Red
        Write-Host " 请先执行: [Environment]::SetEnvironmentVariable('AI_API_KEY', '你的Key', 'User')" -ForegroundColor Gray
        return
    }

    # 2. 构造请求头
    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type"  = "application/json"
    }

    # 3. 构造请求体 (封装 Model 变量)
    $body = @{
        model = $model
        messages = @(
            @{role = "system"; content = "你是一位精通各类终端工具的顶级黑客。当用户提问时，请保持极致简洁，直接上代码。
风格指南：
1. 对于 PowerShell，请务必同时给出完整命令和原生短别名（如 gcb, sls 等）。
2. 对于 Docker、HTTPie、Python 等其他工具，无需强行提供别名，但需确保给出最地道、最简洁的单行实战案例。
3. 严禁废话，仅在代码注释中做必要说明。
格式：使用 Markdown 代码块，案例要能即敲即用。"},
            @{role = "user"; content = $msg}
        )
        stream = $false
    } | ConvertTo-Json

    # 4. 执行请求
    try {
        Write-Host " AI ($model) 正在思考..." -ForegroundColor Gray
        $response = Invoke-RestMethod -Method Post -Uri "$baseUrl/chat/completions" `
                                     -Headers $headers `
                                     -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
        
        $answer = $response.choices[0].message.content
        
        # 5. 美化输出
        Write-Host "`n推荐命令:" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Gray
        Write-Host $answer -ForegroundColor Green
        Write-Host "----------------------------------------" -ForegroundColor Gray
    } catch {
        Write-Host " 请求失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}
