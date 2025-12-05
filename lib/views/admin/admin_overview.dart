import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminOverviewPage extends StatefulWidget {
  const AdminOverviewPage({super.key});

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage> {
  // Activity chart filters
  String _activityInterval = 'Weekly'; // Daily, Weekly, Monthly
  String _activityType = 'All'; // All, Projects, Journal, Wishlist
  
  // User sign-ups filters
  String _signupPeriod = 'Last 7 Days'; // Last 7 Days, Last 30 Days, Last 3 Months, Custom

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Container(
      color: const Color(0xFFF8F9FA),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 16, 
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Activity Chart (Projects, Journal, Wishlist)
            _buildUserActivityChart(context, isTablet),
            const SizedBox(height: 24),

            // System Health Overview
            _buildSystemHealth(context, isTablet),
            const SizedBox(height: 24),

            // User Sign-ups Trend
            _buildSignupTrendChart(context),
            const SizedBox(height: 24),

            // Recent Activity Feed
            _buildRecentActivity(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // User Activity Chart - Shows Projects, Journal, Wishlist creation over time
  Widget _buildUserActivityChart(BuildContext context, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.bar_chart_rounded, color: Colors.blue.shade700, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'User Activity Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ),
                // Time interval dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: _activityInterval,
                    underline: const SizedBox(),
                    isDense: true,
                    items: ['Daily', 'Weekly', 'Monthly']
                        .map((interval) => DropdownMenuItem(
                              value: interval,
                              child: Text(
                                interval,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _activityInterval = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Item type dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: _activityType,
                    underline: const SizedBox(),
                    isDense: true,
                    items: ['All', 'Projects', 'Journal', 'Wishlist']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _activityType = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Chart
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildActivityBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBarChart() {
    // Sample data based on filters
    final data = _getActivityData();
    
    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(data),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.grey.shade800,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()} items',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        data[value.toInt()]['label'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                interval: _getYAxisInterval(data),
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return Text(
                      '0',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    );
                  }
                  // Only show values at the interval
                  final interval = _getYAxisInterval(data);
                  if (value % interval == 0) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _getYAxisInterval(data),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: _buildBarGroups(data),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getActivityData() {
    // Generate sample data based on selected interval
    if (_activityInterval == 'Daily') {
      return List.generate(7, (i) => {
        'label': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
        'projects': _activityType == 'All' || _activityType == 'Projects' ? [5, 8, 6, 9, 7, 4, 3][i] : 0,
        'journal': _activityType == 'All' || _activityType == 'Journal' ? [12, 15, 18, 14, 16, 10, 8][i] : 0,
        'wishlist': _activityType == 'All' || _activityType == 'Wishlist' ? [3, 5, 4, 6, 5, 2, 1][i] : 0,
      });
    } else if (_activityInterval == 'Weekly') {
      return List.generate(6, (i) => {
        'label': 'W${i + 1}',
        'projects': _activityType == 'All' || _activityType == 'Projects' ? [28, 32, 30, 35, 29, 31][i] : 0,
        'journal': _activityType == 'All' || _activityType == 'Journal' ? [68, 72, 70, 75, 69, 71][i] : 0,
        'wishlist': _activityType == 'All' || _activityType == 'Wishlist' ? [18, 22, 20, 25, 19, 21][i] : 0,
      });
    } else {
      return List.generate(6, (i) => {
        'label': ['Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][i],
        'projects': _activityType == 'All' || _activityType == 'Projects' ? [120, 135, 128, 142, 138, 145][i] : 0,
        'journal': _activityType == 'All' || _activityType == 'Journal' ? [280, 295, 288, 302, 298, 305][i] : 0,
        'wishlist': _activityType == 'All' || _activityType == 'Wishlist' ? [75, 82, 78, 85, 81, 88][i] : 0,
      });
    }
  }

  double _getMaxY(List<Map<String, dynamic>> data) {
    double max = 0;
    for (var item in data) {
      double total = (item['projects'] as int).toDouble() +
          (item['journal'] as int).toDouble() +
          (item['wishlist'] as int).toDouble();
      if (total > max) max = total;
    }
    return max * 1.2; // Add 20% padding
  }

  double _getYAxisInterval(List<Map<String, dynamic>> data) {
    final maxY = _getMaxY(data);
    // Calculate a clean interval that divides maxY into 4-6 segments
    final roughInterval = maxY / 5;
    
    // Round to nearest nice number (10, 20, 25, 50, 100, etc.)
    if (roughInterval <= 10) return 10;
    if (roughInterval <= 20) return 20;
    if (roughInterval <= 25) return 25;
    if (roughInterval <= 50) return 50;
    if (roughInterval <= 100) return 100;
    if (roughInterval <= 200) return 200;
    return (roughInterval / 50).ceil() * 50.0;
  }

  List<BarChartGroupData> _buildBarGroups(List<Map<String, dynamic>> data) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      
      double projects = (item['projects'] as int).toDouble();
      double journal = (item['journal'] as int).toDouble();
      double wishlist = (item['wishlist'] as int).toDouble();

      List<BarChartRodStackItem> stackItems = [];
      double fromY = 0;

      if (_activityType == 'All') {
        stackItems = [
          BarChartRodStackItem(0, projects, const Color(0xFF667EEA)),
          BarChartRodStackItem(projects, projects + journal, const Color(0xFF4FACFE)),
          BarChartRodStackItem(projects + journal, projects + journal + wishlist, const Color(0xFF43E97B)),
        ];
        fromY = 0;
      } else if (_activityType == 'Projects') {
        stackItems = [BarChartRodStackItem(0, projects, const Color(0xFF667EEA))];
      } else if (_activityType == 'Journal') {
        stackItems = [BarChartRodStackItem(0, journal, const Color(0xFF4FACFE))];
      } else {
        stackItems = [BarChartRodStackItem(0, wishlist, const Color(0xFF43E97B))];
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: _activityType == 'All' ? projects + journal + wishlist : 
                 _activityType == 'Projects' ? projects :
                 _activityType == 'Journal' ? journal : wishlist,
            rodStackItems: stackItems,
            width: 24,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  // System Health Overview
  Widget _buildSystemHealth(BuildContext context, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.monitor_heart_outlined, color: Colors.blue.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'System Health',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          // Health Metrics
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHealthMetric(
                  'Total Users',
                  '124',
                  '+12 this week',
                  Icons.people_outline,
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildHealthMetric(
                  'Active Sessions',
                  '87',
                  '70% online',
                  Icons.wifi_rounded,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildHealthMetric(
                  'Bug Reports',
                  '3',
                  '2 resolved today',
                  Icons.bug_report_outlined,
                  Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // User Sign-ups Trend Chart with Filters
  Widget _buildSignupTrendChart(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'User Sign-ups Trend',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
            // Period selector dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<String>(
                value: _signupPeriod,
                underline: const SizedBox(),
                isDense: true,
                items: ['Last 7 Days', 'Last 30 Days', 'Last 3 Months', 'Custom']
                    .map((period) => DropdownMenuItem(
                          value: period,
                          child: Text(
                            period,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _signupPeriod = value);
                    if (value == 'Custom') {
                      _showDateRangePicker(context);
                    }
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: _buildSignupLineChart(),
        ),
      ],
    );
  }

  void _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF9ED69),
              onPrimary: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // TODO: Update chart with custom date range
    }
  }

  Widget _buildSignupLineChart() {
    final data = _getSignupData();
    
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        data[value.toInt()]['label'],
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value['value'].toDouble());
              }).toList(),
              isCurved: true,
              color: const Color(0xFF667EEA),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFF667EEA),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF667EEA).withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.grey.shade800,
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toInt()} sign-ups',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSignupData() {
    if (_signupPeriod == 'Last 7 Days') {
      return [
        {'label': 'Mon', 'value': 8},
        {'label': 'Tue', 'value': 12},
        {'label': 'Wed', 'value': 10},
        {'label': 'Thu', 'value': 15},
        {'label': 'Fri', 'value': 13},
        {'label': 'Sat', 'value': 18},
        {'label': 'Sun', 'value': 20},
      ];
    } else if (_signupPeriod == 'Last 30 Days') {
      return List.generate(30, (i) => {
        'label': (i + 1).toString(),
        'value': 8 + (i % 5) * 2 + (i ~/ 7),
      });
    } else {
      return [
        {'label': 'Jul', 'value': 45},
        {'label': 'Aug', 'value': 52},
        {'label': 'Sep', 'value': 48},
        {'label': 'Oct', 'value': 58},
        {'label': 'Nov', 'value': 55},
        {'label': 'Dec', 'value': 62},
      ];
    }
  }

  // Recent Activity Feed - Admin specific events
  Widget _buildRecentActivity(BuildContext context) {
    final activities = [
      _ActivityItem(
        icon: Icons.person_add_outlined,
        title: 'New user signed up',
        subtitle: 'john.doe@example.com',
        time: '15 min ago',
        color: const Color(0xFF43E97B),
      ),
      _ActivityItem(
        icon: Icons.bug_report_outlined,
        title: 'Bug report status changed',
        subtitle: 'Issue #127: Login bug marked as resolved',
        time: '1 hour ago',
        color: const Color(0xFFFF9A9E),
      ),
      _ActivityItem(
        icon: Icons.person_add_outlined,
        title: 'New user signed up',
        subtitle: 'jane.smith@example.com',
        time: '2 hours ago',
        color: const Color(0xFF43E97B),
      ),
      _ActivityItem(
        icon: Icons.gavel_outlined,
        title: 'Account appeal received',
        subtitle: 'User requested account reactivation',
        time: '3 hours ago',
        color: const Color(0xFF667EEA),
      ),
      _ActivityItem(
        icon: Icons.bug_report_outlined,
        title: 'Bug report status changed',
        subtitle: 'Issue #125: Dashboard layout fixed',
        time: '5 hours ago',
        color: const Color(0xFFFF9A9E),
      ),
      _ActivityItem(
        icon: Icons.check_circle_outline,
        title: 'Account appeal approved',
        subtitle: 'User account successfully reactivated',
        time: '6 hours ago',
        color: const Color(0xFF667EEA),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E1E),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: activities.length > 5 ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
            itemCount: activities.length > 5 ? 5 : activities.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activity.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(activity.icon, size: 20, color: activity.color),
                ),
                title: Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                subtitle: Text(
                  activity.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                trailing: Text(
                  activity.time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


}

// Helper class for activity items
class _ActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });
}