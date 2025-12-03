import 'package:flutter/material.dart';
import 'database_helper.dart';

// --- ENUMS ---
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
        return Colors.orange;
      case Prioridade.alta:
        return Colors.red;
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
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
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
  // Controllers
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _prazoController = TextEditingController();

  // Variáveis de Estado (Valores Padrão)
  Prioridade _prioridadeSelecionada = Prioridade.baixa;
  TipoTarefa _tipoSelecionado = TipoTarefa.pessoal;

  List<Map<String, dynamic>> _listaTarefas = [];

  @override
  void initState() {
    super.initState();
    _atualizarListaTarefas();
  }

  // --- BANCO DE DADOS ---

  void _atualizarListaTarefas() async {
    final dbHelper = DatabaseHelper();
    final dados = await dbHelper.queryAllRows();
    setState(() {
      _listaTarefas = dados;
    });
  }

  // Agora esta função serve para SALVAR (Criar) ou ATUALIZAR (Editar)
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
      // Se não tem ID, é CRIAÇÃO (Insert)
      await dbHelper.insert(dadosTarefa);
    } else {
      // Se tem ID, é ATUALIZAÇÃO (Update)
      // Precisamos adicionar o ID no map para o WHERE do banco funcionar
      dadosTarefa['idTarefa'] = id;
      await dbHelper.update(dadosTarefa);
    }

    // Limpa campos
    _tituloController.clear();
    _descricaoController.clear();
    _prazoController.clear();

    // Reseta Enums
    setState(() {
      _prioridadeSelecionada = Prioridade.baixa;
      _tipoSelecionado = TipoTarefa.pessoal;
    });

    _atualizarListaTarefas();

    if (mounted) {
      FocusScope.of(context).unfocus();
    }
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

  // --- TELA ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        centerTitle: true,
        backgroundColor: Colors.blue[100],
      ),
      body: _listaTarefas.isEmpty
          ? const Center(child: Text('Nenhuma tarefa cadastrada.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _listaTarefas.length,
              itemBuilder: (context, index) {
                final item = _listaTarefas[index];

                // Conversão segura de String para Enum
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
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    // AQUI: Ao clicar no item, abre o modo de EDICÃO
                    onTap: () {
                      _mostrarFormulario(context, tarefaParaEditar: item);
                    },
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deletarTarefa(item['idTarefa']),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        // Ao clicar no +, chamamos o formulário SEM tarefa (modo criação)
        onPressed: () => _mostrarFormulario(context, tarefaParaEditar: null),
        child: const Icon(Icons.add),
      ),
    );
  }

  // O parâmetro 'tarefaParaEditar' é opcional (?)
  void _mostrarFormulario(
    BuildContext context, {
    Map<String, dynamic>? tarefaParaEditar,
  }) {
    // LÓGICA DE PREENCHIMENTO AUTOMÁTICO
    if (tarefaParaEditar != null) {
      // Modo Edição: Preenche os campos com os dados existentes
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
      } catch (e) {
        // Se der erro na conversão, mantém o padrão
      }
    } else {
      // Modo Criação: Limpa tudo
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
              // Muda o título dependendo do modo
              title: Text(
                tarefaParaEditar == null ? 'Nova Tarefa' : 'Editar Tarefa',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _tituloController,
                      decoration: const InputDecoration(labelText: 'Título'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _prazoController,
                      decoration: const InputDecoration(
                        labelText: 'Prazo',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Dropdown Prioridade
                    DropdownButtonFormField<Prioridade>(
                      value: _prioridadeSelecionada,
                      decoration: const InputDecoration(
                        labelText: 'Prioridade',
                      ),
                      items: Prioridade.values.map((Prioridade p) {
                        return DropdownMenuItem(value: p, child: Text(p.label));
                      }).toList(),
                      onChanged: (Prioridade? novo) {
                        setDialogState(() => _prioridadeSelecionada = novo!);
                      },
                    ),

                    const SizedBox(height: 10),

                    // Dropdown Tipo
                    DropdownButtonFormField<TipoTarefa>(
                      value: _tipoSelecionado,
                      decoration: const InputDecoration(labelText: 'Tipo'),
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
                    // Limpa controllers ao cancelar para não ficar lixo na próxima vez
                    _tituloController.clear();
                    _descricaoController.clear();
                    _prazoController.clear();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Chama a função passando o ID se for edição, ou null se for criação
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
