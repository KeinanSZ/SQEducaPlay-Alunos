import 'package:flutter/material.dart';
import 'pages/access_choice_page.dart';
import 'package:flutter/services.dart';
import 'services/background_audio_service.dart';
import 'services/progresso_service.dart';
import 'theme/design_tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa o serviço de áudio de fundo uma vez por toda a aplicação
  try {
    await BackgroundAudioService.instance.init();
  } catch (e, s) {
    // Melhoria: Adiciona log em caso de falha para facilitar o diagnóstico.
    debugPrint('Falha ao inicializar o serviço de áudio: $e\n$s');
  }
  // Carrega progresso persistido do banco para disponibilizar perfil/ranking
  try {
    // Correção: Usa a instância singleton para consistência de dados.
    await ProgressoService().carregarDoBanco();
  } catch (e, s) {
    // Melhoria: Não interrompe o início, mas registra o erro para diagnóstico.
    debugPrint('Falha ao carregar o progresso do banco: $e\n$s');
  }
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const SQEducaPlay());
}

class SQEducaPlay extends StatelessWidget {
  const SQEducaPlay({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQEducaPlay',
      debugShowCheckedModeBanner: false,
      theme: DesignTokens.lightTheme(),
      home: const AccessChoicePage(),
    );
  }
}
