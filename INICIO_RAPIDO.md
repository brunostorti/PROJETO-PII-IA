# 🚀 Início Rápido - Integração de IA

## ⚡ O que você precisa fazer (em ordem)

### 1️⃣ Instalar Node.js
**Link direto**: https://nodejs.org/
- Baixe a versão **LTS** (recomendada)
- Instale normalmente
- ⏱️ **5 minutos**

---

### 2️⃣ Instalar Firebase CLI
**Após instalar Node.js**, abra o terminal e execute:
```bash
npm install -g firebase-tools
```
⏱️ **2 minutos**

---

### 3️⃣ Ativar Google Cloud Vision API
**Link direto**: https://console.cloud.google.com/apis/library/vision.googleapis.com?project=projeto-pi-1c9e3

1. Clique no link acima
2. Clique em **"ENABLE"** (Ativar)
3. Aguarde alguns segundos
⏱️ **2 minutos**

---

### 4️⃣ Fazer Login no Firebase
No terminal, execute:
```bash
cd C:\Users\Renato\PII-2025\Projeto_PII
firebase login
```
- Siga as instruções no navegador
⏱️ **2 minutos**

---

### 5️⃣ Instalar Dependências
No terminal, execute:
```bash
cd functions
npm install
cd ..
```
⏱️ **2 minutos**

---

### 6️⃣ Fazer Deploy
No terminal, execute:
```bash
firebase deploy --only functions
```
- **COPIE A URL** que aparecer no final!
- Exemplo: `https://us-central1-projeto-pi-1c9e3.cloudfunctions.net/compareImages`
⏱️ **5 minutos**

---

### 7️⃣ Configurar URL no App
1. Abra: `lib/services/cloud_functions_service.dart`
2. Encontre a linha 10:
   ```dart
   static const String _baseUrl = 'https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net';
   ```
3. Substitua pela URL do Passo 6 (sem o `/compareImages` no final)
4. Salve

---

### 8️⃣ Atualizar Regras do Firestore
**Link direto**: https://console.firebase.google.com/project/projeto-pi-1c9e3/firestore/rules

1. Clique no link acima
2. Cole as regras do arquivo `FIREBASE_SECURITY_RULES.md` (já estão atualizadas)
3. Clique em **Publish**

---

## 📋 Resumo dos Links

- **Node.js**: https://nodejs.org/
- **Vision API**: https://console.cloud.google.com/apis/library/vision.googleapis.com?project=projeto-pi-1c9e3
- **Firebase Console**: https://console.firebase.google.com/project/projeto-pi-1c9e3
- **Firestore Rules**: https://console.firebase.google.com/project/projeto-pi-1c9e3/firestore/rules

---

## 🎯 Ordem de Execução

```
1. Instalar Node.js (https://nodejs.org/)
   ↓
2. npm install -g firebase-tools
   ↓
3. Ativar Vision API (link acima)
   ↓
4. firebase login
   ↓
5. cd functions && npm install && cd ..
   ↓
6. firebase deploy --only functions
   ↓
7. Configurar URL no cloud_functions_service.dart
   ↓
8. Atualizar regras do Firestore
   ↓
9. flutter run e testar! 🎉
```

---

## ⚠️ IMPORTANTE

- **Coleção do Firestore**: NÃO precisa criar manualmente! Será criada automaticamente.
- **Índices**: O Firestore pode pedir para criar índices na primeira vez - apenas clique em "Create Index".
- **Billing**: Primeiros 1.000 requests/mês são GRÁTIS.

---

**Tempo total**: ~20 minutos

**Dúvidas?** Consulte `docs/GUIA_PASSO_A_PASSO.md` para instruções detalhadas!

