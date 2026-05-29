import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/database_service.dart';

class CadastroView extends StatefulWidget {
  const CadastroView({super.key});

  @override
  State<CadastroView> createState() => _CadastroViewState();
}

class _CadastroViewState extends State<CadastroView> {
  final _chkFm = GlobalKey<FormState>();
  final _ctlNom = TextEditingController();
  final _ctlUsr = TextEditingController();
  final _ctlSen = TextEditingController();
  final _ctlCpf = TextEditingController();
  final _ctlTel = TextEditingController();
  final _ctlNsc = TextEditingController();
  final _ctlCep = TextEditingController();
  final _ctlEnd = TextEditingController();
  final _ctlNum = TextEditingController();
  bool _ocuSen = true;
  bool _clg = false;

  @override
  void dispose() {
    _ctlNom.dispose();
    _ctlUsr.dispose();
    _ctlSen.dispose();
    _ctlCpf.dispose();
    _ctlTel.dispose();
    _ctlNsc.dispose();
    _ctlCep.dispose();
    _ctlEnd.dispose();
    _ctlNum.dispose();
    super.dispose();
  }

  Future<void> _puxarCep(String cep) async {
    final vlp = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (vlp.length != 8) return;

    setState(() => _clg = true);
    final url = Uri.parse('https://viacep.com.br/ws/$vlp/json/');

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['erro'] == null) {
          setState(() {
            _ctlEnd.text = '${data['logradouro']} - ${data['bairro']}, ${data['localidade']}/${data['uf']}';
          });
        }
      }
    } catch (_) {}
    setState(() => _clg = false);
  }

  void _cadastrar() async {
    if (_chkFm.currentState!.validate()) {
      final vldUsr = await DbSrv.inst.obUsr(_ctlUsr.text);
      if (vldUsr != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nome de usuário já existe')),
          );
        }
        return;
      }

      final rnd = Random();
      final agc = '0001';
      final cta = '${rnd.nextInt(900000) + 100000}-${rnd.nextInt(9)}';

      final Map<String, String> mapUsr = {
        'nom': _ctlNom.text,
        'usr': _ctlUsr.text,
        'sen': _ctlSen.text,
        'agc': agc,
        'cta': cta,
        'cpf': _ctlCpf.text,
        'tel': _ctlTel.text,
        'nsc': _ctlNsc.text,
        'cep': _ctlCep.text,
        'end': _ctlEnd.text,
        'num': _ctlNum.text,
      };

      await DbSrv.inst.regUsr(mapUsr);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conta criada! Ag: $agc Cta: $cta')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: const Color(0xff121214),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _chkFm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Cadastro Completo', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 32),
              TextFormField(
                controller: _ctlNom,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Nome Completo', labelStyle: TextStyle(color: Colors.grey)),
                validator: (val) => val == null || val.isEmpty ? 'Insira seu nome completo' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ctlUsr,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Nome de Usuário (Login Único)', labelStyle: TextStyle(color: Colors.grey)),
                validator: (val) => val == null || val.isEmpty ? 'Insira seu usuário' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ctlSen,
                obscureText: _ocuSen,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Senha (8 dígitos)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  suffixIcon: IconButton(icon: Icon(_ocuSen ? Icons.visibility_off : Icons.visibility, color: Colors.purple), onPressed: () => setState(() => _ocuSen = !_ocuSen)),
                ),
                validator: (val) => val == null || val.length != 8 ? 'Requer 8 dígitos' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ctlCpf,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                inputFormatters: [FmtCpf()],
                decoration: const InputDecoration(labelText: 'CPF', labelStyle: TextStyle(color: Colors.grey), hintText: '000.000.000-00', hintStyle: TextStyle(color: Colors.white24)),
                validator: (val) => val == null || val.length != 14 ? 'Insira um CPF válido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ctlTel,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                inputFormatters: [FmtTel()],
                decoration: const InputDecoration(labelText: 'Celular', labelStyle: TextStyle(color: Colors.grey), hintText: '(91)90000-0000', hintStyle: TextStyle(color: Colors.white24)),
                validator: (val) => val == null || val.length != 14 ? 'Insira um celular válido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ctlNsc,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                inputFormatters: [FmtNsc()],
                decoration: const InputDecoration(labelText: 'Data de Nascimento', labelStyle: TextStyle(color: Colors.grey), hintText: '00/00/0000', hintStyle: TextStyle(color: Colors.white24)),
                validator: (val) => val == null || val.length != 10 ? 'Insira uma data válida' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ctlCep,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'CEP',
                  labelStyle: const TextStyle(color: Colors.grey),
                  suffixIcon: _clg ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                ),
                onChanged: (val) {
                  if (val.length == 8) _puxarCep(val);
                },
                validator: (val) => val == null || val.isEmpty ? 'Insira o CEP' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ctlEnd,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Endereço', labelStyle: TextStyle(color: Colors.grey)),
                validator: (val) => val == null || val.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ctlNum,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Número da Casa', labelStyle: TextStyle(color: Colors.grey)),
                validator: (val) => val == null || val.isEmpty ? 'Insira o número' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _cadastrar,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Cadastrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FmtCpf extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue ant, TextEditingValue nov) {
    final txt = nov.text.replaceAll(RegExp(r'[^0-9]'), '');
    var res = '';
    if (txt.isNotEmpty) res += txt.substring(0, min(txt.length, 3));
    if (txt.length > 3) res += '.${txt.substring(3, min(txt.length, 6))}';
    if (txt.length > 6) res += '.${txt.substring(6, min(txt.length, 9))}';
    if (txt.length > 9) res += '-${txt.substring(9, min(txt.length, 11))}';
    return TextEditingValue(text: res, selection: TextSelection.collapsed(offset: res.length));
  }
}

class FmtTel extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue ant, TextEditingValue nov) {
    final txt = nov.text.replaceAll(RegExp(r'[^0-9]'), '');
    var res = '';
    if (txt.isNotEmpty) res += '(${txt.substring(0, min(txt.length, 2))}';
    if (txt.length > 2) res += ')${txt.substring(2, min(txt.length, 7))}';
    if (txt.length > 7) res += '-${txt.substring(7, min(txt.length, 11))}';
    return TextEditingValue(text: res, selection: TextSelection.collapsed(offset: res.length));
  }
}

class FmtNsc extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue ant, TextEditingValue nov) {
    final txt = nov.text.replaceAll(RegExp(r'[^0-9]'), '');
    var res = '';
    if (txt.isNotEmpty) res += txt.substring(0, min(txt.length, 2));
    if (txt.length > 2) res += '/${txt.substring(2, min(txt.length, 4))}';
    if (txt.length > 4) res += '/${txt.substring(4, min(txt.length, 8))}';
    return TextEditingValue(text: res, selection: TextSelection.collapsed(offset: res.length));
  }
}