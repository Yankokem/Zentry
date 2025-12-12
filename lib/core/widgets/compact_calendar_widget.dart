import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TicketStatus {
  pending,
  done,
  late,
  inReview,
}

class DateTicket {
  final String title;
  final TicketStatus status;
  final DateTime deadline;
  final String ticketId;
  final String projectName;
  final String projectId;

  DateTicket({
    required this.title,
    required this.status,
    required this.deadline,
    required this.ticketId,
    required this.projectName,
    required this.projectId,
  });
}

class CompactCalendarWidget extends StatefulWidget {
  final Function(DateTime)? onDateSelected;
  final Map<DateTime, List<DateTicket>>? ticketsByDate;
  final Set<DateTime>? markedDates; // Deprecated, kept for compatibility

  const CompactCalendarWidget({
    super.key,
    this.onDateSelected,
    this.ticketsByDate,
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

  List<DateTicket> _getTicketsForDate(DateTime date) {
    if (widget.ticketsByDate == null || date.year == 0) return [];

    final dateKey = widget.ticketsByDate!.keys.firstWhere(
      (key) => _isSameDay(key, date),
      orElse: () => DateTime(0),
    );

    return dateKey.year != 0 ? widget.ticketsByDate![dateKey] ?? [] : [];
  }

  void _showTicketsDialog(DateTime date, List<DateTicket> tickets) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          DateFormat('MMMM d, yyyy').format(date),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: tickets.map((ticket) {
              Color statusColor;
              String statusText;

              switch (ticket.status) {
                case TicketStatus.pending:
                  statusColor = Colors.orange;
                  statusText = 'Pending';
                  break;
                case TicketStatus.done:
                  statusColor = Colors.green;
                  statusText = 'Done';
                  break;
                case TicketStatus.late:
                  statusColor = Colors.red;
                  statusText = 'Late';
                  break;
                case TicketStatus.inReview:
                  statusColor = Colors.purple;
                  statusText = 'In Review';
                  break;
              }

              final deadlineTime = DateFormat('h:mm a').format(ticket.deadline);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.confirmation_number_outlined,
                                size: 11,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ticket.ticketId,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.schedule,
                                size: 11,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                deadlineTime,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.folder_outlined,
                                size: 11,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  ticket.projectName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.orange, 'Pending'),
              const SizedBox(width: 12),
              _buildLegendItem(Colors.green, 'Done'),
              const SizedBox(width: 12),
              _buildLegendItem(Colors.purple, 'In Review'),
              const SizedBox(width: 12),
              _buildLegendItem(Colors.red, 'Late'),
            ],
          ),
          const SizedBox(height: 12),
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
                final tickets = _getTicketsForDate(date);
                final hasTickets = tickets.isNotEmpty;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    widget.onDateSelected?.call(date);

                    // Show popup if there are tickets
                    if (hasTickets) {
                      _showTicketsDialog(date, tickets);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : isToday && !hasTickets
                              ? Theme.of(context).primaryColor.withOpacity(0.15)
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
                        if (hasTickets)
                          Positioned(
                            bottom: 2,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: _buildStatusDots(tickets, isSelected),
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

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStatusDots(List<DateTicket> tickets, bool isSelected) {
    // Group tickets by status
    final hasPending = tickets.any((t) => t.status == TicketStatus.pending);
    final hasDone = tickets.any((t) => t.status == TicketStatus.done);
    final hasInReview = tickets.any((t) => t.status == TicketStatus.inReview);
    final hasLate = tickets.any((t) => t.status == TicketStatus.late);

    final dots = <Widget>[];

    if (hasPending) {
      dots.add(_buildDot(Colors.orange, isSelected));
    }
    if (hasDone) {
      dots.add(_buildDot(Colors.green, isSelected));
    }
    if (hasInReview) {
      dots.add(_buildDot(Colors.purple, isSelected));
    }
    if (hasLate) {
      dots.add(_buildDot(Colors.red, isSelected));
    }

    // Add spacing between dots
    final spacedDots = <Widget>[];
    for (int i = 0; i < dots.length; i++) {
      spacedDots.add(dots[i]);
      if (i < dots.length - 1) {
        spacedDots.add(const SizedBox(width: 3));
      }
    }

    return spacedDots;
  }

  Widget _buildDot(Color color, bool isSelected) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
