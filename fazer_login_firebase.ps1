# Script para fazer login no Firebase
# Execute este arquivo clicando com botão direito > "Executar com PowerShell"

# Adicionar Node.js e npm ao PATH
$env:PATH += ";C:\Program Files\nodejs"
$env:PATH += ";$env:APPDATA\npm"

# Verificar se Node.js está funcionando
Write-Host "Verificando Node.js..." -ForegroundColor Yellow
$nodeVersion = & node --version 2>$null
if ($nodeVersion) {
    Write-Host "✓ Node.js encontrado: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "✗ Node.js não encontrado!" -ForegroundColor Red
    Write-Host "Por favor, instale o Node.js primeiro: https://nodejs.org/" -ForegroundColor Red
    pause
    exit
}

# Verificar se Firebase está instalado
Write-Host "Verificando Firebase CLI..." -ForegroundColor Yellow
$firebasePath = "$env:APPDATA\npm\firebase.cmd"
if (Test-Path $firebasePath) {
    Write-Host "✓ Firebase CLI encontrado" -ForegroundColor Green
} else {
    Write-Host "✗ Firebase CLI não encontrado. Instalando..." -ForegroundColor Yellow
    & npm install -g firebase-tools
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Erro ao instalar Firebase CLI!" -ForegroundColor Red
        pause
        exit
    }
}

# Navegar para a pasta do projeto
Set-Location "C:\Users\Renato\PII-2025\Projeto_PII"

# Fazer login
Write-Host ""
Write-Host "Iniciando login no Firebase..." -ForegroundColor Cyan
Write-Host "Isso abrirá o navegador para você autorizar." -ForegroundColor Cyan
Write-Host ""

& "$env:APPDATA\npm\firebase.cmd" login

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ Login realizado com sucesso!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "✗ Erro no login. Tente novamente." -ForegroundColor Red
}

Write-Host ""
Write-Host "Pressione qualquer tecla para fechar..."
pause

