import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../routes/app_routes.dart';
import '../services/database_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LgnVwSt();
}

class _LgnVwSt extends State<LoginView> {
  final _fK = GlobalKey<FormState>();
  final _cUsr = TextEditingController();
  final _cSen = TextEditingController();
  final _cPin = TextEditingController();
  final _cCpf = TextEditingController();
  final _auth = LocalAuthentication();
  bool _oSen = true;
  bool _oPin = true;

  @override
  void dispose() {
    _cUsr.dispose();
    _cSen.dispose();
    _cPin.dispose();
    _cCpf.dispose();
    super.dispose();
  }

  void _logar() async {
    if (_fK.currentState!.validate()) {
      final res = await DbSrv.inst.obUsr(_cUsr.text);
      if (res != null && res['sen'] == _cSen.text) {
        if (mounted) {
          Navigator.pushNamed(context, AppRoutes.PRINCIPAL, arguments: {'nom': res['nom'], 'usr': res['usr']});
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Acesso incorreto')),
          );
        }
      }
    }
  }

  void _lgrBtm(String nom, String usr, String sen) {
    if (_cPin.text == sen) {
      Navigator.pop(context);
      Navigator.pushNamed(context, AppRoutes.PRINCIPAL, arguments: {'nom': nom, 'usr': usr});
    } else {
      _msg('Senha incorreta');
    }
  }

  void _msg(String texto) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff1f1f23),
        title: const Text('Aviso do Sistema', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text(texto, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _bio(String nom, String usr) async {
    try {
      final can = await _auth.canCheckBiometrics;
      final sup = await _auth.isDeviceSupported();
      final bios = await _auth.getAvailableBiometrics();
      
      if (!can && !sup) {
        _msg('O hardware de biometria deste aparelho não está disponível ou não é suportado.');
        return;
      }

      if (bios.isEmpty) {
        _msg('Nenhuma impressão digital encontrada! Vá nas configurações de segurança do seu celular Android e cadastre seu dedo/PIN de bloqueio de tela primeiro.');
        return;
      }

      final aut = await _auth.authenticate(
        localizedReason: 'Acesse sua conta Paynex',
      );
      
      if (aut && mounted) {
        Navigator.pop(context);
        Navigator.pushNamed(context, AppRoutes.PRINCIPAL, arguments: {'nom': nom, 'usr': usr});
      }
    } catch (e) {
      _msg('Erro ao chamar o sensor nativo: $e');
    }
  }

  void _btm(BuildContext ctx, String nom, String usr, String agc, String cta, String sen) {
    _cPin.clear();
    _oPin = true;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: const Color(0xff1f1f23),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bCtx) {
        return StatefulBuilder(
          builder: (sCtx, setSt) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(bCtx).viewInsets.bottom + 24, top: 24, left: 24, right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Olá, $nom', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.fingerprint, color: Colors.purple, size: 32),
                        onPressed: () => _bio(nom, usr),
                      ),
                    ],
                  ),
                  Text('Usuário: $usr • Ag: $agc • Cc: $cta', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _cPin,
                    obscureText: _oPin,
                    maxLength: 8,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Senha de acesso',
                      labelStyle: const TextStyle(color: Colors.grey),
                      counterText: '',
                      suffixIcon: IconButton(
                        icon: Icon(_oPin ? Icons.visibility_off : Icons.visibility, color: Colors.purple),
                        onPressed: () => setSt(() => _oPin = !_oPin),
                      ),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.purple)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _lgrBtm(nom, usr, sen),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _esq(BuildContext ctx) {
    _cCpf.clear();
    showDialog(
      context: ctx,
      builder: (dCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xff1f1f23),
          title: const Text('Recuperar Acesso', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: _cCpf,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Confirme seu CPF', labelStyle: TextStyle(color: Colors.grey)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            TextButton(
              onPressed: () async {
                final dts = await DbSrv.inst.recSen(_cCpf.text);
                Navigator.pop(dCtx);
                if (dts != null) {
                  showDialog(
                    context: ctx,
                    builder: (rCtx) => AlertDialog(
                      backgroundColor: const Color(0xff1f1f23),
                      title: const Text('Dados Encontrados', style: TextStyle(color: Colors.white)),
                      content: Text('Usuário: ${dts['usr']}\nSenha: ${dts['sen']}', style: const TextStyle(color: Colors.white)),
                      actions: [TextButton(onPressed: () => Navigator.pop(rCtx), child: const Text('OK', style: TextStyle(color: Colors.purple)))],
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('CPF não cadastrado')));
                }
              },
              child: const Text('Buscar', style: TextStyle(color: Colors.purple)),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: const Color(0xff121214),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _fK,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.account_balance_wallet_rounded, size: 80, color: Colors.purple),
                const SizedBox(height: 12),
                const Text('PAYNEX', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                const SizedBox(height: 32),
                FutureBuilder<Map<String, dynamic>?>(
                  future: DbSrv.inst.obUltUsr(),
                  builder: (context, snp) {
                    if (snp.hasData && snp.data != null) {
                      final dt = snp.data!;
                      return GestureDetector(
                        onTap: () => _btm(ctx, dt['nom'], dt['usr'], dt['agc'], dt['cta'], dt['sen']),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xff1f1f23), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purple.withOpacity(0.3))),
                          child: Row(
                            children: [
                              const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.person, color: Colors.white)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(dt['nom'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis)),
                                    Text('Ag: ${dt['agc']} • Cta: ${dt['cta']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.touch_app, color: Colors.purple),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                TextFormField(
                  controller: _cUsr,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Usuário', labelStyle: TextStyle(color: Colors.grey)),
                  validator: (val) => val == null || val.isEmpty ? 'Insira seu usuário' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _cSen,
                  obscureText: _oSen,
                  maxLength: 8,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Senha de Acesso',
                    labelStyle: const TextStyle(color: Colors.grey),
                    counterText: '',
                    suffixIcon: IconButton(icon: Icon(_oSen ? Icons.visibility_off : Icons.visibility, color: Colors.purple), onPressed: () => setState(() => _oSen = !_oSen)),
                  ),
                  validator: (val) => val == null || val.isEmpty || val.length > 8 ? 'No máximo 8 caracteres' : null,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () => _esq(ctx), child: const Text('Esqueceu a senha?', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _logar,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Entrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: () => Navigator.pushNamed(ctx, AppRoutes.CADASTRO), child: const Text('Criar uma conta Paynex', style: TextStyle(color: Colors.grey, fontSize: 16))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}