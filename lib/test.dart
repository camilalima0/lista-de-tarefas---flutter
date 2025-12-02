import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, '_202310268.db');

    // Mudei a versão para 2 para forçar o recarregamento se necessário,
    // mas recomendo desinstalar o app do emulador antes de rodar.
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tarefa (
        idTarefa INTEGER PRIMARY KEY AUTOINCREMENT,
        tituloTarefa TEXT NOT NULL,
        descricaoTarefa TEXT NOT NULL,
        prioridadeTarefa TEXT NOT NULL,
        dataCriacaoTarefa TEXT NOT NULL,
        tipoTarefa TEXT NOT NULL,
        prazoTarefa TEXT NOT NULL
      )
    '''); // <--- A VÍRGULA FOI REMOVIDA AQUI EM CIMA
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('tarefa', row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await database;
    return await db.query('tarefa');
  }

  Future<int> update(Map<String, dynamic> row) async {
    Database db = await database;
    int id = row['idTarefa']; // <--- CORRIGIDO: Era 'id', agora é 'idTarefa'
    return await db.update(
      'tarefa',
      row,
      where: 'idTarefa = ?',
      whereArgs: [id],
    ); // <--- CORRIGIDO
  }

  Future<int> delete(int id) async {
    Database db = await database;
    return await db.delete(
      'tarefa',
      where: 'idTarefa = ?',
      whereArgs: [id],
    ); // <--- CORRIGIDO
  }
}
