import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/database_service.dart';

class MascaraFormatter extends TextInputFormatter {
  final String mascara;
  MascaraFormatter(this.mascara);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String textoLimpo = newValue.text.replaceAll(RegExp(r'\D'), '');
    String res = '';
    int txtIdx = 0;
    
    for (int i = 0; i < mascara.length && txtIdx < textoLimpo.length; i++) {
      if (mascara[i] == '#') {
        res += textoLimpo[txtIdx];
        txtIdx++;
      } else {
        res += mascara[i];
      }
    }
    return TextEditingValue(
      text: res,
      selection: TextSelection.collapsed(offset: res.length),
    );
  }
}

class TransferenciaView extends StatefulWidget {
  const TransferenciaView({super.key});

  @override
  State<TransferenciaView> createState() => _TnfVwSt();
}

class _TnfVwSt extends State<TransferenciaView> {
  int _fse = 0;
  String _tipChv = 'CPF';
  double _sldAtu = 0.00;
  String _usrLog = '';
  bool _ini = false;
  List<String> _chvsUsr = [];
  Map<String, dynamic>? _dadosUsr;
  DateTime _dataTransferencia = DateTime.now();
  
  final _ctlChv = TextEditingController();
  final _ctlVlr = TextEditingController();
  final _ctlPin = TextEditingController();

