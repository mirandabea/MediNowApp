import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/colors.dart';
import 'data/models/medicamento_model.dart';
import 'presentation/auth/splash_screen.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/cadastro_screen.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/medicamento/cadastro_medicamento_screen.dart';
import 'presentation/medicamento/historico_medicamento_screen.dart';
import 'presentation/notification/notification_action_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MediNowApp extends StatelessWidget {
  const MediNowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediNow',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/cadastro': (_) => const CadastroScreen(),
        '/home': (_) => const HomeScreen(),
        '/cadastro-medicamento': (ctx) {
          final med = ModalRoute.of(ctx)?.settings.arguments;
          return CadastroMedicamentoScreen(
            medicamento: med is MedicamentoModel ? med : null,
          );
        },
        '/notification-action': (_) => const NotificationActionScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/historico') {
          final medicamentoId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) =>
                HistoricoMedicamentoScreen(medicamentoId: medicamentoId),
          );
        }
        return null;
      },
    );
  }
}
