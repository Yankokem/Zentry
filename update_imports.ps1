# PowerShell script to update all import statements to use new feature-based barrel files

$rootPath = "c:\Users\kayem\Zentry\lib"

# Define replacement patterns
$replacements = @(
    # Projects feature imports
    @{ Pattern = "import 'package:zentry/models/project_model.dart';"; Replacement = "// Projects barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/models/ticket_model.dart';"; Replacement = "// Projects barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/models/task_model.dart';"; Replacement = "// Projects barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/models/project_role_model.dart';"; Replacement = "// Projects barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/services/project_manager.dart';"; Replacement = "// Projects barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/services/task_manager.dart';"; Replacement = "// Projects barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/widgets/home/project_card.dart';"; Replacement = "// Projects barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/widgets/home/ticket_card.dart';"; Replacement = "// Projects barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/widgets/home/ticket_dialogs.dart';"; Replacement = "// Projects barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/views/home/projects_page.dart';"; Replacement = "// Projects barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/views/home/project_detail_page.dart';"; Replacement = "// Projects barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/views/home/add_project_page.dart';"; Replacement = "// Projects barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/views/home/add_ticket_page.dart';"; Replacement = "// Projects barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/views/home/edit_ticket_page.dart';"; Replacement = "// Projects barrel import - see top of file" }
    
    # Journal feature imports
    @{ Pattern = "import 'package:zentry/models/journal_entry_model.dart';"; Replacement = "// Journal barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/models/mood_model.dart';"; Replacement = "// Journal barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/services/journal_manager.dart';"; Replacement = "// Journal barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/services/firebase/journal_service.dart';"; Replacement = "// Journal barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/services/firebase/mood_service.dart';"; Replacement = "// Journal barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/views/home/journal_page.dart';"; Replacement = "// Journal barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/views/home/add_journal_screen.dart';"; Replacement = "// Journal barrel import - see top of file" }
    
    # Wishlist feature imports
    @{ Pattern = "import 'package:zentry/models/wish_model.dart';"; Replacement = "// Wishlist barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/models/category_model.dart';"; Replacement = "// Wishlist barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/services/wishlist_manager.dart';"; Replacement = "// Wishlist barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/controllers/wishlist_controller.dart';"; Replacement = "// Wishlist barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/widgets/home/wish_card.dart';"; Replacement = "// Wishlist barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/views/home/wishlist_page.dart';"; Replacement = "// Wishlist barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/views/home/add_wishlist_screen.dart';"; Replacement = "// Wishlist barrel import - see top of file" }
    
    # Admin feature imports
    @{ Pattern = "import 'package:zentry/models/bug_report_model.dart';"; Replacement = "// Admin barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/services/firebase/bug_report_service.dart';"; Replacement = "// Admin barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/views/admin/admin_dashboard.dart';"; Replacement = "// Admin barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/views/admin/admin_overview.dart';"; Replacement = "// Admin barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/views/admin/admin_accounts.dart';"; Replacement = "// Admin barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/views/admin/admin_bug_reports.dart';"; Replacement = "// Admin barrel import - see top of file" }
    
    # Auth feature imports
    @{ Pattern = "import 'package:zentry/auth/login_screen.dart';"; Replacement = "// Auth barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/auth/signup_screen.dart';"; Replacement = "// Auth barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/auth/controllers/login_controller.dart';"; Replacement = "// Auth barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/auth/controllers/signup_controller.dart';"; Replacement = "// Auth barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/auth/controllers/google_signin_controller.dart';"; Replacement = "// Auth barrel import - see top of file" }
    
    # Profile feature imports
    @{ Pattern = "import 'package:zentry/views/profile/profile_screen.dart';"; Replacement = "// Profile barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/views/profile/settings_screen.dart';"; Replacement = "// Profile barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/views/profile/faq_screen.dart';"; Replacement = "// Profile barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/views/profile/contact_support_screen.dart';"; Replacement = "// Profile barrel import - see top of file" }
    
    # Core imports
    @{ Pattern = "import 'package:zentry/config/constants.dart';"; Replacement = "// Core barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/config/routes.dart';"; Replacement = "// Core barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/config/theme.dart';"; Replacement = "// Core barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/services/firebase/auth_service.dart';"; Replacement = "// Core barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/services/firebase/user_service.dart';"; Replacement = "// Core barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/services/firebase/firestore_service.dart';"; Replacement = "// Core barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/models/user_model.dart';"; Replacement = "// Core barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/models/notification_model.dart';"; Replacement = "// Core barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/utils/admin_mode.dart';"; Replacement = "// Core barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/utils/admin_test_data.dart';"; Replacement = "// Core barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/providers/wishlist_provider.dart';"; Replacement = "// Core barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/providers/theme_provider.dart';"; Replacement = "// Core barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/providers/settings_provider.dart';"; Replacement = "// Core barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/providers/notification_provider.dart';"; Replacement = "// Core barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/widgets/common/floating_nav_bar.dart';"; Replacement = "// Core barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/widgets/home/add_menu_widget.dart';"; Replacement = "// Core barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/widgets/home/compact_calendar_widget.dart';"; Replacement = "// Core barrel import - see top of file" }
    @{ Pattern = "import 'package:zentry/views/home/home_page.dart';"; Replacement = "// Core barrel import - see top of file" }
    @{ Pattern = "import '../controllers/wishlist_controller.dart';"; Replacement = "import 'package:zentry/features/wishlist/wishlist.dart';" }
)

# Get all Dart files
$dartFiles = Get-ChildItem -Path $rootPath -Filter "*.dart" -Recurse

Write-Host "Found $($dartFiles.Count) Dart files to process"

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    $modified = $false
    
    foreach ($replacement in $replacements) {
        if ($content -match [regex]::Escape($replacement.Pattern)) {
            $content = $content -replace [regex]::Escape($replacement.Pattern), $replacement.Replacement
            $modified = $true
        }
    }
    
    if ($modified) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "Updated: $($file.FullName)"
    }
}

Write-Host "`nImport replacement complete. Remember to add barrel imports at the top of each affected file:"
Write-Host "import 'package:zentry/core/core.dart';"
Write-Host "import 'package:zentry/features/projects/projects.dart';"
Write-Host "import 'package:zentry/features/journal/journal.dart';"
Write-Host "import 'package:zentry/features/wishlist/wishlist.dart';"
Write-Host "import 'package:zentry/features/admin/admin.dart';"
Write-Host "import 'package:zentry/features/auth/auth.dart';"
Write-Host "import 'package:zentry/features/profile/profile.dart';"
