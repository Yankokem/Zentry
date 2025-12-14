# 🔧 FIX: In Progress Status Change Issue

## Problem
When a ticket was moved from **To-Do** to **In Progress** by the PM, the `membersDone` array was not being cleared. This meant:

1. Assignees mark ticket as done in To-Do status → `membersDone` = [all assignees]
2. PM moves ticket to In Progress → `membersDone` still = [all assignees]
3. `allAssigneesDone` = true (because membersDone.length == assignedTo.length)
4. PM could immediately change status again WITHOUT assignees submitting for review ❌

## Root Cause
The `membersDone` array tracks which assignees have completed their part. When PM moved a ticket from To-Do to In Progress, this array wasn't being reset, so the system thought assignees had already submitted for review.

## Solution
Added logic to reset `membersDone` when PM moves ticket from **To-Do** to **In Progress**.

### Code Change
**File**: `lib/features/projects/views/project_detail_page.dart`

```dart
// Reset membersDone in these cases:
// 1. Reverting from In Review to To-Do or In Progress
// 2. Moving from To-Do to In Progress (assignees must submit for review again)
if ((oldStatus == 'in_review' && (newStatus == 'todo' || newStatus == 'in_progress')) ||
    (oldStatus == 'todo' && newStatus == 'in_progress')) {
  updatedTicket = ticket.copyWith(
    status: newStatus,
    membersDone: [], // Reset so assignees must mark as done/submit for review again
  );
} else {
  updatedTicket = ticket.copyWith(status: newStatus);
}
```

## How It Works Now

### Workflow:
1. **To-Do Status**:
   - Assignees mark as done → added to `membersDone`
   - When all assignees mark as done → `allAssigneesDone` = true
   - PM can now move to In Progress

2. **PM Moves To-Do → In Progress**:
   - `membersDone` is **reset to []** ✅
   - `allAssigneesDone` = false
   - PM's "Change Status" button is **disabled** ✅

3. **In Progress Status**:
   - Assignees must "Submit for Review" → added to `membersDone` again
   - When all assignees submit → `allAssigneesDone` = true
   - PM can now move to In Review ✅

4. **PM Moves In Progress → In Review**:
   - `membersDone` is preserved (no reset needed)
   - Ticket is now in review

5. **PM Reverts In Review → To-Do/In Progress**:
   - `membersDone` is **reset to []** ✅
   - Assignees must mark as done/submit for review again

## Testing

### Test Case 1: To-Do → In Progress Reset
1. Create ticket in To-Do
2. As assignee, mark as done
3. As PM, move to In Progress
4. Verify PM's "Change Status" button is **disabled**
5. As assignee, verify you need to "Submit for Review" again
6. As assignee, submit for review
7. As PM, verify "Change Status" button is now **enabled**

### Test Case 2: In Review → In Progress Reset
1. Move ticket to In Review
2. As PM, revert to In Progress
3. Verify PM's "Change Status" button is **disabled**
4. As assignee, verify you need to "Submit for Review" again

## Summary

✅ **Fixed**: PM can no longer change status from In Progress unless assignees submit for review
✅ **Fixed**: `membersDone` is reset when moving To-Do → In Progress
✅ **Fixed**: `membersDone` is reset when reverting from In Review
✅ **Working**: PM must wait for assignees at each stage

## Files Modified
- `lib/features/projects/views/project_detail_page.dart` - Updated `_handleStatusChange` method
