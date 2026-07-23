import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/solicitudes/domain/enums.dart';

class EstadoPedidoBadge extends StatelessWidget {
  final EstadoPedido estadoPedido;

  const EstadoPedidoBadge({super.key, required this.estadoPedido});

  @override
  Widget build(BuildContext context) {
    final entregado = estadoPedido == EstadoPedido.entregado;
    final color = entregado ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        entregado ? 'Entregado' : 'Pendiente',
        style: AppTextStyles.label.copyWith(color: color),
      ),
    );
  }
}
