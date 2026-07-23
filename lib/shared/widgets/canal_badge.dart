import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/solicitudes/domain/enums.dart';

class CanalBadge extends StatelessWidget {
  final CanalVenta canal;

  const CanalBadge({super.key, required this.canal});

  @override
  Widget build(BuildContext context) {
    final isDirecta = canal == CanalVenta.ventaDirecta;
    final backgroundColor =
        isDirecta ? AppColors.directaBg : AppColors.forzaBg;
    final textColor = isDirecta ? AppColors.directaText : AppColors.forzaText;
    final label = isDirecta ? 'Venta Directa' : 'FORZA';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(color: textColor),
      ),
    );
  }
}
