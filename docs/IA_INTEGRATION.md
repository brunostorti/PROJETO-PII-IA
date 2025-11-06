# Documentação - Integração de IA para Comparação de Imagens

## 📋 Visão Geral

Este documento descreve a integração da **Google Cloud Vision API** no aplicativo Flutter para análise e comparação de imagens de obras BIM.

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────┐
│           FLUTTER APP (Frontend)                │
│  - Captura imagens                             │
│  - Mostra resultados                            │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│      FIREBASE STORAGE                            │
│  - Armazena imagens das obras                   │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│   FIREBASE CLOUD FUNCTIONS (Backend)            │
│  - Recebe URLs das imagens                      │
│  - Chama Google Vision API                      │
│  - Processa resultados                          │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│      GOOGLE CLOUD VISION API                    │
│  - Analisa e compara imagens                   │
│  - Retorna dados de evolução                    │
└─────────────────────────────────────────────────┘
```

## 📁 Estrutura de Arquivos

### Frontend (Flutter)

```
lib/
├── models/
│   └── image_comparison.dart          # Modelo de comparação
├── services/
│   ├── ai_comparison_service.dart     # Serviço principal de IA
│   └── cloud_functions_service.dart    # Comunicação com Functions
├── screens/
│   └── image_comparison_screen.dart   # Tela de comparação
└── widgets/
    └── comparison_result_widget.dart  # Widget de resultados
```

### Backend (Firebase Functions)

```
functions/
├── index.js                            # Funções Cloud
├── package.json                       # Dependências Node.js
└── .gitignore                         # Arquivos ignorados
```

## 🔧 Configuração

### 1. Google Cloud Platform

#### Passo 1: Ativar Google Cloud Vision API

1. Acesse o [Google Cloud Console](https://console.cloud.google.com/)
2. Selecione seu projeto Firebase (ou crie um novo)
3. Vá em **APIs & Services** > **Library**
4. Procure por **Cloud Vision API**
5. Clique em **Enable**

#### Passo 2: Criar Service Account

1. Vá em **IAM & Admin** > **Service Accounts**
2. Clique em **Create Service Account**
3. Nome: `vision-api-service`
4. Role: **Cloud Vision API User**
5. Clique em **Create Key** > **JSON**
6. Baixe o arquivo JSON (você vai precisar depois)

#### Passo 3: Configurar Billing

⚠️ **IMPORTANTE**: A Google Cloud Vision API tem um plano gratuito generoso:
- Primeiros **1.000 requests/mês**: **GRÁTIS**
- Após isso: ~$1,50 por 1.000 imagens

Configure o billing no Google Cloud Console se necessário.

### 2. Firebase Functions

#### Passo 1: Instalar Firebase CLI

```bash
npm install -g firebase-tools
```

#### Passo 2: Fazer Login

```bash
firebase login
```

#### Passo 3: Inicializar Functions (se ainda não fez)

```bash
cd functions
npm install
```

#### Passo 4: Configurar Service Account

1. Copie o arquivo JSON da Service Account para `functions/`
2. Renomeie para `service-account-key.json`
3. Adicione ao `.gitignore` (já está configurado)

#### Passo 5: Atualizar `index.js`

Se necessário, adicione o caminho da service account:

```javascript
const vision = require('@google-cloud/vision');
const visionClient = new vision.ImageAnnotatorClient({
  keyFilename: './service-account-key.json', // Se necessário
});
```

#### Passo 6: Fazer Deploy

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

Após o deploy, você receberá a URL da função. Exemplo:
```
https://us-central1-projeto-obras.cloudfunctions.net/compareImages
```

### 3. Configurar URL no Flutter

Edite `lib/services/cloud_functions_service.dart`:

```dart
static const String _baseUrl = 'https://SUA_REGIAO-SEU_PROJETO.cloudfunctions.net';
```

Substitua pelos valores do seu projeto.

## 📊 Estrutura de Dados

### Firestore Collection: `image_comparisons`

A coleção é criada automaticamente quando o primeiro documento é salvo. Estrutura:

```javascript
{
  id: "comparison_123",
  userId: "user_abc",
  projectId: "project_xyz",
  pontoObra: "Ponto A",
  etapaObra: "Fundação",
  
  // Imagens comparadas
  baseImageUrl: "https://...",
  comparedImageUrl: "https://...",
  
  // IDs dos registros
  baseRegistroId: "registro_1",
  comparedRegistroId: "registro_2",
  
  // Resultados da IA
  evolutionPercentage: 45.5,
  similarityScore: 0.65,
  
  // Apontamentos detectados
  detectedChanges: [
    {
      type: "added",
      description: "Nova parede detectada",
      confidence: 0.92
    }
  ],
  
  // Status
  status: "completed", // pending, processing, completed, error
  errorMessage: null,
  
  // Metadados
  timestamp: Timestamp,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

## 🚀 Como Usar

### No App Flutter

1. **Navegar para tela de comparação:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ImageComparisonScreen(
      pontoObra: 'Ponto A',
      projectId: 'project_123',
    ),
  ),
);
```

2. **Selecionar duas imagens** (base e comparada)

3. **Clicar em "Comparar Imagens"**

4. **Aguardar processamento** (pode levar alguns segundos)

5. **Visualizar resultados:**
   - Percentual de evolução
   - Similaridade
   - Mudanças detectadas
   - Apontamentos

### Programaticamente

```dart
// Comparar imagens
final comparisonId = await AIComparisonService.compareImages(
  baseRegistroId: 'registro_1',
  comparedRegistroId: 'registro_2',
);

