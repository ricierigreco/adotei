// Configuração global da aplicação
class AppConfig {
  // Define se o aplicativo deve usar o Supabase (Auth, PostgreSQL, Storage)
  // ou os repositórios Mock (simulados em memória/local).
  // Mude para true quando preencher a supabaseUrl e supabaseAnonKey abaixo.
  static const bool useSupabase = true;

  // Credenciais do Supabase
  // Substitua pelos valores do seu Dashboard em https://supabase.com -> Project Settings -> API
  static const String supabaseUrl = 'https://yqhupohddcwvpnogftix.supabase.co';

  static const String supabaseAnonKey =
      'sb_publishable_AjKLdbqKK-KV7Xh3gF4RYQ_2ODwn_SP';

  // Retorna se o Supabase está com credenciais preenchidas
  static bool get isSupabaseConfigured =>
      supabaseUrl != 'https://SEU_PROJETO.supabase.co' &&
      supabaseAnonKey != 'SUA_CHAVE_ANON_AQUI' &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;

  // Mensagem pré-definida para contato via WhatsApp
  static String getWhatsAppMessage(String animalName) {
    return 'Olá! Vi o anúncio de doação do(a) *$animalName* no app *Adotei!* e gostaria de receber mais informações.';
  }
}
