# 🔒 Passo a Passo: Atualizar Regras do Firestore

## 📍 Link Direto
**Acesse**: https://console.firebase.google.com/project/projeto-pi-1c9e3/firestore/rules

---

## 🎯 Passo a Passo Visual

### **PASSO 1: Acessar o Firebase Console**

1. **Clique no link acima** ou acesse:
   - https://console.firebase.google.com/
   - Selecione o projeto: **projeto-pi-1c9e3**

### **PASSO 2: Navegar até Firestore Rules**

1. No **menu lateral esquerdo**, procure por:
   ```
   🔥 Firestore Database
   ```
2. **Clique** em "Firestore Database"
3. No topo da página, você verá **abas**:
   ```
   [Dados] [Índices] [Regras] [Uso]
   ```
4. **Clique na aba "Regras"** (Rules)

### **PASSO 3: Editar as Regras**

1. Você verá um **editor de código** com as regras atuais
2. **Selecione TODO o conteúdo** (Ctrl+A)
3. **Delete** o conteúdo antigo
4. **Cole** o código completo abaixo:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Regras para a coleção de projetos
    match /projects/{projectId} {
      // Leitura: 
      // - get e list: qualquer usuário autenticado (o código filtra corretamente)
      //   - getProject() é usado principalmente pelo admin (dono)
      //   - list usa arrayContains para filtrar projetos atribuídos
      allow read: if request.auth != null;
      
      // Criação: permitir se usuário autenticado e userId = UID do usuário
      // Verifica se é admin (se documento users/{uid} existir), mas permite mesmo se não existir
      allow create: if request.auth != null 
        && request.resource.data.userId == request.auth.uid
        && (
          // Se documento users/{uid} não existir, permite
          !exists(/databases/$(database)/documents/users/$(request.auth.uid))
          ||
          // Se existir, verifica se é admin
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'
        );
      
      // Atualização: somente dono (pode atualizar qualquer campo, incluindo assignedUsers)
      allow update: if request.auth != null && request.auth.uid == resource.data.userId;
      
      // Delete: somente dono
      allow delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    // Regras para a coleção de registros de obras
    match /registros_obras/{registroId} {
      // Leitura: dono OU admin dono do projeto relacionado
      allow read: if request.auth != null && (
        request.auth.uid == resource.data.userId ||
        (
          resource.data.projectId != null &&
          get(/databases/$(database)/documents/projects/$(resource.data.projectId)).data.userId == request.auth.uid
        )
      );
      // Criação: qualquer usuário autenticado pode criar seu próprio registro
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      // Update/Delete: apenas dono
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    // Regras para futuras coleções de usuários
    match /users/{userId} {
      // Usuário só pode acessar seus próprios dados
      allow read, write: if request.auth != null 
        && request.auth.uid == userId;

      // Campo de role esperado: 'admin' | 'user'
      // Document example:
      // users/{uid} => { role: 'admin' | 'user', displayName: '...' }
    }
    
    // Regras para a coleção de comparações de imagens (IA)
    match /image_comparisons/{comparisonId} {
      // Leitura: usuário só pode ler suas próprias comparações
      allow read: if request.auth != null 
        && resource.data.userId == request.auth.uid;
      
      // Criação: usuário só pode criar comparações para si mesmo
      allow create: if request.auth != null 
        && request.resource.data.userId == request.auth.uid;
      
      // Atualização: usuário só pode atualizar suas próprias comparações
      allow update: if request.auth != null 
        && resource.data.userId == request.auth.uid;
      
      // Delete: usuário só pode deletar suas próprias comparações
      allow delete: if request.auth != null 
        && resource.data.userId == request.auth.uid;
    }
  }
}
```

### **PASSO 4: Publicar as Regras**

1. Após colar o código, **role a página para baixo**
2. Você verá um botão **"Publicar"** (Publish) no canto superior direito
3. **Clique em "Publicar"**
4. Aguarde a confirmação: "Rules published successfully"

### **PASSO 5: Verificar**

1. Você deve ver uma mensagem verde: **"Rules published successfully"**
2. As regras agora estão ativas!

---

## ⚠️ Importante

- **Não precisa criar a coleção manualmente** - ela será criada automaticamente quando o primeiro documento for salvo
- **Se aparecer algum erro de sintaxe**, verifique se copiou todo o código corretamente
- **As regras antigas serão substituídas** - isso é normal e esperado

---

## ✅ Checklist

- [ ] Acessei o Firebase Console
- [ ] Naveguei até Firestore Database > Rules
- [ ] Colei o código completo das regras
- [ ] Cliquei em "Publicar"
- [ ] Vi a mensagem de sucesso

---

**Pronto!** As regras do Firestore estão atualizadas! 🎉

