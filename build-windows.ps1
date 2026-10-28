# EchoBird Lite — Windows 一键构建脚本
# 用法：powershell -ExecutionPolicy Bypass -File .\build-windows.ps1
$ErrorActionPreference = 'Stop'

function Test-Cmd($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

Write-Host '[1/4] 检查工具链...' -ForegroundColor Cyan
if (-not (Test-Cmd 'node')) { throw '未找到 Node.js，请先安装 https://nodejs.org/' }
if (-not (Test-Cmd 'cargo')) {
    throw '未找到 Rust，请先安装 https://rustup.rs/ 并重开终端'
}
if (-not (Test-Cmd 'cargo-tauri')) {
    Write-Host '  未找到 cargo-tauri，正在安装（可能需要几分钟）...' -ForegroundColor Yellow
    cargo install tauri-cli --version '^2' --locked
}
Write-Host ('  node ' + (node -v) + ' / rust ' + (cargo --version)) -ForegroundColor DarkGray

Write-Host '[2/4] 安装前端依赖...' -ForegroundColor Cyan
if (Test-Path 'node_modules') { Write-Host '  node_modules 已存在，跳过' -ForegroundColor DarkGray }
else { npm ci }

Write-Host '[3/4] 编译前端产物...' -ForegroundColor Cyan
npx vite build
if ($LASTEXITCODE -ne 0) { throw '前端构建失败' }

Write-Host '[4/4] 编译 Tauri 应用（首次较慢）...' -ForegroundColor Cyan
cargo tauri build
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Rust 构建失败。可尝试删除 src-tauri/Cargo.toml 末尾的 [profile.release] 整段后重试。' -ForegroundColor Red
    throw 'Tauri 构建失败'
}

$exe = 'src-tauri\target\release\EchoBird.exe'
$nsis = Get-ChildItem 'src-tauri\target\release\bundle\nsis\*.exe' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
Write-Host ''
Write-Host '构建完成：' -ForegroundColor Green
if (Test-Path $exe) { Write-Host ("  免安装程序: " + (Resolve-Path $exe)) }
if ($nsis) { Write-Host ("  安装包    : " + $nsis.FullName) }
