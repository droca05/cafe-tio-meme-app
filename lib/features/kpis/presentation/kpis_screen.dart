import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../solicitudes/presentation/widgets/solicitud_form_widgets.dart';
import '../providers/kpis_providers.dart';

class KpisScreen extends ConsumerWidget {
  const KpisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(kpisProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('KPIs')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FiltroFechas(),
              const SizedBox(height: 24),
              kpisAsync.when(
                data: (kpis) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResumenFinanciero(kpis: kpis),
                    const SizedBox(height: 24),
                    const SeccionTitulo('Ventas por producto'),
                    const SizedBox(height: 8),
                    _TablaProductos(productos: kpis.ventasPorProducto),
                    const SizedBox(height: 24),
                    const SeccionTitulo('Por canal'),
                    const SizedBox(height: 8),
                    _PorCanal(kpis: kpis),
                    const SizedBox(height: 24),
                    const SeccionTitulo('Actividad'),
                    const SizedBox(height: 8),
                    _Actividad(kpis: kpis),
                  ],
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'Ocurrió un error al calcular los KPIs.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltroFechas extends ConsumerWidget {
  const _FiltroFechas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rango = ref.watch(rangoFechaProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _ChipRango(
                label: 'Todo',
                valor: RangoFecha.todo,
                actual: rango,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ChipRango(
                label: 'Hoy',
                valor: RangoFecha.hoy,
                actual: rango,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ChipRango(
                label: 'Esta semana',
                valor: RangoFecha.semana,
                actual: rango,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ChipRango(
                label: 'Este mes',
                valor: RangoFecha.mes,
                actual: rango,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _BotonRangoPersonalizado(
          seleccionado: rango == RangoFecha.personalizado,
          onTap: () =>
              ref.read(rangoFechaProvider.notifier).state =
                  RangoFecha.personalizado,
        ),
        if (rango == RangoFecha.personalizado) ...[
          const SizedBox(height: 12),
          const _SelectorRangoPersonalizado(),
        ],
      ],
    );
  }
}

class _ChipRango extends ConsumerWidget {
  final String label;
  final RangoFecha valor;
  final RangoFecha actual;

  const _ChipRango({
    required this.label,
    required this.valor,
    required this.actual,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seleccionado = valor == actual;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => ref.read(rangoFechaProvider.notifier).state = valor,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.caramel : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: seleccionado ? null : Border.all(color: AppColors.steam),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: seleccionado ? Colors.white : AppColors.espresso,
          ),
        ),
      ),
    );
  }
}

class _BotonRangoPersonalizado extends StatelessWidget {
  final bool seleccionado;
  final VoidCallback onTap;

  const _BotonRangoPersonalizado({
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.caramel : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: seleccionado ? null : Border.all(color: AppColors.steam),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: seleccionado ? Colors.white : AppColors.espresso,
            ),
            const SizedBox(width: 8),
            Text(
              'Rango personalizado',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: seleccionado ? Colors.white : AppColors.espresso,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorRangoPersonalizado extends ConsumerWidget {
  const _SelectorRangoPersonalizado();

  Future<void> _elegirFecha(
    BuildContext context,
    WidgetRef ref,
    bool esInicio,
  ) async {
    final actual = esInicio
        ? ref.read(fechaInicioPersonalizadaProvider)
        : ref.read(fechaFinPersonalizadaProvider);

    final seleccionada = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (seleccionada == null) return;

    if (esInicio) {
      ref.read(fechaInicioPersonalizadaProvider.notifier).state = seleccionada;
    } else {
      ref.read(fechaFinPersonalizadaProvider.notifier).state = seleccionada;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inicio = ref.watch(fechaInicioPersonalizadaProvider);
    final fin = ref.watch(fechaFinPersonalizadaProvider);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _elegirFecha(context, ref, true),
            icon: const Icon(Icons.calendar_today_outlined, size: 16),
            label: Text(inicio == null ? 'Fecha inicio' : formatFecha(inicio)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _elegirFecha(context, ref, false),
            icon: const Icon(Icons.calendar_today_outlined, size: 16),
            label: Text(fin == null ? 'Fecha fin' : formatFecha(fin)),
          ),
        ),
      ],
    );
  }
}

class _ResumenFinanciero extends StatelessWidget {
  final KpisData kpis;

