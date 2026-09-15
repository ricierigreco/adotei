import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/url_helper.dart';
import '../../data/models/animal_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/mock/mock_auth_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/animal_provider.dart';
import 'login_screen.dart';

class AnimalDetailScreen extends StatefulWidget {
  final String animalId;

  const AnimalDetailScreen({Key? key, required this.animalId})
    : super(key: key);

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  AnimalModel? _animal;
  UserModel? _protector;
  bool _isLoading = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final animalProvider = context.read<AnimalProvider>();
    final animal = await animalProvider.getAnimalById(widget.animalId);

    if (animal != null) {
      UserModel? protector;
      if (AppConfig.useSupabase && AppConfig.isSupabaseConfigured) {
        try {
          if (animal.protectorId.isNotEmpty) {
            final doc = await Supabase.instance.client
                .from('profiles')
                .select()
                .eq('id', animal.protectorId)
                .maybeSingle();
            if (doc != null) {
              protector = UserModel.fromMap(doc);
            }
          }
        } catch (e) {
          print('Erro ao buscar dados do protetor no Supabase: $e');
        }
      } else {
        // No Mock
        protector = MockAuthRepository.getProtectorById(animal.protectorId);
      }

      // Protetor padrão se não encontrado (ex: animais do seed inicial)
      protector ??= UserModel(
        id: animal.protectorId.isNotEmpty ? animal.protectorId : 'ong_adotei',
        name: 'Protetor Responsável (Adotei!)',
        email: 'contato@adotei.com.br',
        phone: '11999998888',
        city: animal.city,
        state: animal.state,
        createdAt: DateTime.now(),
      );

      setState(() {
        _animal = animal;
        _protector = protector;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Ações de contato
  void _contactWhatsApp() {
    if (_protector == null || _animal == null) return;
    final message = AppConfig.getWhatsAppMessage(_animal!.name);
    UrlHelper.openWhatsApp(_protector!.phone, message);
  }

  void _contactPhone() {
    if (_protector == null) return;
    UrlHelper.makePhoneCall(_protector!.phone);
  }

  void _contactEmail() {
    if (_protector == null || _animal == null) return;
    UrlHelper.sendEmail(
      _protector!.email,
      'Interesse em adotar ${_animal!.name}',
      'Olá ${_protector!.name},\n\nVi o anúncio do(a) ${_animal!.name} no aplicativo Adotei! e gostaria de saber mais informações sobre o processo de adoção.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_animal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes do Pet')),
        body: const Center(
          child: Text('Animal não encontrado ou foi removido.'),
        ),
      );
    }

    final double width = MediaQuery.of(context).size.width;
    final bool isLargeScreen = width > 700;

    return Scaffold(
      appBar: AppBar(
        title: Text(_animal!.name),
        actions: [
          // Tag com status
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _animal!.status == 'disponivel'
                      ? AppColors.statusDisponivel
                      : (_animal!.status == 'em_processo'
                            ? AppColors.statusProcesso
                            : AppColors.statusAdotado),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _animal!.formattedStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: isLargeScreen
            ? _buildWebLayout(auth, isDark, width)
            : _buildMobileLayout(auth, isDark),
      ),
    );
  }

  // Layout para Web/Desktop (duas colunas)
  Widget _buildWebLayout(AuthProvider auth, bool isDark, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lado Esquerdo: Imagem
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _buildImageGallery(isWeb: true),
                    const SizedBox(height: 16),
                    _buildAboutPetSection(isDark),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Lado Direito: Detalhes e Contato
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMainInfoCard(isDark),
                    const SizedBox(height: 16),
                    _buildCareTagsCard(isDark),
                    const SizedBox(height: 16),
                    _buildContactCard(auth, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Layout para Mobile (uma coluna)
  Widget _buildMobileLayout(AuthProvider auth, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildImageGallery(isWeb: false),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMainInfoCard(isDark),
              const SizedBox(height: 16),
              _buildCareTagsCard(isDark),
              const SizedBox(height: 16),
              _buildAboutPetSection(isDark),
              const SizedBox(height: 16),
              _buildContactCard(auth, isDark),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  // Widget: Carrossel / Galeria de Fotos
  Widget _buildImageGallery({required bool isWeb}) {
    final urls = _animal!.imageUrls;

    return Column(
      children: [
        Container(
          height: isWeb ? 450 : 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.softShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  itemCount: urls.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Image.network(
                      urls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.pets,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),

                // Indicador de seta esquerda
                if (urls.length > 1)
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.4),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Indicador de seta direita
                if (urls.length > 1)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.4),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Indicadores (Pontinhos)
        if (urls.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              urls.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index
                      ? AppColors.primary
                      : Colors.grey.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Widget: Card de Informações Principais
  Widget _buildMainInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _animal!.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${_animal!.breed} • ${_animal!.formattedSpecies}',
            style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),

          // Grade de características básicas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn(
                'PORTE',
                _animal!.formattedSize,
                Icons.straighten,
              ),
              _buildInfoColumn(
                'SEXO',
                _animal!.gender == 'macho' ? 'Macho' : 'Fêmea',
                _animal!.gender == 'macho' ? Icons.male : Icons.female,
              ),
              _buildInfoColumn(
                'IDADE',
                _animal!.formattedAgeGroup,
                Icons.cake_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String title, String val, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Widget: Card de Tags de Cuidados
  Widget _buildCareTagsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cuidados de Saúde',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildCareTag('Vacinado', _animal!.isVaccinated),
              _buildCareTag('Castrado', _animal!.isCastrated),
              _buildCareTag('Vermifugado', _animal!.isDewormed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCareTag(String label, bool isTrue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isTrue ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTrue ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTrue ? Icons.check_circle : Icons.cancel,
            color: isTrue ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isTrue ? Colors.green.shade800 : Colors.red.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Widget: Seção de Descrição / Observações
  Widget _buildAboutPetSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temperamento & Observações',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            _animal!.temperamentNotes.isNotEmpty
                ? _animal!.temperamentNotes
                : 'Nenhuma observação informada pelo protetor.',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }

  // Widget: Card do Protetor e Contato
  Widget _buildContactCard(AuthProvider auth, bool isDark) {
    final String protectorName = _protector?.name ?? 'Protetor Responsável';
    final String protectorLocation = _protector != null
        ? '${_protector!.city}, ${_protector!.state}'
        : '${_animal!.city}, ${_animal!.state}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Protetor Responsável',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Perfil do Protetor
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: _protector?.profilePictureUrl != null
                    ? NetworkImage(_protector!.profilePictureUrl!)
                    : null,
                radius: 24,
                child: _protector?.profilePictureUrl == null
                    ? const Icon(Icons.person, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      protectorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      protectorLocation,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Bloqueio de contato se não estiver logado
          if (!auth.isAuthenticated)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Contatos Protegidos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Faça login ou crie sua conta para ver os dados de contato do protetor e adotar este animal.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Fazer Login',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Botões de contato se logado
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), // Cor do WhatsApp
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _contactWhatsApp,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text(
                'Conversar no WhatsApp',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                    ),
                    onPressed: _contactPhone,
                    icon: const Icon(
                      Icons.phone_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Ligar',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                    ),
                    onPressed: _contactEmail,
                    icon: const Icon(
                      Icons.email_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'E-mail',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