  String _nomRec = '';
  String _cpfRec = '';
  String _ctaRec = '';
  String _usrRec = ''; 

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ini) {
      final argumentos = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      _usrLog = argumentos?['usr'] ?? '';
      _puxarSldEChvs();
      _ini = true;
    }
  }

  void _puxarSldEChvs() async {
    final lista = await DbSrv.inst.obTnf(_usrLog);
    double s = 0.00;
    for (var t in lista) {
      double v = t['val'] ?? 0.0;
      String r = t['rec'] ?? '';
      if (r.contains('Depósito')) {
        s += v;
      } else {
        s -= v;
      }
    }
    
    final u = await DbSrv.inst.obUsr(_usrLog);
    List<String> tmp = [];
    if (u != null && u['cpf'] != null) {
      tmp.add('CPF: ${u['cpf']}');
    }

    final chvesSalvas = await DbSrv.inst.obChaves(_usrLog);
    for (var c in chvesSalvas) {
      tmp.add('${c['tip']}: ${c['val']}');
    }

    setState(() {
      _sldAtu = s;
      _dadosUsr = u;
      _chvsUsr = tmp;
    });
  }

  bool _ehHoje(DateTime dt) {
    DateTime agora = DateTime.now();
    return dt.year == agora.year && dt.month == agora.month && dt.day == agora.day;
  }

  String _fmtDatPura(DateTime dt) {
    String dia = dt.day.toString().padLeft(2, '0');
    String mes = dt.month.toString().padLeft(2, '0');
    return "$dia/$mes/${dt.year}";
  }

  String _fmtMny(double v) {
    String s = v.toStringAsFixed(2);
    List<String> p = s.split('.');
    String i = p[0];
    String d = p[1];
    i = i.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
    return '$i,$d';
  }

  void _vldPin() async {
    final usr = await DbSrv.inst.obUsr(_usrLog);
    if (usr != null && usr['pin'] == _ctlPin.text) {
      Navigator.pop(context);
      String txt = _ctlVlr.text.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim();
      final v = double.tryParse(txt) ?? 0.0;
      
      if (_ehHoje(_dataTransferencia)) {
        await DbSrv.inst.addTnf(v, 'Pix enviado para $_nomRec', _usrLog);
        String nomRemetente = _dadosUsr?['nom']?.toString() ?? 'Usuário Paynex';
        await DbSrv.inst.addTnf(v, 'Depósito: Pix recebido de $nomRemetente', _usrRec);
      } else {
        await DbSrv.inst.addAgendamento(_usrLog, v, 'Pix agendado para $_nomRec', _dataTransferencia.toIso8601String());
      }
      
      setState(() => _fse = 4);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text('PIN de segurança incorreto!')),
      );
    }
  }

  void _pedirPin() {
    _ctlPin.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff1f1f23),
        title: const Text('Confirmação de Segurança', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Insira seu PIN de 6 dígitos para autorizar a transação.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: _ctlPin,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white, letterSpacing: 8, fontSize: 20),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(counterText: '', hintText: '******', hintStyle: TextStyle(color: Colors.white24)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: _vldPin, child: const Text('Confirmar', style: TextStyle(color: Color(0xffa259ff), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _addChvComPin(String rotulo, String valor) {
    final ctlPinChv = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff1f1f23),
        title: const Text('Confirmar Senha', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Insira seu PIN de 6 dígitos para autorizar o cadastro da chave.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: ctlPinChv,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white, letterSpacing: 8, fontSize: 20),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(counterText: '', hintText: '******', hintStyle: TextStyle(color: Colors.white24)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              final usr = await DbSrv.inst.obUsr(_usrLog);
              if (usr != null && usr['pin'] == ctlPinChv.text) {
                Navigator.pop(ctx);
                await DbSrv.inst.addChave(_usrLog, rotulo, valor);
                setState(() {
                  _chvsUsr.add('$rotulo: $valor');
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: Colors.green, content: Text('Chave cadastrada com sucesso!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: Colors.redAccent, content: Text('PIN de segurança incorreto!')),
                );
              }
            },
            child: const Text('Confirmar', style: TextStyle(color: Color(0xffa259ff), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _removerChvPin(String chv) {
    final ctlPinRmv = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff1f1f23),
        title: const Text('Remover Chave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Insira seu PIN de 6 dígitos para autorizar a remoção desta chave.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: ctlPinRmv,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white, letterSpacing: 8, fontSize: 20),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(counterText: '', hintText: '******', hintStyle: TextStyle(color: Colors.white24)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              final usr = await DbSrv.inst.obUsr(_usrLog);
              if (usr != null && usr['pin'] == ctlPinRmv.text) {
                Navigator.pop(ctx);
                String valorLimpo = chv.contains(': ') ? chv.split(': ')[1] : chv;
                await DbSrv.inst.rmvChave(_usrLog, valorLimpo);
                setState(() {
                  _chvsUsr.remove(chv);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: Colors.green, content: Text('Chave removida com sucesso!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: Colors.redAccent, content: Text('PIN de segurança incorreto!')),
                );
              }
            },
            child: const Text('Remover', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: const Color(0xff0a0a0c),
      appBar: AppBar(
        backgroundColor: const Color(0xff0a0a0c),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_fse == 0 || _fse == 4 || _fse == 5) {
              Navigator.pop(ctx);
            } else if (_fse == 6) {
              setState(() => _fse = 0);
            } else {
              setState(() => _fse--);
            }
          },
        ),
        title: Text(_fse == 6 ? 'Minhas Chaves' : 'Área Pix', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(child: _bldFse()),
    );
  }

  Widget _bldFse() {
    switch (_fse) {
      case 0: return _bldPainelInic();
      case 1: return _bldChaveInput();
      case 2: return _bldValorInput();
      case 3: return _bldRevisao();
      case 4: return _bldSucesso();
      case 5: return _bldComprovante();
      case 6: return _bldMinhasChaves();
      default: return _bldPainelInic();
    }
  }

  Widget _bldPainelInic() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Envie e receba pagamentos a qualquer hora.', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 32),
          ListTile(
            tileColor: const Color(0xff1a1a1e),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.swap_horiz, color: Color(0xffa259ff), size: 28),
            title: const Text('Transferir com Pix', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Pagar para uma nova chave', style: TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => setState(() => _fse = 1),
          ),
          const SizedBox(height: 16),
          ListTile(
            tileColor: const Color(0xff1a1a1e),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.vpn_key, color: Color(0xffa259ff), size: 28),
            title: const Text('Minhas Chaves', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Gerenciar e cadastrar suas chaves', style: TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => setState(() => _fse = 6),
          ),
        ],
      ),
    );
  }

  Widget _bldChaveInput() {
    List<TextInputFormatter> formatadores = [];
    TextInputType teclado = TextInputType.text;

    if (_tipChv == 'CPF') {
      formatadores = [MascaraFormatter('###.###.###-##')];
      teclado = TextInputType.number;
    } else if (_tipChv == 'Celular') {
      formatadores = [MascaraFormatter('(##) #####-####')];
      teclado = TextInputType.phone;
    } else if (_tipChv == 'E-mail') {
      teclado = TextInputType.emailAddress;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Para quem você quer transferir?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['CPF', 'Celular', 'E-mail', 'Aleatória'].map((t) {
              final sel = _tipChv == t;
              return GestureDetector(
                onTap: () => setState(() {
                  _tipChv = t;
                  _ctlChv.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xffa259ff) : const Color(0xff1a1a1e),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(t, style: TextStyle(color: sel ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _ctlChv,
            keyboardType: teclado,
            inputFormatters: formatadores,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xff1a1a1e),
              labelText: 'Insira o $_tipChv do destinatário',
              labelStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.search, color: Color(0xffa259ff)),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffa259ff), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () async {
                if (_ctlChv.text.isEmpty) return;

                String txtChv = _ctlChv.text.trim();
                String buscaLimpa = txtChv.replaceAll(RegExp(r'\D'), '');
                String buscaEmail = txtChv.toLowerCase();

                final db = await DbSrv.inst.bd;
                Map<String, dynamic>? dest;

                if (_tipChv == 'CPF') {
                  final usuarios = await db.query('usr');
                  for (var u in usuarios) {
                    String dbCpf = (u['cpf'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
                    if (buscaLimpa.isNotEmpty && dbCpf == buscaLimpa) {
                      dest = u;
                      break;
                    }
                  }
                } else {
                  final chaves = await DbSrv.inst.obTodasChaves();
                  String? usrEncontrado;

                  for (var c in chaves) {
                    String tip = c['tip']?.toString() ?? '';
                    String val = c['val']?.toString() ?? '';

                    if (_tipChv == 'Celular' && tip == 'Celular') {
                      if (val.replaceAll(RegExp(r'\D'), '') == buscaLimpa) {
                        usrEncontrado = c['usr']?.toString();
                        break;
                      }
                    } else if (_tipChv == 'E-mail' && tip == 'E-mail') {
                      if (val.trim().toLowerCase() == buscaEmail) {
                        usrEncontrado = c['usr']?.toString();
                        break;
                      }
                    } else if (_tipChv == 'Aleatória' && tip == 'Aleatória') {
                      if (val.trim() == txtChv) {
                        usrEncontrado = c['usr']?.toString();
                        break;
                      }
                    }
                  }

                  if (usrEncontrado != null) {
                    dest = await DbSrv.inst.obUsr(usrEncontrado);
                  }
                }

                if (dest == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: Colors.redAccent, content: Text('Chave Pix não encontrada!')),
                    );
                  }
                  return;
                }

                if (dest['usr'] == _usrLog) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: Colors.orangeAccent, content: Text('Você não pode enviar um Pix para si mesmo!')),
                    );
                  }
                  return;
                }

                setState(() {
                  _nomRec = dest!['nom']?.toString() ?? '';
                  _cpfRec = dest!['cpf']?.toString() ?? '';
                  _ctaRec = dest!['cta']?.toString() ?? '';
                  _usrRec = dest!['usr']?.toString() ?? ''; 
                  _fse = 2;
                });
              },
              child: const Text('Avançar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bldValorInput() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Qual é o valor da transferência?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Saldo disponível: R\$ ${_fmtMny(_sldAtu)}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          TextField(
            controller: _ctlVlr,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              prefixText: 'R\$ ',
              prefixStyle: TextStyle(color: Colors.white, fontSize: 28),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xffa259ff))),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xffa259ff))),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffa259ff), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () {
                String txt = _ctlVlr.text.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim();
                final v = double.tryParse(txt);
                if (v != null && v > 0 && v <= _sldAtu) {
                  setState(() => _fse = 3);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valor inválido ou saldo insuficiente.')));
                }
              },
              child: const Text('Avançar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bldRevisao() {
    String txt = _ctlVlr.text.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim();
    final v = double.tryParse(txt) ?? 0.0;
    
    String cpfMascarado = _cpfRec;
    if (cpfMascarado.length >= 11) {
      String apenasNum = cpfMascarado.replaceAll(RegExp(r'\D'), '');
      if (apenasNum.length == 11) {
        cpfMascarado = '***.${apenasNum.substring(3, 6)}.${apenasNum.substring(6, 9)}-**';
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revise os detalhes da sua transferência', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Valor a transferir', style: TextStyle(color: Colors.grey)),
              Text('R\$ ${_fmtMny(v)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Colors.white10, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Data de transferência', style: TextStyle(color: Colors.grey)),
              GestureDetector(
                onTap: () async {
                  final escolhida = await showDatePicker(
                    context: context,
                    initialDate: _dataTransferencia,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xffa259ff),
                            onPrimary: Colors.white,
                            surface: Color(0xff1f1f23),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (escolhida != null) {
                    setState(() => _dataTransferencia = escolhida);
                  }
                },
                child: Row(
                  children: [
                    Text(
                      _ehHoje(_dataTransferencia) ? 'Hoje' : _fmtDatPura(_dataTransferencia),
                      style: const TextStyle(color: Color(0xffa259ff), fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.calendar_month, color: Color(0xffa259ff), size: 20),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 32),
          const Text('Para', style: TextStyle(color: Color(0xffa259ff), fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _itmCpr('Nome', _nomRec),
          _itmCpr('CPF', cpfMascarado),
          _itmCpr('Instituição', 'PAYNEX S.A.'),
          _itmCpr('Conta', _ctaRec),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffa259ff), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: _pedirPin,
              child: Text(_ehHoje(_dataTransferencia) ? 'Transferir' : 'Agendar Pix', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bldSucesso() {
    String txt = _ctlVlr.text.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim();
    final v = double.tryParse(txt) ?? 0.0;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: Color(0xff1a1a1e), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          ),
          const SizedBox(height: 24),
          Text(_ehHoje(_dataTransferencia) ? 'Transferência realizada!' : 'Pix agendado com sucesso!', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('R\$ ${_fmtMny(v)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('para $_nomRec', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff1a1a1e), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xffa259ff)))),
              onPressed: () => setState(() => _fse = 5),
              child: const Text('Visualizar comprovante', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Voltar para o início', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _bldComprovante() {
    String txt = _ctlVlr.text.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim();
    final v = double.tryParse(txt) ?? 0.0;

    String cpfDestino = _cpfRec;
    if (cpfDestino.length >= 11) {
      String apenasNum = cpfDestino.replaceAll(RegExp(r'\D'), '');
      if (apenasNum.length == 11) {
        cpfDestino = '***.${apenasNum.substring(3, 6)}.${apenasNum.substring(6, 9)}-**';
      }
    }

    String nomOrigem = _dadosUsr?['nom']?.toString() ?? 'Usuário Paynex';
    String cpfOrigem = _dadosUsr?['cpf']?.toString() ?? '***.***.***-**';
    if (cpfOrigem.length >= 11) {
      String apenasNum = cpfOrigem.replaceAll(RegExp(r'\D'), '');
      if (apenasNum.length == 11) {
        cpfOrigem = '***.${apenasNum.substring(3, 6)}.${apenasNum.substring(6, 9)}-**';
      }
    }
    String ctaOrigem = _dadosUsr?['cta']?.toString() ?? '00000-0';

    final aleatorio = Random();
    const caracteres = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String parteAleatoria = List.generate(15, (idx) => caracteres[aleatorio.nextInt(caracteres.length)]).join();
    String carimboTempo = DateTime.now().toIso8601String().replaceAll(RegExp(r'\D'), '');
    String txId = "E" + (carimboTempo + parteAleatoria).substring(0, 28);

    DateTime agora = DateTime.now();
    String dataFormatada = "";
    if (_ehHoje(_dataTransferencia)) {
      dataFormatada = "${agora.day.toString().padLeft(2, '0')}/${agora.month.toString().padLeft(2, '0')}/${agora.year} - ${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}:${agora.second.toString().padLeft(2, '0')}";
    } else {
      dataFormatada = "${_dataTransferencia.day.toString().padLeft(2, '0')}/${_dataTransferencia.month.toString().padLeft(2, '0')}/${_dataTransferencia.year} (Agendado)";
    }

    String tipoCpr = _ehHoje(_dataTransferencia) ? 'COMPROVANTE DE PIX' : 'COMPROVANTE DE AGENDAMENTO';
    String tituloTela = _ehHoje(_dataTransferencia) ? 'Comprovante de transferência' : 'Comprovante de agendamento';

    String textoComprovante = '''
--- $tipoCpr ---
PAYNEX BANCO DIGITAL
ID: $txId

Valor: R\$ ${_fmtMny(v)}
Data: $dataFormatada

DESTINO:
Nome: $_nomRec
CPF: $cpfDestino
Instituição: PAYNEX S.A.
Conta: $_ctaRec

ORIGEM:
Nome: $nomOrigem
CPF: $cpfOrigem
Instituição: PAYNEX S.A.
Conta: $ctaOrigem
--------------------------
''';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white), 
                onPressed: () => Share.share(textoComprovante),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tituloTela, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$dataFormatada - Pix', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 24),
                const Text('Valor', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text('R\$ ${_fmtMny(v)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('ID da Transação', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text(txId, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace', letterSpacing: 0.5)),
                const Divider(color: Colors.white10, height: 32),
                
                Row(
                  children: [
                    Icon(Icons.arrow_downward, color: const Color(0xffa259ff).withOpacity(0.8), size: 18),
                    const SizedBox(width: 8),
                    const Text('Destino', style: TextStyle(color: Color(0xffa259ff), fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _itmCpr('Nome', _nomRec),
                _itmCpr('CPF', cpfDestino),
                _itmCpr('Instituição', 'PAYNEX S.A.'),
                _itmCpr('Conta', _ctaRec),
                
                const Divider(color: Colors.white10, height: 32),
                
                Row(
                  children: [
                    Icon(Icons.arrow_upward, color: const Color(0xffa259ff).withOpacity(0.8), size: 18),
                    const SizedBox(width: 8),
                    const Text('Origem', style: TextStyle(color: Color(0xffa259ff), fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _itmCpr('Nome', nomOrigem),
                _itmCpr('CPF', cpfOrigem),
                _itmCpr('Instituição', 'PAYNEX S.A.'),
                _itmCpr('Conta', ctaOrigem),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bldMinhasChaves() {
    bool temTel = _chvsUsr.any((el) => el.startsWith('Celular'));
    bool temEml = _chvsUsr.any((el) => el.startsWith('E-mail'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Suas chaves cadastradas', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._chvsUsr.map((chv) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
                decoration: BoxDecoration(color: const Color(0xff1a1a1e), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.key, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(chv, style: const TextStyle(color: Colors.white, fontSize: 14))),
                    if (!chv.startsWith('CPF'))
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => _removerChvPin(chv),
                      ),
                  ],
                ),
              )),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10),
          ),
          const Text('Registrar ou trazer chaves', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (!temTel && _dadosUsr?['tel'] != null)
            _itemOpcaoChave('Celular', _dadosUsr!['tel']),
          if (!temEml && _dadosUsr?['eml'] != null)
            _itemOpcaoChave('E-mail', _dadosUsr!['eml']),
          _itemOpcaoChave('Chave aleatória', 'Criar nova chave única'),
        ],
      ),
    );
  }

  Widget _itemOpcaoChave(String rotulo, String valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xff1a1a1e), borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(
          rotulo == 'Celular' ? Icons.phone : rotulo == 'E-mail' ? Icons.email : Icons.loop,
          color: const Color(0xffa259ff),
        ),
        title: Text(rotulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(valor, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.add, color: Color(0xffa259ff)),
        onTap: () {
          if (rotulo == 'Chave aleatória') {
            final r = Random();
            const c = 'abcdefghijklmnopqrstuvwxyz0123456789';
            String nChv = List.generate(20, (i) => c[r.nextInt(c.length)]).join();
            _addChvComPin('Aleatória', nChv);
          } else {
            _addChvComPin(rotulo, valor);
          }
        },
      ),
    );
  }

  Widget _itmCpr(String c, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(c, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(v, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}