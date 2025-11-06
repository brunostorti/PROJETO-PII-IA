# 🔐 Como Fazer Login no Firebase - MÉTODO CERTO

## ✅ Método Mais Simples (RECOMENDADO)

### **Passo 1: Execute o Script**
1. Na pasta do projeto, você verá um arquivo: `fazer_login_firebase.ps1`
2. **Clique com o botão direito** nele
3. Selecione **"Executar com PowerShell"**
4. Aguarde o script executar
5. Ele abrirá o navegador automaticamente para você autorizar

---

## 🔧 Método Manual (Se o script não funcionar)

### **Passo 1: Abrir PowerShell como Administrador**
1. Pressione `Win + X`
2. Selecione **"Windows PowerShell (Admin)"** ou **"Terminal (Admin)"**

### **Passo 2: Executar estes comandos UM POR VEZ**

```powershell
cd C:\Users\Renato\PII-2025\Projeto_PII
```

```powershell
& "$env:APPDATA\npm\firebase.cmd" login
```

### **Passo 3: Autorizar no Navegador**
- O navegador abrirá automaticamente
- Faça login com sua conta Google
- Clique em **"Permitir"** ou **"Allow"**

---

## 🎯 O que Deve Acontecer

Após executar o comando, você verá:
1. Uma mensagem dizendo que o navegador será aberto
2. O navegador abrirá automaticamente
3. Você faz login e autoriza
4. Volta ao terminal e vê: **"✔ Success! Logged in as seu-email@gmail.com"**

---

## ⚠️ Se Não Funcionar

Me avise qual erro apareceu e eu te ajudo a resolver!

