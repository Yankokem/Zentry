import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CompactCalendarWidget extends StatefulWidget {
  final Function(DateTime)? onDateSelected;
  final Set<DateTime>? markedDates;

  const CompactCalendarWidget({
    super.key,
    this.onDateSelected,
    this.markedDates,
  });

  @override
  State<CompactCalendarWidget> createState() => _CompactCalendarWidgetState();
}

class _CompactCalendarWidgetState extends State<CompactCalendarWidget> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final days = <DateTime>[];

    // Add leading empty days
    for (int i = 0; i < firstDay.weekday % 7; i++) {
      days.add(DateTime(0));
    }

    // Add days of the month
    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(month.year, month.month, i));
    }

    return days;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isMarkedDate(DateTime date) {
    if (widget.markedDates == null || date.year == 0) return false;
    return widget.markedDates!.any((marked) => _isSameDay(marked, date));
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(_currentMonth);
    final monthFormat = DateFormat('MMMM yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _previousMonth,
              ),
              Text(
                monthFormat.format(_currentMonth),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Weekday headers
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 7,
              childAspectRatio: 1.1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: days.map((date) {
                if (date.year == 0) {
                  return const SizedBox.shrink();
                }

                final isToday = _isSameDay(date, DateTime.now());
                final isSelected = _isSameDay(date, _selectedDate);
                final isMarked = _isMarkedDate(date);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    widget.onDateSelected?.call(date);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : isToday
                              ? Theme.of(context).primaryColor.withOpacity(0.2)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                      ? Theme.of(context).primaryColor
                                      : const Color(0xFF1E1E1E),
                            ),
                          ),
                        ),
                        if (isMarked)
                          Positioned(
                            right: 5,
                            top: 5,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.red.shade700 : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
