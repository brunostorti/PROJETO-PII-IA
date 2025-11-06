# 📋 Como Configurar CORS no Firebase Storage

## 🎯 Passo a Passo

### 1. **Clique no Nome do Bucket**
- Clique no nome do bucket: `projeto-pi-1c9e3.firebasestorage.app`
- Isso abrirá a página de detalhes do bucket

### 2. **Vá para a Aba "Configurações" ou "Settings"**
- Na página de detalhes do bucket, procure por uma aba chamada:
  - **"Configurações"** (Settings)
  - **"Permissões"** (Permissions)
  - Ou **"CORS"** diretamente

### 3. **Encontre a Seção CORS**
- Procure por uma seção chamada **"CORS"** ou **"Cross-Origin Resource Sharing"**
- Pode estar em:
  - Configurações → CORS
  - Ou como um botão/aba separada

### 4. **Adicione a Configuração CORS**
- Clique em **"Adicionar configuração CORS"** ou **"Edit CORS configuration"**
- Cole este JSON:

```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "OPTIONS"],
    "responseHeader": ["Content-Type", "Authorization", "Content-Length"],
    "maxAgeSeconds": 3600
  }
]
```

### 5. **Salve**
- Clique em **"Salvar"** ou **"Save"**

---

## 🔄 Alternativa: Via Firebase Console

Se não encontrar no Google Cloud Console, tente pelo Firebase Console:

1. Acesse: https://console.firebase.google.com/project/projeto-pi-1c9e3/storage
2. Clique no bucket
3. Procure por "Configurações" ou "Settings"
4. Procure por "CORS"

---

## 📝 Nota Importante

Se não encontrar a opção de CORS, pode ser que:
- O bucket seja gerenciado pelo Firebase (algumas configurações podem estar desabilitadas)
- Você precise de permissões de "Storage Admin" ou "Owner"

Nesse caso, podemos tentar outra abordagem: usar URLs com tokens de autenticação (já implementado no código).

---

**Me avise se encontrou a opção de CORS ou se precisa de ajuda!** 🚀

