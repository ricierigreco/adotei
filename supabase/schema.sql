-- ==============================================================================
-- SCRIPT DE CRIAÇÃO DO BANCO DE DADOS & SEED — ADOTEI! (SUPABASE)
-- Execute este script no "SQL Editor" do Dashboard do seu projeto Supabase.
-- ==============================================================================

-- 1. Habilitar extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 2. TABELA DE PERFIS DE USUÁRIOS (PROFILES)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT DEFAULT '',
    city TEXT DEFAULT '',
    state TEXT DEFAULT '',
    profile_picture_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    is_email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Habilitar Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Políticas de RLS para Profiles
DROP POLICY IF EXISTS "Perfis são visíveis publicamente" ON public.profiles;
CREATE POLICY "Perfis são visíveis publicamente" 
ON public.profiles FOR SELECT 
USING (true);

DROP POLICY IF EXISTS "Usuários podem inserir seu próprio perfil" ON public.profiles;
CREATE POLICY "Usuários podem inserir seu próprio perfil" 
ON public.profiles FOR INSERT 
WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Usuários podem atualizar seu próprio perfil" ON public.profiles;
CREATE POLICY "Usuários podem atualizar seu próprio perfil" 
ON public.profiles FOR UPDATE 
USING (auth.uid() = id);

-- Trigger para criar perfil automaticamente ao cadastrar novo usuário no Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, phone, city, state, created_at)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email,
    COALESCE(new.raw_user_meta_data->>'phone', ''),
    COALESCE(new.raw_user_meta_data->>'city', ''),
    COALESCE(new.raw_user_meta_data->>'state', ''),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- 3. TABELA DE ANIMAIS (ANIMALS)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.animals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    protector_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    species TEXT NOT NULL CHECK (species IN ('cao', 'gato', 'outro')),
    breed TEXT NOT NULL DEFAULT 'SRD / Sem Raça Definida',
    age_group TEXT NOT NULL CHECK (age_group IN ('filhote', 'jovem', 'adulto', 'idoso')),
    size TEXT NOT NULL CHECK (size IN ('pequeno', 'medio', 'grande')),
    gender TEXT NOT NULL CHECK (gender IN ('macho', 'femea')),
    is_vaccinated BOOLEAN DEFAULT FALSE,
    is_castrated BOOLEAN DEFAULT FALSE,
    is_dewormed BOOLEAN DEFAULT FALSE,
    temperament_notes TEXT DEFAULT '',
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'disponivel' CHECK (status IN ('disponivel', 'em_processo', 'adotado')),
    image_urls TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Índices para buscas rápidas e filtros
CREATE INDEX IF NOT EXISTS idx_animals_species ON public.animals(species);
CREATE INDEX IF NOT EXISTS idx_animals_status ON public.animals(status);
CREATE INDEX IF NOT EXISTS idx_animals_city_state ON public.animals(city, state);
CREATE INDEX IF NOT EXISTS idx_animals_created_at ON public.animals(created_at DESC);

-- Habilitar RLS para Animals
ALTER TABLE public.animals ENABLE ROW LEVEL SECURITY;

-- Políticas de RLS para Animais
DROP POLICY IF EXISTS "Animais são visíveis publicamente" ON public.animals;
CREATE POLICY "Animais são visíveis publicamente" 
ON public.animals FOR SELECT 
USING (true);

DROP POLICY IF EXISTS "Protetores podem cadastrar animais" ON public.animals;
CREATE POLICY "Protetores podem cadastrar animais" 
ON public.animals FOR INSERT 
WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Protetores podem atualizar seus próprios animais" ON public.animals;
CREATE POLICY "Protetores podem atualizar seus próprios animais" 
ON public.animals FOR UPDATE 
USING (auth.uid() = protector_id OR protector_id IS NULL);

DROP POLICY IF EXISTS "Protetores podem excluir seus próprios animais" ON public.animals;
CREATE POLICY "Protetores podem excluir seus próprios animais" 
ON public.animals FOR DELETE 
USING (auth.uid() = protector_id OR protector_id IS NULL);

