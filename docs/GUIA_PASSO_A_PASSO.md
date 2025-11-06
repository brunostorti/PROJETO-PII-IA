# 🚀 Guia Passo a Passo - Configuração Completa

## 📋 Checklist Rápido

- [ ] **Passo 1**: Instalar Node.js
- [ ] **Passo 2**: Instalar Firebase CLI
- [ ] **Passo 3**: Ativar Google Cloud Vision API
- [ ] **Passo 4**: Fazer deploy das Functions
- [ ] **Passo 5**: Configurar URL no app
- [ ] **Passo 6**: Atualizar regras do Firestore
- [ ] **Passo 7**: Testar!

---

## 🔧 PASSO 1: Instalar Node.js

### Por que precisa?
O Firebase CLI precisa do Node.js para funcionar.

### Como fazer:

1. **Acesse**: https://nodejs.org/
2. **Baixe**: A versão LTS (Long Term Support) - recomendada
3. **Instale**: Execute o instalador e siga as instruções
4. **Verifique**: Abra um novo terminal e digite:
   ```bash
   node --version
   ```
   Deve mostrar algo como: `v20.x.x`

### ⏱️ Tempo estimado: 5 minutos

---

## 🔧 PASSO 2: Instalar Firebase CLI

### Por que precisa?
Para fazer deploy das Cloud Functions.

### Como fazer:

1. **Abra o terminal** (PowerShell ou CMD)
2. **Execute**:
   ```bash
   npm install -g firebase-tools
   ```
3. **Aguarde** a instalação terminar
4. **Verifique**:
   ```bash
   firebase --version
   ```
   Deve mostrar algo como: `13.x.x`

### ⏱️ Tempo estimado: 2 minutos

---

## 🔧 PASSO 3: Ativar Google Cloud Vision API

### Por que precisa?
Para a IA poder analisar as imagens.

### Como fazer:

1. **Acesse**: https://console.cloud.google.com/
2. **Faça login** com sua conta Google (mesma do Firebase)
3. **Selecione o projeto**: `projeto-pi-1c9e3`
   - Se não aparecer, clique no seletor de projetos no topo
4. **Vá para APIs**: 
   - Menu lateral > **APIs & Services** > **Library**
   - Ou acesse diretamente: https://console.cloud.google.com/apis/library
5. **Procure**: Digite "Cloud Vision API" na busca
6. **Clique** no resultado "Cloud Vision API"
7. **Clique** no botão **"ENABLE"** (Ativar)
8. **Aguarde** alguns segundos até aparecer "API enabled"

### ⏱️ Tempo estimado: 3 minutos

### 📸 Visual:
```
Google Cloud Console
  └─ APIs & Services
      └─ Library
          └─ [Buscar: "Cloud Vision API"]
              └─ [Clique em ENABLE]
```

---

## 🔧 PASSO 4: Fazer Login no Firebase

### Como fazer:

1. **Abra o terminal** na pasta do projeto:
   ```bash
   cd C:\Users\Renato\PII-2025\Projeto_PII
   ```

2. **Execute**:
   ```bash
   firebase login
   ```

3. **Siga as instruções**:
   - Abrirá o navegador
   - Faça login com sua conta Google
   - Autorize o Firebase CLI
   - Volte ao terminal

### ⏱️ Tempo estimado: 2 minutos

---

## 🔧 PASSO 5: Instalar Dependências das Functions

### Como fazer:

1. **No terminal**, execute:
   ```bash
   cd functions
   npm install
   ```

2. **Aguarde** a instalação terminar (pode levar 1-2 minutos)

3. **Volte para a pasta raiz**:
   ```bash
   cd ..
   ```

### ⏱️ Tempo estimado: 2 minutos

---

## 🔧 PASSO 6: Fazer Deploy das Functions

### Como fazer:

1. **No terminal**, na pasta raiz do projeto, execute:
   ```bash
   firebase deploy --only functions
   ```

2. **Aguarde** o deploy terminar (pode levar 2-5 minutos)

3. **Copie a URL** que aparecerá no final, algo como:
   ```
   https://us-central1-projeto-pi-1c9e3.cloudfunctions.net/compareImages
   ```

4. **Anote essa URL** - você vai precisar dela no próximo passo!

### ⏱️ Tempo estimado: 5 minutos

### ⚠️ Possíveis erros:

- **"Project not found"**: Execute `firebase use projeto-pi-1c9e3`
- **"Permission denied"**: Verifique se fez login corretamente
- **"Billing required"**: Configure o billing no Google Cloud (primeiros 1.000 requests são grátis)

---

## 🔧 PASSO 7: Configurar URL no App

