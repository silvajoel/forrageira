import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/analysis_request.dart';
import '../../services/i_forage_service.dart';
import '../../services/user_service.dart';

class AdminDashboardPage extends StatelessWidget {
  final ValueChanged<String>? onOpenRequests;
  final ValueChanged<String>? onOpenClients;

  const AdminDashboardPage({
    super.key,
    this.onOpenRequests,
    this.onOpenClients,
  });

  @override
  Widget build(BuildContext context) {
    final analysisStream = context.read<IForageService>().watchAllRequests();
    final usersStream = UserService().streamUsers();

    return StreamBuilder<List<AnalysisRequest>>(
      stream: analysisStream,
      builder: (context, analysisSnapshot) {
        if (analysisSnapshot.hasError) {
          return _DashboardMessage(
            icon: Icons.error_outline,
            message: 'Erro ao carregar as análises: ${analysisSnapshot.error}',
          );
        }

        if (analysisSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final analyses = analysisSnapshot.data ?? <AnalysisRequest>[];

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: usersStream,
          builder: (context, usersSnapshot) {
            if (usersSnapshot.hasError) {
              return _DashboardMessage(
                icon: Icons.error_outline,
                message: 'Erro ao carregar os usuários: ${usersSnapshot.error}',
              );
            }

            if (usersSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = usersSnapshot.data ?? <Map<String, dynamic>>[];
            final vm = _DashboardViewModel.fromData(
              analyses: analyses,
              users: users,
            );

            return ListView(
              children: [
                _header(context, vm),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _KpiCard(
                      icon: Icons.analytics_outlined,
                      title: 'Total de análises',
                      value: '${vm.totalAnalyses}',
                      subtitle: 'Solicitações registradas no sistema',
                      onTap: () => onOpenRequests?.call('todos'),
                    ),
                    _KpiCard(
                      icon: Icons.pending_actions_outlined,
                      title: 'Solicitações pendentes',
                      value: '${vm.pendingCount}',
                      subtitle: 'Aguardando avaliação',
                      onTap: () => onOpenRequests?.call('pending'),
                    ),
                    _KpiCard(
                      icon: Icons.task_alt_outlined,
                      title: 'Concluídas',
                      value: '${vm.completedCount}',
                      subtitle: 'Já avaliadas/finalizadas',
                      onTap: () => onOpenRequests?.call('completed'),
                    ),
                    _KpiCard(
                      icon: Icons.people_alt_outlined,
                      title: 'Usuários ativos',
                      value: '${vm.activeUsersCount}',
                      subtitle: 'Cadastros ativos na base',
                      onTap: () => onOpenClients?.call('ativos'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 1100;

                    if (isNarrow) {
                      return Column(
                        children: [
                          _MapCard(viewModel: vm),
                          const SizedBox(height: 16),
                          _ActiveUsersPieCard(viewModel: vm),
                          const SizedBox(height: 16),
                          _AnalysisByStatusCard(viewModel: vm),
                          const SizedBox(height: 16),
                          _WeeklyTrendCard(viewModel: vm),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _MapCard(viewModel: vm)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _ActiveUsersPieCard(viewModel: vm),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _AnalysisByStatusCard(viewModel: vm),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: _WeeklyTrendCard(viewModel: vm)),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _header(BuildContext context, _DashboardViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Wrap(
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard administrativo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Visão geral da operação com foco em análises e usuários.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x14000000)),
            ),
            child: Text(
              'Atualizado em ${DateFormat('dd/MM/yyyy HH:mm').format(vm.generatedAt)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardViewModel {
  final DateTime generatedAt;
  final List<AnalysisRequest> allAnalyses;
  final List<AnalysisRequest> pendingAnalyses;
  final List<AnalysisRequest> completedAnalyses;
  final List<_MapPoint> mapPoints;
  final int totalAnalyses;
  final int pendingCount;
  final int completedCount;
  final int activeUsersCount;
  final Map<String, int> activeUsersByState;
  final Map<String, int> analysesByStatus;
  final List<_DailyCount> dailyCreated;
  final List<_DailyCount> dailyCompleted;

  const _DashboardViewModel({
    required this.generatedAt,
    required this.allAnalyses,
    required this.pendingAnalyses,
    required this.completedAnalyses,
    required this.mapPoints,
    required this.totalAnalyses,
    required this.pendingCount,
    required this.completedCount,
    required this.activeUsersCount,
    required this.activeUsersByState,
    required this.analysesByStatus,
    required this.dailyCreated,
    required this.dailyCompleted,
  });

  factory _DashboardViewModel.fromData({
    required List<AnalysisRequest> analyses,
    required List<Map<String, dynamic>> users,
  }) {
    final completed = analyses.where(_isCompleted).toList()
      ..sort(
            (a, b) => _sortDateDesc(
          a.reviewedAt ?? a.createdAt,
          b.reviewedAt ?? b.createdAt,
        ),
      );

    final pending = analyses.where((item) => !_isCompleted(item)).toList()
      ..sort((a, b) => _sortDateDesc(a.createdAt, b.createdAt));

    final activeUsers = users.where((user) => _toBool(user['active'])).toList();

    final activeUsersByState = <String, int>{};
    for (final user in activeUsers) {
      final state = _extractState(user);
      activeUsersByState[state] = (activeUsersByState[state] ?? 0) + 1;
    }

    final analysesByStatus = <String, int>{
      'Pendentes': 0,
      'Concluídas': 0,
    };

    for (final analysis in analyses) {
      final normalized = _normalizeStatus(analysis);
      if (normalized == 'completed') {
        analysesByStatus['Concluídas'] =
            (analysesByStatus['Concluídas'] ?? 0) + 1;
      } else {
        analysesByStatus['Pendentes'] =
            (analysesByStatus['Pendentes'] ?? 0) + 1;
      }
    }

    final mapPoints = <_MapPoint>[
      ...completed.where(_hasValidLocation).map(
            (item) => _MapPoint(
          latLng: LatLng(item.latitude, item.longitude),
          isCompleted: true,
          label: item.name.isEmpty ? item.id : item.name,
        ),
      ),
      ...pending.where(_hasValidLocation).map(
            (item) => _MapPoint(
          latLng: LatLng(item.latitude, item.longitude),
          isCompleted: false,
          label: item.name.isEmpty ? item.id : item.name,
        ),
      ),
    ];

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 6));

    final dailyCreated = <_DailyCount>[];
    final dailyCompleted = <_DailyCount>[];

    for (var i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      dailyCreated.add(
        _DailyCount(
          day: day,
          count: analyses.where((item) => _sameDate(item.createdAt, day)).length,
        ),
      );
      dailyCompleted.add(
        _DailyCount(
          day: day,
          count: completed
              .where((item) => _sameDate(item.reviewedAt ?? item.createdAt, day))
              .length,
        ),
      );
    }

    final sortedStates = activeUsersByState.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _DashboardViewModel(
      generatedAt: DateTime.now(),
      allAnalyses: analyses,
      pendingAnalyses: pending,
      completedAnalyses: completed,
      mapPoints: mapPoints,
      totalAnalyses: analyses.length,
      pendingCount: pending.length,
      completedCount: completed.length,
      activeUsersCount: activeUsers.length,
      activeUsersByState: {
        for (final entry in sortedStates) entry.key: entry.value,
      },
      analysesByStatus: analysesByStatus,
      dailyCreated: dailyCreated,
      dailyCompleted: dailyCompleted,
    );
  }

  static int _sortDateDesc(DateTime? a, DateTime? b) {
    final left = a ?? DateTime.fromMillisecondsSinceEpoch(0);
    final right = b ?? DateTime.fromMillisecondsSinceEpoch(0);
    return right.compareTo(left);
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final double? height;

  const _DashboardCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: TextStyle(color: Colors.grey.shade700)),
          ],
          const SizedBox(height: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F5B3F).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF1F5B3F)),
                ),
                const SizedBox(height: 14),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final _DashboardViewModel viewModel;

  const _MapCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final points = viewModel.mapPoints;
    final center = _resolveMapCenter(points);

    return _DashboardCard(
      title: 'Mapa das análises',
      subtitle: 'Azul: concluídas • Vermelho: pendentes/em aberto',
      height: 430,
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: const [
              _LegendDot(label: 'Concluídas', color: Color(0xFF2563EB)),
              _LegendDot(label: 'Pendentes', color: Color(0xFFDC2626)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: points.isEmpty
                  ? const _EmptyChart(
                message:
                'Ainda não há análises com localização válida para exibir no mapa.',
              )
                  : FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: points.length == 1 ? 10 : 4.2,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom |
                    InteractiveFlag.drag |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.scrollWheelZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.forrageira',
                  ),
                  MarkerLayer(
                    markers: points
                        .map(
                          (point) => Marker(
                        point: point.latLng,
                        width: 20,
                        height: 20,
                        child: Tooltip(
                          message: point.label,
                          child: Container(
                            decoration: BoxDecoration(
                              color: point.isCompleted
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFDC2626),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LatLng _resolveMapCenter(List<_MapPoint> points) {
    if (points.isEmpty) return const LatLng(-14.2350, -51.9253);
    final avgLat =
        points.map((e) => e.latLng.latitude).reduce((a, b) => a + b) /
            points.length;
    final avgLng =
        points.map((e) => e.latLng.longitude).reduce((a, b) => a + b) /
            points.length;
    return LatLng(avgLat, avgLng);
  }
}

class _ActiveUsersPieCard extends StatelessWidget {
  final _DashboardViewModel viewModel;

  const _ActiveUsersPieCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final entries = viewModel.activeUsersByState.entries.take(6).toList();
    final total = entries.fold<int>(0, (sum, item) => sum + item.value);
    final palette = <Color>[
      const Color(0xFF1D4ED8),
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      const Color(0xFFF59E0B),
      const Color(0xFFDC2626),
      const Color(0xFFDB2777),
    ];

    return _DashboardCard(
      title: 'Usuários ativos por estado',
      subtitle: 'Gráfico em pizza com a distribuição da base ativa',
      height: 430,
      child: entries.isEmpty
          ? const _EmptyChart(
        message:
        'Nenhum usuário ativo encontrado para montar a distribuição por estado.',
      )
          : Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 42,
                sectionsSpace: 3,
                sections: [
                  for (var i = 0; i < entries.length; i++)
                    PieChartSectionData(
                      color: palette[i % palette.length],
                      value: entries[i].value.toDouble(),
                      title: total == 0
                          ? '0%'
                          : '${((entries[i].value / total) * 100).round()}%',
                      radius: 62,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final item = entries[index];
                return Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: palette[index % palette.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.key,
                        style:
                        const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text('${item.value}'),
                  ],
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisByStatusCard extends StatelessWidget {
  final _DashboardViewModel viewModel;

  const _AnalysisByStatusCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final items = viewModel.analysesByStatus.entries.toList();
    final maxValue = items.isEmpty
        ? 1.0
        : math.max(items.map((e) => e.value).reduce(math.max).toDouble(), 1.0);

    return _DashboardCard(
      title: 'Análises por status',
      subtitle: 'Ajuda a enxergar o volume pendente versus concluído',
      height: 320,
      child: items.isEmpty
          ? const _EmptyChart(message: 'Ainda não há dados de status para exibir.')
          : BarChart(
        BarChartData(
          maxY: maxValue + 1,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= items.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      items[index].key,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < items.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: items[i].value.toDouble(),
                    width: 28,
                    borderRadius: BorderRadius.circular(8),
                    color: switch (items[i].key) {
                      'Concluídas' => const Color(0xFF2563EB),
                      _ => const Color(0xFFDC2626),
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyTrendCard extends StatelessWidget {
  final _DashboardViewModel viewModel;

  const _WeeklyTrendCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final maxCreated =
    viewModel.dailyCreated.map((e) => e.count).fold<int>(0, math.max);
    final maxCompleted =
    viewModel.dailyCompleted.map((e) => e.count).fold<int>(0, math.max);
    final maxY =
        math.max(math.max(maxCreated, maxCompleted).toDouble(), 1.0) + 1;

    return _DashboardCard(
      title: 'Movimentação dos últimos 7 dias',
      subtitle: 'Comparativo entre análises criadas e concluídas',
      height: 320,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= viewModel.dailyCreated.length) {
                    return const SizedBox.shrink();
                  }
                  final label =
                  DateFormat('dd/MM').format(viewModel.dailyCreated[index].day);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(label, style: const TextStyle(fontSize: 11)),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: const Color(0xFF1F5B3F),
              barWidth: 3,
              dotData: const FlDotData(show: true),
              spots: [
                for (var i = 0; i < viewModel.dailyCreated.length; i++)
                  FlSpot(i.toDouble(), viewModel.dailyCreated[i].count.toDouble()),
              ],
            ),
            LineChartBarData(
              isCurved: true,
              color: const Color(0xFF2563EB),
              barWidth: 3,
              dotData: const FlDotData(show: true),
              spots: [
                for (var i = 0; i < viewModel.dailyCompleted.length; i++)
                  FlSpot(
                    i.toDouble(),
                    viewModel.dailyCompleted[i].count.toDouble(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' => const Color(0xFF2563EB),
      'in_progress' => const Color(0xFFF59E0B),
      _ => const Color(0xFFDC2626),
    };

    final text = switch (status) {
      'completed' => 'Concluída',
      'in_progress' => 'Em análise',
      _ => 'Pendente',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;

  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ),
    );
  }
}

class _DashboardMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _DashboardMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade600),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }
}

class _MapPoint {
  final LatLng latLng;
  final bool isCompleted;
  final String label;

  const _MapPoint({
    required this.latLng,
    required this.isCompleted,
    required this.label,
  });
}

class _DailyCount {
  final DateTime day;
  final int count;

  const _DailyCount({required this.day, required this.count});
}

bool _isCompleted(AnalysisRequest analysis) =>
    _normalizeStatus(analysis) == 'completed';

String _normalizeStatus(AnalysisRequest analysis) {
  final raw = analysis.status.trim().toLowerCase();

  if (analysis.reviewedAt != null ||
      raw == 'completed' ||
      raw == 'finalizado' ||
      raw == 'finished' ||
      raw == 'reviewed' ||
      raw == 'done') {
    return 'completed';
  }

  if (raw == 'em_analise' || raw == 'em análise' || raw == 'in_progress') {
    return 'in_progress';
  }

  return 'pending';
}

bool _hasValidLocation(AnalysisRequest analysis) {
  return analysis.latitude != 0 &&
      analysis.longitude != 0 &&
      analysis.latitude >= -90 &&
      analysis.latitude <= 90 &&
      analysis.longitude >= -180 &&
      analysis.longitude <= 180;
}

bool _sameDate(DateTime? left, DateTime day) {
  if (left == null) return false;
  return left.year == day.year &&
      left.month == day.month &&
      left.day == day.day;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'ativo';
  }
  return false;
}

String _extractState(Map<String, dynamic> data) {
  final directCandidates = [
    data['state'],
    data['estado'],
    data['uf'],
    data['location_state'],
  ];

  for (final value in directCandidates) {
    final normalized = _normalizeStateValue(value);
    if (normalized != null) return normalized;
  }

  final address = data['address'];
  if (address is Map<String, dynamic>) {
    final nestedCandidates = [
      address['state'],
      address['estado'],
      address['uf'],
    ];
    for (final value in nestedCandidates) {
      final normalized = _normalizeStateValue(value);
      if (normalized != null) return normalized;
    }
  }

  return 'Não informado';
}

String? _normalizeStateValue(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  if (text.length == 2) return text.toUpperCase();
  return text;
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('dd/MM/yyyy HH:mm').format(value);
}
