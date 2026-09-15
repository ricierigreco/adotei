import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/image_helper.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_input.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  Uint8List? _newProfileImageBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      final user = auth.currentUser!;
      _nameController.text = user.name;
      _phoneController.text = user.phone;
      _cityController.text = user.city;
      _stateController.text = user.state;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePicture() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (file != null) {
        setState(() => _isSaving = true);
        final compressed = await ImageHelper.compressImage(file, maxWidth: 400);
        setState(() {
          _isSaving = false;
          if (compressed != null) {
            _newProfileImageBytes = compressed;
          }
        });
      }
    } catch (e) {
      setState(() => _isSaving = false);
      print('Erro ao selecionar foto de perfil: $e');
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();

    if (auth.isAuthenticated) {
      final updatedUser = auth.currentUser!.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim().toUpperCase(),
      );

      final success = await auth.updateProfile(
        updatedUser,
        newProfileImage: _newProfileImageBytes,
      );

      setState(() => _isSaving = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: AppColors.statusDisponivel,
          ),
        );
        Navigator.pop(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(auth.errorMessage ?? 'Erro ao atualizar perfil.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Você não está autenticado.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('Ir para Login'),
              ),
            ],
          ),
        ),
      );
    }

    final user = auth.currentUser!;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Meu Perfil'),
            actions: [
              IconButton(
                icon: const Icon(Icons.check, color: AppColors.primary),
                onPressed: _isSaving ? null : _saveProfile,
                tooltip: 'Salvar Perfil',
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar do usuário clicável
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              backgroundImage: _newProfileImageBytes != null
                                  ? MemoryImage(_newProfileImageBytes!)
                                  : (user.profilePictureUrl != null
                                        ? NetworkImage(user.profilePictureUrl!)
                                        : null),
                              child:
                                  _newProfileImageBytes == null &&
                                      user.profilePictureUrl == null
                                  ? Text(
                                      user.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickProfilePicture,
                                child: const CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  radius: 18,
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // E-mail (Somente leitura para segurança de login)
                      CustomInput(
                        label: 'E-mail (Não editável)',
                        placeholder: user.email,
                        prefixIcon: Icons.email_outlined,
                        controller: TextEditingController(text: user.email),
                        validator: null,
                        onChanged: null,
                        suffixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.grey,
                          size: 20,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Nome Completo
                      CustomInput(
                        label: 'Nome Completo',
                        placeholder: 'Ex: João Carlos da Silva',
                        prefixIcon: Icons.person_outline,
                        controller: _nameController,
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return 'Nome é obrigatório';
                          if (val.trim().split(' ').length < 2)
                            return 'Digite seu nome completo';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Telefone / WhatsApp
                      CustomInput(
                        label: 'Telefone / WhatsApp (com DDD)',
                        placeholder: 'Ex: 11999998888',
                        prefixIcon: Icons.phone_outlined,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return 'Telefone é obrigatório';
                          final clean = val.replaceAll(RegExp(r'\D'), '');
                          if (clean.length < 10)
                            return 'Inclua o DDD no número de telefone';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Cidade e Estado (UF)
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: CustomInput(
                              label: 'Cidade',
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
                      const SizedBox(height: 36),

                      // Botão Salvar Perfil
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
                        onPressed: _isSaving ? null : _saveProfile,
                        child: const Text(
                          'Salvar Alterações',
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
        if (_isSaving)
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
                    'Salvando alterações...',
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
