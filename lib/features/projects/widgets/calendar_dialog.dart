import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:zentry/features/projects/projects.dart';

class CalendarDialog extends StatefulWidget {
  const CalendarDialog({super.key});

  @override
  State<CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<CalendarDialog> {
  final ProjectManager _projectManager = ProjectManager();
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      // Load tickets asynchronously from ProjectManager
      final tickets = await _projectManager.getTickets();
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error silently for now
    }
  }

  // Get dates that have ticket deadlines
  Set<DateTime> _getDeadlineDates() {
    final Set<DateTime> dates = {};
    for (final ticket in _tickets) {
      if (ticket.deadline != null) {
        final date = DateTime(
          ticket.deadline!.year,
          ticket.deadline!.month,
          ticket.deadline!.day,
        );
        dates.add(date);
      }
    }
    return dates;
  }

  // Get tickets that have deadlines on a specific date
  List<Ticket> _getTicketsForDate(DateTime date) {
    return _tickets.where((ticket) {
      return ticket.deadline != null &&
             ticket.deadline!.year == date.year &&
             ticket.deadline!.month == date.month &&
             ticket.deadline!.day == date.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final deadlineDates = _getDeadlineDates();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ticket Deadlines',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: DateTime.now(),
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                  });
                },
                eventLoader: (day) {
                  final date = DateTime(day.year, day.month, day.day);
                  return deadlineDates.contains(date) ? ['deadline'] : [];
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      // Get tickets for this date
                      final ticketsForDate = _getTicketsForDate(date);
                      if (ticketsForDate.isEmpty) return null;
                      
                      // Determine marker color based on ticket status and deadline
                      Color markerColor = Colors.grey; // Default for pending
                      
                      // Check if any ticket is late (past deadline and not in review or done)
                      final now = DateTime.now();
                      final isLate = ticketsForDate.any((ticket) {
                        if (ticket.deadline == null) return false;
                        final isPastDeadline = ticket.deadline!.isBefore(now);
                        final isNotCompleted = ticket.status != 'in_review' && ticket.status != 'done';
                        return isPastDeadline && isNotCompleted;
                      });
                      
                      if (isLate) {
                        markerColor = Colors.red; // Late
                      } else {
                        // Check status priority: done > in_review > pending
                        final hasDone = ticketsForDate.any((t) => t.status == 'done');
                        final hasInReview = ticketsForDate.any((t) => t.status == 'in_review');
                        
                        if (hasDone) {
                          markerColor = Colors.green; // Done
                        } else if (hasInReview) {
                          markerColor = Colors.purple; // In Review
                        } else {
                          markerColor = Colors.grey; // Pending (todo or in_progress)
                        }
                      }
                      
                      return Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: markerColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem(Colors.grey, 'Pending (To-Do / In Progress)'),
                const SizedBox(height: 4),
                _buildLegendItem(Colors.purple, 'In Review'),
                const SizedBox(height: 4),
                _buildLegendItem(Colors.green, 'Done'),
                const SizedBox(height: 4),
                _buildLegendItem(Colors.red, 'Late (Past Deadline)'),
              ],
            ),
            if (_selectedDay != null) ...[
              const SizedBox(height: 16),
              Text(
                'Tickets due on ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ..._getTicketsForDate(_selectedDay!).map((ticket) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(ticket.title),
                      subtitle: Text(ticket.description),
                      trailing: Text(
                        'Status: ${ticket.status}',
                        style: TextStyle(
                          color: ticket.status == 'done' ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  )),
              if (_getTicketsForDate(_selectedDay!).isEmpty)
                Text(
                  'No tickets due on this date.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
              ),
        ),
      ],
    );
  }
}
