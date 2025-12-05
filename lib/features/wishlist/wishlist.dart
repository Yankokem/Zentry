// Wishlist Feature Barrel File
// This file exports all public APIs from the wishlist feature

// Views
export 'views/wishlist_page.dart';
export 'views/wishlist_screen.dart' hide WishlistPage;
export 'views/add_wishlist_screen.dart';

// Models
export 'models/wish_model.dart';
export 'models/category_model.dart';

// Services
export 'services/wishlist_manager.dart';
export 'services/firebase/wishlist_service.dart';
export 'services/firebase/category_service.dart';

// Controllers
export 'controllers/wishlist_controller.dart';

// Widgets
export 'widgets/wish_card.dart';
