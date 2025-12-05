// Projects Feature Barrel File
// This file exports all public APIs from the projects feature

// Views
export 'views/projects_page.dart';
export 'views/project_detail_page.dart';
export 'views/add_project_page.dart';
export 'views/add_ticket_page.dart' hide MultiSelectDialog;
export 'views/edit_ticket_page.dart' hide MultiSelectDialog;
export 'views/tasks_page.dart';

// Models
export 'models/project_model.dart';
export 'models/ticket_model.dart';
export 'models/task_model.dart';
export 'models/project_role_model.dart';

// Services
export 'services/project_manager.dart';
export 'services/task_manager.dart';

// Widgets
export 'widgets/project_card.dart';
export 'widgets/ticket_card.dart';
export 'widgets/task_card.dart';
export 'widgets/ticket_dialogs.dart';
export 'widgets/calendar_dialog.dart';
