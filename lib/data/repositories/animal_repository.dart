import '../models/animal_model.dart';

abstract class AnimalRepository {
  Future<List<AnimalModel>> getAllAnimals({
    String? species,
    String? size,
    String? gender,
    String? ageGroup,
    String? city,
    String? state,
    bool? isVaccinated,
    bool? isCastrated,
    String? query, // busca por nome
  });

  Future<List<AnimalModel>> getAnimalsByProtector(String protectorId);

  Future<AnimalModel> getAnimalById(String id);

  Future<AnimalModel> createAnimal(
    AnimalModel animal,
    List<dynamic> localImages,
  );

  Future<AnimalModel> updateAnimal(
    AnimalModel animal, {
    List<dynamic>? newLocalImages,
    List<String>? imagesToRemove,
  });

  Future<void> deleteAnimal(String id);
}
