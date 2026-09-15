import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_input.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As senhas não coincidem.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim().toUpperCase(),
      password: _passwordController.text,
    );

    if (success) {
      if (mounted) {
        // Exibe mensagem de sucesso e redireciona
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada com sucesso!'),
            backgroundColor: AppColors.statusDisponivel,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Erro desconhecido'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.textLight : AppColors.textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Criar Conta',
          style: TextStyle(
            color: isDark ? AppColors.textLight : AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Junte-se à nossa comunidade',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cadastre-se para anunciar animais para doação e salvar vidas de pets carentes.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nome Completo
                    CustomInput(
                      label: 'Nome Completo',
                      placeholder: 'Ex: Maria das Dores Souza',
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

                    // E-mail
                    CustomInput(
                      label: 'E-mail',
                      placeholder: 'exemplo@gmail.com',
                      prefixIcon: Icons.email_outlined,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'E-mail é obrigatório';
                        if (!val.contains('@')) return 'E-mail inválido';
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
                        // Validação simples de tamanho mínimo para celular BR com DDD
                        final clean = val.replaceAll(RegExp(r'\D'), '');
                        if (clean.length < 10)
                          return 'Telefone inválido. Inclua o DDD.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Localização (Cidade e UF)
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
                    const SizedBox(height: 16),

                    // Senha
                    CustomInput(
                      label: 'Senha',
                      placeholder: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      controller: _passwordController,
                      isPassword: true,
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'Senha é obrigatória';
                        if (val.length < 6)
                          return 'A senha deve ter pelo menos 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirmar Senha
                    CustomInput(
                      label: 'Confirmar Senha',
                      placeholder: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      controller: _confirmPasswordController,
                      isPassword: true,
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'Confirmação obrigatória';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Botão Cadastrar
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: auth.isLoading ? null : _submit,
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Criar Conta',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
