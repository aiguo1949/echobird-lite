# 把 EchoBird Lite 推上 GitHub，用 Actions 出 exe
#
# 前置：装好 Git（https://git-scm.com/download/win）和 GitHub CLI（https://cli.github.com/），
#       执行一次  gh auth login  完成登录。
#
# 用法：powershell -ExecutionPolicy Bypass -File .\push-to-github.ps1 -Repo https://github.com/你的用户名/echobird-lite.git

param(
    [Parameter(Mandatory = $true)][string]$Repo
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw '未找到 git，请先安装 Git for Windows' }

if (-not (Test-Path '.git')) {
    Write-Host '[1/4] 初始化本地仓库...' -ForegroundColor Cyan
    git init | Out-Null
    git branch -M main
} else {
    Write-Host '[1/4] 已有 .git，跳过初始化' -ForegroundColor DarkGray
}

# Actions 机器上必须是稳定的提交者信息，否则 commit 会失败
if (-not (git config user.email)) { git config user.email 'builder@local' }
if (-not (git config user.name)) { git config user.name 'EchoBird Lite Builder' }

Write-Host '[2/4] 暂存并提交...' -ForegroundColor Cyan
git add -A
$staged = git status --porcelain
if ($staged) {
    git commit -m 'EchoBird Lite: remove unused pages, speed up boot, slim assets' | Out-Null
    Write-Host '  已提交' -ForegroundColor DarkGray
} else {
    Write-Host '  没有新改动，跳过提交' -ForegroundColor DarkGray
}

Write-Host '[3/4] 配置远程仓库...' -ForegroundColor Cyan
$existing = git remote get-url origin 2>$null
if ($LASTEXITCODE -eq 0 -and $existing) {
    git remote set-url origin $Repo
} else {
    git remote add origin $Repo
}
Write-Host "  origin -> $Repo" -ForegroundColor DarkGray

Write-Host '[4/4] 推送...' -ForegroundColor Cyan
git push -u origin main

Write-Host ''
Write-Host '推送完成。接下来：' -ForegroundColor Green
Write-Host '  1. 打开仓库页面 → 顶部 Actions 标签'
Write-Host '  2. 左侧选 Build Lite (Windows) → 右侧 Run workflow → 绿色按钮'
Write-Host '  3. 等 15~25 分钟，进入该次运行，页面底部 Artifacts 下载 echobird-lite-windows-x64.zip'
Write-Host '  4. 解压得到 EchoBird_6.0.8_x64-setup.exe 和 EchoBird-portable.exe'
