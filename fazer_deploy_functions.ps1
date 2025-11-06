# Script para instalar dependências e fazer deploy das Cloud Functions
# Execute este script após as correções

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Deploy das Cloud Functions Corrigidas" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se está no diretório correto
if (-not (Test-Path "functions")) {
    Write-Host "❌ Erro: Diretório 'functions' não encontrado!" -ForegroundColor Red
    Write-Host "   Execute este script na raiz do projeto." -ForegroundColor Yellow
    exit 1
}

# Navegar para o diretório functions
Write-Host "📁 Navegando para o diretório functions..." -ForegroundColor Yellow
Set-Location functions

# Verificar se package.json existe
if (-not (Test-Path "package.json")) {
    Write-Host "❌ Erro: package.json não encontrado!" -ForegroundColor Red
    exit 1
}

# Instalar dependências (incluindo cors)
Write-Host ""
Write-Host "📦 Instalando dependências (incluindo cors)..." -ForegroundColor Yellow
npm install

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao instalar dependências!" -ForegroundColor Red
    Set-Location ..
    exit 1
}

Write-Host "✅ Dependências instaladas com sucesso!" -ForegroundColor Green
Write-Host ""

# Verificar se está logado no Firebase
Write-Host "🔐 Verificando login no Firebase..." -ForegroundColor Yellow
$firebaseCheck = & "$env:APPDATA\npm\firebase.cmd" projects:list 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Parece que você não está logado no Firebase." -ForegroundColor Yellow
    Write-Host "   Execute primeiro: .\fazer_login_firebase.ps1" -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Deseja continuar mesmo assim? (s/n)"
    if ($continue -ne "s" -and $continue -ne "S") {
        Set-Location ..
        exit 0
    }
}

# Voltar para a raiz do projeto
Set-Location ..

# Fazer deploy da função compareImages
Write-Host ""
Write-Host "🚀 Fazendo deploy da função compareImages..." -ForegroundColor Yellow
Write-Host "   (Isso pode levar alguns minutos...)" -ForegroundColor Gray
Write-Host ""

& "$env:APPDATA\npm\firebase.cmd" deploy --only functions:compareImages

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Deploy concluído com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Próximos passos:" -ForegroundColor Cyan
    Write-Host "   1. Crie o índice do Firestore (veja CRIAR_INDICE_FIRESTORE.md)" -ForegroundColor White
    Write-Host "   2. Recarregue o app e teste novamente" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Erro durante o deploy!" -ForegroundColor Red
    Write-Host "   Verifique os logs acima para mais detalhes." -ForegroundColor Yellow
    Write-Host ""
}

