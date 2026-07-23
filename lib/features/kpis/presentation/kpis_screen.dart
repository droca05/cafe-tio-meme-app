import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
    );
  }
}

class _FiltroFechas extends ConsumerWidget {
  const _FiltroFechas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rango = ref.watch(rangoFechaProvider);

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipRango(label: 'Todo', valor: RangoFecha.todo, actual: rango),
              _ChipRango(label: 'Hoy', valor: RangoFecha.hoy, actual: rango),
              _ChipRango(
                label: 'Esta semana',
                valor: RangoFecha.semana,
                actual: rango,
              ),
              _ChipRango(
                label: 'Este mes',
                valor: RangoFecha.mes,
                actual: rango,
              ),
              _ChipRango(
                label: 'Rango',
                valor: RangoFecha.personalizado,
                actual: rango,
              ),
            ],
          ),
          if (rango == RangoFecha.personalizado) ...[
            const SizedBox(height: 12),
            const _SelectorRangoPersonalizado(),
          ],
        ],
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.caramel : AppColors.foam,
          borderRadius: BorderRadius.circular(20),
          border: seleccionado ? null : Border.all(color: AppColors.steam),
        ),
        child: Text(
          label,
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
    return Row(
      children: [
        Expanded(
          child: _TarjetaResumen(
            label: 'Total Entregado',
            valor: kpis.totalEntregado,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TarjetaResumen(
            label: 'Total Pendiente',
            valor: kpis.totalPendiente,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  final String label;
  final double valor;
  final Color color;

  const _TarjetaResumen({
    required this.label,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.foam,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 8),
          Text(
            formatMoneda(valor),
            style: AppTextStyles.displayMedium.copyWith(color: color),
          ),
        ],
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
          Row(
            children: [
              Expanded(
                child: _MetricaProducto(
                  label: 'Entregado: ${producto.unidadesEntregadas} uds',
                  monto: producto.ingresosEntregados,
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _MetricaProducto(
                  label: 'Pendiente: ${producto.unidadesPendientes} uds',
                  monto: producto.montoPendiente,
                  color: AppColors.warning,
                ),
              ),
            ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyLight),
        const SizedBox(height: 2),
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
            formatMoneda(datos.totalEntregado),
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
