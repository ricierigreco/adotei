import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/animal_model.dart';
import '../animal_repository.dart';

class SupabaseAnimalRepository implements AnimalRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

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
    try {
      // Inicia a busca filtrando animais que não estão marcados como adotados
      var filterBuilder = _supabase
          .from('animals')
          .select()
          .neq('status', 'adotado');

      // Aplica filtros nativos no Postgres
      if (species != null && species.isNotEmpty) {
        filterBuilder = filterBuilder.eq('species', species.toLowerCase());
      }
      if (size != null && size.isNotEmpty) {
        filterBuilder = filterBuilder.eq('size', size.toLowerCase());
      }
      if (gender != null && gender.isNotEmpty) {
        filterBuilder = filterBuilder.eq('gender', gender.toLowerCase());
      }
      if (ageGroup != null && ageGroup.isNotEmpty) {
        filterBuilder = filterBuilder.eq('age_group', ageGroup.toLowerCase());
      }
      if (state != null && state.isNotEmpty) {
        filterBuilder = filterBuilder.eq('state', state.toUpperCase());
      }
      if (city != null && city.isNotEmpty) {
        filterBuilder = filterBuilder.ilike('city', '%$city%');
      }
      if (isVaccinated == true) {
        filterBuilder = filterBuilder.eq('is_vaccinated', true);
      }
      if (isCastrated == true) {
        filterBuilder = filterBuilder.eq('is_castrated', true);
      }
      if (query != null && query.trim().isNotEmpty) {
        filterBuilder = filterBuilder.ilike('name', '%${query.trim()}%');
      }

      final response = await filterBuilder.order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => AnimalModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao carregar animais do Supabase: $e');
      throw Exception('Erro ao carregar catálogo de animais: $e');
    }
  }

  @override
  Future<List<AnimalModel>> getAnimalsByProtector(String protectorId) async {
    try {
      final response = await _supabase
          .from('animals')
          .select()
          .eq('protector_id', protectorId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => AnimalModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar seus anúncios: $e');
    }
  }

  @override
  Future<AnimalModel> getAnimalById(String id) async {
    try {
      final response = await _supabase
          .from('animals')
          .select()
          .eq('id', id)
          .single();

      return AnimalModel.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao carregar detalhes do animal: $e');
    }
  }

  @override
  Future<AnimalModel> createAnimal(
    AnimalModel animal,
    List<dynamic> localImages,
  ) async {
    try {
      // Gera identificador único temporário caso o id venha vazio
      final tempId = animal.id.isNotEmpty
          ? animal.id
          : 'anim_${DateTime.now().millisecondsSinceEpoch}';

      final List<String> imageUrls = [];

      // Fazer upload de todas as imagens para o bucket de storage 'animals'
      for (int i = 0; i < localImages.length; i++) {
        final dynamic imgData = localImages[i];
        if (imgData is Uint8List) {
          final filePath =
              '$tempId/img_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await _supabase.storage.from('animals').uploadBinary(
                filePath,
                imgData,
                fileOptions: const FileOptions(
                  upsert: true,
                  contentType: 'image/jpeg',
                ),
              );
          final publicUrl =
              _supabase.storage.from('animals').getPublicUrl(filePath);
          imageUrls.add(publicUrl);
        } else if (imgData is String && imgData.startsWith('http')) {
          imageUrls.add(imgData);
        }
      }

      if (imageUrls.isEmpty) {
        throw Exception('Pelo menos uma imagem é obrigatória.');
      }

      final animalToInsert = animal.copyWith(
        id: tempId,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
      );

      final dataMap = animalToInsert.toSupabaseMap();
      // Remove o id caso queira deixar o Postgres gerar UUID padrão ou envia se válido
      if (tempId.startsWith('anim_')) {
        dataMap.remove('id');
      }

      final response =
          await _supabase.from('animals').insert(dataMap).select().single();

      return AnimalModel.fromMap(response);
    } catch (e) {
      print('Erro no createAnimal Supabase: $e');
      throw Exception('Erro ao cadastrar animal no Supabase: $e');
    }
  }

  @override
  Future<AnimalModel> updateAnimal(
    AnimalModel animal, {
    List<dynamic>? newLocalImages,
    List<String>? imagesToRemove,
  }) async {
    try {
      List<String> currentImages = List.from(animal.imageUrls);

      // Remover imagens solicitadas
      if (imagesToRemove != null && imagesToRemove.isNotEmpty) {
        for (final url in imagesToRemove) {
          currentImages.remove(url);
          try {
            // Tenta remover do storage extraindo o path relativo
            final uri = Uri.parse(url);
            final segments = uri.pathSegments;
            final bucketIndex = segments.indexOf('animals');
            if (bucketIndex != -1 && bucketIndex + 1 < segments.length) {
              final storagePath = segments.sublist(bucketIndex + 1).join('/');
              await _supabase.storage.from('animals').remove([storagePath]);
            }
          } catch (_) {}
        }
      }

      // Upload de novas imagens
      if (newLocalImages != null && newLocalImages.isNotEmpty) {
        for (int i = 0; i < newLocalImages.length; i++) {
          final dynamic imgData = newLocalImages[i];
          if (imgData is Uint8List) {
            final filePath =
                '${animal.id}/img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
            await _supabase.storage.from('animals').uploadBinary(
                  filePath,
                  imgData,
                  fileOptions: const FileOptions(
                    upsert: true,
                    contentType: 'image/jpeg',
                  ),
                );
            final publicUrl =
                _supabase.storage.from('animals').getPublicUrl(filePath);
            currentImages.add(publicUrl);
          }
        }
      }

      if (currentImages.isEmpty) {
        throw Exception('O anúncio precisa ter pelo menos uma foto.');
      }

      final updatedAnimal = animal.copyWith(imageUrls: currentImages);

      final response = await _supabase
          .from('animals')
          .update(updatedAnimal.toSupabaseMap())
          .eq('id', animal.id)
          .select()
          .single();

      return AnimalModel.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao atualizar dados do animal: $e');
    }
  }

  @override
  Future<void> deleteAnimal(String id) async {
    try {
      await _supabase.from('animals').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao excluir anúncio: $e');
    }
  }
}
