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
    return await openDatabase(pth, version: 14, onCreate: _criarBd, onUpgrade: _atpBd);
  }

  Future _criarBd(Database db, int ver) async {
    await db.execute('''
      CREATE TABLE usr (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT,
        usr TEXT,
        sen TEXT,
        pin TEXT,
        eml TEXT,
        agc TEXT,
        cta TEXT,
        cpf TEXT,
        tel TEXT,
        nsc TEXT,
        cep TEXT,
        rua TEXT,
        bai TEXT,
        cid TEXT,
        est TEXT,
        end TEXT,
        num TEXT,
        ft TEXT,
        lgn_dat TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tnf (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usr TEXT,
        val REAL,
        rec TEXT,
        dat TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE chv (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usr TEXT,
        tip TEXT,
        val TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE agd (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usr TEXT,
        val REAL,
        rec TEXT,
        dat TEXT,
        status TEXT
      )
    ''');
  }

  Future _atpBd(Database db, int ant, int nov) async {
    if (ant < 14) {
      await db.execute('DROP TABLE IF EXISTS usr');
      await db.execute('DROP TABLE IF EXISTS tnf');
      await db.execute('DROP TABLE IF EXISTS chv');
      await db.execute('DROP TABLE IF EXISTS agd');
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
    final res = await db.query('usr', where: 'lgn_dat IS NOT NULL', orderBy: 'lgn_dat DESC', limit: 1);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<int> marcarLogin(String usr) async {
    final db = await inst.bd;
    return await db.update(
      'usr', 
      {'lgn_dat': DateTime.now().toIso8601String()}, 
      where: 'usr = ?', 
      whereArgs: [usr]
    );
  }

  Future<int> addChave(String usr, String tip, String val) async {
    final db = await inst.bd;
    return await db.insert('chv', {'usr': usr, 'tip': tip, 'val': val});
  }

  Future<int> rmvChave(String usr, String val) async {
    final db = await inst.bd;
    return await db.delete('chv', where: 'usr = ? AND val = ?', whereArgs: [usr, val]);
  }

  Future<List<Map<String, dynamic>>> obChaves(String usr) async {
    final db = await inst.bd;
    return await db.query('chv', where: 'usr = ?', whereArgs: [usr]);
  }

  Future<List<Map<String, dynamic>>> obTodasChaves() async {
    final db = await inst.bd;
    return await db.query('chv');
  }

  Future<Map<String, dynamic>?> recSen(String cpf) async {
    final db = await inst.bd;
    final res = await db.query('usr', where: 'cpf = ?', whereArgs: [cpf]);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<int> addTnf(double val, String rec, String usr) async {
    final db = await inst.bd;
    return await db.insert('tnf', {
      'usr': usr,
      'val': val,
      'rec': rec,
      'dat': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> obTnf(String usr) async {
    final db = await inst.bd;
    return await db.query('tnf', where: 'usr = ?', whereArgs: [usr], orderBy: 'dat DESC');
  }

  Future<int> addAgendamento(String usr, double val, String rec, String dat) async {
    final db = await inst.bd;
    return await db.insert('agd', {
      'usr': usr,
      'val': val,
      'rec': rec,
      'dat': dat,
      'status': 'Pendente'
    });
  }

  Future<List<Map<String, dynamic>>> obAgendamentos(String usr) async {
    final db = await inst.bd;
    return await db.query('agd', where: 'usr = ? AND status = ?', whereArgs: [usr, 'Pendente'], orderBy: 'dat ASC');
  }

  Future<int> cancelarAgendamento(int id) async {
    final db = await inst.bd;
    return await db.update('agd', {'status': 'Cancelado'}, where: 'id = ?', whereArgs: [id]);
  }
}