import 'dart:typed_data';
import '../../models/animal_model.dart';
import '../animal_repository.dart';

class MockAnimalRepository implements AnimalRepository {
  final Duration _delay = const Duration(milliseconds: 600);

  // Banco de dados em memória de animais
  static final List<AnimalModel> _animalsDb = [
    AnimalModel(
      id: 'mock_pet_1',
      protectorId: 'mock_user_1',
      name: 'Pipoca',
      species: 'cao',
      breed: 'SRD / Vira-lata',
      ageGroup: 'filhote',
      size: 'pequeno',
      gender: 'fêmea',
      isVaccinated: true,
      isCastrated: false,
      isDewormed: true,
      temperamentNotes:
          'Muito dócil, brincalhona e adora crianças. Já faz xixi no tapetinho higiênico e se adapta fácil a apartamentos.',
      city: 'São Paulo',
      state: 'SP',
      status: 'disponivel',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      imageUrls: [
        'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=600',
        'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=600',
      ],
    ),
    AnimalModel(
      id: 'mock_pet_2',
      protectorId: 'mock_user_1',
      name: 'Mingau',
      species: 'gato',
      breed: 'Persa / Siamês',
      ageGroup: 'jovem',
      size: 'pequeno',
      gender: 'macho',
      isVaccinated: true,
      isCastrated: true,
      isDewormed: true,
      temperamentNotes:
          'Carinhoso, calmo, mas um pouco assustado no início. Precisa de um lar seguro (apartamento telado).',
      city: 'São Paulo',
      state: 'SP',
      status: 'disponivel',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      imageUrls: [
        'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=600',
      ],
    ),
    AnimalModel(
      id: 'mock_pet_3',
      protectorId: 'mock_user_2',
      name: 'Thor',
      species: 'cao',
      breed: 'Golden / SRD',
      ageGroup: 'adulto',
      size: 'grande',
      gender: 'macho',
      isVaccinated: true,
      isCastrated: true,
      isDewormed: true,
      temperamentNotes:
          'Energético, excelente cão de guarda e companheiro. Precisa de espaço ou passeios diários constantes.',
      city: 'Rio de Janeiro',
      state: 'RJ',
      status: 'disponivel',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      imageUrls: [
        'https://images.unsplash.com/photo-1552053831-71594a27632d?w=600',
      ],
    ),
    AnimalModel(
      id: 'mock_pet_4',
      protectorId: 'mock_user_2',
      name: 'Luna',
      species: 'gato',
      breed: 'SRD / Vira-lata',
      ageGroup: 'adulto',
      size: 'medio',
      gender: 'fêmea',
      isVaccinated: true,
      isCastrated: true,
      isDewormed: true,
      temperamentNotes:
          'Super dócil, adora colo e ronrona muito. Convive muito bem com outros gatos.',
      city: 'Niterói',
      state: 'RJ',
      status: 'disponivel',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      imageUrls: [
        'https://images.unsplash.com/photo-1533738363-b7f9aef128ce?w=600',
      ],
    ),
    AnimalModel(
      id: 'mock_pet_5',
      protectorId: 'mock_user_1',
      name: 'Bolinha',
      species: 'cao',
      breed: 'Poodle / SRD',
      ageGroup: 'idoso',
      size: 'pequeno',
      gender: 'macho',
      isVaccinated: true,
      isCastrated: true,
      isDewormed: true,
      temperamentNotes:
          'Muito quietinho e manso. Ideal para idosos. Enxerga um pouco mal devido à idade, mas é muito independente.',
      city: 'Campinas',
      state: 'SP',
      status: 'disponivel',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      imageUrls: [
        'https://images.unsplash.com/photo-1518717758536-85ae29035b6d?w=600',
      ],
    ),
  ];

