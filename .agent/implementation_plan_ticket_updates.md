# Ticket and Project Management Updates - Implementation Plan

## Overview
Comprehensive updates to the project and ticket functionality including notifications, real-time updates, UI improvements, and workflow enhancements.

## Requirements

### 1. Notifications for Ticket Actions
- **Assignee → PM Notifications:**
  - When assignee clicks "Mark as Done" (in To-Do status)
  - When assignee clicks "Submit For Review" (in In Progress status)
  - Notify PM that ticket is ready for status change

- **PM → Assignee Notifications:**
  - When PM changes ticket status
  - Inform assignee about their ticket's new status
  
- **Special Case - Last Assignee:**
  - If multiple assignees and only one hasn't marked as done
  - Send notification to that last assignee

### 2. Real-Time Ticket Updates
- Implement StreamBuilder for tickets in project detail page
- Auto-refresh when ticket status changes
- Auto-refresh when assignees mark tickets as done
- Update UI immediately without manual refresh

### 3. Fix Project Card Ticket Count
- Currently showing "0/0 tickets"
- Should show actual count: "X/Y tickets" where:
  - X = number of tickets with status 'done'
  - Y = total number of tickets in project

### 4. UI Updates for Status Change Button
- Always show "Change Status" button for PM (regardless of ticket status)
- Remove "Move To Next Status" text (too long)
- Use consistent "Change Status" label

### 5. PM Status Change Dialogs
- **After In Review → Done:**
  - Show confirmation dialog
  - Warning: "When marked as done, you cannot change status or edit the ticket anymore"
  
- **After In Review → To-Do or In Progress:**
  - Show confirmation dialog
  - Message: "Are you sure you want to bring the ticket to previous status?"
  - Note: Editing allowed as long as status is not "Done"

## Implementation Steps

### Step 1: Create Notification Helper Service
File: `lib/features/projects/services/project_notification_service.dart`
- Method: `notifyPMTicketReady(ticket, project, action)` 
- Method: `notifyAssigneeStatusChanged(ticket, project, oldStatus, newStatus)`
- Method: `notifyLastAssignee(ticket, project, lastAssigneeEmail)`

### Step 2: Update Project Detail Page for Real-Time
File: `lib/features/projects/views/project_detail_page.dart`
- Replace FutureBuilder with StreamBuilder for tickets
- Use `ProjectManager().listenToProjectTickets(projectId)`
- Auto-update on ticket changes

### Step 3: Fix Project Card Ticket Count
File: `lib/features/projects/widgets/project_card.dart`
- Add StreamBuilder to listen to project tickets
- Calculate done vs total tickets in real-time
- Update display text

### Step 4: Update Status Change Button UI
File: `lib/features/projects/views/project_detail_page.dart`
- Change button label to always say "Change Status"
- Remove conditional text "Move to Next Status"
- Keep button always enabled for PM (remove disable logic)

### Step 5: Add PM Confirmation Dialogs
File: `lib/features/projects/views/project_detail_page.dart`
- Create `_showStatusChangeDialog(ticket)` method
- Add confirmation for Done status
- Add confirmation for reverting to previous status
- Disable editing when status is Done

### Step 6: Update Ticket Model (if needed)
File: `lib/features/projects/models/ticket_model.dart`
- Add `isLocked` field (true when status = 'done')
- Or use status check directly

### Step 7: Integrate Notifications
- Update "Mark as Done" handler to send notification
- Update "Submit for Review" handler to send notification
- Update status change handler to send notifications
- Check for last assignee scenario

## Files to Modify

1. **lib/features/projects/services/project_notification_service.dart** (NEW)
2. **lib/features/projects/views/project_detail_page.dart** (MAJOR UPDATE)
3. **lib/features/projects/widgets/project_card.dart** (UPDATE)
4. **lib/features/projects/services/project_manager.dart** (MINOR UPDATE)
5. **lib/core/services/firestore_service.dart** (CHECK - may need ticket count methods)

## Testing Checklist

- [ ] PM receives notification when assignee marks as done
- [ ] PM receives notification when assignee submits for review
- [ ] Assignee receives notification when PM changes status
- [ ] Last assignee receives notification when they're the only one left
- [ ] Tickets update in real-time without refresh
- [ ] Project card shows correct ticket count (X/Y)
- [ ] "Change Status" button always visible for PM
- [ ] Confirmation dialog shows when PM marks ticket as Done
- [ ] Confirmation dialog shows when PM reverts ticket status
- [ ] Cannot edit ticket when status is Done
- [ ] Can edit ticket when status is not Done

## Notes

- Use existing NotificationService for sending notifications
- Leverage existing Firestore listeners for real-time updates
- Maintain backward compatibility with existing data
- Ensure notifications are only sent to relevant users
- Handle edge cases (no assignees, single assignee, etc.)
