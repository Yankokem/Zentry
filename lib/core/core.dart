// Core Barrel File
// This file exports all public core APIs

// Config
export 'config/constants.dart';
export 'config/routes.dart';
export 'config/theme.dart';

// Services
export 'services/firebase/auth_service.dart';
export 'services/firebase/user_service.dart';
export 'services/firebase/firestore_service.dart';
export 'services/firebase/firestore_utils.dart';
export 'services/firebase/firebase_config.dart';
export 'services/firebase/admin_service.dart';
export 'services/notification_service.dart';
export 'services/local/storage_service.dart';
export 'services/cloudinary_service.dart';

// Models
export 'models/user_model.dart';
export 'models/notification_model.dart';

// Utils
export 'utils/date_formatter.dart';
export 'utils/encryption_helper.dart';
export 'utils/helpers.dart';
export 'utils/validators.dart';
export 'utils/admin_mode.dart';
export 'utils/admin_test_data.dart';
export 'utils/user_metadata_initializer.dart';

// Widgets
export 'widgets/floating_nav_bar.dart';
export 'widgets/add_menu_widget.dart';
export 'widgets/stat_card.dart';
export 'widgets/compact_calendar_widget.dart';
export 'widgets/admin_guard.dart';
export 'widgets/skeleton_loader.dart';

// Providers
export 'providers/wishlist_provider.dart';
export 'providers/theme_provider.dart';
export 'providers/settings_provider.dart';
export 'providers/notification_provider.dart';

// Views
export 'views/home_screen.dart';
export 'views/home_page.dart';
export 'views/launch_screen.dart';
