# ✅ Solução: Adicionar allUsers na Função

## 🔍 Por Que Não Funciona no Projeto?

O Google Cloud **bloqueia** `allUsers` no nível do **PROJETO** por segurança.

**Mas permite** na **FUNÇÃO específica**! ✅

---

## 🎯 SOLUÇÃO CORRETA

### ⚡ Link Direto (MAIS RÁPIDO):

```
https://console.cloud.google.com/functions/details/us-central1/compareImages?project=projeto-pi-1c9e3
```

### 📋 Passos:

1. **Abra o link acima**
2. **Clique na aba "PERMISSIONS"** (no topo da página)
3. **Clique em "ADD PRINCIPAL"** (botão no topo)
4. **Preencha:**
   - **New principals**: `allUsers`
   - **Select a role**: `Cloud Functions Invoker`
5. **Clique em "SAVE"**

---

## 🎯 Passo a Passo Visual

### 1. Acessar a Função

**Opção A - Link Direto:**
- Cole este link no navegador:
  ```
  https://console.cloud.google.com/functions/details/us-central1/compareImages?project=projeto-pi-1c9e3
  ```

**Opção B - Navegação Manual:**
1. Acesse: https://console.cloud.google.com
2. No menu lateral, clique em **"Cloud Functions"**
3. Clique na função **`compareImages`**

### 2. Abrir Permissões

1. Na página da função, você verá várias abas no topo:
   - **OVERVIEW** (Visão geral)
   - **TRIGGERS** (Gatilhos)
   - **PERMISSIONS** ← **CLIQUE AQUI**
   - **LOGS** (Registros)
   - etc.

2. Clique na aba **"PERMISSIONS"**

### 3. Adicionar Principal

1. Você verá uma lista de "Members" (Membros)
2. No topo, clique no botão **"+ ADD PRINCIPAL"**
3. Uma janela vai abrir

### 4. Preencher Formulário

Na janela que abriu:

1. **New principals** (Novos principais):
   - Digite: `allUsers`
   - Pressione Enter

2. **Select a role** (Selecionar função):
   - Clique no campo
   - Digite: `Cloud Functions Invoker`
   - Selecione a opção que aparecer

3. Clique em **"SAVE"**

### 5. Confirmar

Você verá `allUsers` na lista de membros com a role `Cloud Functions Invoker`.

---

## ✅ Verificação

Após configurar:

1. Volte ao app Flutter
2. Recarregue (F5)
3. Tente comparar imagens
4. **Deve funcionar!** ✅

---

## 🆘 Se Ainda Não Funcionar

1. Verifique se está na função correta: `compareImages`
2. Verifique se está na região correta: `us-central1`
3. Verifique se a role está correta: `Cloud Functions Invoker`
4. Aguarde alguns segundos após salvar (pode levar um momento para propagar)

---

## 📝 Nota Importante

- ✅ **Permitido**: `allUsers` na **FUNÇÃO Cloud Function**
- ❌ **Bloqueado**: `allUsers` no **PROJETO Google Cloud**

Por isso você precisa fazer na função específica!

---

**Use o link direto e siga os passos acima!** 🎯

