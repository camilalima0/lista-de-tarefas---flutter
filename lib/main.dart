import 'package:flutter/material.dart';
import 'database_helper.dart';

// ENUMS
enum Prioridade {
  baixa,
  media,
  alta;

  String get label {
    switch (this) {
      case Prioridade.baixa:
        return 'Baixa';
      case Prioridade.media:
        return 'Média';
      case Prioridade.alta:
        return 'Alta';
    }
  }

  Color get color {
    switch (this) {
      case Prioridade.baixa:
        return Colors.green;
      case Prioridade.media:
        return Colors.amber;
      case Prioridade.alta:
        return Colors.redAccent;
    }
  }
}

enum TipoTarefa {
  estudo,
  trabalho,
  pessoal;

  String get label {
    switch (this) {
      case TipoTarefa.estudo:
        return 'Estudo';
      case TipoTarefa.trabalho:
        return 'Trabalho';
      case TipoTarefa.pessoal:
        return 'Pessoal';
    }
  }
}

final ThemeData temaEnergetico = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.orange,
    primary: Colors.orange,
    secondary: Colors.deepOrange,
    brightness: Brightness.light,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.orange,
    foregroundColor: Colors.white,
    centerTitle: true,
    elevation: 4,
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.deepOrange,
    foregroundColor: Colors.white,
  ),

  cardTheme: CardThemeData(color: Colors.orange[50], elevation: 2),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepOrange,
      foregroundColor: Colors.white,
    ),
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lista de Tarefas',
      theme: temaEnergetico,
      home: const TelaTarefa(),
    );
  }
}

class TelaTarefa extends StatefulWidget {
  const TelaTarefa({super.key});

  @override
  State<TelaTarefa> createState() => _TelaTarefaState();
}

class _TelaTarefaState extends State<TelaTarefa> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _prazoController = TextEditingController();

  Prioridade _prioridadeSelecionada = Prioridade.baixa;
  TipoTarefa _tipoSelecionado = TipoTarefa.pessoal;

  List<Map<String, dynamic>> _listaTarefas = [];

  @override
  void initState() {
    super.initState();
    _atualizarListaTarefas();
  }

  //BANCO DE DADOS
  void _atualizarListaTarefas() async {
    final dbHelper = DatabaseHelper();
    final dados = await dbHelper.queryAllRows();
    setState(() {
      _listaTarefas = dados;
    });
  }

  void _salvarOuAtualizarTarefa({int? id}) async {
    if (_tituloController.text.isEmpty) return;

    final dbHelper = DatabaseHelper();

    Map<String, dynamic> dadosTarefa = {
      'tituloTarefa': _tituloController.text,
      'descricaoTarefa': _descricaoController.text,
      'prazoTarefa': _prazoController.text,
      'dataCriacaoTarefa': DateTime.now().toString(),
      'prioridadeTarefa': _prioridadeSelecionada.name,
      'tipoTarefa': _tipoSelecionado.name,
    };

    if (id == null) {
      await dbHelper.insert(dadosTarefa);
    } else {
      dadosTarefa['idTarefa'] = id;
      await dbHelper.update(dadosTarefa);
    }

    _tituloController.clear();
    _descricaoController.clear();
    _prazoController.clear();

    setState(() {
      _prioridadeSelecionada = Prioridade.baixa;
      _tipoSelecionado = TipoTarefa.pessoal;
    });

    _atualizarListaTarefas();

    if (mounted) FocusScope.of(context).unfocus();
  }

  void _deletarTarefa(int id) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.delete(id);
    _atualizarListaTarefas();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tarefa deletada!')));
    }
  }

  //TELA
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Tarefas')),
      body: _listaTarefas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 80, color: Colors.orange[200]),
                  const SizedBox(height: 20),
                  const Text(
                    'Nenhuma tarefa ainda.\nVamos produzir!',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _listaTarefas.length,
              itemBuilder: (context, index) {
                final item = _listaTarefas[index];

                Prioridade prioridadeObj;
                try {
                  prioridadeObj = Prioridade.values.byName(
                    item['prioridadeTarefa'],
                  );
                } catch (e) {
                  prioridadeObj = Prioridade.baixa;
                }

                TipoTarefa tipoObj;
                try {
                  tipoObj = TipoTarefa.values.byName(item['tipoTarefa']);
                } catch (e) {
                  tipoObj = TipoTarefa.pessoal;
                }

                return Card(
                  child: ListTile(
                    onTap: () =>
                        _mostrarFormulario(context, tarefaParaEditar: item),
                    leading: CircleAvatar(
                      backgroundColor: prioridadeObj.color,
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item['tituloTarefa'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${tipoObj.label} | Prazo: ${item['prazoTarefa']}",
                        ),
                        if (item['descricaoTarefa'] != "")
                          Text(
                            item['descricaoTarefa'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[800],
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.deepOrange),
                      onPressed: () => _deletarTarefa(item['idTarefa']),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(context, tarefaParaEditar: null),
        child: const Icon(Icons.add),
        // A cor deepOrange vem do tema
      ),
    );
  }

  void _mostrarFormulario(
    BuildContext context, {
    Map<String, dynamic>? tarefaParaEditar,
  }) {
    if (tarefaParaEditar != null) {
      _tituloController.text = tarefaParaEditar['tituloTarefa'];
      _descricaoController.text = tarefaParaEditar['descricaoTarefa'];
      _prazoController.text = tarefaParaEditar['prazoTarefa'];
      try {
        _prioridadeSelecionada = Prioridade.values.byName(
          tarefaParaEditar['prioridadeTarefa'],
        );
        _tipoSelecionado = TipoTarefa.values.byName(
          tarefaParaEditar['tipoTarefa'],
        );
      } catch (e) {}
    } else {
      _tituloController.clear();
      _descricaoController.clear();
      _prazoController.clear();
      _prioridadeSelecionada = Prioridade.baixa;
      _tipoSelecionado = TipoTarefa.pessoal;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                tarefaParaEditar == null ? 'Nova Tarefa' : 'Editar Tarefa',
                style: const TextStyle(
                  color: Colors.deepOrange,
                ), // Destaque no título
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.deepOrange,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _prazoController,
                      decoration: const InputDecoration(
                        labelText: 'Prazo',
                        suffixIcon: Icon(
                          Icons.calendar_today,
                          color: Colors.orange,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<Prioridade>(
                      value: _prioridadeSelecionada,
                      decoration: const InputDecoration(
                        labelText: 'Prioridade',
                        border: OutlineInputBorder(),
                      ),
                      items: Prioridade.values.map((Prioridade p) {
                        return DropdownMenuItem(value: p, child: Text(p.label));
                      }).toList(),
                      onChanged: (Prioridade? novo) {
                        setDialogState(() => _prioridadeSelecionada = novo!);
                      },
                    ),

                    const SizedBox(height: 10),

                    DropdownButtonFormField<TipoTarefa>(
                      value: _tipoSelecionado,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
                      ),
                      items: TipoTarefa.values.map((TipoTarefa t) {
                        return DropdownMenuItem(value: t, child: Text(t.label));
                      }).toList(),
                      onChanged: (TipoTarefa? novo) {
                        setDialogState(() => _tipoSelecionado = novo!);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _tituloController.clear();
                    _descricaoController.clear();
                    _prazoController.clear();
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _salvarOuAtualizarTarefa(
                      id: tarefaParaEditar != null
                          ? tarefaParaEditar['idTarefa']
                          : null,
                    );
                    Navigator.pop(context);
                  },
                  child: Text(
                    tarefaParaEditar == null ? 'Salvar' : 'Atualizar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
