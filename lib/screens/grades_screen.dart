import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_scope.dart';
import '../widgets/common.dart';

/// Promedio ponderado por créditos.
double weightedAverage(List<Grade> grades) {
  final credits = grades.fold<int>(0, (sum, g) => sum + g.credits);
  if (credits == 0) {
    return 0;
  }
  final points = grades.fold<double>(0, (sum, g) => sum + g.score * g.credits);
  return points / credits;
}

class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final grades = state.grades;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Color scoreColor(double score) {
      if (score < 7) {
        return scheme.error;
      }
      if (score < 8) {
        return scheme.tertiary;
      }
      return scheme.primary;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Calificaciones')),
      body: RefreshIndicator(
        onRefresh: state.refresh,
        child: ListView(
          children: [
            if (grades.isEmpty && state.loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (grades.isEmpty)
              const EmptyState(
                icon: Icons.school_outlined,
                message: 'Todavía no hay calificaciones publicadas.',
              )
            else ...[
              Card(
                margin: const EdgeInsets.all(16),
                color: scheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Promedio del periodo',
                              style: TextStyle(color: scheme.onPrimaryContainer),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${state.student?.semester ?? ''}° semestre · '
                              '${state.student?.program ?? ''}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        weightedAverage(grades).toStringAsFixed(1),
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SectionTitle('Materias'),
              for (final grade in grades)
                ListTile(
                  title: Text(grade.subject),
                  subtitle: Text('${grade.credits} créditos'),
                  trailing: Text(
                    grade.score.toStringAsFixed(1),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scoreColor(grade.score),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
