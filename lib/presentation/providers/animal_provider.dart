import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../data/models/animal_model.dart';
import '../../data/repositories/animal_repository.dart';
import '../../data/repositories/mock/mock_animal_repository.dart';
import '../../data/repositories/supabase/supabase_animal_repository.dart';

class AnimalProvider extends ChangeNotifier {
  late final AnimalRepository _animalRepository;

  List<AnimalModel> _animals = [];
  List<AnimalModel> _myAnimals = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filtros Atuais
  String? _selectedSpecies;
  String? _selectedSize;
  String? _selectedGender;
  String? _selectedAgeGroup;
  String? _selectedCity;
  String? _selectedState;
  bool _filterVaccinated = false;
  bool _filterCastrated = false;
  String _searchQuery = '';

  List<AnimalModel> get animals => _animals;
  List<AnimalModel> get myAnimals => _myAnimals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Getters para filtros
  String? get selectedSpecies => _selectedSpecies;
  String? get selectedSize => _selectedSize;
  String? get selectedGender => _selectedGender;
  String? get selectedAgeGroup => _selectedAgeGroup;
  String? get selectedCity => _selectedCity;
  String? get selectedState => _selectedState;
  bool get filterVaccinated => _filterVaccinated;
  bool get filterCastrated => _filterCastrated;
  String get searchQuery => _searchQuery;

  AnimalProvider() {
    // Escolhe o repositório correto baseado na configuração do app
    if (AppConfig.useSupabase && AppConfig.isSupabaseConfigured) {
      _animalRepository = SupabaseAnimalRepository();
    } else {
      _animalRepository = MockAnimalRepository();
    }
  }

  // Define os valores de filtros e recarrega
  void setFilters({
    String? species,
    String? size,
    String? gender,
    String? ageGroup,
    String? city,
    String? state,
    bool? isVaccinated,
    bool? isCastrated,
  }) {
    _selectedSpecies = species;
    _selectedSize = size;
    _selectedGender = gender;
    _selectedAgeGroup = ageGroup;
    _selectedCity = city;
    _selectedState = state;
    _filterVaccinated = isVaccinated ?? false;
    _filterCastrated = isCastrated ?? false;

    loadAllAnimals();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadAllAnimals();
  }

  void clearFilters() {
    _selectedSpecies = null;
    _selectedSize = null;
    _selectedGender = null;
    _selectedAgeGroup = null;
    _selectedCity = null;
    _selectedState = null;
    _filterVaccinated = false;
    _filterCastrated = false;
    _searchQuery = '';

    loadAllAnimals();
  }

  // Carrega todos os animais da vitrine com base nos filtros ativos
  Future<void> loadAllAnimals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _animals = await _animalRepository.getAllAnimals(
        species: _selectedSpecies,
        size: _selectedSize,
        gender: _selectedGender,
        ageGroup: _selectedAgeGroup,
        city: _selectedCity,
        state: _selectedState,
        isVaccinated: _filterVaccinated,
        isCastrated: _filterCastrated,
        query: _searchQuery,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Carrega os anúncios do próprio protetor logado
  Future<void> loadMyAnimals(String protectorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myAnimals = await _animalRepository.getAnimalsByProtector(protectorId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // CRUD: Cadastrar Animal
  Future<bool> addAnimal(AnimalModel animal, List<dynamic> localImages) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _animalRepository.createAnimal(animal, localImages);
      await loadAllAnimals(); // recarrega a vitrine
      if (animal.protectorId.isNotEmpty) {
        await loadMyAnimals(animal.protectorId); // recarrega lista do protetor
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // CRUD: Atualizar Animal
  Future<bool> updateAnimal(
    AnimalModel animal, {
    List<dynamic>? newLocalImages,
    List<String>? imagesToRemove,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _animalRepository.updateAnimal(
        animal,
        newLocalImages: newLocalImages,
        imagesToRemove: imagesToRemove,
      );
      await loadAllAnimals();
      await loadMyAnimals(animal.protectorId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // CRUD: Excluir Animal
  Future<bool> deleteAnimal(String animalId, String protectorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _animalRepository.deleteAnimal(animalId);
      await loadAllAnimals();
      await loadMyAnimals(protectorId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Busca detalhada de um único animal por ID
  Future<AnimalModel?> getAnimalById(String id) async {
    try {
      return await _animalRepository.getAnimalById(id);
    } catch (e) {
      print('Erro ao carregar detalhes do pet: $e');
      return null;
    }
  }
}
