import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../data/excel_export_service.dart';
import '../providers/exportar_providers.dart';

class ExportarScreen extends ConsumerStatefulWidget {
  const ExportarScreen({super.key});

  @override
  ConsumerState<ExportarScreen> createState() => _ExportarScreenState();
}

class _ExportarScreenState extends ConsumerState<ExportarScreen> {
  bool _generando = false;

  Future<void> _descargarExcel(ResultadoExportar resultado) async {
    setState(() => _generando = true);

    try {
      final ruta = await ExcelExportService().exportar(
        solicitudes: resultado.solicitudes,
        clientesPorId: resultado.clientesPorId,
        productos: resultado.productos,
      );
      debugPrint('Excel guardado en: $ruta');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 6),
          content: Text(
            'Archivo guardado en: $ruta',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
            'No se pudo generar el Excel: $e',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultadoAsync = ref.watch(solicitudesParaExportarProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Exportar solicitudes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rango de fechas',
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.roast,
              ),
            ),
            const SizedBox(height: 12),
            const _FiltroFechaExportar(),
            const SizedBox(height: 24),
            Text(
              'Estado de la solicitud',
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.roast,
              ),
            ),
            const SizedBox(height: 12),
            const _FiltroEstadoExportar(),
            const SizedBox(height: 24),
            Text(
              'Vista previa',
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.roast,
              ),
            ),
            const SizedBox(height: 12),
            resultadoAsync.when(
              data: (resultado) => _VistaPrevia(resultado: resultado),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => Text(
                'Ocurrió un error al calcular la vista previa.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: resultadoAsync.maybeWhen(
                data: (resultado) => !_generando && resultado.solicitudes.isNotEmpty
                    ? () => _descargarExcel(resultado)
                    : null,
                orElse: () => null,
              ),
              child: _generando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.foam,
                      ),
                    )
                  : const Text('Descargar Excel'),
            ),
          ),
        ),
      ),
    );
  }
}

class _FiltroFechaExportar extends ConsumerWidget {
  const _FiltroFechaExportar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(filtroFechaExportarProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _Chip(
                label: 'Todo',
                seleccionado: filtro == FiltroFechaExportar.todo,
                onTap: () =>
                    ref.read(filtroFechaExportarProvider.notifier).state =
                        FiltroFechaExportar.todo,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Chip(
                label: 'Hoy',
                seleccionado: filtro == FiltroFechaExportar.hoy,
                onTap: () =>
                    ref.read(filtroFechaExportarProvider.notifier).state =
                        FiltroFechaExportar.hoy,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Chip(
                label: 'Esta semana',
                seleccionado: filtro == FiltroFechaExportar.semana,
                onTap: () =>
                    ref.read(filtroFechaExportarProvider.notifier).state =
                        FiltroFechaExportar.semana,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Chip(
                label: 'Este mes',
                seleccionado: filtro == FiltroFechaExportar.mes,
                onTap: () =>
                    ref.read(filtroFechaExportarProvider.notifier).state =
                        FiltroFechaExportar.mes,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _BotonRangoPersonalizado(
          seleccionado: filtro == FiltroFechaExportar.personalizado,
          onTap: () => ref.read(filtroFechaExportarProvider.notifier).state =
              FiltroFechaExportar.personalizado,
        ),
        if (filtro == FiltroFechaExportar.personalizado) ...[
          const SizedBox(height: 12),
          const _SelectorRangoPersonalizado(),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool seleccionado;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.caramel : AppColors.foam,
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
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.caramel : AppColors.foam,
          borderRadius: BorderRadius.circular(12),
          border: seleccionado ? null : Border.all(color: AppColors.steam),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.date_range_outlined,
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
    final provider =
        esInicio ? fechaInicioExportarProvider : fechaFinExportarProvider;
    final actual = ref.read(provider);

    final seleccionada = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (seleccionada == null) return;
    ref.read(provider.notifier).state = seleccionada;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inicio = ref.watch(fechaInicioExportarProvider);
    final fin = ref.watch(fechaFinExportarProvider);

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

class _FiltroEstadoExportar extends ConsumerWidget {
  const _FiltroEstadoExportar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(filtroEstadoExportarProvider);

    return Row(
      children: [
        Expanded(
          child: _Chip(
            label: 'Todos',
            seleccionado: filtro == FiltroEstadoExportar.todos,
            onTap: () =>
                ref.read(filtroEstadoExportarProvider.notifier).state =
                    FiltroEstadoExportar.todos,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Chip(
            label: 'Revisar',
            seleccionado: filtro == FiltroEstadoExportar.revisar,
            onTap: () =>
                ref.read(filtroEstadoExportarProvider.notifier).state =
                    FiltroEstadoExportar.revisar,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Chip(
            label: 'Verificado',
            seleccionado: filtro == FiltroEstadoExportar.verificado,
            onTap: () =>
                ref.read(filtroEstadoExportarProvider.notifier).state =
                    FiltroEstadoExportar.verificado,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Chip(
            label: 'No pagado',
            seleccionado: filtro == FiltroEstadoExportar.noPagado,
            onTap: () =>
                ref.read(filtroEstadoExportarProvider.notifier).state =
                    FiltroEstadoExportar.noPagado,
          ),
        ),
      ],
    );
  }
}

class _VistaPrevia extends StatelessWidget {
  final ResultadoExportar resultado;

  const _VistaPrevia({required this.resultado});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.foam,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${resultado.solicitudes.length} solicitudes encontradas',
            style: AppTextStyles.bodyMedium500,
          ),
          const SizedBox(height: 12),
          Text(
            'Total revisar: ${formatMoneda(resultado.totalRevisar)}',
            style: AppTextStyles.bodyMedium500.copyWith(
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total verificado: ${formatMoneda(resultado.totalVerificado)}',
            style: AppTextStyles.bodyMedium500.copyWith(
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total no pagado: ${formatMoneda(resultado.totalNoPagado)}',
            style: AppTextStyles.bodyMedium500.copyWith(
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
