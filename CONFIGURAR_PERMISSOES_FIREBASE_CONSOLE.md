# 🔐 Como Configurar Permissões IAM pelo Firebase Console

## 🎯 Método 1: Via Google Cloud Console (MAIS FÁCIL)

### Passo 1: Acessar Google Cloud Console

1. No Firebase Console, clique no banner azul que diz:
   **"Acesse o console do Google Cloud para conferir..."**
   
   **OU** acesse diretamente:
   https://console.cloud.google.com/iam-admin/iam?project=projeto-pi-1c9e3

### Passo 2: Configurar Permissões

1. No menu lateral esquerdo, clique em **"IAM & Admin"**
2. Clique em **"IAM"** (ou "IAM & Admin" → "IAM")
3. Clique no botão **"GRANT ACCESS"** (ou "CONCEDER ACESSO" em português)
4. No campo **"New principals"** (Novos principais), digite: `allUsers`
5. No campo **"Select a role"** (Selecionar função), escolha: **"Cloud Functions Invoker"**
6. Clique em **"SAVE"** (Salvar)

### Passo 3: Verificar

1. Na lista de membros, procure por `allUsers`
2. Deve aparecer com a role `Cloud Functions Invoker`
3. ✅ Pronto!

---

## 🎯 Método 2: Via Firebase Console (Função Específica)

### Passo 1: Acessar a Função

1. No Firebase Console, na lista de funções
2. Clique na função **`compareImages`**

### Passo 2: Ir para Permissões

1. Na página da função, procure por:
   - **"Permissions"** (Permissões)
   - **"Security"** (Segurança)
   - **"Access"** (Acesso)
   - Ou um ícone de **cadeado** 🔒

2. Se não encontrar, clique em **"View in Google Cloud Console"** (Ver no Google Cloud Console)
   - Isso vai abrir a função no Google Cloud Console
   - Lá você encontrará a aba **"PERMISSIONS"**

### Passo 3: Adicionar Permissão

1. Na aba **"PERMISSIONS"**, clique em **"ADD PRINCIPAL"** (Adicionar principal)
2. **New principals**: `allUsers`
3. **Role**: `Cloud Functions Invoker`
4. Clique em **"SAVE"**

---

## 🎯 Método 3: Via URL Direta (MAIS RÁPIDO)

### Para a função compareImages:

1. Acesse diretamente:
   https://console.cloud.google.com/functions/details/us-central1/compareImages?project=projeto-pi-1c9e3

2. Clique na aba **"PERMISSIONS"** (Permissões)

3. Clique em **"ADD PRINCIPAL"** (Adicionar principal)

4. Preencha:
   - **New principals**: `allUsers`
   - **Role**: `Cloud Functions Invoker`

5. Clique em **"SAVE"**

---

## 📋 Resumo Rápido

1. **Acesse**: https://console.cloud.google.com/iam-admin/iam?project=projeto-pi-1c9e3
2. **Clique**: "GRANT ACCESS"
3. **Digite**: `allUsers` em "New principals"
4. **Selecione**: `Cloud Functions Invoker` em "Select a role"
5. **Salve**: Clique em "SAVE"

---

## ✅ Verificação

Após configurar, teste:
1. Recarregue o app (F5)
2. Tente comparar imagens
3. Deve funcionar! ✅

---

**Use o Método 1 (Google Cloud Console) - é o mais direto!** 🎯

