import 'package:flutter/material.dart';
import 'dart:convert';
import 'jogo_page.dart';
import 'banco_perguntas.dart';
import 'database/app_database.dart';
import 'services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/app_bar.dart';

class TopicosPage extends StatefulWidget {
  final String ano;
  final String materia;

  const TopicosPage({super.key, required this.ano, required this.materia});

  @override
  State<TopicosPage> createState() => _TopicosPageState();
}

class _TopicosPageState extends State<TopicosPage> {
  final Set<String> _topicosConcluidos = {};
  final Set<String> _topicosEmAndamento = {};
  final Map<String, _TopicProgress> _progressoTopicos = {};
  bool _carregandoProgresso = true;

  String _canonicalGrade(String grade) {
    final value = grade.trim();
    if (value.endsWith('Fundamental')) return value;
    return '$value Fundamental';
  }

  String _trailTitle(String grade, String materia) {
    final year = grade.split('º').first;
    return materia == 'Português'
        ? 'Trilha das palavras - $yearº ano'
        : 'Trilha dos números - $yearº ano';
  }

  String _trailDescription(String grade, String materia) {
    final year = grade.split('º').first;
    if (materia == 'Português') {
      switch (year) {
        case '2':
          return 'Leia, descubra sons e forme novas palavras.';
        case '3':
          return 'Avance na leitura e organize suas ideias.';
        case '4':
          return 'Explore textos, palavras e diferentes sentidos.';
        default:
          return 'Interprete textos e escreva com confiança.';
      }
    }
    switch (year) {
      case '2':
        return 'Conte, compare e resolva desafios até 100.';
      case '3':
        return 'Use operações para resolver desafios do dia a dia.';
      case '4':
        return 'Combine estratégias e descubra novas soluções.';
      default:
        return 'Pense como um explorador e resolva problemas.';
    }
  }

  @override
  void initState() {
    super.initState();
    _carregarProgresso();
  }

  Future<void> _carregarProgresso() async {
    final userId = UserService().currentUser?.id;
    final username = UserService().currentUser?.username;
    final prefs = await SharedPreferences.getInstance();
    final andamento = <String>{};
    final progresso = <String, _TopicProgress>{};
    if (username != null) {
      for (final topico in _getTopicos()) {
        final nome = topico['nome'] as String;
        if (prefs.getBool(_chaveAndamento(username, nome)) ?? false) {
          andamento.add(nome);
        }
        final raw = prefs.getString(_chaveProgresso(username, nome));
        if (raw != null) {
          try {
            final saved = jsonDecode(raw) as Map<String, dynamic>;
            final respostas = (saved['progresso'] as List)
                .where((resposta) => resposta != null)
                .length;
            final total = (saved['progresso'] as List).length;
            if (total > 0 && respostas > 0) {
              progresso[nome] = _TopicProgress(respostas, total);
            }
          } catch (_) {}
        }
      }
    }

    if (userId == null) {
      if (mounted) {
        setState(() {
          _topicosEmAndamento.addAll(andamento);
          _progressoTopicos.addAll(progresso);
          _carregandoProgresso = false;
        });
      }
      return;
    }

    final partidas = await AppDatabase.instance.buscarPartidasUsuario(userId);
    final anoNormalizado = _canonicalGrade(widget.ano);
    final concluidos = partidas
        .where((partida) =>
            partida['materia'] == widget.materia &&
            partida['ano'] == anoNormalizado &&
            (partida['topico'] as String?)?.isNotEmpty == true)
        .map((partida) => partida['topico'] as String)
        .toSet();

    if (mounted) {
      setState(() {
        _topicosConcluidos.addAll(concluidos);
        _topicosEmAndamento.addAll(andamento);
        _topicosEmAndamento.removeAll(concluidos);
        _progressoTopicos.addAll(progresso);
        _carregandoProgresso = false;
      });
    }
  }

  String _chaveAndamento(String username, String topico) {
    return 'topico_em_andamento_${username}_${widget.materia}_${widget.ano}_$topico';
  }

  String _chaveProgresso(String username, String topico) {
    return 'quiz_progress_${username}_${widget.ano}_${widget.materia}_$topico';
  }

  Future<void> _marcarTopicoEmAndamento(String topico) async {
    final username = UserService().currentUser?.username;
    if (username == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveAndamento(username, topico), true);
    if (mounted) {
      setState(() => _topicosEmAndamento.add(topico));
    }
  }

