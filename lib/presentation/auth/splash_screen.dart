import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../data/local/prefs_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/medicamento_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    final t0 = DateTime.now();
    debugPrint('[SPLASH] _inicializar started');

    await Future.delayed(const Duration(milliseconds: 1500));
    debugPrint('[SPLASH] delay: ${DateTime.now().difference(t0).inMilliseconds}ms');
    if (!mounted) return;

    final sessaoId = await AuthRepository().obterSessaoAtiva();
    debugPrint('[SPLASH] obterSessaoAtiva: ${DateTime.now().difference(t0).inMilliseconds}ms');
    if (!mounted) return;

    if (sessaoId == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final pendingPayload =
        await PrefsService.instance.consumirNotificacaoPendente();
    if (!mounted) return;

    if (pendingPayload != null) {
      Navigator.pushReplacementNamed(
        context,
        '/notification-action',
        arguments: pendingPayload,
      );
      return;
    }

    Navigator.pushReplacementNamed(context, '/home');
    debugPrint('[SPLASH] navegou para /home: ${DateTime.now().difference(t0).inMilliseconds}ms');

    MedicamentoRepository().reagendarTodos(sessaoId).then((_) {
      debugPrint('[SPLASH] reagendarTodos concluído: ${DateTime.now().difference(t0).inMilliseconds}ms');
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.medication_rounded,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'MediNow',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Seus medicamentos em dia',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
