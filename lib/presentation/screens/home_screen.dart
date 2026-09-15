import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/animal_provider.dart';
import '../widgets/animal_card.dart';
import '../widgets/filter_drawer.dart';
import 'animal_detail_screen.dart';
import 'animal_form_screen.dart';
import 'login_screen.dart';
import 'my_animals_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Carrega os animais inicialmente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnimalProvider>().loadAllAnimals();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Verifica se está logado para abrir anúncio
  void _navigateToAddAnimal() {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AnimalFormScreen()));
    } else {
      _showLoginRequiredAlert(
        'Para cadastrar um animal para doação, você precisa fazer login.',
      );
    }
  }

  void _showLoginRequiredAlert(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Login Necessário'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Grid Responsiva
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (width > 1200) {
      crossAxisCount = 5;
    } else if (width > 900) {
      crossAxisCount = 4;
    } else if (width > 600) {
      crossAxisCount = 3;
    }

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const FilterDrawer(),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.pets, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Adotei!',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _scaffoldKey.currentState!.openEndDrawer(),
            tooltip: 'Filtros Avançados',
          ),
          const SizedBox(width: 8),
        ],
      ),

      // Menu Lateral de Navegação
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage:
                    auth.isAuthenticated &&
                        auth.currentUser?.profilePictureUrl != null
                    ? NetworkImage(auth.currentUser!.profilePictureUrl!)
                    : null,
                child:
                    auth.isAuthenticated &&
                        auth.currentUser?.profilePictureUrl == null
                    ? Text(
                        auth.currentUser?.name[0].toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : (!auth.isAuthenticated
                          ? const Icon(
                              Icons.person,
                              size: 40,
                              color: AppColors.primary,
                            )
                          : null),
              ),
              accountName: Text(
                auth.isAuthenticated ? auth.currentUser!.name : 'Explorador',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                auth.isAuthenticated
                    ? auth.currentUser!.email
                    : 'Faça login para anunciar',
              ),
            ),

            // Itens de Menu
            ListTile(
              leading: const Icon(Icons.pets),
              title: const Text('Catálogo de Adoção'),
              selected: true,
              selectedColor: AppColors.primary,
              onTap: () => Navigator.pop(context),
            ),

            if (auth.isAuthenticated) ...[
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('Meus Anúncios'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyAnimalsScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('Meu Perfil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ],

            const Spacer(),
            const Divider(),

            if (auth.isAuthenticated)
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Sair da Conta',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  auth.logout();
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.login, color: AppColors.primary),
                title: const Text(
                  'Entrar / Cadastrar',
                  style: TextStyle(color: AppColors.primary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),

      body: Column(
        children: [
          // Campo de busca superior e filtros rápidos
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Campo de Busca
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    context.read<AnimalProvider>().setSearchQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou raça...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<AnimalProvider>().setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? Color(0xFF1E293B) : Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Chips de filtro rápido por espécie
                Consumer<AnimalProvider>(
                  builder: (context, provider, _) {
                    return SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildQuickFilterChip(
                            label: 'Todos',
                            isSelected: provider.selectedSpecies == null,
                            onSelected: () => provider.setFilters(
                              species: null,
                              size: provider.selectedSize,
                              gender: provider.selectedGender,
                              ageGroup: provider.selectedAgeGroup,
                              city: provider.selectedCity,
                              state: provider.selectedState,
                              isVaccinated: provider.filterVaccinated,
                              isCastrated: provider.filterCastrated,
                            ),
                          ),
                          _buildQuickFilterChip(
                            label: '🐶 Cães',
                            isSelected: provider.selectedSpecies == 'cao',
                            onSelected: () => provider.setFilters(
                              species: 'cao',
                              size: provider.selectedSize,
                              gender: provider.selectedGender,
                              ageGroup: provider.selectedAgeGroup,
                              city: provider.selectedCity,
                              state: provider.selectedState,
                              isVaccinated: provider.filterVaccinated,
                              isCastrated: provider.filterCastrated,
                            ),
                          ),
                          _buildQuickFilterChip(
                            label: '🐱 Gatos',
                            isSelected: provider.selectedSpecies == 'gato',
                            onSelected: () => provider.setFilters(
                              species: 'gato',
                              size: provider.selectedSize,
                              gender: provider.selectedGender,
                              ageGroup: provider.selectedAgeGroup,
                              city: provider.selectedCity,
                              state: provider.selectedState,
                              isVaccinated: provider.filterVaccinated,
                              isCastrated: provider.filterCastrated,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Vitrine de Animais
          Expanded(
            child: Consumer<AnimalProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (provider.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            onPressed: () => provider.loadAllAnimals(),
                            child: const Text(
                              'Tentar Novamente',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (provider.animals.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.pets, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Nenhum animalzinho encontrado',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tente alterar os filtros de busca para encontrar mais resultados.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton(
                            onPressed: () => provider.clearFilters(),
                            child: const Text(
                              'Limpar Filtros',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Grid View de animais
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => provider.loadAllAnimals(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: provider.animals.length,
                    itemBuilder: (context, index) {
                      final animal = provider.animals[index];
                      return AnimalCard(
                        animal: animal,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AnimalDetailScreen(animalId: animal.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Botão Anunciar
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _navigateToAddAnimal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Anunciar Pet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textMuted,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
    );
  }
}
