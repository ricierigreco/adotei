# Adotei! 🐾

Aplicativo multiplataforma (Web, Android e iOS) em **Flutter** para conectar protetores de animais (pessoas físicas ou ONGs) a pessoas interessadas em adotar pets com facilidade e carinho.

---

## 🚀 Integração com o Supabase

O projeto já está 100% configurado para rodar com o **Supabase** (PostgreSQL, Auth e Storage).

### Passo 1: Criar o Projeto no Supabase
1. Acesse [supabase.com](https://supabase.com) e faça login gratuito.
2. Clique em **"New Project"**, defina um nome (ex: `adotei-db`) e uma senha de banco de dados.

### Passo 2: Executar o Script do Banco de Dados
1. No dashboard do seu projeto Supabase, acesse a aba **"SQL Editor"** (ícone `>_` no menu lateral esquerdo).
2. Abra o arquivo [`supabase/schema.sql`](supabase/schema.sql) deste repositório, copie todo o conteúdo e cole no SQL Editor.
3. Clique em **"Run"** (ou aperte `Ctrl+Enter`).
   - Isso criará:
     - A tabela `profiles` com sincronização automática do Supabase Auth.
     - A tabela `animals` com índices e segurança por Row Level Security (RLS).
     - Os buckets de Storage `animals` e `profiles` (públicos para fotos).
     - O **Seed inicial com 15 animais reais** cadastrados com fotos de alta resolução do Google/Unsplash!

### Passo 3: Configurar as Chaves no App
1. No Dashboard do Supabase, vá em **Project Settings** (ícone de engrenagem) ➔ **API**.
2. Copie:
   - **Project URL**
   - **Project API Keys ➔ `anon` `public`**
3. Abra o arquivo [`lib/core/config/app_config.dart`](lib/core/config/app_config.dart) e preencha:
   ```dart
   static const String supabaseUrl = 'https://SEU_PROJETO.supabase.co';
   static const String supabaseAnonKey = 'SUA_CHAVE_ANON_AQUI';
   ```

---

## 📱 Executando a Aplicação

Para rodar localmente no Chrome:
```bash
flutter run -d chrome
```

Para rodar no Android ou iOS:
```bash
flutter run
```

> **Dica**: Se as credenciais do Supabase ainda não forem preenchidas, o aplicativo inicia de forma transparente e segura com os dados de demonstração (Mock), permitindo que você navegue pela interface imediatamente.
