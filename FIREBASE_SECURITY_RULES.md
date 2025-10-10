# Regras de Segurança Firebase

Este documento contém as regras de segurança necessárias para o projeto Firebase.

## Firestore Rules

Configure estas regras no Firebase Console > Firestore Database > Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Regras para a coleção de projetos
    match /projects/{projectId} {
      // Leitura: dono pode ler
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      // Criação: apenas admins podem criar projetos (validados via users/{uid}.role)
      allow create: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' &&
        request.resource.data.userId == request.auth.uid;
      // Escrita/atualização: somente dono (admin já será o dono ao criar)
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.userId;
      
      // Permitir criação apenas se o usuário estiver autenticado
      // e o userId do documento for igual ao UID do usuário
      allow create: if request.auth != null 
        && request.auth.uid == request.resource.data.userId;
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
  }
}
```

## Storage Rules

Configure estas regras no Firebase Console > Storage > Rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Regras para imagens de projetos
    match /users/{userId}/projects/{projectId}/images/{fileName} {
      // Permitir leitura e escrita apenas se o usuário estiver autenticado
      // e for o dono do diretório
      allow read, write: if request.auth != null 
        && request.auth.uid == userId;
    }
    
    // Regras para imagens de registros de obras
    match /obras/{userId}/{year}/{month}/{fileName} {
      // Permitir leitura e escrita apenas se o usuário estiver autenticado
      // e for o dono do diretório
      allow read, write: if request.auth != null 
        && request.auth.uid == userId;
    }
    
    // Regras para outros arquivos do usuário
    match /users/{userId}/{allPaths=**} {
      // Usuário só pode acessar seus próprios arquivos
      allow read, write: if request.auth != null 
        && request.auth.uid == userId;
    }
  }
}
```

## Como Aplicar as Regras

### 1. Firestore Rules
1. Acesse o [Firebase Console](https://console.firebase.google.com/)
2. Selecione seu projeto
3. Vá para **Firestore Database** > **Rules**
4. Cole o código das regras do Firestore
5. Clique em **Publish**

### 2. Storage Rules
1. No Firebase Console, vá para **Storage** > **Rules**
2. Cole o código das regras do Storage
3. Clique em **Publish**

## Testando as Regras

### Firestore
```javascript
// Teste de leitura (deve falhar se não for o dono)
// Teste de escrita (deve falhar se não for o dono)
// Teste de criação (deve falhar se userId não for igual ao UID)
```

### Storage
```javascript
// Teste de upload (deve falhar se não for o dono)
// Teste de download (deve falhar se não for o dono)
// Teste de delete (deve falhar se não for o dono)
```

## Considerações de Segurança

1. **Autenticação Obrigatória**: Todas as operações requerem autenticação
2. **Isolamento por Usuário**: Cada usuário só pode acessar seus próprios dados
3. **Validação de Propriedade**: Verificação de que o usuário é dono dos dados
4. **Estrutura Hierárquica**: Organização clara dos dados por usuário

## Monitoramento

- Monitore as regras no Firebase Console > Firestore/Storage > Usage
- Configure alertas para tentativas de acesso negadas
- Revise logs regularmente para identificar padrões suspeitos

## Atualizações Futuras

Quando adicionar novas coleções ou funcionalidades:

1. Adicione regras específicas para cada nova coleção
2. Mantenha o princípio de isolamento por usuário
3. Teste as regras antes de publicar
4. Documente as mudanças neste arquivo
