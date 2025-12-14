# Implementation Summary - Ticket & Project Updates

## ✅ COMPLETED

### 1. Created ProjectNotificationService
- **File**: `lib/features/projects/services/project_notification_service.dart`
- **Features**:
  - `notifyPMTicketReady()` - Notifies PM when assignee marks done or submits for review
  - `notifyAssigneeStatusChanged()` - Notifies assignees when PM changes ticket status
  - `notifyLastAssignee()` - Notifies the last remaining assignee
- **Exported** in `lib/features/projects/projects.dart`

### 2. Added ProjectNotificationService to ProjectDetailPage
- **File**: `lib/features/projects/views/project_detail_page.dart`
- Added instance variable for notification service

## 🔄 IN PROGRESS - REMAINING TASKS

### Task 1: Convert to Real-Time Updates (StreamBuilder)
**File**: `lib/features/projects/views/project_detail_page.dart`

**Changes Needed**:
1. Replace `_buildKanbanColumn` method signature:
   - FROM: `Future<List<Ticket>> ticketsFuture`
   - TO: Use `StreamBuilder` with `_projectManager.listenToProjectTickets(widget.project.id)`

2. Filter tickets by status in the stream
3. Replace both FutureBuilder instances with StreamBuilder

**Code Pattern**:
```dart
StreamBuilder<List<Ticket>>(
  stream: _projectManager.listenToProjectTickets(widget.project.id),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    final allTickets = snapshot.data ?? [];
    final tickets = allTickets.where((t) => t.status == status).toList();
    // ... rest of UI
  }
)
```

### Task 2: Integrate Notifications - Mark as Done
**File**: `lib/features/projects/views/project_detail_page.dart`
**Location**: Lines ~1261-1283 and ~1648-1673

**Add After Update**:
```dart
// Send notification to PM
await _notificationService.notifyPMTicketReady(
  ticket: updatedTicket,
  project: widget.project,
  action: 'marked_done',
);

// Check if this is the last assignee
final remainingAssignees = updatedTicket.assignedTo
    .where((email) => !updatedTicket.membersDone.contains(email))
    .toList();

if (remainingAssignees.length == 1) {
  await _notificationService.notifyLastAssignee(
    ticket: updatedTicket,
    project: widget.project,
    lastAssigneeEmail: remainingAssignees.first,
  );
}
```

### Task 3: Integrate Notifications - Submit for Review
**File**: `lib/features/projects/views/project_detail_page.dart`
**Location**: Lines ~1699-1724

**Add After Update**:
```dart
// Send notification to PM
await _notificationService.notifyPMTicketReady(
  ticket: updatedTicket,
  project: widget.project,
  action: 'submitted_review',
);
```

### Task 4: Update Status Change Button
**File**: `lib/features/projects/views/project_detail_page.dart`
**Location**: Lines ~1610-1636

**Changes**:
1. Remove the conditional disable logic for todo/in_progress
2. Change button label to always say "Change Status"
3. Keep button always enabled for PM

**Replace**:
```dart
Expanded(
  child: ElevatedButton.icon(
    onPressed: () {
      Navigator.pop(context);
      _showChangeStatusDialog(ticket);
    },
    icon: const Icon(Icons.change_circle_outlined),
    label: const Text('Change Status'),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),
```

### Task 5: Create Status Change Dialog with Confirmations
**File**: `lib/features/projects/views/project_detail_page.dart`

