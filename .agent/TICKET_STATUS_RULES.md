# ✅ Ticket Status Rules Implementation - Complete

## Overview
Implemented strict Project Manager (PM) status change rules and updated calendar indicators to reflect ticket status accurately.

## Changes Made

### 1. **PM Status Change Button Logic** 
**File**: `lib/features/projects/views/project_detail_page.dart`

The "Change Status" button is now disabled when:
- Ticket is in **To-Do** status and assignees haven't marked it as done
- Ticket is in **In Progress** status and assignees haven't submitted for review
- Ticket is in **Done** status (cannot be changed)

**Code**:
```dart
onPressed: ticket.status == 'done'
    ? null
    : (ticket.status == 'todo' || ticket.status == 'in_progress') && !ticket.allAssigneesDone
        ? null
        : () {
            Navigator.pop(context);
            _showChangeStatusDialog(ticket);
          },
```

### 2. **Status Change Dialog with Restrictions**
**File**: `lib/features/projects/views/project_detail_page.dart`

Updated `_showChangeStatusDialog` to:
- Disable "In Progress" option when ticket is in To-Do and assignees haven't marked as done
- Disable "In Review" option when ticket is in In Progress and assignees haven't submitted for review
- Show helpful messages explaining why options are disabled

**Rules**:
- **To-Do → In Progress**: Only allowed if `allAssigneesDone` is true
- **In Progress → In Review**: Only allowed if `allAssigneesDone` is true (submitted for review)

### 3. **Reset membersDone When Reverting**
**File**: `lib/features/projects/views/project_detail_page.dart`

When PM reverts a ticket from **In Review** back to **To-Do** or **In Progress**:
- The `membersDone` array is reset to empty `[]`
- Assignees must mark the ticket as done again
- Assignees must submit for review again

**Code**:
```dart
// Reset membersDone if reverting from In Review to To-Do or In Progress
if (oldStatus == 'in_review' && (newStatus == 'todo' || newStatus == 'in_progress')) {
  updatedTicket = ticket.copyWith(
    status: newStatus,
    membersDone: [], // Reset so assignees must mark as done again
  );
} else {
  updatedTicket = ticket.copyWith(status: newStatus);
}
```

### 4. **Calendar Status Indicators**
**File**: `lib/features/projects/widgets/calendar_dialog.dart`

Updated calendar markers to show different colors based on ticket status:

| Color | Status | Condition |
|-------|--------|-----------|
| 🔴 **Red** | Late | Past deadline AND not in review or done |
| 🟢 **Green** | Done | Ticket status is "done" |
| 🟣 **Purple** | In Review | Ticket status is "in_review" |
| ⚪ **Grey** | Pending | Ticket status is "todo" or "in_progress" |

**Priority**: Late > Done > In Review > Pending

**Legend Added**: Shows all color meanings in the calendar dialog

## Status Flow Rules

### For Assignees:
1. **To-Do**: Can mark as "Done" → moves to assignee's personal done list
2. **In Progress**: Can "Submit for Review" → enables PM to move to In Review
3. **In Review**: Cannot change (PM controls)
4. **Done**: Cannot change

### For Project Manager:
1. **To-Do → In Progress**: ❌ Disabled until assignees mark as done
2. **In Progress → In Review**: ❌ Disabled until assignees submit for review
3. **In Review → Done**: ✅ Allowed with confirmation
4. **In Review → To-Do/In Progress**: ✅ Allowed with confirmation + resets membersDone
5. **Done → Any**: ❌ Disabled (final state)

## Testing Checklist

### Test 1: To-Do Status Restrictions
- [ ] Create a ticket in To-Do status
- [ ] As PM, verify "Change Status" button is disabled
- [ ] As assignee, mark ticket as done
- [ ] As PM, verify "Change Status" button is now enabled
- [ ] Click "Change Status" and verify only "In Progress" is available

### Test 2: In Progress Status Restrictions
- [ ] Move ticket to In Progress
- [ ] As PM, verify "Change Status" button is disabled
- [ ] As assignee, click "Submit for Review"
- [ ] As PM, verify "Change Status" button is now enabled
- [ ] Click "Change Status" and verify "In Review" is available

### Test 3: Revert and Reset
- [ ] Move ticket to In Review
- [ ] As PM, revert ticket to In Progress
- [ ] Verify confirmation dialog appears
- [ ] Confirm revert
- [ ] As assignee, verify status shows "Submit for Review" (not marked as done)
- [ ] Verify PM's "Change Status" is disabled again

### Test 4: Calendar Indicators
- [ ] Create tickets with different statuses and deadlines
- [ ] Open calendar dialog
- [ ] Verify grey dots for To-Do/In Progress tickets
- [ ] Verify purple dots for In Review tickets
- [ ] Verify green dots for Done tickets
- [ ] Create a ticket past deadline in To-Do status
- [ ] Verify red dot for late ticket
- [ ] Check legend shows all 4 colors correctly

### Test 5: Done Status Lock
- [ ] Move ticket to Done
- [ ] Verify "Edit" button is disabled
- [ ] Verify "Change Status" button is disabled
- [ ] Verify ticket cannot be modified

## Files Modified

1. `lib/features/projects/views/project_detail_page.dart`
   - Updated Change Status button logic
   - Updated `_showChangeStatusDialog` with restrictions
   - Updated `_handleStatusChange` to reset membersDone

2. `lib/features/projects/widgets/calendar_dialog.dart`
   - Updated marker colors based on status
   - Added legend with all status colors
   - Added `_buildLegendItem` helper method

## Success Criteria ✅

- [x] PM cannot change status from To-Do until assignees mark as done
- [x] PM cannot change status from In Progress until assignees submit for review
- [x] Reverting from In Review resets membersDone
- [x] Calendar shows grey for pending tickets
- [x] Calendar shows purple for in review tickets
- [x] Calendar shows green for done tickets
- [x] Calendar shows red for late tickets
- [x] Legend explains all color meanings

## Notes

- The `allAssigneesDone` property checks if `membersDone.length == assignedTo.length`
- When assignees "Mark as Done", they're added to `membersDone` array
- When assignees "Submit for Review", all assignees are in `membersDone`
- Reverting from In Review clears `membersDone`, requiring assignees to re-submit
- Calendar uses priority system: Late > Done > In Review > Pending
