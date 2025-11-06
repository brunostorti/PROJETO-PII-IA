# Script para configurar permissões e fazer deploy da função
Write-Host "🔧 Configurando permissões e fazendo deploy..." -ForegroundColor Cyan

# Verificar Firebase CLI
$firebasePath = "$env:APPDATA\npm\firebase.cmd"
if (-not (Test-Path $firebasePath)) {
    Write-Host "❌ Firebase CLI não encontrado!" -ForegroundColor Red
    Write-Host "💡 Instale com: npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}

# Verificar login
Write-Host "🔍 Verificando login no Firebase..." -ForegroundColor Yellow
& $firebasePath projects:list 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️ Não está logado. Fazendo login..." -ForegroundColor Yellow
    & $firebasePath login --no-localhost
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erro ao fazer login!" -ForegroundColor Red
        exit 1
    }
}

# Definir projeto
Write-Host "📌 Configurando projeto: projeto-pi-1c9e3" -ForegroundColor Yellow
& $firebasePath use projeto-pi-1c9e3
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao configurar projeto!" -ForegroundColor Red
    exit 1
}

# Instalar dependências
Write-Host "📦 Instalando dependências..." -ForegroundColor Yellow
if (-not (Test-Path "functions\node_modules")) {
    Set-Location functions
    & "$env:APPDATA\npm\npm.cmd" install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erro ao instalar dependências!" -ForegroundColor Red
        Set-Location ..
        exit 1
    }
    Set-Location ..
}

# Fazer deploy
Write-Host ""
Write-Host "🚀 Fazendo deploy das funções..." -ForegroundColor Cyan
Write-Host "⏳ Isso pode levar alguns minutos..." -ForegroundColor Yellow
Write-Host ""

& $firebasePath deploy --only functions

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ DEPLOY CONCLUÍDO!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 PRÓXIMOS PASSOS:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Verifique no Firebase Console:" -ForegroundColor White
    Write-Host "   https://console.firebase.google.com/project/projeto-pi-1c9e3/functions" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Se ainda der erro 'Forbidden', configure IAM:" -ForegroundColor White
    Write-Host "   - Acesse: https://console.cloud.google.com/iam-admin/iam?project=projeto-pi-1c9e3" -ForegroundColor Gray
    Write-Host "   - Adicione a role 'Cloud Functions Invoker' para 'allUsers'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Teste a comparação de imagens no app!" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ ERRO NO DEPLOY!" -ForegroundColor Red
    Write-Host "💡 Verifique os erros acima." -ForegroundColor Yellow
    exit 1
}

