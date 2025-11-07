# 👥 Gerenciar Usuários do Projeto

## ✅ O que foi implementado

A funcionalidade para que o **admin** (ou dono do projeto) possa adicionar usuários a um projeto já está implementada!

### Funcionalidades disponíveis:

1. **Botão no AppBar** - Ícone de pessoas (👥) na tela de detalhes do projeto
   - Visível apenas para **admin** ou **dono do projeto**
   - Abre a tela de gerenciamento de usuários

2. **Tela de Gerenciamento** (`ProjectUsersScreen`)
   - Busca de usuários por email
   - Lista de usuários atribuídos ao projeto
   - Adicionar usuários ao projeto
   - Remover usuários do projeto

3. **Serviços implementados**
   - `ProjectService.addUserToProject()` - Adiciona usuário
   - `ProjectService.removeUserFromProject()` - Remove usuário
   - `UserService.searchUsers()` - Busca usuários

4. **Regras de segurança atualizadas**
   - Admin pode atualizar projetos (incluindo `assignedUsers`)
   - Dono do projeto pode atualizar projetos

## 📋 O que você precisa fazer

### Atualizar as Regras do Firestore

As regras precisam ser atualizadas para permitir que admins atualizem projetos.

**Acesse**: https://console.firebase.google.com/project/projeto-pi-1c9e3/firestore/rules

**Substitua a regra de atualização de projetos** (linha ~61) por:

```javascript
// Atualização: dono OU admin (pode atualizar qualquer campo, incluindo assignedUsers)
allow update: if request.auth != null && (
  request.auth.uid == resource.data.userId ||
  (
    exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'
  )
);
```

**Ou use o arquivo completo atualizado**: `ATUALIZAR_FIRESTORE_RULES.md`

## 🎯 Como usar

1. **Acesse um projeto** (como admin ou dono)
2. **Clique no ícone de pessoas** (👥) no AppBar
3. **Busque usuários** digitando o email no campo de busca
4. **Adicione usuários** clicando no botão ➕ ao lado do usuário
5. **Remova usuários** clicando no botão 🗑️ na lista de usuários atribuídos

## 📝 Notas importantes

- **Usuários precisam ter documento no Firestore** para aparecer na busca
- Usuários adicionados ao projeto terão acesso a:
  - Ver o projeto na lista
  - Acessar pontos da obra
  - Fazer comparações
  - Ver relatórios
- Apenas o **dono** pode deletar o projeto
- **Admin** pode adicionar/remover usuários de qualquer projeto

## 🔒 Segurança

- Apenas **admin** ou **dono do projeto** podem gerenciar usuários
- As regras do Firestore validam permissões no servidor
- Usuários atribuídos têm acesso de leitura/escrita ao projeto e seus pontos