-- ==============================================================================
-- 4. BUCKETS DE STORAGE (ANIMAIS & PERFIS)
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public) 
VALUES ('animals', 'animals', true)
ON CONFLICT (id) DO UPDATE SET public = true;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('profiles', 'profiles', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Políticas de acesso público para visualização das imagens do Storage
DROP POLICY IF EXISTS "Imagens de animais são públicas" ON storage.objects;
CREATE POLICY "Imagens de animais são públicas" 
ON storage.objects FOR SELECT 
USING (bucket_id IN ('animals', 'profiles'));

DROP POLICY IF EXISTS "Usuários autenticados podem enviar imagens" ON storage.objects;
CREATE POLICY "Usuários autenticados podem enviar imagens" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id IN ('animals', 'profiles') AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Usuários podem atualizar suas próprias imagens" ON storage.objects;
CREATE POLICY "Usuários podem atualizar suas próprias imagens" 
ON storage.objects FOR UPDATE 
USING (bucket_id IN ('animals', 'profiles') AND auth.role() = 'authenticated');

-- ==============================================================================
-- 5. SEED: 15 ANIMAIS PARA ADOÇÃO COM FOTOS REAIS (UNSPLASH / FOTOS REAIS)
-- ==============================================================================
-- Limpa animais pré-existentes de seed para evitar duplicatas ao reexecutar
DELETE FROM public.animals WHERE protector_id IS NULL;

INSERT INTO public.animals (
    name, species, breed, age_group, size, gender,
    is_vaccinated, is_castrated, is_dewormed,
    temperament_notes, city, state, status, image_urls, created_at
) VALUES 
(
    'Thor',
    'cao',
    'Labrador Retriever',
    'jovem',
    'grande',
    'macho',
    true, true, true,
    'Thor é super dócil, brincalhão e adora correr no parque. Convive muito bem com crianças e outros cães.',
    'São Paulo',
    'SP',
    'disponivel',
    ARRAY['https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=800&q=80'],
    NOW() - INTERVAL '1 day'
),
(
    'Mimi',
    'gato',
    'SRD (Vira-lata)',
    'filhote',
    'pequeno',
    'femea',
    true, false, true,
    'Gatinha carinhosa, ronrona o tempo todo e adora colo. Resgatada de uma caixa de papelão.',
    'Rio de Janeiro',
    'RJ',
    'disponivel',
    ARRAY['https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=800&q=80'],
    NOW() - INTERVAL '2 days'
),
(
    'Bob',
    'cao',
    'Caramelo (SRD)',
    'adulto',
    'medio',
    'macho',
    true, true, true,
    'O clássico vira-lata caramelo brasileiro! Tranquilo, companheiro para passeios e muito protetor da casa.',
    'Curitiba',
    'PR',
    'disponivel',
    ARRAY['https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&w=800&q=80'],
    NOW() - INTERVAL '3 days'
),
(
    'Luna',
    'gato',
    'Persa Mestiça',
    'jovem',
    'pequeno',
    'femea',
    true, true, true,
    'Tranquila e silenciosa. Gosta de passar a tarde na janela observando o movimento. Já castrada.',
    'Belo Horizonte',
    'MG',
    'disponivel',
    ARRAY['https://images.unsplash.com/photo-1573865526739-10659fec78a5?auto=format&fit=crop&w=800&q=80'],
    NOW() - INTERVAL '4 days'
),
(
    'Rex',
    'cao',
    'Pastor Alemão Mestiço',
    'adulto',
    'grande',
    'macho',
    true, true, true,
    'Excelente cão de guarda e companhia. Leal, obediente, sabe sentar e dar a pata.',
    'Porto Alegre',
    'RS',
    'disponivel',
    ARRAY['https://images.unsplash.com/photo-1589941013453-ec89f33b5455?auto=format&fit=crop&w=800&q=80'],
    NOW() - INTERVAL '5 days'
),
(
    'Mel',
    'cao',
    'Golden Retriever',
    'adulto',
    'grande',
    'femea',
    true, true, true,
    'Uma doçura de cadela! Ama água, busca bolinha e é perfeita para família com crianças.',
    'Salvador',
    'BA',
    'disponivel',
    ARRAY['https://images.unsplash.com/photo-1537151625747-768eb6cf92b2?auto=format&fit=crop&w=800&q=80'],
    NOW() - INTERVAL '6 days'
),
(
    'Nina',
    'gato',
    'Tricolor (SRD)',
    'adulto',
    'pequeno',
    'femea',
    true, true, true,
    'Gata tricolor linda e graciosa. Gosta de sachê e brinquedos com penas. Muito limpa e educada.',
    'Fortaleza',
    'CE',
    'disponivel',
    ARRAY['https://images.unsplash.com/photo-1533738363-b7f9aef128ce?auto=format&fit=crop&w=800&q=80'],
    NOW() - INTERVAL '7 days'
),
(
    'Bart',
    'cao',
    'Beagle',
    'jovem',
    'medio',
    'macho',
    true, true, true,
    'Curioso, farejador nato e cheio de energia! Precisa de tutor que goste de fazer caminhadas.',
    'Recife',
    'PE',
    'disponivel',
    ARRAY['https://images.unsplash.com/photo-1505628346881-b72b27e84530?auto=format&fit=crop&w=800&q=80'],
    NOW() - INTERVAL '8 days'
),
(
    'Zoe',
    'gato',
    'Siamês',
    'adulto',
    'pequeno',
    'femea',
    true, true, true,
    'Olhos azuis penetrantes e muito comunicativa. Gosta de conversar com os tutores e deitar no colo.',
    'Brasília',
    'DF',
    'disponivel',
    ARRAY['https://images.unsplash.com/photo-1543852786-1cf6624b9987?auto=format&fit=crop&w=800&q=80'],
    NOW() - INTERVAL '9 days'
),
(
    'Max',
    'cao',
    'Poodle Mestiço',
    'idoso',
    'pequeno',
    'macho',
    true, true, true,
    'Cãozinho idoso, extremamente calmo, quase não late. Ideal para apartamento ou tutores que trabalham de home office.',
    'Manaus',
    'AM',
    'disponivel',
    ARRAY['https://images.unsplash.com/photo-1517849845537-4d257902454a?auto=format&fit=crop&w=800&q=80'],
    NOW() - INTERVAL '10 days'
),
(
    'Lola',
    'cao',
    'SRD (Vira-lata)',
    'filhote',
    'medio',
    'femea',
    true, false, true,
    'Filhotinha resgatada de terreno baldio. Saudável, vacinas em dia e já comendo ração seca.',
    'Campinas',
    'SP',
    'disponivel',
    ARRAY['https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&w=800&q=80'],
    NOW() - INTERVAL '11 days'
),
(
    'Frajola',
    'gato',
    'Frajolinha (Preto e Branco)',
    'jovem',
    'pequeno',
    'macho',
    true, true, true,
    'Gatinho ativo e muito brincalhão. Adora caçar bolinhas de papel e subir no arranhador.',
    'Santos',
    'SP',
    'disponivel',
    ARRAY['https://images.unsplash.com/photo-1518791841217-8f162f1e1131?auto=format&fit=crop&w=800&q=80'],
    NOW() - INTERVAL '12 days'
),
(
    'Duque',
    'cao',
    'Rottweiler Mestiço',
    'adulto',
    'grande',
    'macho',
    true, true, true,
    'Porte imponente mas coração mole! Adora carinho na barriga e se dá muito bem com a família.',
    'Goiânia',
    'GO',
    'disponivel',
    ARRAY['https://images.unsplash.com/photo-1561037404-61cd46aa615b?auto=format&fit=crop&w=800&q=80'],
    NOW() - INTERVAL '13 days'
),
(
    'Brisa',
    'gato',
    'Maine Coon Mestiça',
    'adulto',
    'medio',
    'femea',
    true, true, true,
    'Pelagem longa e macia, porte elegante. Dócil, calma e muito amorosa.',
    'Florianópolis',
    'SC',
    'disponivel',
    ARRAY['https://images.unsplash.com/photo-1561948955-570b270e7c36?auto=format&fit=crop&w=800&q=80'],
    NOW() - INTERVAL '14 days'
),
(
    'Pipoca',
    'cao',
    'Shih Tzu Mestiço',
    'jovem',
    'pequeno',
    'macho',
    true, true, true,
    'Muito simpático e sociável com outros pets. Pêlo tosado recentemente, pronto para um novo lar.',
    'Natal',
    'RN',
    'disponivel',
    ARRAY['https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&w=800&q=80'],
    NOW() - INTERVAL '15 days'
);
