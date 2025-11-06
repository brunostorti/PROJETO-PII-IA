# 📋 Como Criar o Índice do Firestore

## ⚠️ Erro Atual
```
[cloud_firestore/failed-precondition] The query requires an index.
```

## 🔗 Link Direto (Clique Aqui)
O erro no console deve ter um link. Clique nele para criar o índice automaticamente.

**OU** acesse manualmente:
```
https://console.firebase.google.com/project/projeto-pi-1c9e3/firestore/indexes
```

---

## 📝 Passo a Passo Manual

### 1. Acesse o Firebase Console
- Vá para: https://console.firebase.google.com/project/projeto-pi-1c9e3/firestore/indexes

### 2. Clique em "Criar Índice"

### 3. Preencha os Campos:
- **Coleção**: `image_comparisons`
- **Campos do Índice**:
  1. `userId` - **Ascendente** (Ascending)
  2. `projectId` - **Ascendente** (Ascending)  
  3. `timestamp` - **Descendente** (Descending)

### 4. Clique em "Criar"

### 5. Aguarde
- O índice pode levar alguns minutos para ser criado
- Você verá o status mudando de "Criando" para "Habilitado"

---

## ✅ Verificação
Após criar o índice, recarregue o app e tente fazer uma comparação novamente.

O erro de índice deve desaparecer! 🎉

