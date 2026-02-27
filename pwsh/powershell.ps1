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
