import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../routes/app_routes.dart';
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

class PrincipalView extends StatefulWidget {
  const PrincipalView({super.key});

  @override
  State<PrincipalView> createState() => _PrncVwSt();
}

class _PrncVwSt extends State<PrincipalView> {
  bool _vsl = false;
  bool _vslDds = false;
  int _aba = 0;
  final double _sldBse = 0.00;
  File? _arqFt;
  final _pck = ImagePicker();
  bool _iniFoto = false;

  void _puxarFotoBd(String usr) async {
    final u = await DbSrv.inst.obUsr(usr);
    if (u != null && u['ft'] != null && u['ft'].toString().isNotEmpty) {
      setState(() {
        _arqFt = File(u['ft'].toString());
      });
    }
  }

  String _fmtMny(double v) {
    String s = v.toStringAsFixed(2);
    List<String> p = s.split('.');
    String i = p[0];
    String d = p[1];
    i = i.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
    return '$i,$d';
  }

  String _fmtDat(String txtDat) {
    try {
      DateTime dt = DateTime.parse(txtDat);
      String dia = dt.day.toString().padLeft(2, '0');
      String mes = dt.month.toString().padLeft(2, '0');
      String hora = dt.hour.toString().padLeft(2, '0');
      String min = dt.minute.toString().padLeft(2, '0');
      return "$dia/$mes/${dt.year} - $hora:$min";
    } catch (_) {
      return "Data indisponível";
    }
  }

