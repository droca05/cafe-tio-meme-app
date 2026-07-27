import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/solicitudes/domain/enums.dart';

(IconData, Color) estadoSolicitudIconoColor(EstadoSolicitud estado) {
  switch (estado) {
    case EstadoSolicitud.revisar:
      return (Icons.warning_amber_rounded, AppColors.warning);
    case EstadoSolicitud.verificado:
      return (Icons.check_circle_rounded, AppColors.success);
    case EstadoSolicitud.noPagado:
      return (Icons.cancel_rounded, AppColors.danger);
  }
}

String estadoSolicitudNombre(EstadoSolicitud estado) {
  switch (estado) {
    case EstadoSolicitud.revisar:
      return 'Revisar';
    case EstadoSolicitud.verificado:
      return 'Verificado';
    case EstadoSolicitud.noPagado:
      return 'No pagado';
  }
}

class EstadoSolicitudIcon extends StatelessWidget {
  final EstadoSolicitud estado;

  const EstadoSolicitudIcon({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final (icono, color) = estadoSolicitudIconoColor(estado);
    return Icon(icono, color: color);
  }
}
