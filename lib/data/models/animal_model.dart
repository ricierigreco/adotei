import 'dart:convert';

class AnimalModel {
  final String id;
  final String protectorId;
  final String name;
  final String species; // cao, gato, outro
  final String breed; // SRD / Vira-lata ou raça definida
  final String ageGroup; // filhote, jovem, adulto, idoso
  final String size; // pequeno, médio, grande
  final String gender; // macho, fêmea
  final bool isVaccinated;
  final bool isCastrated;
  final bool isDewormed; // vermifugado
  final String temperamentNotes;
  final String city;
  final String state;
  final String status; // disponivel, em_processo, adotado
  final DateTime createdAt;
  final List<String> imageUrls;

  AnimalModel({
    required this.id,
    required this.protectorId,
    required this.name,
    required this.species,
    required this.breed,
    required this.ageGroup,
    required this.size,
    required this.gender,
    required this.isVaccinated,
    required this.isCastrated,
    required this.isDewormed,
    required this.temperamentNotes,
    required this.city,
    required this.state,
    required this.status,
    required this.createdAt,
    required this.imageUrls,
  });

  AnimalModel copyWith({
    String? id,
    String? protectorId,
    String? name,
    String? species,
    String? breed,
    String? ageGroup,
    String? size,
    String? gender,
    bool? isVaccinated,
    bool? isCastrated,
    bool? isDewormed,
    String? temperamentNotes,
    String? city,
    String? state,
    String? status,
    DateTime? createdAt,
    List<String>? imageUrls,
  }) {
    return AnimalModel(
      id: id ?? this.id,
      protectorId: protectorId ?? this.protectorId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      ageGroup: ageGroup ?? this.ageGroup,
      size: size ?? this.size,
      gender: gender ?? this.gender,
      isVaccinated: isVaccinated ?? this.isVaccinated,
      isCastrated: isCastrated ?? this.isCastrated,
      isDewormed: isDewormed ?? this.isDewormed,
      temperamentNotes: temperamentNotes ?? this.temperamentNotes,
      city: city ?? this.city,
      state: state ?? this.state,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'protectorId': protectorId,
      'name': name,
      'species': species,
      'breed': breed,
      'ageGroup': ageGroup,
      'size': size,
      'gender': gender,
      'isVaccinated': isVaccinated,
      'isCastrated': isCastrated,
      'isDewormed': isDewormed,
      'temperamentNotes': temperamentNotes,
      'city': city,
      'state': state,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'imageUrls': imageUrls,
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'protector_id': protectorId,
      'name': name,
      'species': species,
      'breed': breed,
      'age_group': ageGroup,
      'size': size,
      'gender': gender,
      'is_vaccinated': isVaccinated,
      'is_castrated': isCastrated,
      'is_dewormed': isDewormed,
      'temperament_notes': temperamentNotes,
      'city': city,
      'state': state,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'image_urls': imageUrls,
    };
  }

  factory AnimalModel.fromMap(Map<String, dynamic> map) {
    List<String> images = [];
    if (map['image_urls'] != null) {
      images = List<String>.from(map['image_urls']);
    } else if (map['imageUrls'] != null) {
      images = List<String>.from(map['imageUrls']);
    }

    return AnimalModel(
      id: map['id']?.toString() ?? '',
      protectorId: map['protector_id']?.toString() ?? map['protectorId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      species: map['species']?.toString() ?? 'cao',
      breed: map['breed']?.toString() ?? 'SRD',
      ageGroup: map['age_group']?.toString() ?? map['ageGroup']?.toString() ?? 'adulto',
      size: map['size']?.toString() ?? 'medio',
      gender: map['gender']?.toString() ?? 'macho',
      isVaccinated: map['is_vaccinated'] ?? map['isVaccinated'] ?? false,
      isCastrated: map['is_castrated'] ?? map['isCastrated'] ?? false,
      isDewormed: map['is_dewormed'] ?? map['isDewormed'] ?? false,
      temperamentNotes: map['temperament_notes']?.toString() ?? map['temperamentNotes']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      state: map['state']?.toString() ?? '',
      status: map['status']?.toString() ?? 'disponivel',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : (map['createdAt'] != null
              ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      imageUrls: images,
    );
  }

  String toJson() => json.encode(toMap());

  factory AnimalModel.fromJson(String source) =>
      AnimalModel.fromMap(json.decode(source));

  // Helpers para exibição formatada amigável
  String get formattedStatus {
    switch (status) {
      case 'disponivel':
        return 'Disponível';
      case 'em_processo':
        return 'Adoção em Andamento';
      case 'adotado':
        return 'Adotado! 🎉';
      default:
        return 'Desconhecido';
    }
  }

  String get formattedSpecies {
    switch (species) {
      case 'cao':
        return 'Cão';
      case 'gato':
        return 'Gato';
      default:
        return 'Outro';
    }
  }

  String get formattedSize {
    switch (size) {
      case 'pequeno':
        return 'Porte Pequeno';
      case 'medio':
        return 'Porte Médio';
      case 'grande':
        return 'Porte Grande';
      default:
        return 'Médio';
    }
  }

  String get formattedAgeGroup {
    switch (ageGroup) {
      case 'filhote':
        return 'Filhote';
      case 'jovem':
        return 'Jovem';
      case 'adulto':
        return 'Adulto';
      case 'idoso':
        return 'Idoso';
      default:
        return 'Adulto';
    }
  }
}
