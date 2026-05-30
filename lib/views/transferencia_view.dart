import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';

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
  
  final _ctlChv = TextEditingController();
  final _ctlVlr = TextEditingController();
  final _ctlPin = TextEditingController();

  final String _nomRec = 'Luan da Silva Medeiros';
  final String _cpfRec = '***.584.218-**';
  final String _ctaRec = '14587-9';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ini) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      _usrLog = args?['usr'] ?? '';
      _puxarSldEChvs();
      _ini = true;
    }
  }

  void _puxarSldEChvs() async {
    final list = await DbSrv.inst.obTnf(_usrLog);
    double s = 0.00;
    for (var t in list) {
      double v = t['val'] ?? 0.0;
      String r = t['rec'] ?? '';
      if (r.contains('Depósito')) s += v; else s -= v;
    }
    
    final u = await DbSrv.inst.obUsr(_usrLog);
    List<String> tmp = [];
    if (u != null) {
      if (u['cpf'] != null) tmp.add('CPF: ${u['cpf']}');
      if (u['tel'] != null) tmp.add('Celular: ${u['tel']}');
    }

    setState(() {
      _sldAtu = s;
      _chvsUsr = tmp;
    });
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
      final v = double.tryParse(_ctlVlr.text) ?? 0.0;
      await DbSrv.inst.addTnf(v, 'Pix enviado para $_nomRec', _usrLog);
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

  void _gerarChvAleatoria() {
    final r = Random();
    const c = 'abcdefghijklmnopqrstuvwxyz0123456789';
    String nChv = List.generate(20, (i) => c[r.nextInt(c.length)]).join();
    setState(() {
      _chvsUsr.add('Aleatória: $nChv');
    });
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
                onTap: () => setState(() => _tipChv = t),
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
              onPressed: () {
                if (_ctlChv.text.isNotEmpty) setState(() => _fse = 2);
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
            keyboardType: TextInputType.number,
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
                final v = double.tryParse(_ctlVlr.text);
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
    final v = double.tryParse(_ctlVlr.text) ?? 0.0;
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
          const Text('Para', style: TextStyle(color: Color(0xffa259ff), fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _itmCpr('Nome', _nomRec),
          _itmCpr('CPF', _cpfRec),
          _itmCpr('Instituição', 'PAYNEX S.A.'),
          _itmCpr('Conta', _ctaRec),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffa259ff), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: _pedirPin,
              child: const Text('Transferir', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bldSucesso() {
    final v = double.tryParse(_ctlVlr.text) ?? 0.0;
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
          const Text('Transferência realizada!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
    final v = double.tryParse(_ctlVlr.text) ?? 0.0;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
              IconButton(icon: const Icon(Icons.share_outlined, color: Colors.white), onPressed: () {}),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Comprovante de transferência', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Hoje mesmo - Pix', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 32),
                const Text('Valor', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 4),
                Text('R\$ ${_fmtMny(v)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const Divider(color: Colors.white10, height: 40),
                const Text('Destino', style: TextStyle(color: Color(0xffa259ff), fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _itmCpr('Nome', _nomRec),
                _itmCpr('CPF', _cpfRec),
                _itmCpr('Instituição', 'PAYNEX S.A.'),
                _itmCpr('Conta', _ctaRec),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bldMinhasChaves() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Suas chaves cadastradas para receber transferências:', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _chvsUsr.length,
              itemBuilder: (ctx, i) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xff1a1a1e), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.key, color: Color(0xffa259ff), size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_chvsUsr[i], style: const TextStyle(color: Colors.white, fontSize: 14))),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffa259ff), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Registrar Chave Aleatória', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: _gerarChvAleatoria,
            ),
          ),
        ],
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