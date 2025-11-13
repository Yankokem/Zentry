# TODO: Add Pin Feature for Projects

## Steps to Complete:
- [x] Add `isPinned` field to `Project` model in `lib/models/project_model.dart`
- [x] Update `ProjectManager` to include pin/unpin methods in `lib/services/project_manager.dart`
- [x] Update `FirestoreService` to handle pinning in `lib/services/firebase/firestore_service.dart`
- [x] Modify `ProjectsPage` to sort pinned projects first in `lib/views/home/projects_page.dart`
- [x] Add pin/unpin button to `ProjectCard` in `lib/widgets/home/project_card.dart`
- [x] Test the pin functionality
