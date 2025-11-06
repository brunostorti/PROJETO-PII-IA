# 🔍 Guia Completo - Como Encontrar e Configurar CORS

## 📍 Método 1: Google Cloud Console (Mais Direto)

### Passo 1: Acesse o Bucket
1. Você já está na página de buckets
2. **Clique diretamente no NOME do bucket**: `projeto-pi-1c9e3.firebasestorage.app`
   - NÃO clique no menu de 3 pontos
   - Clique no próprio nome/texto do bucket

### Passo 2: Na Página de Detalhes
Após clicar no nome, você verá uma página com várias abas no topo:
- **Visão geral** (Overview)
- **Objetos** (Objects)
- **Configurações** (Settings) ← **CLIQUE AQUI**
- **Permissões** (Permissions)
- **Lifecycle** (Ciclo de vida)

### Passo 3: Encontre CORS
1. Clique na aba **"Configurações"** (Settings)
2. Role a página para baixo
3. Procure por uma seção chamada:
   - **"CORS"** ou
   - **"Cross-Origin Resource Sharing"** ou
   - **"Configuração de CORS"**

### Passo 4: Adicionar Configuração
1. Se já houver uma configuração, clique em **"Editar"** (Edit)
2. Se não houver, clique em **"Adicionar configuração CORS"** ou **"Add CORS configuration"**
3. Cole este JSON:

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

4. Clique em **"Salvar"** (Save)

---

## 📍 Método 2: Via Firebase Console

### Passo 1: Acesse Firebase Console
1. Vá para: https://console.firebase.google.com/project/projeto-pi-1c9e3/storage
2. Você verá o bucket listado

### Passo 2: Configurações
1. Clique no bucket
2. Procure por um ícone de **engrenagem** ⚙️ ou **"Configurações"**
3. Procure por **"CORS"**

**Nota**: No Firebase Console, a configuração de CORS pode não estar disponível diretamente. Nesse caso, use o Método 1 (Google Cloud Console).

---

## 📍 Método 3: Via Firebase CLI (Terminal)

Se você não conseguir encontrar a opção na interface, podemos configurar via terminal:

### Comando:
```bash
# Criar arquivo CORS
echo '[{"origin":["*"],"method":["GET","HEAD","OPTIONS"],"responseHeader":["Content-Type","Authorization","Content-Length"],"maxAgeSeconds":3600}]' > cors.json

# Aplicar CORS ao bucket
gsutil cors set cors.json gs://projeto-pi-1c9e3.firebasestorage.app
```

**Mas primeiro precisamos instalar o `gsutil` ou usar o Firebase CLI.**

---

## 🎯 O Que Procurar Exatamente

Na página de **Configurações** do bucket, você deve procurar por:

1. **Seção "CORS"** - geralmente no final da página
2. **Botão "Aditar configuração CORS"** ou **"Edit CORS configuration"**
3. **Área de texto JSON** onde você pode colar a configuração

---

## ❓ Se Ainda Não Encontrar

Me diga:
1. **O que você vê** quando clica no nome do bucket?
2. **Quais abas** aparecem no topo da página?
3. **Há alguma seção** chamada "Configurações", "Settings", "Permissions"?

Com essas informações, posso te guiar mais especificamente! 🚀

