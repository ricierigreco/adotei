import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/animal_model.dart';

class AnimalCard extends StatelessWidget {
  final AnimalModel animal;
  final VoidCallback onTap;

  const AnimalCard({
    Key? key,
    required this.animal,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Configuração de cores para tags
    final Color speciesColor = animal.species == 'cao' ? Colors.blue.shade100 : Colors.purple.shade100;
    final Color speciesTextColor = animal.species == 'cao' ? Colors.blue.shade800 : Colors.purple.shade800;

    final Color genderColor = animal.gender == 'macho' ? Colors.teal.shade50 : Colors.pink.shade50;
    final Color genderTextColor = animal.gender == 'macho' ? Colors.teal.shade700 : Colors.pink.shade700;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.softShadow,
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagem do Animal
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      animal.imageUrls.isNotEmpty 
                          ? animal.imageUrls.first 
                          : 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=600',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.pets, size: 40, color: Colors.grey),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                          ),
                        );
                      },
                    ),
                    // Tag de Status (se não for "disponivel")
                    if (animal.status != 'disponivel')
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: animal.status == 'em_processo' 
                                ? AppColors.statusProcesso 
                                : AppColors.statusAdotado,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            animal.formattedStatus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Conteúdo textual
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nome e Espécie
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            animal.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textLight : AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: speciesColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            animal.formattedSpecies,
                            style: TextStyle(
                              color: speciesTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Raça / Idade
                    Text(
                      '${animal.breed} • ${animal.formattedAgeGroup}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Tags de Porte e Sexo
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            animal.formattedSize,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textLight : AppColors.textDark.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: genderColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            animal.gender == 'macho' ? 'Macho' : 'Fêmea',
                            style: TextStyle(
                              color: genderTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    const Divider(height: 1, thickness: 0.5),
                    const SizedBox(height: 8),

                    // Localização (Cidade/Estado)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${animal.city}, ${animal.state}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



