# --- Oh My Posh ---
oh-my-posh init pwsh --config "negligible" | Invoke-Expression

# --- PSReadLine ---
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle InlineView
Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" } -ExtraPromptLineCount 1
Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadLineOption -HistoryNoDuplicates

# --- PSCompletions ---
Import-Module PSCompletions -Force
psc menu config enable_menu_enhance 1 *>$null

# fnm
## 清理一天前的 symlink
function Clear-FnmMultishells {
  $dir = "$env:LOCALAPPDATA\fnm_multishells"
  if (Test-Path $dir) {
    Get-ChildItem $dir -Directory | Where-Object {
      $_.CreationTime -lt (Get-Date).AddDays(-1)
    } | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
  }
}
Clear-FnmMultishells
## 加载 fnm 环境
fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression

# alias
sal oc opencode
sal vim nvim

# functions
function Edit-History { vim (Get-PSReadLineOption).HistorySavePath }
