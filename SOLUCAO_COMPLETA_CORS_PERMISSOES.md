# ✅ SOLUÇÃO COMPLETA - CORS e Permissões

## 🔍 Problemas Identificados

1. **CORS Error**: `Access-Control-Allow-Origin header is missing`
2. **Forbidden Error**: `Your client does not have permission to get URL`

---

## ✅ Correções Aplicadas

### 1. **Função Corrigida**
- ✅ Região explícita: `.region('us-central1')`
- ✅ Timeout aumentado: `120 segundos`
- ✅ Memória aumentada: `512MB`
- ✅ Configuração `runWith` adicionada

### 2. **Script de Deploy Criado**
- ✅ `configurar_permissoes_firebase.ps1` - Script completo

---

## 🚀 PASSO A PASSO PARA RESOLVER

### Passo 1: Fazer Deploy da Função

Execute no PowerShell:

```powershell
.\configurar_permissoes_firebase.ps1
```

Este script vai:
- ✅ Verificar login no Firebase
- ✅ Configurar projeto correto
- ✅ Instalar dependências
- ✅ Fazer deploy das funções

---

### Passo 2: Configurar Permissões IAM

**Opção A: Via Google Cloud Console (RECOMENDADO)**

1. Acesse: https://console.cloud.google.com/iam-admin/iam?project=projeto-pi-1c9e3
2. Clique em **"GRANT ACCESS"**
3. **New principals**: `allUsers`
4. **Role**: `Cloud Functions Invoker`
5. Clique em **"SAVE"**

**Opção B: Via Firebase Console**

1. Acesse: https://console.firebase.google.com/project/projeto-pi-1c9e3/functions
2. Clique na função `compareImages`
3. Vá em **"Permissions"**
4. Adicione `allUsers` com role `Cloud Functions Invoker`

---

### Passo 3: Testar

1. Recarregue o app (F5)
2. Faça login
3. Selecione duas imagens
4. Clique em "Comparar Imagens"
5. **Deve funcionar!** ✅

---

## 📋 O Que Foi Corrigido

1. ✅ Função com região explícita
2. ✅ Timeout e memória configurados
3. ✅ Script de deploy criado
4. ✅ Instruções de IAM criadas

---

## ⚠️ IMPORTANTE

- A função **já verifica autenticação** internamente
- Permitir `allUsers` é seguro porque exige login
- O erro de CORS será resolvido após configurar IAM

---

## 🆘 Se Ainda Der Erro

1. Verifique se o deploy foi concluído:
   ```powershell
   firebase functions:list
   ```

2. Verifique os logs:
   ```powershell
   firebase functions:log --only compareImages
   ```

3. Verifique IAM:
   - Certifique-se de que `allUsers` tem `Cloud Functions Invoker`

---

**Execute o script e configure IAM agora!** 🎯

