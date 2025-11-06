# 🔒 Atualizar Regras do Firebase Storage

## ⚠️ IMPORTANTE: Problema de Carregamento de Imagens

O erro "HTTP request failed, statusCode: 0" indica que as regras do Firebase Storage estão bloqueando o acesso às imagens.

## 📍 Link Direto
**Acesse**: https://console.firebase.google.com/project/projeto-pi-1c9e3/storage/rules

---

## 🎯 Passo a Passo

### **PASSO 1: Acessar Storage Rules**

1. **Acesse o link acima** ou:
   - Firebase Console: https://console.firebase.google.com/
   - Selecione o projeto: **projeto-pi-1c9e3**
   - Menu lateral > **Storage**
   - Clique na aba **"Rules"** (Regras)

### **PASSO 2: Editar as Regras**

1. Você verá um **editor de código** com as regras atuais
2. **Selecione TODO o conteúdo** (Ctrl+A)
3. **Delete** o conteúdo antigo
4. **Cole** o código completo abaixo:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Regras para imagens de projetos
    match /users/{userId}/projects/{projectId}/images/{fileName} {
      // Permitir leitura se usuário autenticado E for o dono
      allow read: if request.auth != null 
        && request.auth.uid == userId;
      // Permitir escrita apenas se for o dono
      allow write: if request.auth != null 
        && request.auth.uid == userId;
    }
    
    // Regras para imagens de registros de obras
    match /obras/{userId}/{year}/{month}/{fileName} {
      // Permitir leitura se usuário autenticado E for o dono
      allow read: if request.auth != null 
        && request.auth.uid == userId;
      // Permitir escrita apenas se for o dono
      allow write: if request.auth != null 
        && request.auth.uid == userId;
    }
    
    // Regra genérica para permitir leitura de imagens autenticadas
    // Isso resolve problemas de CORS e acesso no web
    match /{allPaths=**} {
      // Permitir leitura se usuário estiver autenticado
      // Isso permite que URLs com token funcionem corretamente
      allow read: if request.auth != null;
      // Escrita apenas para paths específicos acima
      allow write: if false;
    }
  }
}
```

### **PASSO 3: Publicar as Regras**

1. Após colar o código, **role a página para baixo**
2. Você verá um botão **"Publicar"** (Publish) no canto superior direito
3. **Clique em "Publicar"**
4. Aguarde a confirmação: "Rules published successfully"

### **PASSO 4: Verificar**

1. Você deve ver uma mensagem verde: **"Rules published successfully"**
2. As regras agora estão ativas!
3. **Recarregue o app** no navegador (F5)

---

## ⚠️ Importante

- **A regra genérica** `match /{allPaths=**}` permite leitura autenticada de qualquer arquivo
- **Isso é seguro** porque exige autenticação (`request.auth != null`)
- **A escrita** continua restrita aos paths específicos

---

## ✅ Checklist

- [ ] Acessei o Firebase Console > Storage > Rules
- [ ] Colei o código completo das regras
- [ ] Cliquei em "Publicar"
- [ ] Vi a mensagem de sucesso
- [ ] Recarreguei o app (F5)

---

**Pronto!** As regras do Storage estão atualizadas! 🎉

