# Script para configurar CORS no Firebase Storage via gsutil
# Requer Google Cloud SDK instalado

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Configurar CORS no Firebase Storage" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se gsutil está instalado
$gsutilPath = Get-Command gsutil -ErrorAction SilentlyContinue

if (-not $gsutilPath) {
    Write-Host "❌ gsutil não encontrado!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Opções:" -ForegroundColor Yellow
    Write-Host "1. Instalar Google Cloud SDK:" -ForegroundColor White
    Write-Host "   https://cloud.google.com/sdk/docs/install" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. OU configurar manualmente no Google Cloud Console:" -ForegroundColor White
    Write-Host "   - Acesse: https://console.cloud.google.com/storage/browser?project=projeto-pi-1c9e3" -ForegroundColor Gray
    Write-Host "   - Clique no bucket: projeto-pi-1c9e3.firebasestorage.app" -ForegroundColor Gray
    Write-Host "   - Vá em Configurações → CORS" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# Criar arquivo de configuração CORS
Write-Host "📝 Criando arquivo de configuração CORS..." -ForegroundColor Yellow
$corsConfig = @'
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "OPTIONS"],
    "responseHeader": ["Content-Type", "Authorization", "Content-Length"],
    "maxAgeSeconds": 3600
  }
]
'@

$corsConfig | Out-File -FilePath "cors.json" -Encoding UTF8

Write-Host "✅ Arquivo cors.json criado!" -ForegroundColor Green
Write-Host ""

# Aplicar CORS ao bucket
Write-Host "🚀 Aplicando configuração CORS ao bucket..." -ForegroundColor Yellow
Write-Host "   Bucket: projeto-pi-1c9e3.firebasestorage.app" -ForegroundColor Gray
Write-Host ""

gsutil cors set cors.json gs://projeto-pi-1c9e3.firebasestorage.app

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ CORS configurado com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Próximos passos:" -ForegroundColor Cyan
    Write-Host "   1. Recarregue o app" -ForegroundColor White
    Write-Host "   2. Teste novamente o carregamento de imagens" -ForegroundColor White
    Write-Host ""
    
    # Limpar arquivo temporário
    Remove-Item "cors.json" -ErrorAction SilentlyContinue
} else {
    Write-Host ""
    Write-Host "❌ Erro ao configurar CORS!" -ForegroundColor Red
    Write-Host "   Verifique se você está autenticado no Google Cloud:" -ForegroundColor Yellow
    Write-Host "   gcloud auth login" -ForegroundColor Gray
    Write-Host ""
}