  @override
  Future<List<AnimalModel>> getAllAnimals({
    String? species,
    String? size,
    String? gender,
    String? ageGroup,
    String? city,
    String? state,
    bool? isVaccinated,
    bool? isCastrated,
    String? query,
  }) async {
    await Future.delayed(_delay);

    // Retorna todos os que não estão como 'adotado' por padrão para a vitrine pública,
    // ou aplica os filtros passados.
    Iterable<AnimalModel> result = _animalsDb.where(
      (p) => p.status != 'adotado',
    );

    if (species != null && species.isNotEmpty) {
      result = result.where(
        (p) => p.species.toLowerCase() == species.toLowerCase(),
      );
    }
    if (size != null && size.isNotEmpty) {
      result = result.where((p) => p.size.toLowerCase() == size.toLowerCase());
    }
    if (gender != null && gender.isNotEmpty) {
      result = result.where(
        (p) => p.gender.toLowerCase() == gender.toLowerCase(),
      );
    }
    if (ageGroup != null && ageGroup.isNotEmpty) {
      result = result.where(
        (p) => p.ageGroup.toLowerCase() == ageGroup.toLowerCase(),
      );
    }
    if (city != null && city.isNotEmpty) {
      result = result.where(
        (p) => p.city.toLowerCase().contains(city.toLowerCase()),
      );
    }
    if (state != null && state.isNotEmpty) {
      result = result.where(
        (p) => p.state.toLowerCase() == state.toLowerCase(),
      );
    }
    if (isVaccinated != null && isVaccinated) {
      result = result.where((p) => p.isVaccinated);
    }
    if (isCastrated != null && isCastrated) {
      result = result.where((p) => p.isCastrated);
    }
    if (query != null && query.isNotEmpty) {
      result = result.where(
        (p) =>
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            p.breed.toLowerCase().contains(query.toLowerCase()),
      );
    }

    return result.toList();
  }

  @override
  Future<List<AnimalModel>> getAnimalsByProtector(String protectorId) async {
    await Future.delayed(_delay);
    return _animalsDb.where((p) => p.protectorId == protectorId).toList();
  }

  @override
  Future<AnimalModel> getAnimalById(String id) async {
    await Future.delayed(_delay);
    return _animalsDb.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Animal não encontrado.'),
    );
  }

  @override
  Future<AnimalModel> createAnimal(
    AnimalModel animal,
    List<dynamic> localImages,
  ) async {
    await Future.delayed(_delay);

    // Simula upload de imagens locais (ex: gera URLs do Unsplash)
    final List<String> mockUrls = [];
    if (localImages.isNotEmpty) {
      for (int i = 0; i < localImages.length; i++) {
        mockUrls.add(
          animal.species == 'gato'
              ? 'https://images.unsplash.com/photo-1573865526739-10659fec78a5?w=600&sig=$i'
              : 'https://images.unsplash.com/photo-1537151625747-7ae78db6158d?w=600&sig=$i',
        );
      }
    } else {
      mockUrls.add(
        'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=600',
      );
    }

    final newAnimal = animal.copyWith(
      id: 'mock_pet_${DateTime.now().millisecondsSinceEpoch}',
      imageUrls: mockUrls,
      createdAt: DateTime.now(),
    );

    _animalsDb.insert(0, newAnimal);
    return newAnimal;
  }

  @override
  Future<AnimalModel> updateAnimal(
    AnimalModel animal, {
    List<dynamic>? newLocalImages,
    List<String>? imagesToRemove,
  }) async {
    await Future.delayed(_delay);

    final index = _animalsDb.indexWhere((p) => p.id == animal.id);
    if (index == -1) {
      throw Exception('Animal não encontrado.');
    }

    List<String> currentUrls = List<String>.from(_animalsDb[index].imageUrls);

    // Remove as imagens solicitadas
    if (imagesToRemove != null) {
      currentUrls.removeWhere((url) => imagesToRemove.contains(url));
    }

    // Simula upload das novas imagens locais
    if (newLocalImages != null && newLocalImages.isNotEmpty) {
      for (int i = 0; i < newLocalImages.length; i++) {
        currentUrls.add(
          animal.species == 'gato'
              ? 'https://images.unsplash.com/photo-1573865526739-10659fec78a5?w=600&sig=${i + 10}'
              : 'https://images.unsplash.com/photo-1537151625747-7ae78db6158d?w=600&sig=${i + 10}',
        );
      }
    }

    // Garante que ainda temos pelo menos uma imagem
    if (currentUrls.isEmpty) {
      currentUrls.add(
        'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=600',
      );
    }

    final updatedAnimal = animal.copyWith(imageUrls: currentUrls);

    _animalsDb[index] = updatedAnimal;
    return updatedAnimal;
  }

  @override
  Future<void> deleteAnimal(String id) async {
    await Future.delayed(_delay);
    _animalsDb.removeWhere((p) => p.id == id);
  }
}
