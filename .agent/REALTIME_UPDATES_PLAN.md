# Real-Time Updates Implementation Plan

## Current Status

### ✅ Already Implemented:
1. **Project Detail Page**: Already uses `StreamBuilder` for real-time ticket updates (line 620)
2. **Home Page KPI Cards**: Already uses streams for tickets and calculates KPIs in real-time
3. **Home Page Calendar**: Already uses streams for tickets via `_subscribeToTicketsStream()`

### ❌ Needs Implementation:
1. **Calendar Dialog**: Currently uses `Future` to load tickets once, needs to use `Stream` for real-time updates

## Implementation Tasks

### Task 1: Update Calendar Dialog to Use Streams
**File**: `lib/features/projects/widgets/calendar_dialog.dart`

**Changes**:
1. Replace `_loadTickets()` Future method with a Stream subscription
2. Use `StreamBuilder` or `setState` with stream listener
3. Update calendar markers when tickets change
4. Dispose stream subscription properly

**Benefits**:
- Calendar updates automatically when ticket status changes
- Calendar updates when new tickets are added/deleted
- Calendar markers reflect current ticket status in real-time

### Task 2: Verify Home Page Real-Time Updates
**File**: `lib/core/views/home_page.dart`

**Status**: Already implemented!
- Uses `_subscribeToTicketsStream()` to listen to all project tickets
- Calculates KPIs in `_processTicketUpdates()` method
- Updates calendar data in real-time via `_ticketsByDate`

## Testing Plan

### Test 1: Ticket Status Change Real-Time Update
1. Open project detail page
2. Open calendar dialog
3. Change ticket status (e.g., To-Do → In Progress)
4. **Expected**: 
   - Kanban board updates immediately ✅ (already working)
   - Calendar dialog marker color changes immediately ✅ (will work after fix)
   - Home page KPI cards update ✅ (already working)
   - Home page calendar updates ✅ (already working)

### Test 2: New Ticket Real-Time Update
1. Open home page
2. Add a new ticket to a project
3. **Expected**:
   - Home page "Pending Tasks" count increases ✅
   - Calendar shows new deadline marker ✅
   - Project detail page shows new ticket ✅

### Test 3: Ticket Deletion Real-Time Update
1. Open calendar dialog
2. Delete a ticket
3. **Expected**:
   - Calendar marker disappears ✅
   - KPI cards update ✅

## Implementation Details

### Calendar Dialog Stream Implementation

```dart
class _CalendarDialogState extends State<CalendarDialog> {
  final ProjectManager _projectManager = ProjectManager();
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  DateTime? _selectedDay;
  StreamSubscription<List<Ticket>>? _ticketsSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToTickets();
  }

  void _subscribeToTickets() {
    // Get all projects and listen to their tickets
    _projectManager.listenToProjects().listen((projects) {
      // Combine all tickets from all projects
      final allTickets = <Ticket>[];
      for (final project in projects) {
        _projectManager.listenToProjectTickets(project.id).listen((tickets) {
          // Update tickets list
          setState(() {
            _tickets = allTickets + tickets;
            _isLoading = false;
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _ticketsSubscription?.cancel();
    super.dispose();
  }
}
```

## Summary

- **Project Detail Page**: ✅ Already has real-time updates
- **Home Page KPIs**: ✅ Already has real-time updates
- **Home Page Calendar**: ✅ Already has real-time updates
- **Calendar Dialog**: ❌ Needs to be updated to use streams

Only the Calendar Dialog needs to be updated for full real-time functionality!
