import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../application/dashboard_controller.dart';
import '../data/dashboard_api.dart';
import '../data/dashboard_repository.dart';

/// Tela principal do Dashboard — cards de receita/despesa/saldo + gráfico
/// de pizza por categoria. Suporta pull-to-refresh.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Carrega o dashboard logo após o primeiro frame para evitar mexer no
    // estado durante o build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final userName =
        authState is AuthAuthenticated ? authState.user.name : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('OrçaFácil'),
        actions: [
          IconButton(
            tooltip: 'Transações',
            icon: const Icon(Icons.list_alt),
            onPressed: () => context.go('/transactions'),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(dashboardControllerProvider.notifier).refresh(),
          child: _DashboardBody(state: state, userName: userName),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.state, required this.userName});

  final DashboardState state;
  final String userName;

  @override
  Widget build(BuildContext context) {
    if (state is DashboardInitial || state is DashboardLoading) {
      return const _LoadingView();
    }
    if (state is DashboardError) {
      return _ErrorView(message: (state as DashboardError).message);
    }
    final loaded = state as DashboardLoaded;
    return _LoadedView(data: loaded.data, userName: userName);
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    // ListView para permitir pull-to-refresh mesmo durante loading.
    return ListView(
      key: const Key('dashboard-loading'),
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 200),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      key: const Key('dashboard-error'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        Icon(
          Icons.error_outline,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: () =>
                ref.read(dashboardControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ),
      ],
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.data, required this.userName});

  final DashboardData data;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final summary = data.summary;
    return ListView(
      key: const Key('dashboard-loaded'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (userName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Olá, $userName',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        _SummaryCards(summary: summary),
        const SizedBox(height: 24),
        Text(
          'Despesas por categoria',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _CategoryChart(breakdown: data.breakdown),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary});

  final MonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                key: const Key('card-saldo-total'),
                title: 'Saldo total',
                value: summary.saldoTotalContas,
                color: Colors.blueGrey,
                icon: Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                key: const Key('card-saldo-mes'),
                title: 'Saldo do mês',
                value: summary.saldo,
                color: summary.saldo >= 0 ? Colors.teal : Colors.red,
                icon: Icons.savings,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                key: const Key('card-receita'),
                title: 'Receita do mês',
                value: summary.receitaTotal,
                color: Colors.green,
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                key: const Key('card-despesa'),
                title: 'Despesa do mês',
                value: summary.despesaTotal,
                color: Colors.red,
                icon: Icons.trending_down,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatBrl(value),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.breakdown});

  final CategoryBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    if (breakdown.items.isEmpty) {
      return SizedBox(
        key: const Key('chart-empty'),
        height: 200,
        child: Center(
          child: Text(
            'Sem despesas no período.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    final total = breakdown.items.fold<double>(0, (s, i) => s + i.total);
    return Column(
      key: const Key('chart-loaded'),
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                for (final item in breakdown.items)
                  PieChartSectionData(
                    value: item.total,
                    color: _parseColor(item.color),
                    title: total == 0
                        ? ''
                        : '${((item.total / total) * 100).toStringAsFixed(0)}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final item in breakdown.items)
              _LegendChip(
                color: _parseColor(item.color),
                label: '${item.name} (${formatBrl(item.total)})',
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Converte string `#RRGGBB` ou `RRGGBB` para `Color`. Default cinza quando
/// inválido ou nulo.
Color _parseColor(String? raw) {
  if (raw == null || raw.isEmpty) return Colors.grey;
  var hex = raw.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 6) hex = 'FF$hex';
  final intColor = int.tryParse(hex, radix: 16);
  if (intColor == null) return Colors.grey;
  return Color(intColor);
}

/// Formata um valor monetário em BRL (R$ 1.234,56).
String formatBrl(double value) {
  final negative = value < 0;
  final abs = value.abs();
  final intPart = abs.truncate();
  final cents = ((abs - intPart) * 100).round().toString().padLeft(2, '0');
  final intStr = intPart.toString();
  final buf = StringBuffer();
  for (var i = 0; i < intStr.length; i++) {
    if (i > 0 && (intStr.length - i) % 3 == 0) buf.write('.');
    buf.write(intStr[i]);
  }
  return '${negative ? '-' : ''}R\$ ${buf.toString()},$cents';
}
