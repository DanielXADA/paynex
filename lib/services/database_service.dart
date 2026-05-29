import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbSrv {
  static final DbSrv inst = DbSrv._init();
  static Database? _bd;

  DbSrv._init();

  Future<Database> get bd async {
    if (_bd != null) return _bd!;
    _bd = await _initBd('paynex.db');
    return _bd!;
  }

  Future<Database> _initBd(String arq) async {
    final cam = await getDatabasesPath();
    final pth = join(cam, arq);
    return await openDatabase(pth, version: 5, onCreate: _criarBd, onUpgrade: _atpBd);
  }

  Future _criarBd(Database db, int ver) async {
    await db.execute('''
      CREATE TABLE usr (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT,
        usr TEXT,
        sen TEXT,
        agc TEXT,
        cta TEXT,
        cpf TEXT,
        tel TEXT,
        nsc TEXT,
        cep TEXT,
        end TEXT,
        num TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tnf (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        val REAL,
        rec TEXT,
        dat TEXT
      )
    ''');
  }

  Future _atpBd(Database db, int ant, int nov) async {
    if (ant < 5) {
      await db.execute('DROP TABLE IF EXISTS usr');
      await db.execute('DROP TABLE IF EXISTS tnf');
      await _criarBd(db, nov);
    }
  }

  Future<int> regUsr(Map<String, String> dados) async {
    final db = await inst.bd;
    return await db.insert('usr', dados);
  }

  Future<Map<String, dynamic>?> obUsr(String usr) async {
    final db = await inst.bd;
    final res = await db.query('usr', where: 'usr = ?', whereArgs: [usr]);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<Map<String, dynamic>?> obUltUsr() async {
    final db = await inst.bd;
    final res = await db.query('usr', orderBy: 'id DESC', limit: 1);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<Map<String, dynamic>?> recSen(String cpf) async {
    final db = await inst.bd;
    final res = await db.query('usr', where: 'cpf = ?', whereArgs: [cpf]);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<int> addTnf(double val, String rec) async {
    final db = await inst.bd;
    return await db.insert('tnf', {
      'val': val,
      'rec': rec,
      'dat': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> obTnf() async {
    final db = await inst.bd;
    return await db.query('tnf', orderBy: 'dat DESC');
  }
}