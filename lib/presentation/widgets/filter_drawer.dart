import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/animal_provider.dart';

class FilterDrawer extends StatefulWidget {
  const FilterDrawer({Key? key}) : super(key: key);

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  String? _species;
  String? _size;
  String? _gender;
  String? _ageGroup;
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  bool _isVaccinated = false;
  bool _isCastrated = false;

  @override
  void initState() {
    super.initState();
    // Recupera os filtros ativos no provider ao inicializar
    final provider = Provider.of<AnimalProvider>(context, listen: false);
    _species = provider.selectedSpecies;
    _size = provider.selectedSize;
    _gender = provider.selectedGender;
    _ageGroup = provider.selectedAgeGroup;
    _cityController.text = provider.selectedCity ?? '';
    _stateController.text = provider.selectedState ?? '';
    _isVaccinated = provider.filterVaccinated;
    _isCastrated = provider.filterCastrated;
  }

  @override
  void dispose() {
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho do Drawer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtrar Animais',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Opções de Filtro (Scrolável)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Espécie
                  _buildSectionTitle('Espécie'),
                  _buildChipGroup(
                    options: {
                      null: 'Todos',
                      'cao': 'Cão',
                      'gato': 'Gato',
                      'outro': 'Outro',
                    },
                    selectedValue: _species,
                    onSelected: (val) => setState(() => _species = val),
                  ),
                  const SizedBox(height: 16),

                  // Porte
                  _buildSectionTitle('Porte'),
                  _buildChipGroup(
                    options: {
                      null: 'Todos',
                      'pequeno': 'Pequeno',
                      'medio': 'Médio',
                      'grande': 'Grande',
                    },
                    selectedValue: _size,
                    onSelected: (val) => setState(() => _size = val),
                  ),
                  const SizedBox(height: 16),

                  // Sexo
                  _buildSectionTitle('Sexo'),
                  _buildChipGroup(
                    options: {
                      null: 'Todos',
                      'macho': 'Macho',
                      'fêmea': 'Fêmea',
                    },
                    selectedValue: _gender,
                    onSelected: (val) => setState(() => _gender = val),
                  ),
                  const SizedBox(height: 16),

                  // Idade
                  _buildSectionTitle('Idade'),
                  _buildChipGroup(
                    options: {
                      null: 'Todos',
                      'filhote': 'Filhote',
                      'jovem': 'Jovem',
                      'adulto': 'Adulto',
                      'idoso': 'Idoso',
                    },
                    selectedValue: _ageGroup,
                    onSelected: (val) => setState(() => _ageGroup = val),
                  ),
                  const SizedBox(height: 16),

                  // Localização
                  _buildSectionTitle('Localização'),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: 'Cidade',
                            hintText: 'Ex: São Paulo',
                            prefixIcon: const Icon(
                              Icons.location_city,
                              size: 18,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _stateController,
                          maxLength: 2,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'UF',
                            hintText: 'Ex: SP',
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Vacinação e Castração
                  _buildSectionTitle('Cuidados'),
                  SwitchListTile(
                    title: const Text(
                      'Apenas Vacinados',
                      style: TextStyle(fontSize: 14),
                    ),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    value: _isVaccinated,
                    onChanged: (val) => setState(() => _isVaccinated = val),
                  ),
                  SwitchListTile(
                    title: const Text(
                      'Apenas Castrados',
                      style: TextStyle(fontSize: 14),
                    ),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    value: _isCastrated,
                    onChanged: (val) => setState(() => _isCastrated = val),
                  ),
                ],
              ),
            ),

            // Botões de Ação
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Limpar Filtros
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ),
                      onPressed: () {
                        context.read<AnimalProvider>().clearFilters();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Limpar',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Aplicar Filtros
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        context.read<AnimalProvider>().setFilters(
                          species: _species,
                          size: _size,
                          gender: _gender,
                          ageGroup: _ageGroup,
                          city: _cityController.text.trim().isNotEmpty
                              ? _cityController.text.trim()
                              : null,
                          state:
                              _stateController.text
                                  .trim()
                                  .toUpperCase()
                                  .isNotEmpty
                              ? _stateController.text.trim().toUpperCase()
                              : null,
                          isVaccinated: _isVaccinated,
                          isCastrated: _isCastrated,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Filtrar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildChipGroup<T>({
    required Map<T, String> options,
    required T selectedValue,
    required void Function(T) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: options.entries.map((entry) {
        final isSelected = selectedValue == entry.key;
        return ChoiceChip(
          label: Text(entry.value),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onSelected(entry.key);
            }
          },
          selectedColor: AppColors.primary.withOpacity(0.15),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          backgroundColor: Colors.transparent,
          side: BorderSide(
            color: isSelected
                ? AppColors.primary
                : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
      }).toList(),
    );
  }
}
