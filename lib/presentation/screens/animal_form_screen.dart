import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/image_helper.dart';
import '../../data/models/animal_model.dart';
import '../providers/auth_provider.dart';
import '../providers/animal_provider.dart';
import '../widgets/custom_input.dart';

class AnimalFormScreen extends StatefulWidget {
  final AnimalModel? animalToEdit;

  const AnimalFormScreen({Key? key, this.animalToEdit}) : super(key: key);

  @override
  State<AnimalFormScreen> createState() => _AnimalFormScreenState();
}

class _AnimalFormScreenState extends State<AnimalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Controladores de Texto
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _notesController = TextEditingController();

  // Valores Selecionados
  String _species = 'cao'; // cao, gato, outro
  String _ageGroup = 'adulto'; // filhote, jovem, adulto, idoso
  String _size = 'medio'; // pequeno, medio, grande
  String _gender = 'macho'; // macho, fêmea
  String _status = 'disponivel'; // disponivel, em_processo, adotado
  bool _isVaccinated = false;
  bool _isCastrated = false;
  bool _isDewormed = false;

  // Imagens locais selecionadas (bytes Uint8List para compatibilidade Web + Mobile)
  final List<Uint8List> _selectedImagesBytes = [];

  // Imagens existentes na edição que devem ser mantidas
  List<String> _existingUrls = [];
  // Imagens existentes removidas durante a edição
  final List<String> _urlsToRemove = [];

  bool _isSubmitting = false;

  bool get isEditMode => widget.animalToEdit != null;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();

    if (isEditMode) {
      final pet = widget.animalToEdit!;
      _nameController.text = pet.name;
      _breedController.text = pet.breed;
      _cityController.text = pet.city;
      _stateController.text = pet.state;
      _notesController.text = pet.temperamentNotes;
      _species = pet.species;
      _ageGroup = pet.ageGroup;
      _size = pet.size;
      _gender = pet.gender;
      _status = pet.status;
      _isVaccinated = pet.isVaccinated;
      _isCastrated = pet.isCastrated;
      _isDewormed = pet.isDewormed;
      _existingUrls = List<String>.from(pet.imageUrls);
    } else {
      // Pré-popula localização com dados do perfil do protetor logado
      if (auth.isAuthenticated) {
        _cityController.text = auth.currentUser!.city;
        _stateController.text = auth.currentUser!.state;
      }
      _breedController.text = 'SRD / Vira-lata';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Selecionar fotos da galeria ou câmera
  Future<void> _pickImage() async {
    if (_selectedImagesBytes.length + _existingUrls.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Limite máximo de 5 fotos atingido.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file != null) {
        setState(() => _isSubmitting = true);

        // Comprime a imagem antes de armazenar na memória
        final compressedBytes = await ImageHelper.compressImage(file);

        setState(() {
          _isSubmitting = false;
          if (compressedBytes != null) {
            _selectedImagesBytes.add(compressedBytes);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erro ao processar imagem.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        });
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      print('Erro ao selecionar foto: $e');
    }
  }

  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImagesBytes.removeAt(index);
    });
  }

  void _removeExistingImage(String url) {
    setState(() {
      _existingUrls.remove(url);
      _urlsToRemove.add(url);
    });
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImagesBytes.isEmpty && _existingUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos 1 foto do animal.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final animalProvider = context.read<AnimalProvider>();

    final protectorId = auth.currentUser?.id ?? '';
    final petId = isEditMode ? widget.animalToEdit!.id : '';

    final animal = AnimalModel(
      id: petId,
      protectorId: protectorId,
      name: _nameController.text.trim(),
      species: _species,
      breed: _breedController.text.trim(),
      ageGroup: _ageGroup,
      size: _size,
      gender: _gender,
      isVaccinated: _isVaccinated,
      isCastrated: _isCastrated,
      isDewormed: _isDewormed,
      temperamentNotes: _notesController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim().toUpperCase(),
      status: _status,
      createdAt: isEditMode ? widget.animalToEdit!.createdAt : DateTime.now(),
      imageUrls: _existingUrls, // Contém apenas os restantes
    );

    bool success;
    if (isEditMode) {
      success = await animalProvider.updateAnimal(
        animal,
        newLocalImages: _selectedImagesBytes,
        imagesToRemove: _urlsToRemove,
      );
    } else {
      success = await animalProvider.addAnimal(animal, _selectedImagesBytes);
    }

    setState(() => _isSubmitting = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode
                  ? 'Anúncio atualizado com sucesso!'
                  : 'Animal anunciado com sucesso! 🎉',
            ),
            backgroundColor: AppColors.statusDisponivel,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              animalProvider.errorMessage ?? 'Erro ao salvar anúncio.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(isEditMode ? 'Editar Anúncio' : 'Anunciar Animal'),
            actions: [
              IconButton(
                icon: const Icon(Icons.check, color: AppColors.primary),
                onPressed: _isSubmitting ? null : _save,
                tooltip: 'Salvar Anúncio',
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Carrossel de Fotos do Animal
                      Text(
                        'Fotos do Animal (${_selectedImagesBytes.length + _existingUrls.length}/5)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // Botão Adicionar Foto
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    style: BorderStyle.values[1],
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Adicionar',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Fotos Existentes (Editar)
                            ..._existingUrls.map(
                              (url) => Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: NetworkImage(url),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () => _removeExistingImage(url),
                                      child: const CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Colors.black54,
                                        child: Icon(
                                          Icons.close,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Novas Fotos Selecionadas
                            ..._selectedImagesBytes.map((bytes) {
                              final int index = _selectedImagesBytes.indexOf(
                                bytes,
                              );
                              return Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: MemoryImage(bytes),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () => _removeSelectedImage(index),
                                      child: const CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Colors.black54,
                                        child: Icon(
                                          Icons.close,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nome
                      CustomInput(
                        label: 'Nome do Animal',
                        placeholder: 'Ex: Pipoca',
                        prefixIcon: Icons.pets_outlined,
                        controller: _nameController,
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return 'Nome é obrigatório';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Espécie e Gênero lado a lado
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Espécie',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _species,
                                  decoration: InputDecoration(
                                    fillColor: isDark
                                        ? Color(0xFF1E293B)
                                        : Color(0xFFF1F5F9),
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'cao',
                                      child: Text('Cão'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'gato',
                                      child: Text('Gato'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'outro',
                                      child: Text('Outro'),
                                    ),
                                  ],
                                  onChanged: (val) =>
                                      setState(() => _species = val ?? 'cao'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sexo',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _gender,
                                  decoration: InputDecoration(
                                    fillColor: isDark
                                        ? Color(0xFF1E293B)
                                        : Color(0xFFF1F5F9),
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'macho',
                                      child: Text('Macho'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'fêmea',
                                      child: Text('Fêmea'),
                                    ),
                                  ],
                                  onChanged: (val) =>
                                      setState(() => _gender = val ?? 'macho'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Raça
                      CustomInput(
                        label: 'Raça',
                        placeholder: 'Ex: SRD / Vira-lata, Poodle, Persa...',
                        prefixIcon: Icons.search_off_outlined,
                        controller: _breedController,
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return 'Raça é obrigatória. Use SRD se não souber.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Idade e Porte lado a lado
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Idade Aproximada',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _ageGroup,
                                  decoration: InputDecoration(
                                    fillColor: isDark
                                        ? Color(0xFF1E293B)
                                        : Color(0xFFF1F5F9),
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'filhote',
                                      child: Text('Filhote'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'jovem',
                                      child: Text('Jovem'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'adulto',
                                      child: Text('Adulto'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'idoso',
                                      child: Text('Idoso'),
                                    ),
                                  ],
                                  onChanged: (val) => setState(
                                    () => _ageGroup = val ?? 'adulto',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Porte',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _size,
                                  decoration: InputDecoration(
                                    fillColor: isDark
                                        ? Color(0xFF1E293B)
                                        : Color(0xFFF1F5F9),
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'pequeno',
                                      child: Text('Pequeno'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'medio',
                                      child: Text('Médio'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'grande',
                                      child: Text('Grande'),
                                    ),
                                  ],
                                  onChanged: (val) =>
                                      setState(() => _size = val ?? 'medio'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Status (apenas visível em edição)
                      if (isEditMode) ...[
                        const Text(
                          'Status do Anúncio',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _status,
                          decoration: InputDecoration(
                            fillColor: isDark
                                ? Color(0xFF1E293B)
                                : Color(0xFFF1F5F9),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'disponivel',
                              child: Text('Disponível'),
                            ),
                            DropdownMenuItem(
                              value: 'em_processo',
                              child: Text('Adoção em Andamento'),
                            ),
                            DropdownMenuItem(
                              value: 'adotado',
                              child: Text('Adotado (Remover da Vitrine)'),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _status = val ?? 'disponivel'),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Localização
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: CustomInput(
                              label: 'Cidade onde está o pet',
                              placeholder: 'Ex: São Paulo',
                              prefixIcon: Icons.location_city_outlined,
                              controller: _cityController,
                              validator: (val) {
                                if (val == null || val.isEmpty)
                                  return 'Cidade obrigatória';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: CustomInput(
                              label: 'UF (Estado)',
                              placeholder: 'Ex: SP',
                              controller: _stateController,
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'UF';
                                if (val.trim().length != 2) return '2 letras';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Cuidados de Saúde (Switches)
                      const Text(
                        'Cuidados & Saúde',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('Vacinado'),
                        value: _isVaccinated,
                        activeColor: AppColors.primary,
                        onChanged: (val) =>
                            setState(() => _isVaccinated = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: const Text('Castrado'),
                        value: _isCastrated,
                        activeColor: AppColors.primary,
                        onChanged: (val) =>
                            setState(() => _isCastrated = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: const Text('Vermifugado'),
                        value: _isDewormed,
                        activeColor: AppColors.primary,
                        onChanged: (val) =>
                            setState(() => _isDewormed = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),

                      // Temperamento / Notas
                      CustomInput(
                        label: 'Temperamento & Observações',
                        placeholder:
                            'Descreva como é o pet: dócil, brincalhão, convive bem com gatos, etc...',
                        controller: _notesController,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 36),

                      // Botão Salvar
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isSubmitting ? null : _save,
                        child: const Text(
                          'Salvar Anúncio',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Indicador de Carregamento Geral (Loading Overlay)
        if (_isSubmitting)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Salvando anúncio...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