**Add New Method** (after _buildActionButtons):
```dart
void _showChangeStatusDialog(Ticket ticket) async {
  final statuses = ['todo', 'in_progress', 'in_review', 'done'];
  
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Change Ticket Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 16),
          ...statuses.map((status) {
            final isCurrentStatus = ticket.status == status;
            return ListTile(
              leading: _getStatusIcon(status),
              title: Text(_formatStatus(status)),
              trailing: isCurrentStatus ? const Icon(Icons.check) : null,
              onTap: isCurrentStatus
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await _handleStatusChange(ticket, status);
                    },
            );
          }),
        ],
      ),
    ),
  );
}

Future<void> _handleStatusChange(Ticket ticket, String newStatus) async {
  final oldStatus = ticket.status;
  
  // Show confirmation for specific transitions
  if (ticket.status == 'in_review') {
    if (newStatus == 'done') {
      // Confirm moving to Done
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mark as Done?'),
          content: const Text(
            'When a ticket is marked as done, you cannot change its status or edit it anymore. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Mark as Done'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
    } else if (newStatus == 'todo' || newStatus == 'in_progress') {
      // Confirm reverting to previous status
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Revert Status?'),
          content: Text(
            'Are you sure you want to bring this ticket back to ${_formatStatus(newStatus)}? You can still edit the ticket as long as it\'s not marked as Done.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Revert Status'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
    }
  }
  
  // Update ticket status
  final updatedTicket = ticket.copyWith(status: newStatus);
  await _projectManager.updateTicket(
    ticket.projectId,
    ticket.ticketNumber,
    updatedTicket,
  );
  
  // Send notifications to assignees
  await _notificationService.notifyAssigneeStatusChanged(
    ticket: updatedTicket,
    project: widget.project,
    oldStatus: oldStatus,
    newStatus: newStatus,
  );
  
  _refreshTickets();
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Ticket status changed to ${_formatStatus(newStatus)}'),
      backgroundColor: Colors.green,
    ),
  );
}

Icon _getStatusIcon(String status) {
  switch (status) {
    case 'todo':
      return const Icon(Icons.circle_outlined, color: Colors.grey);
    case 'in_progress':
      return const Icon(Icons.play_arrow, color: Colors.orange);
    case 'in_review':
      return const Icon(Icons.visibility, color: Colors.purple);
    case 'done':
      return const Icon(Icons.check_circle, color: Colors.green);
    default:
      return const Icon(Icons.circle);
  }
}
```

### Task 6: Disable Editing for Done Tickets
**File**: `lib/features/projects/views/project_detail_page.dart`
**Location**: Lines ~1590-1607 (Edit Ticket button)

**Modify**:
```dart
Expanded(
  child: ElevatedButton.icon(
    onPressed: ticket.status == 'done'
        ? null
        : () {
            Navigator.pop(context);
            _navigateToEditTicketPage(ticket);
          },
    icon: const Icon(Icons.edit),
    label: const Text('Edit Ticket'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1E1E1E),
      disabledBackgroundColor: Colors.grey.shade300,
      disabledForegroundColor: Colors.grey.shade600,
      elevation: 0,
      side: BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),
```

### Task 7: Fix Project Card Ticket Count
**File**: `lib/features/projects/widgets/project_card.dart`
**Location**: Lines ~794-800

**Current Code**:
```dart
Text(
  '${widget.project.completedTickets}/${widget.project.totalTickets} tickets',
  ...
),
```

**Replace With StreamBuilder**:
```dart
StreamBuilder<List<Ticket>>(
  stream: ProjectManager().listenToProjectTickets(widget.project.id),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final tickets = snapshot.data!;
      final doneCount = tickets.where((t) => t.status == 'done').length;
      final totalCount = tickets.length;
      return Text(
        '$doneCount/$totalCount tickets',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return Text(
      '${widget.project.completedTickets}/${widget.project.totalTickets} tickets',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.bold,
      ),
    );
  },
)
```

## 📝 TESTING CHECKLIST

After implementing all changes:

- [ ] PM receives notification when assignee marks ticket as done
- [ ] PM receives notification when assignee submits for review
- [ ] Assignee receives notification when PM changes ticket status
- [ ] Last assignee receives notification when they're the only one left
- [ ] Tickets update in real-time without manual refresh
- [ ] Project card shows correct ticket count (X/Y)
- [ ] "Change Status" button always visible and enabled for PM
- [ ] Confirmation dialog shows when PM marks ticket as Done
- [ ] Confirmation dialog shows when PM reverts ticket from In Review
- [ ] Cannot edit ticket when status is Done
- [ ] Can edit ticket when status is not Done

## 🚀 NEXT STEPS

1. Implement real-time updates (StreamBuilder)
2. Add notification calls to Mark as Done handlers
3. Add notification call to Submit for Review handler
4. Update Status Change button UI
5. Create _showChangeStatusDialog method
6. Disable editing for Done tickets
7. Fix project card ticket count
8. Test all functionality
