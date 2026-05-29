import 'package:flutter/material.dart';
import '../views/login_view.dart';
import '../views/principal_view.dart';
import '../views/cotacao_view.dart';
import '../views/transferencia_view.dart';
import '../views/cadastro_view.dart';

class AppRoutes {
  static const String LOGIN = '/';
  static const String PRINCIPAL = '/principal';
  static const String COTACAO = '/cotacao';
  static const String TRANSFERENCIA = '/transferencia';
  static const String CADASTRO = '/cadastro';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      LOGIN: (ctx) => const LoginView(),
      PRINCIPAL: (ctx) => const PrincipalView(),
      COTACAO: (ctx) => const CotacaoView(),
      TRANSFERENCIA: (ctx) => const TransferenciaView(),
      CADASTRO: (ctx) => const CadastroView(),
    };
  }
}