import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DataUsageChart extends StatefulWidget {
  const DataUsageChart({super.key});

  @override
  State<DataUsageChart> createState() => _DataUsageChartState();
}

class _DataUsageChartState extends State<DataUsageChart>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  
  final List<DataUsageItem> _usageData = [
    DataUsageItem('Conversations', 45.2, Colors.blue),
    DataUsageItem('Memories', 32.1, Colors.green),
    DataUsageItem('Settings', 12.3, Colors.orange),
    DataUsageItem('Analytics', 8.7, Colors.purple),
    DataUsageItem('Other', 1.7, Colors.grey),
  ];

  @override
  void initState() {
    super.initState();
    
    _controllers = _usageData.map((item) {
      return AnimationController(
        duration: Duration(milliseconds: 1000 + (item.percentage * 20).round()),
        vsync: this,
      );
    }).toList();

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutQuart),
      );
    }).toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '156.2 MB',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideX(begin: -0.3),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    'Total storage used',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .slideX(begin: -0.3),
                ],
              ),
            ),
            
            Container(
              width: 80,
              height: 80,
              child: CustomPaint(
                painter: DonutChartPainter(_usageData, _animations),
              ),
            )
            .animate()
            .scale(
              duration: 800.ms,
              delay: 200.ms,
              curve: Curves.elasticOut,
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Storage Breakdown',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        )
        .animate()
        .fadeIn(delay: 600.ms)
        .slideX(begin: -0.3),
        
        const SizedBox(height: 12),
        
        ..._usageData.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${(item.percentage * _animations[index].value).toStringAsFixed(1)}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: item.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _calculateSize(item.percentage * _animations[index].value),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              );
            },
          )
          .animate()
          .fadeIn(delay: (700 + index * 100).ms)
          .slideX(begin: 0.3);
        }),
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.cloud_queue,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Data is stored locally and encrypted',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 1200.ms)
        .slideY(begin: 0.3),
      ],
    );
  }

  String _calculateSize(double percentage) {
    final totalMB = 156.2;
    final sizeMB = (totalMB * percentage / 100);
    
    if (sizeMB < 1) {
      return '${(sizeMB * 1024).toStringAsFixed(0)} KB';
    } else {
      return '${sizeMB.toStringAsFixed(1)} MB';
    }
  }
}

class DataUsageItem {
  final String label;
  final double percentage;
  final Color color;

  DataUsageItem(this.label, this.percentage, this.color);
}

class DonutChartPainter extends CustomPainter {
  final List<DataUsageItem> data;
  final List<Animation<double>> animations;

  DonutChartPainter(this.data, this.animations) : super(repaint: Listenable.merge(animations));

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.6;

    double startAngle = -90 * (3.14159 / 180); // Start from top

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final animatedPercentage = item.percentage * animations[i].value;
      final sweepAngle = (animatedPercentage / 100) * 2 * 3.14159;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius - innerRadius
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (radius + innerRadius) / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class StorageWarningCard extends StatelessWidget {
  final double usagePercentage;
  final String warningMessage;

  const StorageWarningCard({
    required this.usagePercentage,
    required this.warningMessage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWarning = usagePercentage > 80;
    final isCritical = usagePercentage > 95;
    
    Color warningColor = Colors.green;
    IconData warningIcon = Icons.check_circle;
    
    if (isCritical) {
      warningColor = Colors.red;
      warningIcon = Icons.error;
    } else if (isWarning) {
      warningColor = Colors.orange;
      warningIcon = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warningColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(warningIcon, color: warningColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${usagePercentage.toStringAsFixed(1)}% Storage Used',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  warningMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: warningColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 400.ms)
    .slideY(begin: 0.3);
  }
}