  // Busca os tópicos disponíveis no banco de perguntas
  List<Map<String, dynamic>> _getTopicos() {
    final anoNormalizado = _canonicalGrade(widget.ano);
    final perguntas = BancoPerguntas.perguntas[widget.materia]?[anoNormalizado];
    
    if (perguntas == null || perguntas.isEmpty) {
      return [];
    }

    // Cria lista de tópicos com ícones e cores apropriadas
    List<Map<String, dynamic>> topicos = [];
    int colorIndex = 0;
    
    // Ordem específica dos tópicos BNCC para Português por ano
    List<String> ordemTopicosPortugues = [];
    
    if (anoNormalizado == '2º Ano Fundamental') {
      ordemTopicosPortugues = [
        'Leitura/escuta e interpretação',
        'Análise linguística/semiótica (ortografia e pontuação)',
        'Análise linguística/semiótica (vocabulário)'
      ];
    } else if (anoNormalizado == '5º Ano Fundamental') {
      ordemTopicosPortugues = [
        'Leitura/escuta e interpretação',
        'Produção de textos'
      ];
    } else {
      // 3º e 4º Anos
      ordemTopicosPortugues = [
        'Leitura/escuta e interpretação',
        'Análise linguística/semiótica (ortografia)',
        'Produção de textos'
      ];
    }
    
    // Cores variadas para os cards
    final cores = [
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
      Colors.purple,
      Colors.teal,
      Colors.blue,
      Colors.green,
      Colors.red,
    ];

    // Ícones por tipo de tópico
    Map<String, IconData> iconesMatematica = {
      'números': Icons.numbers,
      'adição': Icons.add,
      'subtração': Icons.remove,
      'multiplicação': Icons.close,
      'divisão': Icons.clear,
      'frações': Icons.pie_chart,
      'geometria': Icons.square,
      'formas': Icons.category,
      'área': Icons.crop_square,
      'perímetro': Icons.border_style,
      'decimais': Icons.looks_one,
      'medidas': Icons.straighten,
      'tempo': Icons.access_time,
      'operações': Icons.calculate,
      'sistema': Icons.grid_3x3,
    };

    Map<String, IconData> iconesPortugues = {
      'Alfabetização': Icons.abc,
      'Análise linguística/semiótica': Icons.spellcheck,
      'Leitura/escuta e interpretação': Icons.menu_book,
      'Análise linguística/semiótica (ortografia e pontuação)': Icons.spellcheck,
      'Análise linguística/semiótica (vocabulário)': Icons.book,
      'Produção de textos': Icons.create,
      'Ortografia': Icons.spellcheck,
      'ortografia': Icons.spellcheck,
      'pontuação': Icons.edit,
      'texto': Icons.description,
      'linguística': Icons.spellcheck,
      'semiótica': Icons.spellcheck,
      'leitura': Icons.menu_book,
      'interpretação': Icons.article,
    };

    // Lista para armazenar os tópicos na ordem correta
    List<String> topicosOrdenados = [];
    
    if (widget.materia == 'Português') {
      // Filtra os tópicos disponíveis na ordem BNCC
      topicosOrdenados = ordemTopicosPortugues
          .where((t) => perguntas.keys.contains(t))
          .toList();
    } else {
      // Para outras matérias, mantém a ordem original
      topicosOrdenados = perguntas.keys.toList();
    }

    for (var topico in topicosOrdenados) {
      IconData icone = Icons.star; // ícone padrão
      
      // Seleciona ícone baseado no nome do tópico
      if (widget.materia == 'Matemática') {
        for (var palavra in iconesMatematica.keys) {
          if (topico.toLowerCase().contains(palavra)) {
            icone = iconesMatematica[palavra]!;
            break;
          }
        }
      } else if (widget.materia == 'Português') {
        // Usa o tópico exato para encontrar o ícone
        icone = iconesPortugues[topico] ?? Icons.star;
      }

      topicos.add({
        'nome': topico,
        'icone': icone,
        'cor': cores[colorIndex % cores.length],
      });
      colorIndex++;
    }

    return topicos;
  }

  @override
  Widget build(BuildContext context) {
    final topicos = _getTopicos();
    final anoNormalizado = _canonicalGrade(widget.ano);

    return Scaffold(
      appBar: AppTopBar(title: '${widget.materia} - $anoNormalizado'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _trailTitle(anoNormalizado, widget.materia),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _trailDescription(anoNormalizado, widget.materia),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: topicos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum tópico disponível\npara ${widget.materia} - $anoNormalizado',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: topicos.length,
                        separatorBuilder: (context, index) => Center(
                          child: Container(
                            width: 4,
                            height: 18,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final topico = topicos[index];
                          final concluido = _topicosConcluidos.contains(topico['nome']);
                          final emAndamento = _topicosEmAndamento.contains(topico['nome']);
                          final progresso = _progressoTopicos[topico['nome']];
                          return TweenAnimationBuilder(
                            duration: Duration(milliseconds: 300 + (index * 100)),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: Card(
                              elevation: 8,
                              shadowColor: topico['cor'].withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: InkWell(
                                onTap: () async {
                                  final navigator = Navigator.of(context);
                                  await _marcarTopicoEmAndamento(topico['nome'] as String);
                                  await navigator.push(
                                    MaterialPageRoute(
                                      builder: (_) => JogoPage(
                                        ano: anoNormalizado,
                                        materia: widget.materia,
                                        topico: topico['nome'],
                                      ),
                                    ),
                                  );
                                  if (mounted) await _carregarProgresso();
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        topico['cor'],
                                        topico['cor'].withValues(alpha: 0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Etapa ${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          topico['icone'],
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        topico['nome'],
                                        textAlign: TextAlign.center,
                                        maxLines: 3,
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.1,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(0, 1),
                                              blurRadius: 3,
                                              color: Colors.black26,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildTopicStatus(concluido, emAndamento, progresso),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

    Widget _buildTopicStatus(
      bool concluido,
      bool emAndamento,
      _TopicProgress? progresso,
    ) {
    final label = _carregandoProgresso
        ? 'Carregando...'
        : concluido
            ? 'Concluído'
        : emAndamento
          ? 'Em andamento'
          : 'Disponível';
    final color = concluido
      ? Colors.green.shade700
      : emAndamento
        ? Colors.orange.shade800
        : Colors.blueGrey.shade700;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                concluido
                    ? Icons.check_circle
                    : emAndamento
                        ? Icons.timelapse
                        : Icons.play_circle_outline,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                progresso == null || concluido
                    ? label
                    : '$label: ${progresso.respondidas} de ${progresso.total}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (progresso != null && !concluido) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: 150,
            child: LinearProgressIndicator(
              value: progresso.percentual,
              minHeight: 5,
              backgroundColor: Colors.white54,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ],
    );
  }
}

class _TopicProgress {
  final int respondidas;
  final int total;

  const _TopicProgress(this.respondidas, this.total);

  double get percentual => (respondidas / total).clamp(0.0, 1.0);
}
