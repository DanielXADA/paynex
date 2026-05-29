import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CotacaoView extends StatefulWidget {
  const CotacaoView({super.key});

  @override
  State<CotacaoView> createState() => _CtcVwSt();
}

class _CtcVwSt extends State<CotacaoView> {
  Map<String, dynamic> _ctc = {};
  bool _clg = true;
  final _cVlrBrl = TextEditingController();
  double _resUsd = 0.0;
  double _resEur = 0.0;
  double _resBtc = 0.0;

  @override
  void initState() {
    super.initState();
    _puxarCtc();
  }

  @override
  void dispose() {
    _cVlrBrl.dispose();
    super.dispose();
  }

  Future<void> _puxarCtc() async {
    setState(() => _clg = true);
    final url = Uri.parse('https://economia.awesomeapi.com.br/last/USD-BRL,EUR-BRL,BTC-BRL');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        setState(() {
          _ctc = jsonDecode(res.body);
        });
        _calc();
      }
    } catch (_) {}
    setState(() => _clg = false);
  }

  void _calc() {
    final v = double.tryParse(_cVlrBrl.text) ?? 0.0;
    if (_ctc['USDBRL'] != null) {
      final f = double.tryParse(_ctc['USDBRL']['bid'] ?? '0') ?? 1.0;
      _resUsd = f > 0 ? v / f : 0.0;
    }
    if (_ctc['EURBRL'] != null) {
      final f = double.tryParse(_ctc['EURBRL']['bid'] ?? '0') ?? 1.0;
      _resEur = f > 0 ? v / f : 0.0;
    }
    if (_ctc['BTCBRL'] != null) {
      final f = double.tryParse(_ctc['BTCBRL']['bid'] ?? '0') ?? 1.0;
      _resBtc = f > 0 ? v / f : 0.0;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: const Color(0xff0a0a0c),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Cotações Paynex', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Color(0xffa259ff)), onPressed: _puxarCtc)
        ],
      ),
      body: _clg
          ? const Center(child: CircularProgressIndicator(color: Color(0xffa259ff)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _itmMoeda('Dólar Comercial', 'USD', _ctc['USDBRL']),
                  const SizedBox(height: 16),
                  _itmMoeda('Euro', 'EUR', _ctc['EURBRL']),
                  const SizedBox(height: 16),
                  _itmMoeda('Bitcoin', 'BTC', _ctc['BTCBRL']),
                  const SizedBox(height: 32),
                  const Text('Simulador de Conversão', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _cVlrBrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Valor em Reais (R\$)',
                            labelStyle: TextStyle(color: Colors.grey),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xffa259ff))),
                          ),
                          onChanged: (_) => _calc(),
                        ),
                        const SizedBox(height: 24),
                        _resLinha('Dólar (USD)', 'US\$ ${_resUsd.toStringAsFixed(2)}'),
                        const Divider(color: Colors.white10, height: 20),
                        _resLinha('Euro (EUR)', '€ ${_resEur.toStringAsFixed(2)}'),
                        const Divider(color: Colors.white10, height: 20),
                        _resLinha('Bitcoin (BTC)', '₿ ${_resBtc.toStringAsFixed(6)}'),
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _resLinha(String label, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        Text(valor, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _itmMoeda(String nom, String sig, Map<String, dynamic>? dados) {
    final double vlr = dados != null ? double.tryParse(dados['bid'] ?? '0') ?? 0.0 : 0.0;
    final String varc = dados != null ? dados['pctChange'] ?? '0' : '0';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nom, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(sig, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('R\$ ${vlr.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('$varc%', style: TextStyle(color: varc.contains('-') ? Colors.red : Colors.green, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}