  void _mostrarDetalheTransacao(Map<String, dynamic> t) {
    final double v = t['val'] ?? 0.0;
    final String r = t['rec'] ?? '';
    final String d = t['dat'] ?? '';
    final bool eDep = r.contains('Depósito');
    final bool eBol = r.contains('Equatorial');

    String titulo = 'Transferência Enviada';
    IconData icone = Icons.arrow_downward;
    Color corIcone = Colors.redAccent;

    if (eDep) {
      titulo = r.contains('recebido') ? 'Pix Recebido' : 'Depósito Concluído';
      icone = Icons.arrow_upward;
      corIcone = Colors.green;
    } else if (eBol) {
      titulo = 'Pagamento de Conta';
      icone = Icons.receipt_long;
      corIcone = Colors.grey;
    }

    String descLimpa = r.replaceAll('Depósito: ', '');
    if (descLimpa.startsWith('Pagamento Equatorial: ')) {
      descLimpa = descLimpa.replaceAll('Pagamento Equatorial: ', '');
    } else if (descLimpa == 'Pagamento Equatorial') {
      descLimpa = 'Pagamento de Boleto';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff1f1f23),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bCtx) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(bCtx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: corIcone.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(icone, color: corIcone, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 32),
              const Text('Valor', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                '${eDep ? '+' : '-'} R\$ ${_fmtMny(v)}', 
                style: TextStyle(color: eDep ? Colors.green : (eBol ? Colors.grey : Colors.white), fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text('Data e Hora', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              Text(_fmtDat(d), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              const Text('Descrição', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              Text(descLimpa, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff1a1a1e), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () => Navigator.pop(bCtx),
                  child: const Text('Fechar Detalhes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _abrirExtratoCompleto(List<Map<String, dynamic>> tnfs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff0a0a0c),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bCtx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Extrato Completo', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(bCtx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: tnfs.isNotEmpty
                    ? ListView.builder(
                        itemCount: tnfs.length,
                        itemBuilder: (lCtx, idx) {
                          final t = tnfs[idx];
                          final double v = t['val'] ?? 0.0;
                          final String r = t['rec'] ?? '';
                          final bool eDep = r.contains('Depósito');
                          final bool eBol = r.contains('Equatorial');

                          IconData itemIcone = Icons.arrow_downward;
                          Color itemCor = Colors.red;
                          if (eDep) {
                            itemIcone = Icons.arrow_upward;
                            itemCor = Colors.green;
                          } else if (eBol) {
                            itemIcone = Icons.receipt_long;
                            itemCor = Colors.grey;
                          }

                          String descLimpa = r.replaceAll('Depósito: ', '');
                          if (descLimpa.startsWith('Pagamento Equatorial: ')) {
                            descLimpa = descLimpa.replaceAll('Pagamento Equatorial: ', '');
                          } else if (descLimpa == 'Pagamento Equatorial') {
                            descLimpa = 'Pagamento de Boleto';
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(bCtx);
                              _mostrarDetalheTransacao(t);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.02), 
                                borderRadius: BorderRadius.circular(16), 
                                border: Border.all(color: Colors.white.withOpacity(0.05))
                              ),
                              child: Row(
                                children: [
                                  Icon(itemIcone, color: itemCor),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      descLimpa, 
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text('${eDep ? '+' : '-'} R\$ ${_fmtMny(v)}', style: TextStyle(color: itemCor, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(child: Text('Nenhuma transação encontrada', style: TextStyle(color: Colors.grey))),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mudarFoto(String usr) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff1f1f23),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Color(0xffa259ff)),
            title: const Text('Tirar Nova Foto', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(ctx);
              final f = await _pck.pickImage(source: ImageSource.camera);
              if (f != null) {
                final b = await DbSrv.inst.bd;
                await b.update('usr', {'ft': f.path}, where: 'usr = ?', whereArgs: [usr]);
                setState(() => _arqFt = File(f.path));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Color(0xffa259ff)),
            title: const Text('Escolher da Galeria', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(ctx);
              final f = await _pck.pickImage(source: ImageSource.gallery);
              if (f != null) {
                final b = await DbSrv.inst.bd;
                await b.update('usr', {'ft': f.path}, where: 'usr = ?', whereArgs: [usr]);
                setState(() => _arqFt = File(f.path));
              }
            },
          ),
          if (_arqFt != null)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Remover Foto Atual', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(ctx);
                final b = await DbSrv.inst.bd;
                await b.update('usr', {'ft': ''}, where: 'usr = ?', whereArgs: [usr]);
                setState(() => _arqFt = null);
              },
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _vfcSen(String usr, VoidCallback cnf) {
    final ctl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff1f1f23),
        title: const Text('Confirmar Senha', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctl,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Senha de Acesso', labelStyle: TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              final d = await DbSrv.inst.obUsr(usr);
              if (d != null && d['sen'] == ctl.text) {
                Navigator.pop(ctx);
                cnf();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha incorrecta!')));
              }
            },
            child: const Text('Confirmar', style: TextStyle(color: Color(0xffa259ff))),
          )
        ],
      ),
    );
  }

  void _atldDdo(String usr, String col, String vlrAtu) async {
    if (col == 'end') {
      final u = await DbSrv.inst.obUsr(usr) ?? {};
      final ctlCep = TextEditingController(text: u['cep'] ?? '');
      final ctlRua = TextEditingController(text: u['rua'] ?? '');
      final ctlBai = TextEditingController(text: u['bai'] ?? '');
      final ctlCid = TextEditingController(text: u['cid'] ?? '');
      final ctlEst = TextEditingController(text: u['est'] ?? '');
      final ctlNum = TextEditingController(text: u['num'] ?? '');
      bool carregando = false;

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (context, setSt) => AlertDialog(
              backgroundColor: const Color(0xff1f1f23),
              title: const Text('Alterar Endereço', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: ctlCep,
                      keyboardType: TextInputType.number,
                      inputFormatters: [MascaraFormatter('#####-###')],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'CEP',
                        labelStyle: const TextStyle(color: Colors.grey),
                        suffixIcon: carregando
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xffa259ff)),
                              )
                            : null,
                      ),
                      onChanged: (v) async {
                        String clp = v.replaceAll(RegExp(r'\D'), '');
                        if (clp.length == 8) {
                          setSt(() => carregando = true);
                          try {
                            final cli = HttpClient();
                            final req = await cli.getUrl(Uri.parse('https://viacep.com.br/ws/$clp/json/'));
                            final res = await req.close();
                            if (res.statusCode == 200) {
                              final corps = await res.transform(utf8.decoder).join();
                              final dds = jsonDecode(corps);
                              if (dds['erro'] != true) {
                                ctlRua.text = dds['logradouro'] ?? '';
                                ctlBai.text = dds['bairro'] ?? '';
                                ctlCid.text = dds['localidade'] ?? '';
                                ctlEst.text = dds['uf'] ?? '';
                              }
                            }
                          } catch (_) {}
                          setSt(() => carregando = false);
                        }
                      },
                    ),
                    TextField(
                      controller: ctlRua,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Rua', labelStyle: TextStyle(color: Colors.grey)),
                    ),
                    TextField(
                      controller: ctlBai,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Bairro', labelStyle: TextStyle(color: Colors.grey)),
                    ),
                    TextField(
                      controller: ctlCid,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Cidade', labelStyle: TextStyle(color: Colors.grey)),
                    ),
                    TextField(
                      controller: ctlEst,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Estado', labelStyle: TextStyle(color: Colors.grey)),
                    ),
                    TextField(
                      controller: ctlNum,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Número da Casa', labelStyle: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                TextButton(
                  onPressed: () async {
                    final b = await DbSrv.inst.bd;
                    await b.update('usr', {
                      'cep': ctlCep.text,
                      'rua': ctlRua.text,
                      'bai': ctlBai.text,
                      'cid': ctlCid.text,
                      'est': ctlEst.text,
                      'num': ctlNum.text,
                    }, where: 'usr = ?', whereArgs: [usr]);
                    if (mounted) Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: const Text('Salvar', style: TextStyle(color: Color(0xffa259ff), fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        );
      }
    } else {
      final ctl = TextEditingController(text: vlrAtu);
      String tit = 'Celular';
      if (col == 'eml') tit = 'E-mail';

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xff1f1f23),
          title: Text('Alterar $tit', style: const TextStyle(color: Colors.white)),
          content: TextField(
            controller: ctl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Novo valor', labelStyle: TextStyle(color: Colors.grey)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            TextButton(
              onPressed: () async {
                final b = await DbSrv.inst.bd;
                await b.update('usr', {col: ctl.text}, where: 'usr = ?', whereArgs: [usr]);
                if (mounted) Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('Salvar', style: TextStyle(color: Color(0xffa259ff))),
            )
          ],
        ),
      );
    }
  }

  void _addDep(String usr) {
    final ctlDep = TextEditingController();
    showDialog(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xff1f1f23),
          title: const Text('Depositar', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: ctlDep,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Valor do Depósito', labelStyle: TextStyle(color: Colors.grey)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            TextButton(
              onPressed: () async {
                final vlr = double.tryParse(ctlDep.text);
                if (vlr != null && vlr > 0) {
                  await DbSrv.inst.addTnf(vlr, 'Depósito Recebido', usr);
                  if (mounted) Navigator.pop(dCtx);
                }
              },
              child: const Text('Confirmar', style: TextStyle(color: Color(0xffa259ff), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ).then((_) => setState(() {}));
  }

  void _abrirPagar(String usr, double sldAtu) {
    final _ctlBlt = TextEditingController();
    final _ctlPin = TextEditingController();
    int fseBlt = 0;
    double vlrBlt = 120.50;
    String nomeConvenio = 'Equatorial Energia';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff1f1f23),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bCtx) {
        return StatefulBuilder(builder: (sCtx, setSt) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(bCtx).viewInsets.bottom + 24, top: 24, left: 24, right: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (fseBlt == 0) ...[
                  const Text('Pagamento de Boleto', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ctlBlt,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Código de barras do boleto', labelStyle: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffa259ff)),
                    onPressed: () {
                      String codigo = _ctlBlt.text.replaceAll(RegExp(r'\D'), '').trim();
                      if (codigo.isNotEmpty) {
                        String convenio = 'Boleto Bancário';
                        if (codigo.startsWith('8')) {
                          convenio = 'Equatorial Energia';
                        } else if (codigo.startsWith('3') || codigo.startsWith('2')) {
                          convenio = 'Boleto Nubank';
                        } else if (codigo.startsWith('0') || codigo.startsWith('7')) {
                          convenio = 'Boleto Banco do Brasil';
                        } else {
                          convenio = 'Boleto Bradesco S.A.';
                        }

                        double valorCalculado = 120.50; 
                        if (codigo.length >= 10) {
                          String fim = codigo.substring(codigo.length - 10);
                          int? centavos = int.tryParse(fim);
                          if (centavos != null && centavos > 0) {
                            valorCalculado = centavos / 100.0;
                          }
                        }

                        if (sldAtu >= valorCalculado) {
                          setSt(() {
                            vlrBlt = valorCalculado;
                            nomeConvenio = convenio;
                            fseBlt = 1;
                          });
                        } else {
                          Navigator.pop(bCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.redAccent, 
                              content: Text('Saldo insuficiente! Este boleto custa R\$ ${_fmtMny(valorCalculado)}')
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Buscar Boleto', style: TextStyle(color: Colors.white)),
                  )
                ] else if (fseBlt == 1) ...[
                  const Text('Confirmar Pagamento', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Empresa/Convênio:\n$nomeConvenio', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, height: 1.4)),
                        const SizedBox(height: 12),
                        Text('Valor:\nR\$ ${_fmtMny(vlrBlt)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ctlPin,
                    obscureText: true,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 6),
                    decoration: const InputDecoration(labelText: 'Insira seu PIN de 6 dígitos', labelStyle: TextStyle(color: Colors.grey), counterText: ''),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffa259ff)),
                    onPressed: () async {
                      final uDat = await DbSrv.inst.obUsr(usr);
                      if (uDat != null && uDat['pin'] == _ctlPin.text) {
                        await DbSrv.inst.addTnf(vlrBlt, 'Pagamento Equatorial: $nomeConvenio', usr);
                        setSt(() => fseBlt = 2);
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(backgroundColor: Colors.redAccent, content: Text('PIN de segurança incorreto!')),
                        );
                      }
                    },
                    child: const Text('Confirmar e Pagar', style: TextStyle(color: Colors.white)),
                  )
                ] else ...[
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  const Text('Conta Paga com Sucesso!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('R\$ ${_fmtMny(vlrBlt)}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Beneficiário: $nomeConvenio', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff1a1a1e)),
                    onPressed: () => Navigator.pop(bCtx),
                    child: const Text('Fechar', style: TextStyle(color: Colors.white)),
                  )
                ]
              ],
            ),
          );
        });
      },
    ).then((_) => setState(() {}));
  }

  void _abrirChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff1f1f23),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bCtx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(bCtx).viewInsets.bottom + 24, top: 24, left: 24, right: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  CircleAvatar(backgroundColor: Color(0xffa259ff), child: Icon(Icons.support_agent, color: Colors.white)),
                  SizedBox(width: 12),
                  Text('Suporte PAYNEX', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                child: const Text('Olá! Sou o assistente virtual do PAYNEX. Como posso te ajudar hoje com suas transações locais?', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 12),
              _itemChat('1. Como fazer um Pix?', bCtx, 'Vá na tela inicial, clique no botão Pix, insira o tipo de chave do destinatário e digite o valor de transferência desejado.'),
              _itemChat('2. Como funciona o depósito?', bCtx, 'Basta clicar em Depósito na tela inicial, digitar o valor fictício e clicar em Confirmar. O saldo updates na hora.'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _itemChat(String t, BuildContext bCtx, String resp) {
    return TextButton(
      onPressed: () {
        Navigator.pop(bCtx);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xff1f1f23),
            title: const Text('Ajuda PAYNEX', style: TextStyle(color: Colors.white)),
            content: Text(resp, style: const TextStyle(color: Colors.grey)),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido', style: TextStyle(color: Color(0xffa259ff))))],
          ),
        );
      },
      child: Align(alignment: Alignment.centerLeft, child: Text(t, style: const TextStyle(color: Color(0xffa259ff)))),
    );
  }

  void _abrirSino(List<Map<String, dynamic>> tnfs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff1f1f23),
        title: const Text('Notificações', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: tnfs.isEmpty
              ? const Text('Nenhum alerta recente encontrado.', style: TextStyle(color: Colors.grey))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: tnfs.length > 3 ? 3 : tnfs.length,
                  itemBuilder: (c, i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text('• ${tnfs[i]['rec']}: R\$ ${_fmtMny(tnfs[i]['val'])} processado.', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar', style: TextStyle(color: Color(0xffa259ff))))],
      ),
    );
  }

  void _abrirAgendamentos(String usr) async {
    final list = await DbSrv.inst.obAgendamentos(usr);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff1f1f23),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bCtx) {
        return StatefulBuilder(
          builder: (sCtx, setSt) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Agendamentos Próximos', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(bCtx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Nenhum agendamento pendente.', style: TextStyle(color: Colors.grey))),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: list.length,
                        itemBuilder: (ctx, idx) {
                          final a = list[idx];
                          final double v = a['val'] ?? 0.0;
                          final String r = a['rec'] ?? '';
                          final String d = a['dat'] ?? '';
                          final int id = a['id'] ?? 0;
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (dCtx) => AlertDialog(
                                  backgroundColor: const Color(0xff1f1f23),
                                  title: const Text('Deseja cancelar esse agendamento?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  content: const Text('Após a confirmação seu agendamento será cancelado.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Voltar', style: TextStyle(color: Colors.grey))),
                                    TextButton(
                                      onPressed: () async {
                                        await DbSrv.inst.cancelarAgendamento(id);
                                        Navigator.pop(dCtx);
                                        Navigator.pop(bCtx);
                                        setState(() {});
                                      },
                                      child: const Text('Sim', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.grey),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                        Text(_fmtDat(d).split(' - ')[0], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Text('R\$ ${_fmtMny(v)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  double _clcSld(List<Map<String, dynamic>> tnfs) {
    double s = _sldBse;
    for (var t in tnfs) {
      double v = t['val'] ?? 0.0;
      String r = t['rec'] ?? '';
      if (r.contains('Depósito')) {
        s += v;
      } else {
        s -= v;
      }
    }
    return s;
  }

  @override
  Widget build(BuildContext ctx) {
    final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>?;
    final nom = args?['nom'] ?? 'Daniel';
    final usrLog = args?['usr'] ?? '';

    if (!_iniFoto && usrLog.isNotEmpty) {
      _puxarFotoBd(usrLog);
      _iniFoto = true;
    }

    return Scaffold(
      backgroundColor: const Color(0xff0a0a0c),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xffa259ff).withOpacity(0.15)),
            ),
          ),
          SafeArea(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: DbSrv.inst.obTnf(usrLog),
              builder: (context, snp) {
                final list = snp.data ?? [];
                final sldAtu = _clcSld(list);

                if (_aba == 1) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() => _aba = 0);
                    Navigator.pushNamed(ctx, AppRoutes.TRANSFERENCIA, arguments: args).then((_) => setState(() {}));
                  });
                }

                return IndexedStack(
                  index: _aba == 2 ? 1 : 0,
                  children: [
                    _bldHme(nom, usrLog, sldAtu, list, ctx),
                    _bldPfl(usrLog),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xff0a0a0c),
        currentIndex: _aba,
        onTap: (v) => setState(() => _aba = v),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xffa259ff),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
        ],
      ),
    );
  }

  Widget _bldHme(String nom, String usr, double sld, List<Map<String, dynamic>> tnfs, BuildContext ctx) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PAYNEX', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white, size: 26), onPressed: () => _abrirSino(tnfs)),
                  IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 26), onPressed: _abrirChat),
                  GestureDetector(
                    onTap: () => setState(() => _aba = 2),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xffa259ff),
                      backgroundImage: _arqFt != null ? FileImage(_arqFt!) : null,
                      child: _arqFt == null ? Text(nom[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Olá, $nom', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Saldo Disponível', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    IconButton(icon: Icon(_vsl ? Icons.visibility : Icons.visibility_off, color: const Color(0xffa259ff)), onPressed: () => setState(() => _vsl = !_vsl)),
                  ],
                ),
                Text(_vsl ? 'R\$ ${_fmtMny(sld)}' : 'R\$ •••••', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, shadows: [Shadow(color: Color(0xffa259ff), blurRadius: 20)])),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _abrirAgendamentos(usr),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.1))),
              child: const Row(
                children: [
                  Icon(Icons.event_note, color: Color(0xffa259ff)),
                  SizedBox(width: 16),
                  Text('Agendamentos próximos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _btnAco(Icons.pix, 'Pix', () => Navigator.pushNamed(ctx, AppRoutes.TRANSFERENCIA, arguments: {'nom': nom, 'usr': usr}).then((_) => setState(() {}))),
                _btnAco(Icons.qr_code_scanner, 'Pagar', () => _abrirPagar(usr, sld)),
                _btnAco(Icons.file_download_outlined, 'Depósito', () => _addDep(usr)),
                _btnAco(Icons.trending_up, 'Cotação', () => Navigator.pushNamed(ctx, AppRoutes.COTACAO)),
                _btnAco(Icons.swap_horiz, 'Transf.', () => Navigator.pushNamed(ctx, AppRoutes.TRANSFERENCIA, arguments: {'nom': nom, 'usr': usr}).then((_) => setState(() {}))),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Histórico de Transações', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => _abrirExtratoCompleto(tnfs),
                child: const Text('Ver tudo', style: TextStyle(color: Color(0xffa259ff), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (tnfs.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tnfs.length > 4 ? 4 : tnfs.length,
              itemBuilder: (lCtx, idx) {
                final t = tnfs[idx];
                final double v = t['val'] ?? 0.0;
                final String r = t['rec'] ?? '';
                final bool eDep = r.contains('Depósito');
                final bool eBol = r.contains('Equatorial');

                IconData itemIcone = Icons.arrow_downward;
                Color itemCor = Colors.red;
                if (eDep) {
                  itemIcone = Icons.arrow_upward;
                  itemCor = Colors.green;
                } else if (eBol) {
                  itemIcone = Icons.receipt_long;
                  itemCor = Colors.grey;
                }

                String descLimpa = r.replaceAll('Depósito: ', '');
                if (descLimpa.startsWith('Pagamento Equatorial: ')) {
                  descLimpa = descLimpa.replaceAll('Pagamento Equatorial: ', '');
                } else if (descLimpa == 'Pagamento Equatorial') {
                  descLimpa = 'Pagamento de Boleto';
                }

                return GestureDetector(
                  onTap: () => _mostrarDetalheTransacao(t),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
                    child: Row(
                      children: [
                        Icon(itemIcone, color: itemCor),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            descLimpa, 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text('${eDep ? '+' : '-'} R\$ ${_fmtMny(v)}', style: TextStyle(color: itemCor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(16)),
              child: const Text('Nenhuma transação realizada', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _bldPfl(String usr) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: DbSrv.inst.obUsr(usr),
      builder: (context, snp) {
        if (!snp.hasData || snp.data == null) {
          return const Center(child: CircularProgressIndicator(color: Color(0xffa259ff)));
        }
        final u = snp.data!;
        
        String endExib = 'Não cadastrado';
        if ((u['rua'] != null && u['rua'].toString().isNotEmpty) || (u['end'] != null && u['end'].toString().isNotEmpty)) {
          endExib = '${u['rua'] ?? u['end'] ?? ''}, Nº ${u['num'] ?? ''}';
          if (u['bai'] != null && u['bai'].toString().isNotEmpty) endExib += ' - ${u['bai']}';
          if (u['cid'] != null && u['cid'].toString().isNotEmpty) endExib += ', ${u['cid']}';
          if (u['est'] != null && u['est'].toString().isNotEmpty) endExib += '/${u['est']}';
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _mudarFoto(usr),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xff1a1a1e),
                          backgroundImage: _arqFt != null ? FileImage(_arqFt!) : null,
                          child: _arqFt == null ? const Icon(Icons.person, color: Color(0xffa259ff), size: 36) : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Color(0xffa259ff), shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u['nom'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text('Conta Digital Ativa', style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 32),
              const Text('Dados da Conta', style: TextStyle(color: Color(0xffa259ff), fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _itmPflDts('Instituição', 'PAYNEX S.A. (552)', null),
              _itmPflDts('Agência', u['agc'] ?? '0001', null),
              _itmPflDts('Conta Corrente', u['cta'] ?? '', null),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dados Pessoais', style: TextStyle(color: Color(0xffa259ff), fontSize: 15, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(_vslDds ? Icons.visibility : Icons.visibility_off, color: const Color(0xffa259ff), size: 22),
                    onPressed: () {
                      if (_vslDds) {
                        setState(() => _vslDds = false);
                      } else {
                        _vfcSen(usr, () => setState(() => _vslDds = true));
                      }
                    },
                  )
                ],
              ),
              const SizedBox(height: 12),
              _itmPflDts('Nome de Usuário', u['usr'] ?? '', null),
              _itmPflDts('CPF', _vslDds ? (u['cpf'] ?? '') : '***.***.***-**', null),
              _itmPflDts(
                'E-mail', 
                _vslDds ? (u['eml'] ?? '') : '******@******.***', 
                _vslDds ? () => _atldDdo(usr, 'eml', u['eml'] ?? '') : null
              ),
              _itmPflDts(
                'Celular', 
                _vslDds ? (u['tel'] ?? '') : '(**) *****-****', 
                _vslDds ? () => _atldDdo(usr, 'tel', u['tel'] ?? '') : null
              ),
              _itmPflDts(
                'Endereço', 
                _vslDds ? endExib : '*********', 
                _vslDds ? () => _atldDdo(usr, 'end', '') : null
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff1a1a1e), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.redAccent))),
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.LOGIN),
                  child: const Text('Sair da Conta', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _itmPflDts(String c, String v, VoidCallback? acl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(v, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500))),
              if (acl != null)
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xffa259ff), size: 18),
                  onPressed: acl,
                )
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
        ],
      ),
    );
  }

  Widget _btnAco(IconData i, String l, VoidCallback cmd) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          GestureDetector(
            onTap: cmd,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xff1a1a1e),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xffa259ff).withOpacity(0.3)),
                boxShadow: [BoxShadow(color: const Color(0xffa259ff).withOpacity(0.2), blurRadius: 15, spreadRadius: 1)],
              ),
              child: Icon(i, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(l, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}