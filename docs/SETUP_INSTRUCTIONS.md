# 🚀 Instruções de Configuração - Integração de IA

## ✅ O que já foi implementado

1. ✅ Modelo de dados (`ImageComparison`)
2. ✅ Serviços de comunicação (Flutter)
3. ✅ Tela de comparação de imagens
4. ✅ Widget de resultados
5. ✅ Cloud Functions (código pronto)
6. ✅ Documentação completa

## 📋 O que você precisa fazer

### 1. Configurar Google Cloud Vision API

#### Passo 1: Ativar a API
1. Acesse [Google Cloud Console](https://console.cloud.google.com/)
2. Selecione o projeto: **projeto-pi-1c9e3**
3. Vá em **APIs & Services** > **Library**
4. Procure **"Cloud Vision API"**
5. Clique em **Enable**

#### Passo 2: Configurar Billing (se necessário)
- Primeiros 1.000 requests/mês são **GRÁTIS**
- Após isso: ~$1,50 por 1.000 imagens
- Configure billing apenas se precisar de mais que 1.000 requests/mês

### 2. Configurar Firebase Functions

#### Passo 1: Instalar Firebase CLI (se ainda não tiver)
```bash
npm install -g firebase-tools
```

#### Passo 2: Fazer Login
```bash
firebase login
```

#### Passo 3: Instalar Dependências
```bash
cd functions
npm install
```

#### Passo 4: Fazer Deploy
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

**IMPORTANTE**: Após o deploy, você receberá uma URL como:
```
https://us-central1-projeto-pi-1c9e3.cloudfunctions.net/compareImages
```

### 3. Configurar URL no App Flutter

Edite o arquivo: `lib/services/cloud_functions_service.dart`

Encontre a linha:
```dart
static const String _baseUrl = 'https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net';
```

Substitua pela URL que você recebeu no deploy. Exemplo:
```dart
static const String _baseUrl = 'https://us-central1-projeto-pi-1c9e3.cloudfunctions.net';
```

### 4. Atualizar Regras do Firestore

No Firebase Console:
1. Vá em **Firestore Database** > **Rules**
2. Adicione as regras para `image_comparisons` (já estão no arquivo `FIREBASE_SECURITY_RULES.md`)
3. Clique em **Publish**

As regras já estão documentadas em `FIREBASE_SECURITY_RULES.md`.

### 5. Testar a Integração

1. Execute o app: `flutter run`
2. Faça login
3. Navegue até a tela de comparação
4. Selecione duas imagens do mesmo ponto
5. Clique em "Comparar Imagens"
6. Aguarde o processamento (pode levar alguns segundos)
7. Visualize os resultados

## 🔍 Verificações

### Verificar se Functions está funcionando
```bash
firebase functions:log
```

### Verificar se Vision API está ativada
- Google Cloud Console > APIs & Services > Enabled APIs
- Deve aparecer "Cloud Vision API"

### Verificar se a coleção foi criada
- Firebase Console > Firestore Database
- Deve aparecer a coleção `image_comparisons` (criada automaticamente)

## 🐛 Troubleshooting

### Erro: "Cloud Function não encontrada"
- Verifique se fez o deploy: `firebase deploy --only functions`
- Verifique a URL no `cloud_functions_service.dart`
- Verifique os logs: `firebase functions:log`

### Erro: "Vision API não autorizada"
- Verifique se a API está ativada no Google Cloud
- Verifique se o billing está configurado (se necessário)

### Erro: "Usuário não autenticado"
- Verifique se está logado no app
- Verifique as regras do Firestore

### Comparações não aparecem
- Verifique os logs do Firestore
- Verifique se a coleção `image_comparisons` foi criada
- Verifique as regras de segurança

## 📚 Documentação Adicional

- Documentação completa: `docs/IA_INTEGRATION.md`
- Regras de segurança: `FIREBASE_SECURITY_RULES.md`

## ✅ Checklist Final

- [ ] Google Cloud Vision API ativada
- [ ] Firebase Functions deployadas
- [ ] URL configurada no `cloud_functions_service.dart`
- [ ] Regras do Firestore atualizadas
- [ ] Teste realizado com sucesso

---

**Pronto!** Após completar esses passos, a integração de IA estará totalmente funcional! 🎉