// Escutar atualizações
AIComparisonService.getComparisonsStream(userId).listen((comparisons) {
  // Processar comparações
});

// Buscar comparação específica
final comparison = await AIComparisonService.getComparison(comparisonId);
```

## 🔍 Como Funciona a Análise

### 1. Detecção de Objetos

A Vision API detecta objetos nas imagens usando machine learning:
- Estruturas de construção
- Materiais
- Equipamentos
- Elementos arquitetônicos

### 2. Comparação

O sistema compara:
- **Labels**: Descrições dos objetos detectados
- **Objetos localizados**: Posição e tipo de objetos
- **Texto**: Qualquer texto presente nas imagens

### 3. Cálculo de Evolução

```
Evolução = ((Novos Objetos - Objetos Antigos) / Objetos Antigos) * 100 + 50
```

Ajustado para estar sempre entre 0-100%.

### 4. Detecção de Mudanças

- **Adicionado**: Novos objetos/labels detectados
- **Removido**: Objetos que não aparecem mais
- **Modificado**: Mudanças significativas detectadas

## 📝 Índices do Firestore

Para melhor performance, crie estes índices compostos no Firestore:

1. **Collection**: `image_comparisons`
   - Campos: `userId` (Ascending), `timestamp` (Descending)

2. **Collection**: `image_comparisons`
   - Campos: `userId` (Ascending), `pontoObra` (Ascending), `timestamp` (Descending)

3. **Collection**: `image_comparisons`
   - Campos: `userId` (Ascending), `projectId` (Ascending), `timestamp` (Descending)

O Firestore vai sugerir criar esses índices automaticamente quando você fizer a primeira query.

## 🐛 Troubleshooting

### Erro: "Usuário não autenticado"
- Verifique se o usuário está logado no Firebase Auth
- Confirme que o token está sendo enviado corretamente

### Erro: "Cloud Function não encontrada"
- Verifique a URL no `cloud_functions_service.dart`
- Confirme que a função foi deployada com sucesso
- Verifique os logs: `firebase functions:log`

### Erro: "Vision API não autorizada"
- Verifique se a API está ativada no Google Cloud
- Confirme que a Service Account tem permissões corretas
- Verifique o billing do projeto

### Comparações não aparecem
- Verifique os logs do Firestore
- Confirme que a coleção `image_comparisons` está sendo criada
- Verifique as regras de segurança do Firestore

## 🔒 Segurança

### Firestore Rules

Adicione estas regras para a coleção `image_comparisons`:

```javascript
match /image_comparisons/{comparisonId} {
  // Usuários só podem ler suas próprias comparações
  allow read: if request.auth != null && 
                 resource.data.userId == request.auth.uid;
  
  // Usuários só podem criar comparações para si mesmos
  allow create: if request.auth != null && 
                   request.resource.data.userId == request.auth.uid;
  
  // Usuários só podem atualizar suas próprias comparações
  allow update: if request.auth != null && 
                   resource.data.userId == request.auth.uid;
  
  // Usuários só podem deletar suas próprias comparações
  allow delete: if request.auth != null && 
                   resource.data.userId == request.auth.uid;
}
```

### Cloud Functions

As funções já verificam autenticação automaticamente usando `context.auth`.

## 📈 Custos Estimados

### Plano Gratuito
- **1.000 requests/mês**: Grátis
- Ideal para desenvolvimento e testes

### Após o Plano Gratuito
- **$1,50 por 1.000 imagens** analisadas
- Exemplo: 5.000 comparações/mês = $7,50

### Dicas para Economizar
- Cache resultados de comparações
- Evite comparar a mesma imagem múltiplas vezes
- Use compressão de imagens antes de enviar

## 🎯 Próximos Passos

1. ✅ Integração básica implementada
2. 🔄 Melhorar detecção de mudanças específicas
3. 🔄 Adicionar visualização lado a lado das imagens
4. 🔄 Gráficos de evolução temporal
5. 🔄 Exportação de relatórios

## 📞 Suporte

Para dúvidas ou problemas:
1. Verifique os logs do Firebase Functions
2. Consulte a [documentação da Vision API](https://cloud.google.com/vision/docs)
3. Revise este documento

---

**Última atualização**: Janeiro 2025
**Versão**: 1.0.0

