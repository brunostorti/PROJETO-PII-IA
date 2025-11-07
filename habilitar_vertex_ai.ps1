# Script para habilitar Vertex AI API no projeto Google Cloud
# Execute este script no PowerShell

Write-Host "🔧 Habilitando Vertex AI API no projeto projeto-pi-1c9e3..." -ForegroundColor Cyan

# Verificar se gcloud está instalado
$gcloud = Get-Command gcloud -ErrorAction SilentlyContinue
if (-not $gcloud) {
    Write-Host "❌ Google Cloud SDK não encontrado!" -ForegroundColor Red
    Write-Host "   Instale em: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
    exit 1
}

# Definir projeto
Write-Host "📋 Configurando projeto..." -ForegroundColor Cyan
gcloud config set project projeto-pi-1c9e3

# Habilitar Vertex AI API
Write-Host "🚀 Habilitando Vertex AI API..." -ForegroundColor Cyan
gcloud services enable aiplatform.googleapis.com --project=projeto-pi-1c9e3

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Vertex AI API habilitada com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "⏳ Aguarde alguns minutos para a API ser totalmente ativada..." -ForegroundColor Yellow
    Write-Host "   Depois, teste novamente uma comparação no app." -ForegroundColor Yellow
} else {
    Write-Host "❌ Erro ao habilitar Vertex AI API" -ForegroundColor Red
    Write-Host "   Verifique se você tem permissões de administrador no projeto." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📝 Verifique também se a Service Account das Functions tem a role:" -ForegroundColor Cyan
Write-Host "   - roles/aiplatform.user" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Service Account: projeto-pi-1c9e3@appspot.gserviceaccount.com" -ForegroundColor Yellow

