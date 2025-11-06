# 🔐 Como Configurar Permissões IAM para Cloud Functions

## ⚠️ Problema: "Forbidden" ou "Your client does not have permission"

Isso acontece quando a função não tem permissões públicas para ser chamada.

---

## 🎯 SOLUÇÃO: Configurar IAM no Google Cloud Console

### Passo 1: Acessar Google Cloud Console

1. Acesse: https://console.cloud.google.com/iam-admin/iam?project=projeto-pi-1c9e3
2. Faça login com a mesma conta do Firebase

### Passo 2: Adicionar Permissão Pública

1. No menu lateral, clique em **"IAM & Admin"** → **"IAM"**
2. Clique no botão **"GRANT ACCESS"** (Conceder acesso)
3. No campo **"New principals"**, digite: `allUsers`
4. No campo **"Select a role"**, selecione: **"Cloud Functions Invoker"**
5. Clique em **"SAVE"**

### Passo 3: Verificar Função

1. Acesse: https://console.cloud.google.com/functions/list?project=projeto-pi-1c9e3
2. Clique na função `compareImages`
3. Vá na aba **"PERMISSIONS"**
4. Verifique se `allUsers` tem a role `Cloud Functions Invoker`

---

## 🔄 Alternativa: Via Firebase Console

1. Acesse: https://console.firebase.google.com/project/projeto-pi-1c9e3/functions
2. Clique na função `compareImages`
3. Vá em **"Permissions"** ou **"Permissões"**
4. Adicione `allUsers` com role `Cloud Functions Invoker`

---

## ⚠️ IMPORTANTE

- **`allUsers`** permite que qualquer pessoa autenticada chame a função
- A função já verifica autenticação internamente (`context.auth`)
- Isso é seguro porque a função exige login do Firebase

---

## 🧪 Teste Após Configurar

1. Recarregue o app (F5)
2. Faça login
3. Tente comparar imagens
4. Deve funcionar! ✅

---

**Execute o script de deploy primeiro, depois configure IAM!** 🎯

