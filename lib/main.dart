import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/constants/app_colors.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/animal_provider.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Supabase se configurado
  if (AppConfig.useSupabase && AppConfig.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      print('Supabase inicializado com sucesso.');
    } catch (e) {
      print('Erro ao inicializar Supabase: $e');
    }
  } else {
    print(
      'Rodando em Modo MOCK (Simulado). Supabase aguardando credenciais em app_config.dart.',
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AnimalProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Adotei!',
            debugShowCheckedModeBanner: false,

            // Tema Claro Premium
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.light,
                primary: AppColors.primary,
                secondary: AppColors.secondary,
                surface: AppColors.surfaceLight,
                background: AppColors.backgroundLight,
              ),
              scaffoldBackgroundColor: AppColors.backgroundLight,

              // Tipografia Global
              textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
                  .copyWith(
                    displayLarge: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                    ),
                    displayMedium: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                    ),
                    displaySmall: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                    ),
                    headlineLarge: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                    ),
                    headlineMedium: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                    ),
                    headlineSmall: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                    ),
                    titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),

              // Estilização do AppBar
              appBarTheme: AppBarTheme(
                backgroundColor: AppColors.backgroundLight,
                elevation: 0,
                centerTitle: false,
                iconTheme: const IconThemeData(color: AppColors.textDark),
                titleTextStyle: GoogleFonts.outfit(
                  color: AppColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Estilização do Card
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            // Tema Escuro Elegante
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.dark,
                primary: AppColors.primary,
                secondary: AppColors.secondary,
                surface: AppColors.surfaceDark,
                background: AppColors.backgroundDark,
              ),
              scaffoldBackgroundColor: AppColors.backgroundDark,

              // Tipografia Global Dark
              textTheme:
                  GoogleFonts.interTextTheme(
                    Theme.of(context).primaryTextTheme,
                  ).copyWith(
                    displayLarge: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textLight,
                    ),
                    displayMedium: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textLight,
                    ),
                    displaySmall: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textLight,
                    ),
                    headlineLarge: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textLight,
                    ),
                    headlineMedium: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                    ),
                    headlineSmall: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                    titleLarge: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),

              // Estilização do AppBar Dark
              appBarTheme: AppBarTheme(
                backgroundColor: AppColors.backgroundDark,
                elevation: 0,
                centerTitle: false,
                iconTheme: const IconThemeData(color: AppColors.textLight),
                titleTextStyle: GoogleFonts.outfit(
                  color: AppColors.textLight,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Estilização do Card Dark
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            themeMode: ThemeMode.system, // Segue o tema do sistema do usuário

            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
