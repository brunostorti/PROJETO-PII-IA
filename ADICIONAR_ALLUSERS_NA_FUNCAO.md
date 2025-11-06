# 🔐 Como Adicionar allUsers na Função Específica

## ⚠️ Problema

O Google Cloud **NÃO permite** adicionar `allUsers` no nível do **PROJETO**.

**Solução**: Adicione `allUsers` diretamente na **FUNÇÃO**, não no projeto!

---

## 🎯 SOLUÇÃO: Configurar na Função Específica

### Passo 1: Acessar a Função Diretamente

**Clique neste link:**
```
https://console.cloud.google.com/functions/details/us-central1/compareImages?project=projeto-pi-1c9e3
```

**OU** faça assim:

1. No Google Cloud Console, vá em **"Cloud Functions"** (no menu lateral)
2. Clique na função **`compareImages`**

### Passo 2: Abrir Aba PERMISSIONS

1. Na página da função, clique na aba **"PERMISSIONS"** (Permissões)
2. Você verá uma lista de membros/principals

### Passo 3: Adicionar allUsers

1. Clique no botão **"ADD PRINCIPAL"** (Adicionar principal)
2. No campo **"New principals"**, digite: `allUsers`
3. No campo **"Select a role"**, escolha: **"Cloud Functions Invoker"**
4. Clique em **"SAVE"** (Salvar)

### Passo 4: Confirmar

Você verá `allUsers` na lista com a role `Cloud Functions Invoker`.

---

## 🎯 Método Alternativo: Via Firebase Console

### Passo 1: No Firebase Console

1. Acesse: https://console.firebase.google.com/project/projeto-pi-1c9e3/functions
2. Clique na função **`compareImages`**

### Passo 2: Ver no Google Cloud

1. Na página da função, procure por:
   - **"View in Google Cloud Console"** ← **CLIQUE AQUI**
   - Ou um link para o Google Cloud Console

### Passo 3: Configurar Permissões

1. No Google Cloud Console, clique na aba **"PERMISSIONS"**
2. Clique em **"ADD PRINCIPAL"**
3. Preencha:
   - **New principals**: `allUsers`
   - **Role**: `Cloud Functions Invoker`
4. Clique em **"SAVE"**

---

## 📋 Resumo Rápido

1. **Acesse a função**: https://console.cloud.google.com/functions/details/us-central1/compareImages?project=projeto-pi-1c9e3
2. **Clique na aba**: "PERMISSIONS"
3. **Clique em**: "ADD PRINCIPAL"
4. **Digite**: `allUsers`
5. **Selecione role**: `Cloud Functions Invoker`
6. **Salve**: "SAVE"

---

## ✅ Importante

- ✅ **Permitido**: Adicionar `allUsers` na **FUNÇÃO**
- ❌ **NÃO permitido**: Adicionar `allUsers` no **PROJETO**

Por isso você precisa fazer na função específica, não no projeto!

---

**Use o link direto acima para acessar a função!** 🎯

