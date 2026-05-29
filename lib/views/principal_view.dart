import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../services/database_service.dart';

class PrincipalView extends StatefulWidget {
  const PrincipalView({super.key});

  @override
  State<PrincipalView> createState() => _PrncVwSt();
}

class _PrncVwSt extends State<PrincipalView> {
  bool _vsl = false;
  int _aba = 0;
  double _sld = 1500.50;

  void _addDep() {
    showDialog(
      context: context,
      builder: (dCtx) {
        final ctlDep = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xff1f1f23),
          title: const Text('Depositar', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: ctlDep,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Valor do Depósito',
              labelStyle: TextStyle(color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final vlr = double.tryParse(ctlDep.text);
                if (vlr != null && vlr > 0) {
                  setState(() {
                    _sld += vlr;
                  });
                  await DbSrv.inst.addTnf(vlr, 'Depósito Recebido');
                  setState(() {});
                }
                if (mounted) Navigator.pop(dCtx);
              },
              child: const Text('Confirmar', style: TextStyle(color: Colors.purple)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final nom = ModalRoute.of(ctx)!.settings.arguments as String? ?? 'Luan';

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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xffa259ff).withValues(alpha: 0.15),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'PAYNEX',
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.notifications_none, color: Colors.white, size: 26),
                                const SizedBox(width: 12),
                                const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 26),
                                const SizedBox(width: 12),
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xffa259ff),
                                  child: Text(nom[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Saldo Disponível', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                  IconButton(
                                    icon: Icon(_vsl ? Icons.visibility : Icons.visibility_off, color: const Color(0xffa259ff)),
                                    onPressed: () => setState(() => _vsl = !_vsl),
                                  ),
                                ],
                              ),
                              Text(
                                _vsl ? 'R\$ ${_sld.toStringAsFixed(2)}' : 'R\$ •••••',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Color(0xffa259ff), blurRadius: 20)],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
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
                        const SizedBox(height: 32),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _btnAco(Icons.pix, 'Pix', () {}),
                              _btnAco(Icons.qr_code_scanner, 'Pagar', () {}),
                              _btnAco(Icons.file_download_outlined, 'Depósito', _addDep),
                              _btnAco(Icons.trending_up, 'Cotação', () => Navigator.pushNamed(ctx, AppRoutes.COTACAO)),
                              _btnAco(Icons.swap_horiz, 'Transf.', () => Navigator.pushNamed(ctx, AppRoutes.TRANSFERENCIA)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text('Histórico de Transações', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: DbSrv.inst.obTnf(),
                          builder: (context, snp) {
                            if (snp.hasData && snp.data!.isNotEmpty) {
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: snp.data!.length,
                                itemBuilder: (lCtx, idx) {
                                  final t = snp.data![idx];
                                  final double v = t['val'] ?? 0.0;
                                  final String r = t['rec'] ?? '';
                                  final bool isDep = r.contains('Depósito');
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.02),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              isDep ? Icons.arrow_downward : Icons.arrow_upward,
                                              color: isDep ? Colors.green : Colors.red,
                                            ),
                                            const SizedBox(width: 16),
                                            Text(r, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                        Text(
                                          '${isDep ? '+' : '-'} R\$ ${v.toStringAsFixed(2)}',
                                          style: TextStyle(color: isDep ? Colors.green : Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'Nenhuma transação realizada',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
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
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
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
                border: Border.all(color: const Color(0xffa259ff).withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(color: const Color(0xffa259ff).withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 1),
                ],
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