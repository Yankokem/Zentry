import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:zentry/features/admin/admin.dart';
import 'package:zentry/features/admin/widgets/skeleton_loader.dart';

class AdminOverviewPage extends StatefulWidget {
  const AdminOverviewPage({super.key});

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Services - initialized once
  late final BugReportService _bugReportService = BugReportService();
  late final AccountAppealService _appealService = AccountAppealService();
  late final AdminAnalyticsService _analyticsService = AdminAnalyticsService();
  
  // Activity chart filters
  String _activityInterval = 'Monthly'; // Daily, Weekly, Monthly
  String _activityType = 'All'; // All, Projects, Journal, Wishlist
  
  // User sign-ups filters
  String _signupPeriod = 'Last 7 Days'; // Last 7 Days, Last 30 Days, Last 3 Months, Custom
  
  // Real-time data for charts
  Map<String, List<Map<String, dynamic>>> _activityData = {};
  List<Map<String, dynamic>> _signupData = [];
  bool _isLoadingActivity = true;
  bool _isLoadingSignups = true;

  @override
  void initState() {
    super.initState();
    _loadActivityData();
    _loadSignupData();
  }

  Future<void> _loadActivityData() async {
    setState(() => _isLoadingActivity = true);
    try {
      final data = await _analyticsService.getActivityData(
        interval: _activityInterval,
        activityType: _activityType,
      );
      if (mounted) {
        setState(() {
          _activityData = data;
          _isLoadingActivity = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingActivity = false);
      }
    }
  }

  Future<void> _loadSignupData() async {
    setState(() => _isLoadingSignups = true);
    try {
      final data = await _analyticsService.getSignupTrendData(_signupPeriod);
      if (mounted) {
        setState(() {
          _signupData = data;
          _isLoadingSignups = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSignups = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
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
            // Support Stats Section
            _buildSupportStats(context, isTablet),
            const SizedBox(height: 24),

            // User Activity Chart (Projects, Journal, Wishlist)
            _buildUserActivityChart(context, isTablet),
            const SizedBox(height: 24),

            // System Health Overview
            _buildSystemHealth(context, isTablet),
            const SizedBox(height: 24),

            // User Sign-ups Trend
            _buildSignupTrendChart(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Support Stats - Shows Bug Reports and Account Appeals
  Widget _buildSupportStats(BuildContext context, bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<List<BugReportModel>>(
            stream: _bugReportService.getBugReportsStream(),
            builder: (context, snapshot) {
              // Show skeleton while loading or if there's an error
              if (snapshot.connectionState == ConnectionState.waiting || snapshot.hasError) {
                return const SkeletonStatCard();
              }
              
              final allReports = snapshot.data ?? [];
              final open = allReports.where((r) => r.status == 'Open').length;
              final inProgress = allReports.where((r) => r.status == 'In Progress').length;
              final totalActive = open + inProgress;
              
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.bug_report_rounded, 
                            color: Colors.red.shade600, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Bug Reports',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$totalActive',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$open open, $inProgress in progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<List<AccountAppealModel>>(
            stream: _appealService.getAppealsStream(),
            builder: (context, snapshot) {
              // Show skeleton while loading or if there's an error
              if (snapshot.connectionState == ConnectionState.waiting || snapshot.hasError) {
                return const SkeletonStatCard();
              }
              
              final allAppeals = snapshot.data ?? [];
              final pending = allAppeals.where((a) => a.status == 'Pending').length;
              
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.security_rounded, 
                            color: Colors.orange.shade600, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Pending Appeals',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$pending',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Awaiting review',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
                        _loadActivityData();
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
                        _loadActivityData();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Chart
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildActivityBarChart(),
          ),
          // Chart label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Center(
              child: Text(
                _analyticsService.getActivityChartLabel(_activityInterval),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBarChart() {
    if (_isLoadingActivity) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Convert real data to chart format
    final data = _convertActivityDataForChart();
    
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

  List<Map<String, dynamic>> _convertActivityDataForChart() {
    final projects = _activityData['projects'] ?? [];
    final journal = _activityData['journal'] ?? [];
    final wishlist = _activityData['wishlist'] ?? [];

    final result = <Map<String, dynamic>>[];
    final maxLength = [projects.length, journal.length, wishlist.length].reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < maxLength; i++) {
      result.add({
        'label': i < projects.length ? projects[i]['label'] : '',
        'projects': i < projects.length ? projects[i]['value'] : 0,
        'journal': i < journal.length ? journal[i]['value'] : 0,
        'wishlist': i < wishlist.length ? wishlist[i]['value'] : 0,
      });
    }

    return result;
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

      if (_activityType == 'All') {
        stackItems = [
          BarChartRodStackItem(0, projects, const Color(0xFF667EEA)),
          BarChartRodStackItem(projects, projects + journal, const Color(0xFF4FACFE)),
          BarChartRodStackItem(projects + journal, projects + journal + wishlist, const Color(0xFF43E97B)),
        ];
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
                StreamBuilder<int>(
                  stream: _analyticsService.getTotalUsersCountStream(),
                  builder: (context, totalSnapshot) {
                    return FutureBuilder<int>(
                      future: _analyticsService.getNewUsersThisWeek(),
                      builder: (context, weekSnapshot) {
                        final total = totalSnapshot.data ?? 0;
                        final thisWeek = weekSnapshot.data ?? 0;
                        return _buildHealthMetric(
                          'Total Users',
                          '$total',
                          '+$thisWeek this week',
                          Icons.people_outline,
                          Colors.green,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                StreamBuilder<int>(
                  stream: _analyticsService.getActiveUsersCountStream(),
                  builder: (context, activeSnapshot) {
                    return StreamBuilder<int>(
                      stream: _analyticsService.getTotalUsersCountStream(),
                      builder: (context, totalSnapshot) {
                        final active = activeSnapshot.data ?? 0;
                        final total = totalSnapshot.data ?? 1;
                        final percentage = total > 0 ? ((active / total) * 100).toInt() : 0;
                        return _buildHealthMetric(
                          'Active Users',
                          '$active',
                          '$percentage% active (7 days)',
                          Icons.wifi_rounded,
                          Colors.blue,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<BugReportModel>>(
                  stream: _bugReportService.getBugReportsStream(),
                  builder: (context, snapshot) {
                    final reports = snapshot.data ?? [];
                    final open = reports.where((r) => r.status == 'Open').length;
                    final closed = reports.where((r) => r.status == 'Closed').length;
                    return _buildHealthMetric(
                      'Bug Reports',
                      '${reports.length}',
                      '$open open, $closed closed',
                      Icons.bug_report_outlined,
                      Colors.orange,
                    );
                  },
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
                    } else {
                      _loadSignupData();
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
    if (_isLoadingSignups) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_signupData.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('No signup data available')),
      );
    }
    
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
                  if (value.toInt() >= 0 && value.toInt() < _signupData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _signupData[value.toInt()]['label'],
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
              spots: _signupData.asMap().entries.map((e) {
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
}
