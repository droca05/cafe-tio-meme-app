import 'package:intl/intl.dart';

String formatMoneda(double valor) {
  final formateador = NumberFormat('#,##0.00', 'es');
  return 'Q${formateador.format(valor)}';
}
