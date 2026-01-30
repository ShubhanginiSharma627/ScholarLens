import 'package:flutter/material.dart';
import '../widgets/common/top_navigation_bar.dart';
import '../services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  AnalyticsData? _analyticsData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final data = await _analyticsService.getAnalyticsData();
      if (mounted) {
        setState(() {
          _analyticsData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Analytics screen error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const TopNavigationBar(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _analyticsData == null
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _loadAnalyticsData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0), // Extra bottom padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Analytics Dashboard',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track your learning progress and identify improvement areas',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildKeyMetricsGrid(context),
                          const SizedBox(height: 20),
                          _buildStudyTimeChart(context),
                          const SizedBox(height: 20),
                          _buildActivityBreakdown(context),
                          const SizedBox(height: 20),
                          _buildPerformanceBySubject(context),
                          const SizedBox(height: 20),
                          _buildAreasToImprove(context),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load analytics',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start studying to see your progress!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAnalyticsData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  Widget _buildKeyMetricsGrid(BuildContext context) {
    if (_analyticsData == null) return const SizedBox.shrink();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth > 400 ? 1.6 : 1.4, // Responsive aspect ratio
          children: [
            _buildMetricCard(
              icon: Icons.schedule,
              iconColor: const Color(0xFF7C3AED),
              value: '${_analyticsData!.totalStudyTime.toStringAsFixed(1)}h',
              label: 'Study Time\n(Week)',
            ),
            _buildMetricCard(
              icon: Icons.gps_fixed,
              iconColor: const Color(0xFF14B8A6),
              value: '${_analyticsData!.averageAccuracy.toStringAsFixed(0)}%',
              label: 'Average\nAccuracy',
            ),
            _buildMetricCard(
              icon: Icons.local_fire_department,
              iconColor: const Color(0xFFFF9500),
              value: '${_analyticsData!.streak ?? 1}', // Handle nullable streak, default to 1
              label: 'Current\nStreak',
            ),
            _buildMetricCard(
              icon: Icons.trending_up,
              iconColor: _analyticsData!.performanceChange >= 0 
                  ? const Color(0xFF10B981) 
                  : const Color(0xFFEF4444),
              value: '${_analyticsData!.performanceChange >= 0 ? '+' : ''}${_analyticsData!.performanceChange.toStringAsFixed(0)}%',
              label: 'Performance\nChange',
            ),
          ],
        );
      },
    );
  }
  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6), // Reduced padding
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18, // Reduced icon size
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20, // Reduced font size
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 2), // Reduced spacing
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10, // Reduced font size
                      color: Colors.grey[600],
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStudyTimeChart(BuildContext context) {
    if (_analyticsData == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Color(0xFF7C3AED),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Study Time This Week',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: StudyTimeChartPainter(_analyticsData!.weeklyStudyTime),
              size: const Size(double.infinity, 200),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildActivityBreakdown(BuildContext context) {
    if (_analyticsData == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '⚡',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'Activity Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 120,
                  child: CustomPaint(
                    painter: PieChartPainter(_analyticsData!.activityBreakdown),
                    size: const Size(120, 120),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 3,
                child: Column(
                  children: _analyticsData!.activityBreakdown.entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildActivityItem(
                              entry.key,
                              '${entry.value.toStringAsFixed(0)}%',
                              _getActivityColor(entry.key),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String activity) {
    switch (activity) {
      case 'Flashcards':
        return const Color(0xFF7C3AED);
      case 'Mock Exams':
        return const Color(0xFF14B8A6);
      case 'AI Tutor':
        return const Color(0xFFFF9500);
      case 'Snap & Solve':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }
  Widget _buildActivityItem(String label, String percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          percentage,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  Widget _buildPerformanceBySubject(BuildContext context) {
    if (_analyticsData == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '📊',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'Performance by Subject',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_analyticsData!.subjectPerformance.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No subject data available yet.\nStart studying to see your performance!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: CustomPaint(
                painter: BarChartPainter(_analyticsData!.subjectPerformance),
                size: const Size(double.infinity, 200),
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildAreasToImprove(BuildContext context) {
    if (_analyticsData == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '🎯',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'Areas to Improve',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_analyticsData!.areasToImprove.isEmpty && (_analyticsData!.weakestTopics?.isEmpty ?? true))
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Great job! No areas need immediate improvement.\nKeep up the excellent work!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                ..._analyticsData!.areasToImprove.take(2).map((area) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildImprovementItem(
                        area.subject,
                        area.currentScore,
                        area.change,
                        area.change >= 0 ? Colors.green : Colors.red,
                      ),
                    )),
                ...(_analyticsData!.weakestTopics ?? []).take(2).map((topic) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildTopicItem(
                        topic.topic,
                        topic.count,
                        Colors.orange,
                      ),
                    )),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                            children: [
                              const TextSpan(
                                text: 'AI Tip: ',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              TextSpan(
                                text: _getImprovementTip(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _getImprovementTip() {
    if (_analyticsData!.areasToImprove.isNotEmpty) {
      return 'Focus on ${_analyticsData!.areasToImprove.first.subject} this week. Try generating more flashcards for this subject!';
    } else if ((_analyticsData!.weakestTopics?.isNotEmpty ?? false)) {
      return 'Consider reviewing ${_analyticsData!.weakestTopics!.first.topic} more frequently to strengthen your understanding.';
    } else {
      return 'Keep practicing regularly to maintain your excellent performance!';
    }
  }

  Widget _buildTopicItem(String topic, int count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                topic,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$count interactions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: 0.3, // Placeholder value for visual representation
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }
  Widget _buildImprovementItem(String subject, int percentage, int change, Color changeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              subject,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${change > 0 ? '+' : ''}$change%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: changeColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage < 50 ? const Color(0xFF7C3AED) : const Color(0xFF14B8A6),
          ),
          minHeight: 6,
        ),
      ],
    );
  }
}
class StudyTimeChartPainter extends CustomPainter {
  final List<WeeklyStudyData> weeklyData;
  
  StudyTimeChartPainter(this.weeklyData);

  @override
  void paint(Canvas canvas, Size size) {
    if (weeklyData.isEmpty) return;
    
    final paint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final maxHours = weeklyData.map((d) => d.hours).reduce((a, b) => a > b ? a : b);
    final points = <Offset>[];
    
    for (int i = 0; i < weeklyData.length; i++) {
      final x = size.width * (i / (weeklyData.length - 1));
      final y = size.height * (1 - (weeklyData[i].hours / (maxHours + 1)));
      points.add(Offset(x, y));
    }

    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, size.height);
      for (final point in points) {
        path.lineTo(point.dx, point.dy);
      }
      path.lineTo(points.last.dx, size.height);
      path.close();
      canvas.drawPath(path, fillPaint);

      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(linePath, paint);
    }

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    for (int i = 0; i < weeklyData.length && i < points.length; i++) {
      textPainter.text = TextSpan(
        text: weeklyData[i].day,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, size.height - 20),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
class PieChartPainter extends CustomPainter {
  final Map<String, double> activityData;
  
  PieChartPainter(this.activityData);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    final colors = [
      const Color(0xFF7C3AED), // Flashcards
      const Color(0xFF14B8A6), // Mock Exams
      const Color(0xFFFF9500), // AI Tutor
      const Color(0xFF10B981), // Snap & Solve
    ];
    
    final activities = activityData.keys.toList();
    final percentages = activityData.values.toList();
    
    double startAngle = -90 * (3.14159 / 180); // Start from top
    for (int i = 0; i < percentages.length && i < colors.length; i++) {
      final sweepAngle = (percentages[i] / 100) * 2 * 3.14159;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }
    
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.4, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
class BarChartPainter extends CustomPainter {
  final Map<String, double> subjectData;
  
  BarChartPainter(this.subjectData);

  @override
  void paint(Canvas canvas, Size size) {
    if (subjectData.isEmpty) return;
    
    final subjects = subjectData.keys.toList();
    final scores = subjectData.values.toList();
    final barWidth = size.width / (subjects.length * 2);
    const maxScore = 100.0;
    
    for (int i = 0; i < subjects.length; i++) {
      final barHeight = (scores[i] / maxScore) * (size.height - 40);
      final x = (i + 0.5) * (size.width / subjects.length) - barWidth / 2;
      final y = size.height - 40 - barHeight;
      
      final paint = Paint()
        ..color = const Color(0xFF14B8A6)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(4),
        ),
        paint,
      );
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: subjects[i].length > 8 ? '${subjects[i].substring(0, 8)}...' : subjects[i],
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, size.height - 20),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}