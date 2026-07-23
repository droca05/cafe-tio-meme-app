import 'package:intl/intl.dart';

String formatFecha(DateTime fecha) {
  return DateFormat('dd/MM/yyyy').format(fecha);
}

String formatFechaHora(DateTime fecha) {
  return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
}
