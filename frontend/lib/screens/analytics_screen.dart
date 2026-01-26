import 'package:flutter/material.dart';

/// Analytics screen showing detailed learning statistics and insights
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Key Metrics Cards
                    _buildKeyMetricsGrid(context),
                    const SizedBox(height: 20),
                    
                    // Study Time Chart
                    _buildStudyTimeChart(context),
                    const SizedBox(height: 20),
                    
                    // Activity Breakdown
                    _buildActivityBreakdown(context),
                    const SizedBox(height: 20),
                    
                    // Performance by Subject
                    _buildPerformanceBySubject(context),
                    const SizedBox(height: 20),
                    
                    // Areas to Improve
                    _buildAreasToImprove(context),
                    const SizedBox(height: 100), // Bottom padding for navigation
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar with logo, streak, notifications, profile
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ScholarLens',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department, color: Color(0xFFFF9500), size: 16),
                    SizedBox(width: 4),
                    Text(
                      '7',
                      style: TextStyle(
                        color: Color(0xFFFF9500),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined, size: 24),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF7C3AED),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Title and description
          const Text(
            'Analytics Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your learning progress and identify improvement areas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.schedule,
                iconColor: const Color(0xFF7C3AED),
                value: '23.5h',
                label: 'Study Time (Week)',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.gps_fixed,
                iconColor: const Color(0xFF14B8A6),
                value: '78%',
                label: 'Avg Accuracy',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.quiz,
                iconColor: const Color(0xFFFF9500),
                value: '505',
                label: 'Questions Solved',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.trending_up,
                iconColor: const Color(0xFF10B981),
                value: '+12%',
                label: 'Performance Change',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyTimeChart(BuildContext context) {
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
              painter: StudyTimeChartPainter(),
              size: const Size(double.infinity, 200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBreakdown(BuildContext context) {
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
                    painter: PieChartPainter(),
                    size: const Size(120, 120),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildActivityItem('Flashcards', '35%', const Color(0xFF7C3AED)),
                    const SizedBox(height: 8),
                    _buildActivityItem('Mock Exams', '25%', const Color(0xFF14B8A6)),
                    const SizedBox(height: 8),
                    _buildActivityItem('AI Tutor', '20%', const Color(0xFFFF9500)),
                    const SizedBox(height: 8),
                    _buildActivityItem('Snap & Solve', '20%', const Color(0xFF10B981)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: BarChartPainter(),
              size: const Size(double.infinity, 200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreasToImprove(BuildContext context) {
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
          _buildImprovementItem('Organic Chemistry', 45, -5, Colors.red),
          const SizedBox(height: 16),
          _buildImprovementItem('Geometry Proofs', 52, 8, Colors.green),
          const SizedBox(height: 16),
          _buildImprovementItem('Electromagnetism', 58, 3, Colors.green),
          const SizedBox(height: 16),
          _buildImprovementItem('Calculus', 61, 12, Colors.green),
          const SizedBox(height: 20),
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
                      children: const [
                        TextSpan(
                          text: 'AI Tip: ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: 'Focus on Organic Chemistry this week. Try the "Snap & Solve" feature with reaction diagrams!',
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

// Custom painters for charts
class StudyTimeChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Sample data points for the week
    final points = [
      Offset(size.width * 0.1, size.height * 0.7),
      Offset(size.width * 0.25, size.height * 0.6),
      Offset(size.width * 0.4, size.height * 0.8),
      Offset(size.width * 0.55, size.height * 0.5),
      Offset(size.width * 0.7, size.height * 0.6),
      Offset(size.width * 0.85, size.height * 0.3),
    ];

    // Draw filled area
    final path = Path();
    path.moveTo(points.first.dx, size.height);
    for (final point in points) {
      path.lineTo(point.dx, point.dy);
    }
    path.lineTo(points.last.dx, size.height);
    path.close();
    canvas.drawPath(path, fillPaint);

    // Draw line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, paint);

    // Draw days labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    for (int i = 0; i < days.length; i++) {
      textPainter.text = TextSpan(
        text: days[i],
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PieChartPainter extends CustomPainter {
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

    final percentages = [35, 25, 20, 20];
    double startAngle = -90 * (3.14159 / 180); // Start from top

    for (int i = 0; i < percentages.length; i++) {
      final sweepAngle = (percentages[i] / 100) * 2 * 3.14159;
      final paint = Paint()
        ..color = colors[i]
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

    // Draw center circle
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.4, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final subjects = ['Physics', 'Math', 'English'];
    final scores = [85, 92, 78];
    final barWidth = size.width / (subjects.length * 2);
    final maxScore = 100;

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

      // Draw subject labels
      final textPainter = TextPainter(
        text: TextSpan(
          text: subjects[i],
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}