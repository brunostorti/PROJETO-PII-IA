# 🎯 Passo a Passo Visual - Configurar IAM

## 📍 ONDE ESTÁ NO FIREBASE CONSOLE

### Opção 1: Link Direto no Banner

No Firebase Console, você vê um banner azul que diz:
> "Acesse o console do Google Cloud para conferir..."

**Clique nos links azuis desse banner!** Eles levam direto ao Google Cloud Console.

---

## 🚀 PASSO A PASSO COMPLETO

### Passo 1: Abrir Google Cloud Console

**Clique aqui** (ou copie e cole no navegador):
```
https://console.cloud.google.com/iam-admin/iam?project=projeto-pi-1c9e3
```

### Passo 2: Menu Lateral

No menu lateral esquerdo, você verá:
- ☁️ Cloud Overview
- 🔍 IAM & Admin ← **CLIQUE AQUI**
- 📊 Billing
- etc.

### Passo 3: IAM

Dentro de "IAM & Admin", clique em:
- **IAM** ← **CLIQUE AQUI**

### Passo 4: Botão Grant Access

No topo da página, você verá um botão:
- **"+ GRANT ACCESS"** ou **"+ CONCEDER ACESSO"** ← **CLIQUE AQUI**

### Passo 5: Preencher Formulário

Uma janela vai abrir. Preencha:

1. **New principals** (Novos principais):
   ```
   allUsers
   ```

2. **Select a role** (Selecionar função):
   - Clique no campo
   - Digite: `Cloud Functions Invoker`
   - Selecione a opção que aparecer

3. Clique em **"SAVE"** (Salvar)

### Passo 6: Confirmar

Você verá uma mensagem de confirmação e `allUsers` aparecerá na lista com a role `Cloud Functions Invoker`.

---

## 🎯 ALTERNATIVA: Pela Função Específica

### Passo 1: Acessar Função

No Firebase Console, na lista de funções:
1. Clique em **`compareImages`**

### Passo 2: Ver no Google Cloud

Na página da função, procure por:
- **"View in Google Cloud Console"** ← **CLIQUE AQUI**

### Passo 3: Aba Permissions

No Google Cloud Console:
1. Clique na aba **"PERMISSIONS"** (Permissões)
2. Clique em **"ADD PRINCIPAL"** (Adicionar principal)
3. Preencha:
   - **New principals**: `allUsers`
   - **Role**: `Cloud Functions Invoker`
4. Clique em **"SAVE"**

---

## ✅ TESTE

Após configurar:
1. Volte ao app
2. Recarregue (F5)
3. Tente comparar imagens
4. **Deve funcionar!** ✅

---

## 🆘 Se Não Encontrar

**Use este link direto:**
https://console.cloud.google.com/iam-admin/iam?project=projeto-pi-1c9e3

Depois siga do **Passo 2** acima.

---

**É mais fácil pelo Google Cloud Console!** 🎯

