import 'package:flutter/material.dart';
import 'database_helper.dart'; // Importe seu arquivo aqui

void main() async {
  // 1. Garante que o Flutter carregou os plugins nativos antes de usar o banco
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Teste rápido: Inserir uma tarefa
  final dbHelper = DatabaseHelper();

  // Criando um dado fake para testar
  int id = await dbHelper.insert({
    'tituloTarefa': 'Estudar Flutter',
    'descricaoTarefa': 'Verificar conexão com SQLite',
    'prioridadeTarefa': 'Alta',
    'dataCriacaoTarefa': '2023-10-01',
    'tipoTarefa': 'Estudo',
    'prazoTarefa': '2023-10-05',
  });

  print('Tarefa inserida com ID: $id');

  // 3. Teste rápido: Ler o que foi inserido
  List<Map<String, dynamic>> lista = await dbHelper.queryAllRows();
  print('Todas as tarefas: $lista');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Teste DB')),
        body: const Center(
          child: Text('Olhe o console para ver o DB funcionando'),
        ),
      ),
    );
  }
}