### Como fazer:

1. **Abra o arquivo**: `lib/services/cloud_functions_service.dart`

2. **Encontre a linha** (por volta da linha 9):
   ```dart
   static const String _baseUrl = 'https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net';
   ```

3. **Substitua** pela URL que você copiou no Passo 6

   **Exemplo**: Se a URL foi:
   ```
   https://us-central1-projeto-pi-1c9e3.cloudfunctions.net/compareImages
   ```
   
   Você deve usar apenas a parte base:
   ```dart
   static const String _baseUrl = 'https://us-central1-projeto-pi-1c9e3.cloudfunctions.net';
   ```
   
   ⚠️ **IMPORTANTE**: Remova o `/compareImages` do final!

4. **Salve** o arquivo

### ⏱️ Tempo estimado: 1 minuto

---

## 🔧 PASSO 8: Atualizar Regras do Firestore

### Como fazer:

1. **Acesse**: https://console.firebase.google.com/
2. **Selecione o projeto**: `projeto-pi-1c9e3`
3. **Vá para Firestore**: Menu lateral > **Firestore Database**
4. **Clique na aba**: **Rules**
5. **Copie e cole** as regras abaixo no final (antes do último `}`):

```javascript
    // Regras para a coleção de comparações de imagens (IA)
    match /image_comparisons/{comparisonId} {
      // Leitura: usuário só pode ler suas próprias comparações
      allow read: if request.auth != null 
        && resource.data.userId == request.auth.uid;
      
      // Criação: usuário só pode criar comparações para si mesmo
      allow create: if request.auth != null 
        && request.resource.data.userId == request.auth.uid;
      
      // Atualização: usuário só pode atualizar suas próprias comparações
      allow update: if request.auth != null 
        && resource.data.userId == request.auth.uid;
      
      // Delete: usuário só pode deletar suas próprias comparações
      allow delete: if request.auth != null 
        && resource.data.userId == request.auth.uid;
    }
```

6. **Clique em**: **Publish**

### ⏱️ Tempo estimado: 2 minutos

### 📸 Onde encontrar:
```
Firebase Console
  └─ Firestore Database
      └─ Rules (aba no topo)
          └─ [Cole as regras]
              └─ [Publish]
```

---

## 🎉 PASSO 9: Testar!

### Como fazer:

1. **Execute o app**:
   ```bash
   flutter run
   ```

2. **Faça login** no app

3. **No dashboard**, clique no ícone de **comparação** (↔️) no AppBar

4. **Selecione duas imagens** do mesmo ponto da obra

5. **Clique em "Comparar Imagens"**

6. **Aguarde** o processamento (alguns segundos)

7. **Veja os resultados**! 🎊

---

## 🆘 Problemas Comuns

### ❌ "Node.js não encontrado"
- **Solução**: Instale o Node.js (Passo 1)

### ❌ "Firebase CLI não encontrado"
- **Solução**: Instale o Firebase CLI (Passo 2)

### ❌ "API não ativada"
- **Solução**: Ative a Cloud Vision API (Passo 3)

### ❌ "Deploy falhou"
- **Solução**: 
  - Verifique se fez login: `firebase login`
  - Verifique se instalou dependências: `cd functions && npm install`
  - Verifique os logs: `firebase functions:log`

### ❌ "Erro 403 - Permission denied"
- **Solução**: 
  - Verifique se a Vision API está ativada
  - Verifique se o billing está configurado (se necessário)

### ❌ "Comparação não funciona"
- **Solução**:
  - Verifique se a URL está correta no `cloud_functions_service.dart`
  - Verifique os logs: `firebase functions:log`
  - Verifique se as regras do Firestore foram atualizadas

---

## 📞 Links Úteis

- **Node.js**: https://nodejs.org/
- **Google Cloud Console**: https://console.cloud.google.com/
- **Firebase Console**: https://console.firebase.google.com/
- **Cloud Vision API**: https://console.cloud.google.com/apis/library/vision.googleapis.com
- **Documentação Vision API**: https://cloud.google.com/vision/docs

---

## ✅ Checklist Final

Antes de testar, confirme:

- [ ] Node.js instalado
- [ ] Firebase CLI instalado
- [ ] Login no Firebase feito
- [ ] Cloud Vision API ativada
- [ ] Dependências instaladas (`npm install` na pasta functions)
- [ ] Deploy feito com sucesso
- [ ] URL configurada no app
- [ ] Regras do Firestore atualizadas

---

**Tempo total estimado**: ~20 minutos

**Pronto!** Após completar todos os passos, a integração de IA estará funcionando! 🚀

