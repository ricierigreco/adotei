-- ==============================================================================
-- RLS COMPLETO — ADOTEI!
-- Execute este script no SQL Editor do Supabase Dashboard.
-- Pode reexecutar com segurança — todos os comandos usam IF NOT EXISTS / DROP IF EXISTS.
-- ==============================================================================

-- ==============================================================================
-- TABELA: profiles
-- ==============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Qualquer pessoa pode ver perfis (exibição do protetor no detalhe do animal)
DROP POLICY IF EXISTS "profiles_select_public" ON public.profiles;
CREATE POLICY "profiles_select_public"
  ON public.profiles FOR SELECT
  USING (true);

-- Usuários autenticados podem inserir o próprio perfil
DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
CREATE POLICY "profiles_insert_own"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Usuários autenticados podem atualizar o próprio perfil
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Usuários autenticados podem deletar o próprio perfil
DROP POLICY IF EXISTS "profiles_delete_own" ON public.profiles;
CREATE POLICY "profiles_delete_own"
  ON public.profiles FOR DELETE
  TO authenticated
  USING (auth.uid() = id);

-- ==============================================================================
-- TABELA: animals
-- ==============================================================================

ALTER TABLE public.animals ENABLE ROW LEVEL SECURITY;

-- Qualquer pessoa (inclusive não logada) pode ver animais disponíveis
DROP POLICY IF EXISTS "animals_select_public" ON public.animals;
CREATE POLICY "animals_select_public"
  ON public.animals FOR SELECT
  USING (true);

-- Usuários autenticados podem cadastrar animais
DROP POLICY IF EXISTS "animals_insert_authenticated" ON public.animals;
CREATE POLICY "animals_insert_authenticated"
  ON public.animals FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = protector_id OR protector_id IS NULL);

-- Usuários podem atualizar apenas os próprios animais (ou animais de seed sem dono)
DROP POLICY IF EXISTS "animals_update_own" ON public.animals;
CREATE POLICY "animals_update_own"
  ON public.animals FOR UPDATE
  TO authenticated
  USING (auth.uid() = protector_id OR protector_id IS NULL)
  WITH CHECK (auth.uid() = protector_id OR protector_id IS NULL);

-- Usuários podem excluir apenas os próprios animais
DROP POLICY IF EXISTS "animals_delete_own" ON public.animals;
CREATE POLICY "animals_delete_own"
  ON public.animals FOR DELETE
  TO authenticated
  USING (auth.uid() = protector_id OR protector_id IS NULL);

-- ==============================================================================
-- STORAGE: bucket "animals" (fotos dos animais)
-- ==============================================================================

-- Leitura pública (qualquer pessoa pode ver as fotos)
DROP POLICY IF EXISTS "storage_animals_select_public" ON storage.objects;
CREATE POLICY "storage_animals_select_public"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'animals');

-- Apenas autenticados podem fazer upload no bucket animals
DROP POLICY IF EXISTS "storage_animals_insert_auth" ON storage.objects;
CREATE POLICY "storage_animals_insert_auth"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'animals');

-- Apenas autenticados podem atualizar/substituir arquivos em animals
DROP POLICY IF EXISTS "storage_animals_update_auth" ON storage.objects;
CREATE POLICY "storage_animals_update_auth"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'animals');

-- Apenas autenticados podem deletar arquivos de animals
DROP POLICY IF EXISTS "storage_animals_delete_auth" ON storage.objects;
CREATE POLICY "storage_animals_delete_auth"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'animals');

-- ==============================================================================
-- STORAGE: bucket "profiles" (fotos de perfil dos usuários)
-- ==============================================================================

-- Leitura pública das fotos de perfil
DROP POLICY IF EXISTS "storage_profiles_select_public" ON storage.objects;
CREATE POLICY "storage_profiles_select_public"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'profiles');

-- Upload restrito ao próprio usuário (path começa com o UUID do usuário)
DROP POLICY IF EXISTS "storage_profiles_insert_own" ON storage.objects;
CREATE POLICY "storage_profiles_insert_own"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'profiles'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Atualização restrita ao próprio usuário
DROP POLICY IF EXISTS "storage_profiles_update_own" ON storage.objects;
CREATE POLICY "storage_profiles_update_own"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'profiles'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Deleção restrita ao próprio usuário
DROP POLICY IF EXISTS "storage_profiles_delete_own" ON storage.objects;
CREATE POLICY "storage_profiles_delete_own"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'profiles'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ==============================================================================
-- TRIGGER: criação automática de perfil ao registrar usuário
-- Garante que ao criar conta via supabase.auth.signUp(), um perfil é criado.
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, phone, city, state, created_at)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    COALESCE(new.email, ''),
    COALESCE(new.raw_user_meta_data->>'phone', ''),
    COALESCE(new.raw_user_meta_data->>'city', ''),
    COALESCE(new.raw_user_meta_data->>'state', ''),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE
    SET
      name  = EXCLUDED.name,
      email = EXCLUDED.email;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- VERIFICAÇÃO FINAL — Lista todas as políticas ativas
-- ==============================================================================
SELECT
  schemaname,
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename IN ('profiles', 'animals', 'objects')
ORDER BY tablename, cmd;
