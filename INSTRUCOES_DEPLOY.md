# 🚀 INSTRUÇÕES PARA DEPLOY - SOLUÇÃO DEFINITIVA

## ✅ Correções Aplicadas

A função `compareImages` foi corrigida com:
- ✅ Melhor tratamento de erros
- ✅ Logs detalhados em cada etapa
- ✅ Validação de download de imagens
- ✅ Timeout de 30 segundos por imagem
- ✅ Limite de 10MB por imagem
- ✅ Mensagens de erro mais claras

---

## 🎯 COMANDO PARA DEPLOY

### Opção 1: Script Automático (RECOMENDADO)

Execute no PowerShell (na raiz do projeto):

```powershell
.\deploy_function_corrigida.ps1
```

Este script vai:
1. ✅ Verificar dependências
2. ✅ Instalar se necessário
3. ✅ Fazer login no Firebase (se necessário)
4. ✅ Fazer deploy da função

---

### Opção 2: Manual

Se preferir fazer manualmente:

```powershell
# 1. Ir para pasta functions
cd functions

# 2. Instalar dependências (se necessário)
npm install

# 3. Voltar para raiz
cd ..

# 4. Fazer deploy
firebase deploy --only functions:compareImages
```

**OU** se npm não estiver no PATH:

```powershell
cd functions
& "$env:APPDATA\npm\npm.cmd" install
cd ..
& "$env:APPDATA\npm\firebase.cmd" deploy --only functions:compareImages
```

---

## ⚠️ IMPORTANTE

1. **Certifique-se de estar logado no Firebase:**
   ```powershell
   firebase login
   ```

2. **Certifique-se de estar no projeto correto:**
   ```powershell
   firebase use projeto-pi-1c9e3
   ```

---

## 📋 Após o Deploy

1. ✅ A função será atualizada no Firebase
2. ✅ Teste a comparação de imagens no app
3. ✅ Se ainda der erro, veja os logs:
   ```powershell
   firebase functions:log --only compareImages
   ```

---

## 🆘 Se Der Erro no Deploy

**Erro de permissões:**
- Verifique se está logado: `firebase login`
- Verifique se tem permissões no projeto

**Erro de dependências:**
- Execute: `cd functions && npm install && cd ..`

**Erro de região:**
- A função está configurada para `us-central1`
- Não precisa mudar nada

---

## ✅ PRÓXIMO PASSO

**Execute o script agora:**
```powershell
.\deploy_function_corrigida.ps1
```

**OU** execute os comandos manuais acima.

---

**Isso vai resolver o erro `[firebase_functions/internal] internal`!** 🎯

