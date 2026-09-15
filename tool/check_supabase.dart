import 'package:supabase/supabase.dart';

void main() async {
  const url = 'https://yqhupohddcwvpnogftix.supabase.co';
  const anonKey = 'sb_publishable_AjKLdbqKK-KV7Xh3gF4RYQ_2ODwn_SP';

  print('=== DIAGNÓSTICO DE CONEXÃO COM O SUPABASE ===');
  print('URL: $url');
  final client = SupabaseClient(url, anonKey);

  try {
    print('1. Testando consulta à tabela "animals"...');
    final response = await client.from('animals').select();
    final list = response as List;
    print('✅ Conexão bem-sucedida!');
    print('✅ Tabela "animals" encontrada.');
    print('📊 Total de animais cadastrados: ${list.length}');
    if (list.isNotEmpty) {
      print('🐾 Primeiro animal encontrado: ${list.first['name']} (${list.first['species']})');
    }
  } catch (e) {
    print('❌ Erro ao consultar tabela "animals": $e');
  }

  try {
    print('\n2. Testando consulta à tabela "profiles"...');
    final profiles = await client.from('profiles').select();
    final pList = profiles as List;
    print('✅ Tabela "profiles" encontrada.');
    print('👥 Total de perfis: ${pList.length}');
  } catch (e) {
    print('❌ Erro ao consultar tabela "profiles": $e');
  }
}