  const _ResumenFinanciero({required this.kpis});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TarjetaResumen(
          icono: Icons.warning_amber_rounded,
          iconoColor: AppColors.warning,
          label: 'Total Revisar',
          valor: formatMoneda(kpis.totalRevisar),
          valorColor: AppColors.warning,
        ),
        const SizedBox(height: 10),
        _TarjetaResumen(
          icono: Icons.check_circle_rounded,
          iconoColor: AppColors.success,
          label: 'Total Verificado',
          valor: formatMoneda(kpis.totalVerificado),
          valorColor: AppColors.success,
        ),
        const SizedBox(height: 10),
        _TarjetaResumen(
          icono: Icons.cancel_rounded,
          iconoColor: AppColors.danger,
          label: 'Total No pagado',
          valor: formatMoneda(kpis.totalNoPagado),
          valorColor: AppColors.danger,
        ),
        const SizedBox(height: 10),
        _TarjetaResumen(
          icono: Icons.attach_money,
          iconoColor: AppColors.roast,
          label: 'Total General',
          valor: formatMoneda(
            kpis.totalRevisar + kpis.totalVerificado + kpis.totalNoPagado,
          ),
          valorColor: AppColors.roast,
        ),
      ],
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  final IconData icono;
  final Color iconoColor;
  final String label;
  final String valor;
  final Color valorColor;

  const _TarjetaResumen({
    required this.icono,
    required this.iconoColor,
    required this.label,
    required this.valor,
    required this.valorColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.foam,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.espresso.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icono, color: iconoColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.roast,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                valor,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: valorColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TablaProductos extends StatelessWidget {
  final List<VentaProducto> productos;

  const _TablaProductos({required this.productos});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final producto in productos) _FilaProducto(producto: producto),
      ],
    );
  }
}

class _FilaProducto extends StatelessWidget {
  final VentaProducto producto;

  const _FilaProducto({required this.producto});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.foam,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.steam),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(producto.nombre, style: AppTextStyles.bodyMedium500),
          const SizedBox(height: 10),
          _MetricaProducto(
            label: 'Revisar: ${producto.unidadesRevisar} uds',
            monto: producto.montoRevisar,
            color: AppColors.warning,
          ),
          const SizedBox(height: 6),
          _MetricaProducto(
            label: 'Verificado: ${producto.unidadesVerificado} uds',
            monto: producto.montoVerificado,
            color: AppColors.success,
          ),
          const SizedBox(height: 6),
          _MetricaProducto(
            label: 'No pagado: ${producto.unidadesNoPagado} uds',
            monto: producto.montoNoPagado,
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }
}

class _MetricaProducto extends StatelessWidget {
  final String label;
  final double monto;
  final Color color;

  const _MetricaProducto({
    required this.label,
    required this.monto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: AppTextStyles.bodyLight)),
        Text(
          formatMoneda(monto),
          style: AppTextStyles.bodyMedium500.copyWith(color: color),
        ),
      ],
    );
  }
}

class _PorCanal extends StatelessWidget {
  final KpisData kpis;

  const _PorCanal({required this.kpis});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TarjetaCanal(
            nombre: 'FORZA',
            color: AppColors.forzaText,
            datos: kpis.forza,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TarjetaCanal(
            nombre: 'Venta Directa',
            color: AppColors.directaText,
            datos: kpis.ventaDirecta,
          ),
        ),
      ],
    );
  }
}

class _TarjetaCanal extends StatelessWidget {
  final String nombre;
  final Color color;
  final VentaCanal datos;

  const _TarjetaCanal({
    required this.nombre,
    required this.color,
    required this.datos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.foam,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.steam),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nombre, style: AppTextStyles.label.copyWith(color: color)),
          const SizedBox(height: 8),
          Text(
            '${datos.cantidadSolicitudes} solicitudes',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            formatMoneda(datos.totalVerificado),
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Actividad extends StatelessWidget {
  final KpisData kpis;

  const _Actividad({required this.kpis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.foam,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.steam),
      ),
      child: Column(
        children: [
          _FilaActividad(
            label: 'Total de solicitudes',
            valor: '${kpis.totalSolicitudes}',
          ),
          _FilaActividad(
            label: 'Clientes únicos atendidos',
            valor: '${kpis.clientesUnicos}',
          ),
          _FilaActividad(
            label: 'Ticket promedio',
            valor: formatMoneda(kpis.ticketPromedio),
          ),
        ],
      ),
    );
  }
}

class _FilaActividad extends StatelessWidget {
  final String label;
  final String valor;

  const _FilaActividad({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.bodyMedium),
          ),
          Text(
            valor,
            style: AppTextStyles.bodyMedium500,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
