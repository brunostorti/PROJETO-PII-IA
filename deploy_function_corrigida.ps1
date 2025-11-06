# Script para fazer deploy da função corrigida
Write-Host "🚀 Iniciando deploy da função compareImages..." -ForegroundColor Cyan

# Verificar se está no diretório correto
if (-not (Test-Path "functions\index.js")) {
    Write-Host "❌ Erro: Execute este script na raiz do projeto!" -ForegroundColor Red
    exit 1
}

# Verificar se Firebase CLI está instalado
$firebasePath = "$env:APPDATA\npm\firebase.cmd"
if (-not (Test-Path $firebasePath)) {
    Write-Host "❌ Firebase CLI não encontrado em: $firebasePath" -ForegroundColor Red
    Write-Host "💡 Instale com: npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}

# Verificar se está logado no Firebase
Write-Host "🔍 Verificando login no Firebase..." -ForegroundColor Yellow
$firebaseUser = & $firebasePath list 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️ Parece que não está logado. Fazendo login..." -ForegroundColor Yellow
    & $firebasePath login --no-localhost
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erro ao fazer login no Firebase!" -ForegroundColor Red
        exit 1
    }
}

# Verificar dependências
Write-Host "📦 Verificando dependências..." -ForegroundColor Yellow
if (-not (Test-Path "functions\node_modules")) {
    Write-Host "📥 Instalando dependências..." -ForegroundColor Yellow
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
Write-Host "🚀 Fazendo deploy da função compareImages..." -ForegroundColor Cyan
Write-Host "⏳ Isso pode levar alguns minutos..." -ForegroundColor Yellow

& $firebasePath deploy --only functions:compareImages

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ DEPLOY CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎯 A função foi atualizada com:" -ForegroundColor Cyan
    Write-Host "   - Melhor tratamento de erros" -ForegroundColor White
    Write-Host "   - Logs detalhados" -ForegroundColor White
    Write-Host "   - Validação de download" -ForegroundColor White
    Write-Host "   - Timeout configurado" -ForegroundColor White
    Write-Host ""
    Write-Host "🧪 Teste agora a comparação de imagens!" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "❌ ERRO NO DEPLOY!" -ForegroundColor Red
    Write-Host "💡 Verifique os erros acima e tente novamente." -ForegroundColor Yellow
    exit 1
}

