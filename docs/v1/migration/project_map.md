# Project Map — Keystone lib/

Generated from current lib/ structure.
This is the reference file for migration planning.
Never edited manually — only regenerated.

---

## Core

### lib/core/analytics/analytics_constants.dart
**Description:** Global constants and configuration.

**Dependencies:**
- None

**Dependents:**
- lib/features/knowledge_base/presentation/providers/notes_providers.dart
- lib/features/technician_profile/presentation/providers/profile_provider.dart

### lib/core/analytics/ks_analytics.dart
**Description:** Defines the KsAnalytics class.

**Dependencies:**
- package:flutter/foundation.dart
- package:supabase_flutter/supabase_flutter.dart

**Dependents:**
- lib/features/knowledge_base/presentation/providers/notes_providers.dart
- lib/features/technician_profile/presentation/providers/profile_provider.dart

### lib/core/constants/app_constants.dart
**Description:** Global constants and configuration.

**Dependencies:**
- None

**Dependents:**
- lib/features/whatsapp_followup/domain/usecases/build_followup_message_usecase.dart
- lib/features/whatsapp_followup/presentation/providers/follow_up_provider.dart
- lib/features/whatsapp_followup/presentation/widgets/follow_up_button.dart
- lib/features/whatsapp_followup/presentation/widgets/follow_up_message_preview.dart

### lib/core/constants/app_enums.dart
**Description:** Global constants and configuration.

**Dependencies:**
- None

**Dependents:**
- lib/features/auth/presentation/providers/auth_notifier.dart
- lib/features/auth/presentation/screens/onboarding_screen.dart
- lib/features/job_logging/data/models/job_model.dart
- lib/features/job_logging/domain/entities/job_entity.dart
- lib/features/job_logging/domain/usecases/log_job_usecase.dart
- lib/features/job_logging/presentation/providers/job_providers.dart
- lib/features/job_logging/presentation/screens/log_job_screen.dart
- lib/features/job_logging/presentation/widgets/job_card.dart
- lib/features/job_logging/presentation/widgets/service_type_picker.dart
- lib/features/knowledge_base/data/models/knowledge_note_model.dart
- lib/features/knowledge_base/domain/entities/knowledge_note_entity.dart
- lib/features/knowledge_base/domain/usecases/create_note_usecase.dart
- lib/features/knowledge_base/presentation/providers/notes_providers.dart
- lib/features/knowledge_base/presentation/screens/add_note_screen.dart
- lib/features/technician_profile/data/models/profile_model.dart
- lib/features/technician_profile/data/repositories/profile_repository_impl.dart
- lib/features/technician_profile/domain/entities/profile_entity.dart
- lib/features/technician_profile/presentation/screens/edit_profile_screen.dart
- lib/features/technician_profile/presentation/screens/public_profile_screen.dart

### lib/core/constants/supabase_constants.dart
**Description:** Global constants and configuration.

**Dependencies:**
- None

**Dependents:**
- lib/main.dart
- lib/features/technician_profile/data/datasources/profile_remote_datasource.dart

### lib/core/constants/whatsapp_constants.dart
**Description:** Global constants and configuration.

**Dependencies:**
- None

**Dependents:**
- lib/features/whatsapp_followup/domain/usecases/build_followup_message_usecase.dart
- lib/features/whatsapp_followup/presentation/providers/follow_up_provider.dart
- lib/features/whatsapp_followup/presentation/widgets/follow_up_button.dart
- lib/features/whatsapp_followup/presentation/widgets/follow_up_message_preview.dart

### lib/core/errors/app_exception.dart
**Description:** Defines the AppException class.

**Dependencies:**
- None

**Dependents:**
- lib/core/errors/auth_exception.dart
- lib/core/errors/network_exception.dart
- lib/core/errors/storage_exception.dart
- lib/core/errors/validation_exception.dart

### lib/core/errors/auth_exception.dart
**Description:** Defines the AuthException class.

**Dependencies:**
- app_exception.dart

**Dependents:**
- lib/features/auth/data/datasources/auth_remote_datasource.dart
- lib/features/auth/data/repositories/auth_repository_impl.dart

### lib/core/errors/network_exception.dart
**Description:** Defines the NetworkException class.

**Dependencies:**
- app_exception.dart

**Dependents:**
- lib/core/utils/whatsapp_launcher.dart
- lib/features/auth/data/datasources/auth_remote_datasource.dart
- lib/features/customer_history/data/datasources/customer_remote_datasource.dart
- lib/features/job_logging/data/datasources/job_remote_datasource.dart
- lib/features/knowledge_base/data/datasources/knowledge_note_remote_datasource.dart
- lib/features/technician_profile/data/datasources/profile_remote_datasource.dart
- lib/features/whatsapp_followup/data/datasources/follow_up_remote_datasource.dart

### lib/core/errors/storage_exception.dart
**Description:** Defines the StorageException class.

**Dependencies:**
- app_exception.dart

**Dependents:**
- lib/features/job_logging/data/datasources/job_local_datasource.dart
- lib/features/job_logging/data/repositories/job_repository_impl.dart

### lib/core/errors/validation_exception.dart
**Description:** Defines the ValidationException class.

**Dependencies:**
- app_exception.dart

**Dependents:**
- lib/core/utils/phone_formatter.dart
- lib/features/auth/domain/usecases/request_otp_usecase.dart
- lib/features/auth/domain/usecases/verify_otp_usecase.dart
- lib/features/job_logging/data/repositories/job_repository_impl.dart
- lib/features/job_logging/domain/usecases/log_job_usecase.dart
- lib/features/job_logging/presentation/providers/job_providers.dart
- lib/features/knowledge_base/domain/usecases/create_note_usecase.dart
- lib/features/technician_profile/domain/usecases/update_profile_usecase.dart

### lib/core/network/connectivity_service.dart
**Description:** Defines the ConnectivityService class.

**Dependencies:**
- package:connectivity_plus/connectivity_plus.dart

**Dependents:**
- lib/core/providers/connectivity_provider.dart
- lib/features/customer_history/data/repositories/customer_repository_impl.dart
- lib/features/customer_history/presentation/providers/customer_providers.dart
- lib/features/job_logging/data/repositories/job_repository_impl.dart
- lib/features/job_logging/presentation/providers/job_providers.dart

### lib/core/network/supabase_client.dart
**Description:** N/A

**Dependencies:**
- package:supabase_flutter/supabase_flutter.dart

**Dependents:**
- None

### lib/core/providers/auth_provider.dart
**Description:** Presentation layer state management.

**Dependencies:**
- package:flutter/foundation.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:supabase_flutter/supabase_flutter.dart
- supabase_provider.dart

**Dependents:**
- lib/core/router/app_router.dart
- lib/features/auth/presentation/providers/auth_notifier.dart
- lib/features/auth/presentation/screens/onboarding_screen.dart
- lib/features/auth/presentation/screens/transition_screen.dart
- lib/features/technician_profile/presentation/screens/profile_screen.dart

### lib/core/providers/connectivity_provider.dart
**Description:** Presentation layer state management.

**Dependencies:**
- package:flutter_riverpod/flutter_riverpod.dart
- ../network/connectivity_service.dart

**Dependents:**
- lib/core/widgets/ks_offline_banner.dart

### lib/core/providers/shared_feature_providers.dart
**Description:** Presentation layer state management.

**Dependencies:**
- None

**Dependents:**
- lib/features/job_logging/presentation/providers/job_providers.dart
- lib/features/job_logging/presentation/screens/log_job_screen.dart

### lib/core/providers/supabase_provider.dart
**Description:** Presentation layer state management.

**Dependencies:**
- package:flutter_riverpod/flutter_riverpod.dart
- package:supabase_flutter/supabase_flutter.dart

**Dependents:**
- lib/core/providers/auth_provider.dart
- lib/features/auth/presentation/providers/auth_notifier.dart
- lib/features/customer_history/presentation/providers/customer_providers.dart
- lib/features/job_logging/presentation/providers/job_providers.dart
- lib/features/knowledge_base/presentation/providers/notes_providers.dart
- lib/features/technician_profile/presentation/providers/profile_provider.dart
- lib/features/whatsapp_followup/presentation/providers/follow_up_provider.dart

### lib/core/router/app_router.dart
**Description:** Defines Riverpod providers.

**Dependencies:**
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- ../providers/auth_provider.dart
- route_names.dart
- ../../features/auth/presentation/screens/landing_screen.dart
- ../../features/auth/presentation/screens/phone_entry_screen.dart
- ../../features/auth/presentation/screens/otp_verify_screen.dart
- ../../features/auth/presentation/screens/onboarding_screen.dart
- ../../features/auth/presentation/screens/transition_screen.dart
- ../../features/job_logging/presentation/screens/job_list_screen.dart
- ../../features/job_logging/presentation/screens/log_job_screen.dart
- ../../features/whatsapp_followup/presentation/screens/job_detail_screen.dart
- ../../features/customer_history/presentation/screens/customer_list_screen.dart
- ../../features/customer_history/presentation/screens/add_customer_screen.dart
- ../../features/customer_history/presentation/screens/customer_detail_screen.dart
- ../../features/knowledge_base/presentation/screens/notes_list_screen.dart
- ../../features/knowledge_base/presentation/screens/add_note_screen.dart
- ../../features/knowledge_base/presentation/screens/note_detail_screen.dart
- ../../features/technician_profile/presentation/screens/profile_screen.dart
- ../../features/technician_profile/presentation/screens/edit_profile_screen.dart
- ../../features/technician_profile/presentation/screens/public_profile_screen.dart

**Dependents:**
- lib/app.dart

### lib/core/router/route_names.dart
**Description:** Defines the RouteNames class.

**Dependencies:**
- None

**Dependents:**
- lib/core/router/app_router.dart
- lib/features/auth/presentation/screens/landing_screen.dart
- lib/features/auth/presentation/screens/onboarding_screen.dart
- lib/features/auth/presentation/screens/phone_entry_screen.dart
- lib/features/auth/presentation/screens/transition_screen.dart
- lib/features/customer_history/presentation/screens/customer_detail_screen.dart
- lib/features/customer_history/presentation/screens/customer_list_screen.dart
- lib/features/job_logging/presentation/screens/job_list_screen.dart
- lib/features/knowledge_base/presentation/screens/notes_list_screen.dart
- lib/features/technician_profile/presentation/screens/profile_screen.dart

### lib/core/storage/hive_service.dart
**Description:** Defines the HiveService class.

**Dependencies:**
- package:hive_flutter/hive_flutter.dart

**Dependents:**
- lib/main.dart
- lib/features/auth/domain/usecases/logout_usecase.dart
- lib/features/customer_history/data/datasources/customer_local_datasource.dart
- lib/features/job_logging/data/datasources/job_local_datasource.dart
- lib/features/whatsapp_followup/data/repositories/follow_up_repository_impl.dart

### lib/core/theme/app_colors.dart
**Description:** Defines the AppColors class.

**Dependencies:**
- package:flutter/material.dart

**Dependents:**
- lib/core/theme/app_text_styles.dart
- lib/core/theme/app_theme.dart
- lib/core/widgets/ks_app_bar.dart
- lib/core/widgets/ks_avatar.dart
- lib/core/widgets/ks_badge.dart
- lib/core/widgets/ks_banner.dart
- lib/core/widgets/ks_bottom_nav.dart
- lib/core/widgets/ks_button.dart
- lib/core/widgets/ks_card.dart
- lib/core/widgets/ks_confirm_dialog.dart
- lib/core/widgets/ks_divider.dart
- lib/core/widgets/ks_empty_state.dart
- lib/core/widgets/ks_loading_indicator.dart
- lib/core/widgets/ks_logo.dart
- lib/core/widgets/ks_logo_animated.dart
- lib/core/widgets/ks_offline_banner.dart
- lib/core/widgets/ks_search_bar.dart
- lib/core/widgets/ks_skeleton_loader.dart
- lib/core/widgets/ks_snackbar.dart
- lib/core/widgets/ks_tag_chip.dart
- lib/core/widgets/ks_text_field.dart
- lib/features/auth/presentation/screens/landing_screen.dart
- lib/features/auth/presentation/screens/onboarding_screen.dart
- lib/features/auth/presentation/screens/otp_verify_screen.dart
- lib/features/auth/presentation/screens/phone_entry_screen.dart
- lib/features/auth/presentation/screens/transition_screen.dart
- lib/features/auth/presentation/widgets/auth_header.dart
- lib/features/auth/presentation/widgets/name_step_view.dart
- lib/features/auth/presentation/widgets/onboarding_bottom_bar.dart
- lib/features/auth/presentation/widgets/onboarding_step_indicator.dart
- lib/features/auth/presentation/widgets/services_step_view.dart
- lib/features/customer_history/presentation/screens/add_customer_screen.dart
- lib/features/customer_history/presentation/screens/customer_detail_screen.dart
- lib/features/customer_history/presentation/screens/customer_list_screen.dart
- lib/features/customer_history/presentation/widgets/customer_card.dart
- lib/features/job_logging/presentation/screens/job_list_screen.dart
- lib/features/job_logging/presentation/screens/log_job_screen.dart
- lib/features/job_logging/presentation/widgets/job_card.dart
- lib/features/job_logging/presentation/widgets/service_type_picker.dart
- lib/features/knowledge_base/presentation/screens/add_note_screen.dart
- lib/features/knowledge_base/presentation/screens/note_detail_screen.dart
- lib/features/knowledge_base/presentation/screens/notes_list_screen.dart
- lib/features/knowledge_base/presentation/widgets/note_card.dart
- lib/features/knowledge_base/presentation/widgets/tag_input_field.dart
- lib/features/technician_profile/presentation/screens/edit_profile_screen.dart
- lib/features/technician_profile/presentation/screens/profile_screen.dart
- lib/features/technician_profile/presentation/screens/public_profile_screen.dart
- lib/features/whatsapp_followup/presentation/screens/job_detail_screen.dart
- lib/features/whatsapp_followup/presentation/widgets/follow_up_button.dart
- lib/features/whatsapp_followup/presentation/widgets/follow_up_message_preview.dart

### lib/core/theme/app_spacing.dart
**Description:** Defines the AppSpacing class.

**Dependencies:**
- None

**Dependents:**
- lib/core/theme/app_theme.dart
- lib/core/widgets/ks_avatar.dart
- lib/core/widgets/ks_badge.dart
- lib/core/widgets/ks_button.dart
- lib/core/widgets/ks_card.dart
- lib/core/widgets/ks_confirm_dialog.dart
- lib/core/widgets/ks_divider.dart
- lib/core/widgets/ks_empty_state.dart
- lib/core/widgets/ks_offline_banner.dart
- lib/core/widgets/ks_search_bar.dart
- lib/core/widgets/ks_skeleton_loader.dart
- lib/core/widgets/ks_snackbar.dart
- lib/core/widgets/ks_tag_chip.dart
- lib/core/widgets/ks_text_field.dart
- lib/features/auth/presentation/widgets/onboarding_bottom_bar.dart
- lib/features/customer_history/presentation/screens/customer_list_screen.dart
- lib/features/customer_history/presentation/widgets/customer_card.dart
- lib/features/knowledge_base/presentation/screens/note_detail_screen.dart
- lib/features/technician_profile/presentation/screens/edit_profile_screen.dart
- lib/features/technician_profile/presentation/screens/public_profile_screen.dart

### lib/core/theme/app_text_styles.dart
**Description:** Defines the AppTextStyles class.

**Dependencies:**
- package:flutter/material.dart
- app_colors.dart

**Dependents:**
- lib/core/widgets/ks_app_bar.dart
- lib/core/widgets/ks_avatar.dart
- lib/core/widgets/ks_badge.dart
- lib/core/widgets/ks_banner.dart
- lib/core/widgets/ks_bottom_nav.dart
- lib/core/widgets/ks_button.dart
- lib/core/widgets/ks_confirm_dialog.dart
- lib/core/widgets/ks_empty_state.dart
- lib/core/widgets/ks_offline_banner.dart
- lib/core/widgets/ks_search_bar.dart
- lib/core/widgets/ks_snackbar.dart
- lib/core/widgets/ks_tag_chip.dart
- lib/core/widgets/ks_text_field.dart
- lib/features/auth/presentation/screens/landing_screen.dart
- lib/features/auth/presentation/screens/onboarding_screen.dart
- lib/features/auth/presentation/screens/otp_verify_screen.dart
- lib/features/auth/presentation/screens/phone_entry_screen.dart
- lib/features/auth/presentation/screens/transition_screen.dart
- lib/features/customer_history/presentation/screens/add_customer_screen.dart
- lib/features/customer_history/presentation/screens/customer_detail_screen.dart
- lib/features/customer_history/presentation/screens/customer_list_screen.dart
- lib/features/customer_history/presentation/widgets/customer_card.dart
- lib/features/job_logging/presentation/screens/job_list_screen.dart
- lib/features/job_logging/presentation/screens/log_job_screen.dart
- lib/features/job_logging/presentation/widgets/job_card.dart
- lib/features/job_logging/presentation/widgets/service_type_picker.dart
- lib/features/knowledge_base/presentation/screens/add_note_screen.dart
- lib/features/knowledge_base/presentation/screens/note_detail_screen.dart
- lib/features/knowledge_base/presentation/screens/notes_list_screen.dart
- lib/features/knowledge_base/presentation/widgets/note_card.dart
- lib/features/knowledge_base/presentation/widgets/tag_input_field.dart
- lib/features/technician_profile/presentation/screens/edit_profile_screen.dart
- lib/features/technician_profile/presentation/screens/profile_screen.dart
- lib/features/technician_profile/presentation/screens/public_profile_screen.dart
- lib/features/whatsapp_followup/presentation/screens/job_detail_screen.dart
- lib/features/whatsapp_followup/presentation/widgets/follow_up_button.dart
- lib/features/whatsapp_followup/presentation/widgets/follow_up_message_preview.dart

### lib/core/theme/app_theme.dart
**Description:** N/A

**Dependencies:**
- package:flutter/material.dart
- package:google_fonts/google_fonts.dart
- app_colors.dart
- app_spacing.dart

**Dependents:**
- lib/app.dart

### lib/core/usecases/use_case.dart
**Description:** Domain layer business logic.

**Dependencies:**
- None

**Dependents:**
- lib/features/auth/domain/usecases/logout_usecase.dart
- lib/features/auth/domain/usecases/request_otp_usecase.dart
- lib/features/auth/domain/usecases/verify_otp_usecase.dart
- lib/features/customer_history/domain/usecases/create_customer_usecase.dart
- lib/features/customer_history/domain/usecases/delete_customer_usecase.dart
- lib/features/customer_history/domain/usecases/get_customer_by_phone_usecase.dart
- lib/features/customer_history/domain/usecases/get_customer_usecase.dart
- lib/features/customer_history/domain/usecases/get_customers_usecase.dart
- lib/features/customer_history/domain/usecases/sync_offline_customers_usecase.dart
- lib/features/job_logging/domain/usecases/get_job_usecase.dart
- lib/features/job_logging/domain/usecases/get_jobs_usecase.dart
- lib/features/job_logging/domain/usecases/log_job_usecase.dart
- lib/features/job_logging/domain/usecases/sync_offline_jobs_usecase.dart
- lib/features/knowledge_base/domain/usecases/archive_note_usecase.dart
- lib/features/knowledge_base/domain/usecases/create_note_usecase.dart
- lib/features/knowledge_base/domain/usecases/get_notes_usecase.dart
- lib/features/technician_profile/domain/usecases/get_profile_usecase.dart
- lib/features/technician_profile/domain/usecases/share_profile_usecase.dart
- lib/features/technician_profile/domain/usecases/update_profile_usecase.dart
- lib/features/whatsapp_followup/domain/usecases/build_followup_message_usecase.dart
- lib/features/whatsapp_followup/domain/usecases/send_followup_usecase.dart

### lib/core/utils/currency_formatter.dart
**Description:** Defines the CurrencyFormatter class.

**Dependencies:**
- None

**Dependents:**
- lib/features/job_logging/presentation/providers/job_providers.dart
- lib/features/job_logging/presentation/screens/job_list_screen.dart
- lib/features/job_logging/presentation/screens/log_job_screen.dart
- lib/features/job_logging/presentation/widgets/job_card.dart

### lib/core/utils/date_formatter.dart
**Description:** Defines the DateFormatter class.

**Dependencies:**
- package:intl/intl.dart

**Dependents:**
- lib/features/customer_history/presentation/screens/customer_detail_screen.dart
- lib/features/customer_history/presentation/widgets/customer_card.dart
- lib/features/job_logging/presentation/widgets/job_card.dart
- lib/features/knowledge_base/presentation/screens/note_detail_screen.dart
- lib/features/knowledge_base/presentation/widgets/note_card.dart
- lib/features/whatsapp_followup/presentation/screens/job_detail_screen.dart

### lib/core/utils/phone_formatter.dart
**Description:** Defines the PhoneFormatter class.

**Dependencies:**
- ../errors/validation_exception.dart

**Dependents:**
- lib/features/auth/domain/usecases/request_otp_usecase.dart
- lib/features/auth/domain/usecases/verify_otp_usecase.dart
- lib/features/auth/presentation/providers/auth_notifier.dart
- lib/features/job_logging/presentation/providers/job_providers.dart
- lib/features/job_logging/presentation/screens/log_job_screen.dart

### lib/core/utils/slug_generator.dart
**Description:** Defines the SlugGenerator class.

**Dependencies:**
- None

**Dependents:**
- None

### lib/core/utils/whatsapp_launcher.dart
**Description:** Defines the WhatsAppLauncher class.

**Dependencies:**
- package:url_launcher/url_launcher.dart
- ../errors/network_exception.dart

**Dependents:**
- lib/features/whatsapp_followup/domain/usecases/send_followup_usecase.dart
- lib/features/whatsapp_followup/presentation/widgets/follow_up_button.dart

### lib/core/widgets/ks_app_bar.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- ../theme/app_colors.dart
- ../theme/app_text_styles.dart

**Dependents:**
- lib/features/customer_history/presentation/screens/add_customer_screen.dart
- lib/features/customer_history/presentation/screens/customer_detail_screen.dart
- lib/features/customer_history/presentation/screens/customer_list_screen.dart
- lib/features/job_logging/presentation/screens/job_list_screen.dart
- lib/features/job_logging/presentation/screens/log_job_screen.dart
- lib/features/knowledge_base/presentation/screens/add_note_screen.dart
- lib/features/knowledge_base/presentation/screens/note_detail_screen.dart
- lib/features/knowledge_base/presentation/screens/notes_list_screen.dart
- lib/features/technician_profile/presentation/screens/edit_profile_screen.dart
- lib/features/technician_profile/presentation/screens/profile_screen.dart
- lib/features/whatsapp_followup/presentation/screens/job_detail_screen.dart

### lib/core/widgets/ks_avatar.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- ../theme/app_colors.dart
- ../theme/app_spacing.dart
- ../theme/app_text_styles.dart

**Dependents:**
- None

### lib/core/widgets/ks_badge.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- ../theme/app_colors.dart
- ../theme/app_spacing.dart
- ../theme/app_text_styles.dart

**Dependents:**
- None

### lib/core/widgets/ks_banner.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_animate/flutter_animate.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- ../theme/app_colors.dart
- ../theme/app_text_styles.dart

**Dependents:**
- lib/features/auth/presentation/screens/onboarding_screen.dart
- lib/features/auth/presentation/screens/otp_verify_screen.dart
- lib/features/auth/presentation/screens/phone_entry_screen.dart

### lib/core/widgets/ks_bottom_nav.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- ../theme/app_colors.dart
- ../theme/app_text_styles.dart

**Dependents:**
- lib/features/customer_history/presentation/screens/customer_list_screen.dart
- lib/features/job_logging/presentation/screens/job_list_screen.dart
- lib/features/knowledge_base/presentation/screens/notes_list_screen.dart

### lib/core/widgets/ks_button.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- ../theme/app_colors.dart
- ../theme/app_spacing.dart
- ../theme/app_text_styles.dart

**Dependents:**
- lib/core/widgets/ks_confirm_dialog.dart
- lib/core/widgets/ks_empty_state.dart
- lib/features/technician_profile/presentation/screens/edit_profile_screen.dart

### lib/core/widgets/ks_card.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- ../theme/app_colors.dart
- ../theme/app_spacing.dart

**Dependents:**
- None

### lib/core/widgets/ks_confirm_dialog.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- ../theme/app_colors.dart
- ../theme/app_spacing.dart
- ../theme/app_text_styles.dart
- ks_button.dart

**Dependents:**
- None

### lib/core/widgets/ks_divider.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- ../theme/app_colors.dart
- ../theme/app_spacing.dart

**Dependents:**
- None

### lib/core/widgets/ks_empty_state.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- ../theme/app_colors.dart
- ../theme/app_spacing.dart
- ../theme/app_text_styles.dart
- ks_button.dart

**Dependents:**
- lib/features/technician_profile/presentation/screens/public_profile_screen.dart

### lib/core/widgets/ks_loading_indicator.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- ../theme/app_colors.dart

**Dependents:**
- lib/features/technician_profile/presentation/screens/public_profile_screen.dart

### lib/core/widgets/ks_logo.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_svg/flutter_svg.dart
- ../theme/app_colors.dart

**Dependents:**
- lib/features/auth/presentation/screens/landing_screen.dart

### lib/core/widgets/ks_logo_animated.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_svg/flutter_svg.dart
- package:flutter_animate/flutter_animate.dart
- ../theme/app_colors.dart

**Dependents:**
- lib/features/auth/presentation/screens/transition_screen.dart

### lib/core/widgets/ks_offline_banner.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- ../theme/app_colors.dart
- ../theme/app_spacing.dart
- ../theme/app_text_styles.dart
- ../providers/connectivity_provider.dart

**Dependents:**
- lib/features/customer_history/presentation/screens/add_customer_screen.dart
- lib/features/customer_history/presentation/screens/customer_detail_screen.dart
- lib/features/customer_history/presentation/screens/customer_list_screen.dart
- lib/features/job_logging/presentation/screens/job_list_screen.dart
- lib/features/job_logging/presentation/screens/log_job_screen.dart
- lib/features/knowledge_base/presentation/screens/add_note_screen.dart
- lib/features/knowledge_base/presentation/screens/notes_list_screen.dart
- lib/features/technician_profile/presentation/screens/edit_profile_screen.dart
- lib/features/whatsapp_followup/presentation/screens/job_detail_screen.dart

### lib/core/widgets/ks_search_bar.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- ../theme/app_colors.dart
- ../theme/app_spacing.dart
- ../theme/app_text_styles.dart

**Dependents:**
- None

### lib/core/widgets/ks_skeleton_loader.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- ../theme/app_colors.dart
- ../theme/app_spacing.dart

**Dependents:**
- None

### lib/core/widgets/ks_snackbar.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- ../theme/app_colors.dart
- ../theme/app_spacing.dart
- ../theme/app_text_styles.dart

**Dependents:**
- lib/features/customer_history/presentation/screens/add_customer_screen.dart
- lib/features/customer_history/presentation/screens/customer_list_screen.dart
- lib/features/job_logging/presentation/screens/job_list_screen.dart
- lib/features/job_logging/presentation/screens/log_job_screen.dart
- lib/features/knowledge_base/presentation/screens/add_note_screen.dart
- lib/features/knowledge_base/presentation/screens/note_detail_screen.dart
- lib/features/knowledge_base/presentation/screens/notes_list_screen.dart
- lib/features/technician_profile/presentation/screens/edit_profile_screen.dart

### lib/core/widgets/ks_tag_chip.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- ../theme/app_colors.dart
- ../theme/app_spacing.dart
- ../theme/app_text_styles.dart

**Dependents:**
- None

### lib/core/widgets/ks_text_field.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- package:flutter/services.dart
- ../theme/app_colors.dart
- ../theme/app_spacing.dart
- ../theme/app_text_styles.dart

**Dependents:**
- lib/features/technician_profile/presentation/screens/edit_profile_screen.dart

## Features

## Auth

### lib/features/auth/data/datasources/auth_remote_datasource.dart
**Description:** Data source for remote or local storage.

**Dependencies:**
- package:flutter/foundation.dart
- package:supabase_flutter/supabase_flutter.dart
- ../../../../core/errors/auth_exception.dart
- ../../../../core/errors/network_exception.dart
- ../models/user_model.dart

**Dependents:**
- lib/features/auth/data/repositories/auth_repository_impl.dart
- lib/features/auth/presentation/providers/auth_notifier.dart

### lib/features/auth/data/models/user_model.dart
**Description:** Data model for JSON serialization.

**Dependencies:**
- ../../domain/entities/user_entity.dart

**Dependents:**
- lib/features/auth/data/datasources/auth_remote_datasource.dart

### lib/features/auth/data/repositories/auth_repository_impl.dart
**Description:** Data layer implementation of the repository.

**Dependencies:**
- package:supabase_flutter/supabase_flutter.dart
- ../../../../core/errors/auth_exception.dart
- ../../domain/entities/user_entity.dart
- ../../domain/repositories/auth_repository.dart
- ../datasources/auth_remote_datasource.dart

**Dependents:**
- lib/features/auth/presentation/providers/auth_notifier.dart

### lib/features/auth/domain/entities/user_entity.dart
**Description:** Domain entity for business logic.

**Dependencies:**
- None

**Dependents:**
- lib/features/auth/data/models/user_model.dart
- lib/features/auth/data/repositories/auth_repository_impl.dart
- lib/features/auth/domain/repositories/auth_repository.dart

### lib/features/auth/domain/repositories/auth_repository.dart
**Description:** Defines the AuthRepository class.

**Dependencies:**
- package:supabase_flutter/supabase_flutter.dart
- ../entities/user_entity.dart

**Dependents:**
- lib/features/auth/data/repositories/auth_repository_impl.dart
- lib/features/auth/domain/usecases/logout_usecase.dart
- lib/features/auth/domain/usecases/request_otp_usecase.dart
- lib/features/auth/domain/usecases/verify_otp_usecase.dart
- lib/features/auth/presentation/providers/auth_notifier.dart

### lib/features/auth/domain/usecases/logout_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- ../../../../core/usecases/use_case.dart
- ../../../../core/storage/hive_service.dart
- ../repositories/auth_repository.dart

**Dependents:**
- None

### lib/features/auth/domain/usecases/request_otp_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- ../../../../core/errors/validation_exception.dart
- ../../../../core/usecases/use_case.dart
- ../../../../core/utils/phone_formatter.dart
- ../repositories/auth_repository.dart

**Dependents:**
- lib/features/auth/presentation/providers/auth_notifier.dart

### lib/features/auth/domain/usecases/verify_otp_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- ../../../../core/errors/validation_exception.dart
- ../../../../core/usecases/use_case.dart
- ../../../../core/utils/phone_formatter.dart
- ../repositories/auth_repository.dart

**Dependents:**
- lib/features/auth/presentation/providers/auth_notifier.dart

### lib/features/auth/presentation/providers/auth_notifier.dart
**Description:** Presentation layer state management.

**Dependencies:**
- package:flutter/foundation.dart
- package:flutter_riverpod/flutter_riverpod.dart
- ../../../../core/providers/supabase_provider.dart
- ../../../../core/providers/auth_provider.dart
- ../../../../core/utils/phone_formatter.dart
- ../../../technician_profile/domain/entities/profile_entity.dart
- ../../../../core/constants/app_enums.dart
- ../../../technician_profile/domain/repositories/profile_repository.dart
- ../../../technician_profile/presentation/providers/profile_provider.dart
- ../../data/datasources/auth_remote_datasource.dart
- ../../data/repositories/auth_repository_impl.dart
- ../../domain/repositories/auth_repository.dart
- ../../domain/usecases/request_otp_usecase.dart
- ../../domain/usecases/verify_otp_usecase.dart

**Dependents:**
- lib/features/auth/presentation/screens/onboarding_screen.dart
- lib/features/auth/presentation/screens/otp_verify_screen.dart
- lib/features/auth/presentation/screens/phone_entry_screen.dart
- lib/features/auth/presentation/screens/transition_screen.dart

### lib/features/auth/presentation/screens/landing_screen.dart
**Description:** UI screen widget.

**Dependencies:**
- package:flutter/material.dart
- package:go_router/go_router.dart
- package:flutter_animate/flutter_animate.dart
- ../../../../core/router/route_names.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/widgets/ks_logo.dart

**Dependents:**
- lib/core/router/app_router.dart

### lib/features/auth/presentation/screens/onboarding_screen.dart
**Description:** UI screen widget.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- package:flutter_animate/flutter_animate.dart
- ../../../../core/providers/auth_provider.dart
- ../../../../core/router/route_names.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/widgets/ks_banner.dart
- ../../../../core/constants/app_enums.dart
- ../providers/auth_notifier.dart

**Dependents:**
- lib/core/router/app_router.dart

### lib/features/auth/presentation/screens/otp_verify_screen.dart
**Description:** UI screen widget.

**Dependencies:**
- dart:async
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:pinput/pinput.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- package:flutter_animate/flutter_animate.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/widgets/ks_banner.dart
- ../providers/auth_notifier.dart

**Dependents:**
- lib/core/router/app_router.dart

### lib/features/auth/presentation/screens/phone_entry_screen.dart
**Description:** UI screen widget.

**Dependencies:**
- package:flutter/material.dart
- package:flutter/services.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:flutter_svg/flutter_svg.dart
- package:go_router/go_router.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- package:flutter_animate/flutter_animate.dart
- ../../../../core/router/route_names.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/widgets/ks_banner.dart
- ../providers/auth_notifier.dart

**Dependents:**
- lib/core/router/app_router.dart

### lib/features/auth/presentation/screens/transition_screen.dart
**Description:** UI screen widget.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- ../../../../core/providers/auth_provider.dart
- ../../../../core/router/route_names.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/widgets/ks_logo_animated.dart
- ../../../technician_profile/presentation/providers/profile_provider.dart
- ../providers/auth_notifier.dart

**Dependents:**
- lib/core/router/app_router.dart

### lib/features/auth/presentation/widgets/auth_header.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- ../../../../core/theme/app_colors.dart

**Dependents:**
- None

### lib/features/auth/presentation/widgets/name_step_view.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- ../../../../core/theme/app_colors.dart
- onboarding_step_indicator.dart

**Dependents:**
- None

### lib/features/auth/presentation/widgets/onboarding_bottom_bar.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_spacing.dart

**Dependents:**
- None

### lib/features/auth/presentation/widgets/onboarding_step_indicator.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- ../../../../core/theme/app_colors.dart

**Dependents:**
- lib/features/auth/presentation/widgets/name_step_view.dart
- lib/features/auth/presentation/widgets/services_step_view.dart

### lib/features/auth/presentation/widgets/services_step_view.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- ../../../../core/theme/app_colors.dart
- ../../../technician_profile/domain/entities/profile_entity.dart
- onboarding_step_indicator.dart

**Dependents:**
- None

## Customer History

### lib/features/customer_history/data/datasources/customer_local_datasource.dart
**Description:** Data source for remote or local storage.

**Dependencies:**
- ../../../../core/storage/hive_service.dart
- ../models/customer_model.dart

**Dependents:**
- lib/features/customer_history/data/repositories/customer_repository_impl.dart
- lib/features/customer_history/presentation/providers/customer_providers.dart
- lib/features/job_logging/data/repositories/job_repository_impl.dart

### lib/features/customer_history/data/datasources/customer_remote_datasource.dart
**Description:** Data source for remote or local storage.

**Dependencies:**
- package:supabase_flutter/supabase_flutter.dart
- ../../../../core/errors/network_exception.dart
- ../models/customer_model.dart

**Dependents:**
- lib/features/customer_history/data/repositories/customer_repository_impl.dart
- lib/features/customer_history/presentation/providers/customer_providers.dart

### lib/features/customer_history/data/models/customer_model.dart
**Description:** Data model for JSON serialization.

**Dependencies:**
- ../../domain/entities/customer_entity.dart

**Dependents:**
- lib/features/customer_history/data/datasources/customer_local_datasource.dart
- lib/features/customer_history/data/datasources/customer_remote_datasource.dart
- lib/features/customer_history/data/repositories/customer_repository_impl.dart

### lib/features/customer_history/data/repositories/customer_repository_impl.dart
**Description:** Data layer implementation of the repository.

**Dependencies:**
- package:supabase_flutter/supabase_flutter.dart
- package:uuid/uuid.dart
- ../../../../core/network/connectivity_service.dart
- ../../job_logging/data/datasources/job_local_datasource.dart
- ../../domain/entities/customer_entity.dart
- ../../domain/repositories/customer_repository.dart
- ../datasources/customer_remote_datasource.dart
- ../datasources/customer_local_datasource.dart
- ../models/customer_model.dart

**Dependents:**
- lib/features/customer_history/presentation/providers/customer_providers.dart

### lib/features/customer_history/domain/entities/customer_entity.dart
**Description:** Domain entity for business logic.

**Dependencies:**
- ../../../job_logging/domain/entities/job_entity.dart

**Dependents:**
- lib/features/customer_history/data/models/customer_model.dart
- lib/features/customer_history/data/repositories/customer_repository_impl.dart
- lib/features/customer_history/domain/repositories/customer_repository.dart
- lib/features/customer_history/domain/usecases/create_customer_usecase.dart
- lib/features/customer_history/domain/usecases/get_customer_by_phone_usecase.dart
- lib/features/customer_history/domain/usecases/get_customer_usecase.dart
- lib/features/customer_history/domain/usecases/get_customers_usecase.dart
- lib/features/customer_history/presentation/providers/customer_providers.dart
- lib/features/customer_history/presentation/screens/customer_detail_screen.dart
- lib/features/customer_history/presentation/widgets/customer_card.dart
- lib/features/job_logging/presentation/widgets/job_card.dart

### lib/features/customer_history/domain/repositories/customer_repository.dart
**Description:** Defines the CustomerRepository class.

**Dependencies:**
- ../entities/customer_entity.dart

**Dependents:**
- lib/features/customer_history/data/repositories/customer_repository_impl.dart
- lib/features/customer_history/domain/usecases/create_customer_usecase.dart
- lib/features/customer_history/domain/usecases/delete_customer_usecase.dart
- lib/features/customer_history/domain/usecases/get_customer_by_phone_usecase.dart
- lib/features/customer_history/domain/usecases/get_customer_usecase.dart
- lib/features/customer_history/domain/usecases/get_customers_usecase.dart
- lib/features/customer_history/domain/usecases/sync_offline_customers_usecase.dart
- lib/features/customer_history/presentation/providers/customer_providers.dart
- lib/features/job_logging/presentation/providers/job_providers.dart

### lib/features/customer_history/domain/usecases/create_customer_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- package:uuid/uuid.dart
- ../../../../core/usecases/use_case.dart
- ../entities/customer_entity.dart
- ../repositories/customer_repository.dart

**Dependents:**
- lib/features/customer_history/presentation/providers/customer_providers.dart

### lib/features/customer_history/domain/usecases/delete_customer_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- ../../../../core/usecases/use_case.dart
- ../repositories/customer_repository.dart

**Dependents:**
- None

### lib/features/customer_history/domain/usecases/get_customer_by_phone_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- ../../../../core/usecases/use_case.dart
- ../entities/customer_entity.dart
- ../repositories/customer_repository.dart

**Dependents:**
- lib/features/customer_history/presentation/providers/customer_providers.dart

### lib/features/customer_history/domain/usecases/get_customer_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- ../../../../core/usecases/use_case.dart
- ../entities/customer_entity.dart
- ../repositories/customer_repository.dart

**Dependents:**
- None

### lib/features/customer_history/domain/usecases/get_customers_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- ../../../../core/usecases/use_case.dart
- ../entities/customer_entity.dart
- ../repositories/customer_repository.dart

**Dependents:**
- lib/features/customer_history/presentation/providers/customer_providers.dart

### lib/features/customer_history/domain/usecases/sync_offline_customers_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- ../../../../core/usecases/use_case.dart
- ../repositories/customer_repository.dart

**Dependents:**
- lib/features/customer_history/presentation/providers/customer_providers.dart

### lib/features/customer_history/presentation/providers/customer_providers.dart
**Description:** Presentation layer state management.

**Dependencies:**
- package:flutter_riverpod/flutter_riverpod.dart
- package:supabase_flutter/supabase_flutter.dart
- ../../../../core/providers/supabase_provider.dart
- ../../../../core/network/connectivity_service.dart
- ../../job_logging/presentation/providers/job_providers.dart
- ../../data/datasources/customer_remote_datasource.dart
- ../../data/datasources/customer_local_datasource.dart
- ../../data/repositories/customer_repository_impl.dart
- ../../domain/entities/customer_entity.dart
- ../../domain/repositories/customer_repository.dart
- ../../domain/usecases/create_customer_usecase.dart
- ../../domain/usecases/get_customers_usecase.dart
- ../../domain/usecases/get_customer_by_phone_usecase.dart
- ../../domain/usecases/sync_offline_customers_usecase.dart

**Dependents:**
- lib/features/customer_history/presentation/screens/add_customer_screen.dart
- lib/features/customer_history/presentation/screens/customer_detail_screen.dart
- lib/features/customer_history/presentation/screens/customer_list_screen.dart
- lib/features/job_logging/presentation/providers/job_providers.dart
- lib/features/whatsapp_followup/presentation/screens/job_detail_screen.dart
- lib/features/whatsapp_followup/presentation/widgets/follow_up_button.dart
- lib/features/whatsapp_followup/presentation/widgets/follow_up_message_preview.dart

### lib/features/customer_history/presentation/screens/add_customer_screen.dart
**Description:** UI screen widget.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/widgets/ks_app_bar.dart
- ../../../../core/widgets/ks_offline_banner.dart
- ../../../../core/widgets/ks_snackbar.dart
- ../providers/customer_providers.dart

**Dependents:**
- lib/core/router/app_router.dart

### lib/features/customer_history/presentation/screens/customer_detail_screen.dart
**Description:** UI screen widget.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/utils/date_formatter.dart
- ../../../../core/widgets/ks_app_bar.dart
- ../../../../core/widgets/ks_offline_banner.dart
- ../../../../core/router/route_names.dart
- ../../../job_logging/presentation/providers/job_providers.dart
- ../../../job_logging/domain/entities/job_entity.dart
- ../providers/customer_providers.dart
- ../../domain/entities/customer_entity.dart

**Dependents:**
- lib/core/router/app_router.dart

### lib/features/customer_history/presentation/screens/customer_list_screen.dart
**Description:** UI screen widget.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- ../../../../core/router/route_names.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_spacing.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/widgets/ks_app_bar.dart
- ../../../../core/widgets/ks_bottom_nav.dart
- ../../../../core/widgets/ks_offline_banner.dart
- ../../../../core/widgets/ks_snackbar.dart
- ../providers/customer_providers.dart
- ../widgets/customer_card.dart

**Dependents:**
- lib/core/router/app_router.dart

### lib/features/customer_history/presentation/widgets/customer_card.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_spacing.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/utils/date_formatter.dart
- ../../domain/entities/customer_entity.dart

**Dependents:**
- lib/features/customer_history/presentation/screens/customer_list_screen.dart

## Job Logging

### lib/features/job_logging/data/datasources/job_local_datasource.dart
**Description:** Data source for remote or local storage.

**Dependencies:**
- package:hive_flutter/hive_flutter.dart
- ../../../../core/errors/storage_exception.dart
- ../../../../core/storage/hive_service.dart
- ../models/job_model.dart

**Dependents:**
- lib/features/customer_history/data/repositories/customer_repository_impl.dart
- lib/features/job_logging/data/repositories/job_repository_impl.dart
- lib/features/job_logging/presentation/providers/job_providers.dart

### lib/features/job_logging/data/datasources/job_remote_datasource.dart
**Description:** Data source for remote or local storage.

**Dependencies:**
- package:supabase_flutter/supabase_flutter.dart
- ../../../../core/errors/network_exception.dart
- ../models/job_model.dart

**Dependents:**
- lib/features/job_logging/data/repositories/job_repository_impl.dart
- lib/features/job_logging/presentation/providers/job_providers.dart

### lib/features/job_logging/data/models/job_model.dart
**Description:** Data model for JSON serialization.

**Dependencies:**
- ../../../../core/constants/app_enums.dart
- ../../domain/entities/job_entity.dart

**Dependents:**
- lib/features/job_logging/data/datasources/job_local_datasource.dart
- lib/features/job_logging/data/datasources/job_remote_datasource.dart
- lib/features/job_logging/data/repositories/job_repository_impl.dart

### lib/features/job_logging/data/repositories/job_repository_impl.dart
**Description:** Data layer implementation of the repository.

**Dependencies:**
- package:supabase_flutter/supabase_flutter.dart
- ../../../../core/errors/storage_exception.dart
- ../../../../core/errors/validation_exception.dart
- ../../../../core/network/connectivity_service.dart
- ../../customer_history/data/datasources/customer_local_datasource.dart
- ../../whatsapp_followup/domain/repositories/follow_up_repository.dart
- ../../domain/entities/job_entity.dart
- ../../domain/repositories/job_repository.dart
- ../datasources/job_remote_datasource.dart
- ../datasources/job_local_datasource.dart
- ../models/job_model.dart

**Dependents:**
- lib/features/job_logging/presentation/providers/job_providers.dart

### lib/features/job_logging/domain/entities/job_entity.dart
**Description:** Domain entity for business logic.

**Dependencies:**
- ../../../../core/constants/app_enums.dart

**Dependents:**
- lib/features/customer_history/domain/entities/customer_entity.dart
- lib/features/customer_history/presentation/screens/customer_detail_screen.dart
- lib/features/job_logging/data/models/job_model.dart
- lib/features/job_logging/data/repositories/job_repository_impl.dart
- lib/features/job_logging/domain/repositories/job_repository.dart
- lib/features/job_logging/domain/usecases/get_job_usecase.dart
- lib/features/job_logging/domain/usecases/get_jobs_usecase.dart
- lib/features/job_logging/domain/usecases/log_job_usecase.dart
- lib/features/job_logging/presentation/providers/job_providers.dart
- lib/features/job_logging/presentation/widgets/job_card.dart
- lib/features/whatsapp_followup/presentation/widgets/follow_up_button.dart
- lib/features/whatsapp_followup/presentation/widgets/follow_up_message_preview.dart

### lib/features/job_logging/domain/repositories/job_repository.dart
**Description:** Defines the JobRepository class.

**Dependencies:**
- ../entities/job_entity.dart

**Dependents:**
- lib/features/job_logging/data/repositories/job_repository_impl.dart
- lib/features/job_logging/domain/usecases/get_job_usecase.dart
- lib/features/job_logging/domain/usecases/get_jobs_usecase.dart
- lib/features/job_logging/domain/usecases/log_job_usecase.dart
- lib/features/job_logging/domain/usecases/sync_offline_jobs_usecase.dart
- lib/features/job_logging/presentation/providers/job_providers.dart

### lib/features/job_logging/domain/usecases/get_job_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- ../../../../core/usecases/use_case.dart
- ../entities/job_entity.dart
- ../repositories/job_repository.dart

**Dependents:**
- lib/features/job_logging/presentation/providers/job_providers.dart

### lib/features/job_logging/domain/usecases/get_jobs_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- ../../../../core/usecases/use_case.dart
- ../entities/job_entity.dart
- ../repositories/job_repository.dart

**Dependents:**
- lib/features/job_logging/presentation/providers/job_providers.dart

### lib/features/job_logging/domain/usecases/log_job_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- package:uuid/uuid.dart
- ../../../../core/errors/validation_exception.dart
- ../../../../core/usecases/use_case.dart
- ../entities/job_entity.dart
- ../repositories/job_repository.dart
- ../../../../core/constants/app_enums.dart

**Dependents:**
- lib/features/job_logging/presentation/providers/job_providers.dart

### lib/features/job_logging/domain/usecases/sync_offline_jobs_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- ../../../../core/usecases/use_case.dart
- ../repositories/job_repository.dart

**Dependents:**
- lib/features/job_logging/presentation/providers/job_providers.dart

### lib/features/job_logging/presentation/providers/job_providers.dart
**Description:** Presentation layer state management.

**Dependencies:**
- dart:async
- package:flutter/foundation.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:supabase_flutter/supabase_flutter.dart
- ../../../../core/network/connectivity_service.dart
- ../../../../core/providers/supabase_provider.dart
- ../../../../core/errors/validation_exception.dart
- ../../../../core/utils/phone_formatter.dart
- ../../../../core/utils/currency_formatter.dart
- ../../customer_history/domain/repositories/customer_repository.dart
- ../../customer_history/presentation/providers/customer_providers.dart
- ../../whatsapp_followup/presentation/providers/follow_up_provider.dart
- ../../data/datasources/job_local_datasource.dart
- ../../data/datasources/job_remote_datasource.dart
- ../../data/repositories/job_repository_impl.dart
- ../../domain/entities/job_entity.dart
- ../../domain/repositories/job_repository.dart
- ../../domain/usecases/get_jobs_usecase.dart
- ../../domain/usecases/get_job_usecase.dart
- ../../domain/usecases/log_job_usecase.dart
- ../../domain/usecases/sync_offline_jobs_usecase.dart
- ../../domain/usecases/archive_job_usecase.dart
- ../../../../core/constants/app_enums.dart
- ../../../../core/providers/shared_feature_providers.dart

**Dependents:**
- lib/features/customer_history/presentation/providers/customer_providers.dart
- lib/features/customer_history/presentation/screens/customer_detail_screen.dart
- lib/features/job_logging/presentation/screens/job_list_screen.dart
- lib/features/job_logging/presentation/screens/log_job_screen.dart
- lib/features/whatsapp_followup/presentation/screens/job_detail_screen.dart

### lib/features/job_logging/presentation/screens/job_list_screen.dart
**Description:** UI screen widget.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- ../../../../core/router/route_names.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/utils/currency_formatter.dart
- ../../../../core/widgets/ks_app_bar.dart
- ../../../../core/widgets/ks_bottom_nav.dart
- ../../../../core/widgets/ks_offline_banner.dart
- ../../../../core/widgets/ks_snackbar.dart
- ../providers/job_providers.dart
- ../widgets/job_card.dart

**Dependents:**
- lib/core/router/app_router.dart

### lib/features/job_logging/presentation/screens/log_job_screen.dart
**Description:** UI screen widget.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/utils/currency_formatter.dart
- ../../../../core/utils/phone_formatter.dart
- ../../../../core/widgets/ks_app_bar.dart
- ../../../../core/widgets/ks_offline_banner.dart
- ../../../../core/widgets/ks_snackbar.dart
- ../../../../core/constants/app_enums.dart
- ../../../../core/providers/shared_feature_providers.dart
- ../providers/job_providers.dart
- ../widgets/service_type_picker.dart

**Dependents:**
- lib/core/router/app_router.dart

### lib/features/job_logging/presentation/widgets/job_card.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/utils/currency_formatter.dart
- ../../../../core/utils/date_formatter.dart
- ../../customer_history/domain/entities/customer_entity.dart
- ../../domain/entities/job_entity.dart
- ../../../../core/constants/app_enums.dart

**Dependents:**
- lib/features/job_logging/presentation/screens/job_list_screen.dart

### lib/features/job_logging/presentation/widgets/service_type_picker.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/constants/app_enums.dart

**Dependents:**
- lib/features/job_logging/presentation/screens/log_job_screen.dart

## Knowledge Base

### lib/features/knowledge_base/data/datasources/knowledge_note_remote_datasource.dart
**Description:** Data source for remote or local storage.

**Dependencies:**
- package:supabase_flutter/supabase_flutter.dart
- ../../../../core/errors/network_exception.dart
- ../models/knowledge_note_model.dart

**Dependents:**
- lib/features/knowledge_base/data/repositories/knowledge_note_repository_impl.dart
- lib/features/knowledge_base/presentation/providers/notes_providers.dart

### lib/features/knowledge_base/data/models/knowledge_note_model.dart
**Description:** Data model for JSON serialization.

**Dependencies:**
- ../../domain/entities/knowledge_note_entity.dart
- ../../../../core/constants/app_enums.dart

**Dependents:**
- lib/features/knowledge_base/data/datasources/knowledge_note_remote_datasource.dart

### lib/features/knowledge_base/data/repositories/knowledge_note_repository_impl.dart
**Description:** Data layer implementation of the repository.

**Dependencies:**
- package:supabase_flutter/supabase_flutter.dart
- ../../domain/entities/knowledge_note_entity.dart
- ../../domain/repositories/knowledge_note_repository.dart
- ../datasources/knowledge_note_remote_datasource.dart

**Dependents:**
- lib/features/knowledge_base/presentation/providers/notes_providers.dart

### lib/features/knowledge_base/domain/entities/knowledge_note_entity.dart
**Description:** Domain entity for business logic.

**Dependencies:**
- ../../../../core/constants/app_enums.dart

**Dependents:**
- lib/features/knowledge_base/data/models/knowledge_note_model.dart
- lib/features/knowledge_base/data/repositories/knowledge_note_repository_impl.dart
- lib/features/knowledge_base/domain/repositories/knowledge_note_repository.dart
- lib/features/knowledge_base/domain/usecases/create_note_usecase.dart
- lib/features/knowledge_base/domain/usecases/get_notes_usecase.dart
- lib/features/knowledge_base/presentation/providers/notes_providers.dart
- lib/features/knowledge_base/presentation/screens/note_detail_screen.dart
- lib/features/knowledge_base/presentation/widgets/note_card.dart

### lib/features/knowledge_base/domain/repositories/knowledge_note_repository.dart
**Description:** Defines the KnowledgeNoteRepository class.

**Dependencies:**
- ../entities/knowledge_note_entity.dart

**Dependents:**
- lib/features/knowledge_base/data/repositories/knowledge_note_repository_impl.dart
- lib/features/knowledge_base/domain/usecases/archive_note_usecase.dart
- lib/features/knowledge_base/domain/usecases/create_note_usecase.dart
- lib/features/knowledge_base/domain/usecases/get_notes_usecase.dart
- lib/features/knowledge_base/presentation/providers/notes_providers.dart

### lib/features/knowledge_base/domain/usecases/archive_note_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- ../../../../core/usecases/use_case.dart
- ../repositories/knowledge_note_repository.dart

**Dependents:**
- lib/features/knowledge_base/presentation/providers/notes_providers.dart

### lib/features/knowledge_base/domain/usecases/create_note_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- ../../../../core/errors/validation_exception.dart
- ../../../../core/usecases/use_case.dart
- ../entities/knowledge_note_entity.dart
- ../repositories/knowledge_note_repository.dart
- ../../../../core/constants/app_enums.dart

**Dependents:**
- lib/features/knowledge_base/presentation/providers/notes_providers.dart

### lib/features/knowledge_base/domain/usecases/get_notes_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- ../../../../core/usecases/use_case.dart
- ../entities/knowledge_note_entity.dart
- ../repositories/knowledge_note_repository.dart

**Dependents:**
- lib/features/knowledge_base/presentation/providers/notes_providers.dart

### lib/features/knowledge_base/presentation/providers/notes_providers.dart
**Description:** Presentation layer state management.

**Dependencies:**
- package:flutter_riverpod/flutter_riverpod.dart
- package:supabase_flutter/supabase_flutter.dart
- ../../../../core/providers/supabase_provider.dart
- ../../../../core/analytics/ks_analytics.dart
- ../../../../core/analytics/analytics_constants.dart
- ../../data/datasources/knowledge_note_remote_datasource.dart
- ../../data/repositories/knowledge_note_repository_impl.dart
- ../../domain/entities/knowledge_note_entity.dart
- ../../domain/repositories/knowledge_note_repository.dart
- ../../domain/usecases/create_note_usecase.dart
- ../../domain/usecases/get_notes_usecase.dart
- ../../domain/usecases/archive_note_usecase.dart
- ../../../../core/constants/app_enums.dart

**Dependents:**
- lib/features/knowledge_base/presentation/screens/add_note_screen.dart
- lib/features/knowledge_base/presentation/screens/note_detail_screen.dart
- lib/features/knowledge_base/presentation/screens/notes_list_screen.dart

### lib/features/knowledge_base/presentation/screens/add_note_screen.dart
**Description:** UI screen widget.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/widgets/ks_app_bar.dart
- ../../../../core/widgets/ks_offline_banner.dart
- ../../../../core/widgets/ks_snackbar.dart
- ../../../../core/constants/app_enums.dart
- ../providers/notes_providers.dart
- ../widgets/tag_input_field.dart

**Dependents:**
- lib/core/router/app_router.dart

### lib/features/knowledge_base/presentation/screens/note_detail_screen.dart
**Description:** UI screen widget.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_spacing.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/utils/date_formatter.dart
- ../../../../core/widgets/ks_app_bar.dart
- ../../../../core/widgets/ks_snackbar.dart
- ../providers/notes_providers.dart
- ../../domain/entities/knowledge_note_entity.dart

**Dependents:**
- lib/core/router/app_router.dart

### lib/features/knowledge_base/presentation/screens/notes_list_screen.dart
**Description:** UI screen widget.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- ../../../../core/router/route_names.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/widgets/ks_app_bar.dart
- ../../../../core/widgets/ks_bottom_nav.dart
- ../../../../core/widgets/ks_offline_banner.dart
- ../../../../core/widgets/ks_snackbar.dart
- ../providers/notes_providers.dart
- ../widgets/note_card.dart

**Dependents:**
- lib/core/router/app_router.dart

### lib/features/knowledge_base/presentation/widgets/note_card.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/utils/date_formatter.dart
- ../../domain/entities/knowledge_note_entity.dart

**Dependents:**
- lib/features/knowledge_base/presentation/screens/notes_list_screen.dart

### lib/features/knowledge_base/presentation/widgets/tag_input_field.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_text_styles.dart

**Dependents:**
- lib/features/knowledge_base/presentation/screens/add_note_screen.dart

## Technician Profile

### lib/features/technician_profile/data/datasources/profile_remote_datasource.dart
**Description:** Data source for remote or local storage.

**Dependencies:**
- dart:io
- package:flutter/foundation.dart
- package:supabase_flutter/supabase_flutter.dart
- ../../../../core/errors/network_exception.dart
- ../../../../core/constants/supabase_constants.dart
- ../models/profile_model.dart

**Dependents:**
- lib/features/technician_profile/data/repositories/profile_repository_impl.dart
- lib/features/technician_profile/presentation/providers/profile_provider.dart

### lib/features/technician_profile/data/models/profile_model.dart
**Description:** Data model for JSON serialization.

**Dependencies:**
- ../../domain/entities/profile_entity.dart
- ../../../../core/constants/app_enums.dart

**Dependents:**
- lib/features/technician_profile/data/datasources/profile_remote_datasource.dart

### lib/features/technician_profile/data/repositories/profile_repository_impl.dart
**Description:** Data layer implementation of the repository.

**Dependencies:**
- package:flutter/foundation.dart
- package:supabase_flutter/supabase_flutter.dart
- ../../domain/entities/profile_entity.dart
- ../../../../core/constants/app_enums.dart
- ../../domain/repositories/profile_repository.dart
- ../datasources/profile_remote_datasource.dart

**Dependents:**
- lib/features/technician_profile/presentation/providers/profile_provider.dart

### lib/features/technician_profile/domain/entities/profile_entity.dart
**Description:** Domain entity for business logic.

**Dependencies:**
- ../../../../core/constants/app_enums.dart

**Dependents:**
- lib/features/auth/presentation/providers/auth_notifier.dart
- lib/features/auth/presentation/widgets/services_step_view.dart
- lib/features/technician_profile/data/models/profile_model.dart
- lib/features/technician_profile/data/repositories/profile_repository_impl.dart
- lib/features/technician_profile/domain/repositories/profile_repository.dart
- lib/features/technician_profile/domain/usecases/get_profile_usecase.dart
- lib/features/technician_profile/domain/usecases/update_profile_usecase.dart
- lib/features/technician_profile/presentation/providers/profile_provider.dart
- lib/features/technician_profile/presentation/screens/edit_profile_screen.dart
- lib/features/technician_profile/presentation/screens/public_profile_screen.dart

### lib/features/technician_profile/domain/repositories/profile_repository.dart
**Description:** Defines the ProfileRepository class.

**Dependencies:**
- ../entities/profile_entity.dart

**Dependents:**
- lib/features/auth/presentation/providers/auth_notifier.dart
- lib/features/technician_profile/data/repositories/profile_repository_impl.dart
- lib/features/technician_profile/domain/usecases/get_profile_usecase.dart
- lib/features/technician_profile/domain/usecases/share_profile_usecase.dart
- lib/features/technician_profile/domain/usecases/update_profile_usecase.dart
- lib/features/technician_profile/presentation/providers/profile_provider.dart

### lib/features/technician_profile/domain/usecases/get_profile_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- ../../../../core/usecases/use_case.dart
- ../entities/profile_entity.dart
- ../repositories/profile_repository.dart

**Dependents:**
- lib/features/technician_profile/presentation/providers/profile_provider.dart

### lib/features/technician_profile/domain/usecases/share_profile_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- ../../../../core/usecases/use_case.dart
- ../repositories/profile_repository.dart

**Dependents:**
- lib/features/technician_profile/presentation/providers/profile_provider.dart

### lib/features/technician_profile/domain/usecases/update_profile_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- ../../../../core/errors/validation_exception.dart
- ../../../../core/usecases/use_case.dart
- ../entities/profile_entity.dart
- ../repositories/profile_repository.dart

**Dependents:**
- lib/features/technician_profile/presentation/providers/profile_provider.dart

### lib/features/technician_profile/presentation/providers/profile_provider.dart
**Description:** Presentation layer state management.

**Dependencies:**
- package:flutter/foundation.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:supabase_flutter/supabase_flutter.dart
- package:share_plus/share_plus.dart
- ../../../../core/providers/supabase_provider.dart
- ../../../../core/analytics/ks_analytics.dart
- ../../../../core/analytics/analytics_constants.dart
- ../../data/datasources/profile_remote_datasource.dart
- ../../data/repositories/profile_repository_impl.dart
- ../../domain/entities/profile_entity.dart
- ../../domain/repositories/profile_repository.dart
- ../../domain/usecases/get_profile_usecase.dart
- ../../domain/usecases/update_profile_usecase.dart
- ../../domain/usecases/share_profile_usecase.dart

**Dependents:**
- lib/features/auth/presentation/providers/auth_notifier.dart
- lib/features/auth/presentation/screens/transition_screen.dart
- lib/features/technician_profile/presentation/screens/edit_profile_screen.dart
- lib/features/technician_profile/presentation/screens/profile_screen.dart
- lib/features/technician_profile/presentation/screens/public_profile_screen.dart
- lib/features/whatsapp_followup/presentation/widgets/follow_up_button.dart
- lib/features/whatsapp_followup/presentation/widgets/follow_up_message_preview.dart

### lib/features/technician_profile/presentation/screens/edit_profile_screen.dart
**Description:** UI screen widget.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:image_picker/image_picker.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_spacing.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/widgets/ks_app_bar.dart
- ../../../../core/widgets/ks_button.dart
- ../../../../core/widgets/ks_offline_banner.dart
- ../../../../core/widgets/ks_snackbar.dart
- ../../../../core/widgets/ks_text_field.dart
- ../providers/profile_provider.dart
- ../../domain/entities/profile_entity.dart
- ../../../../core/constants/app_enums.dart

**Dependents:**
- lib/core/router/app_router.dart

### lib/features/technician_profile/presentation/screens/profile_screen.dart
**Description:** UI screen widget.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/widgets/ks_app_bar.dart
- ../../../../core/router/route_names.dart
- ../../../../core/providers/auth_provider.dart
- ../providers/profile_provider.dart

**Dependents:**
- lib/core/router/app_router.dart

### lib/features/technician_profile/presentation/screens/public_profile_screen.dart
**Description:** UI screen widget.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:url_launcher/url_launcher.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_spacing.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/widgets/ks_loading_indicator.dart
- ../../../../core/widgets/ks_empty_state.dart
- ../providers/profile_provider.dart
- ../../domain/entities/profile_entity.dart
- ../../../../core/constants/app_enums.dart

**Dependents:**
- lib/core/router/app_router.dart

## Whatsapp Followup

### lib/features/whatsapp_followup/data/datasources/follow_up_remote_datasource.dart
**Description:** Data source for remote or local storage.

**Dependencies:**
- package:supabase_flutter/supabase_flutter.dart
- ../../../../core/errors/network_exception.dart
- ../models/follow_up_model.dart

**Dependents:**
- lib/features/whatsapp_followup/data/repositories/follow_up_repository_impl.dart
- lib/features/whatsapp_followup/presentation/providers/follow_up_provider.dart

### lib/features/whatsapp_followup/data/models/follow_up_model.dart
**Description:** Data model for JSON serialization.

**Dependencies:**
- ../../domain/entities/follow_up_entity.dart

**Dependents:**
- lib/features/whatsapp_followup/data/datasources/follow_up_remote_datasource.dart

### lib/features/whatsapp_followup/data/repositories/follow_up_repository_impl.dart
**Description:** Data layer implementation of the repository.

**Dependencies:**
- package:supabase_flutter/supabase_flutter.dart
- ../../../../core/storage/hive_service.dart
- ../../domain/entities/follow_up_entity.dart
- ../../domain/repositories/follow_up_repository.dart
- ../datasources/follow_up_remote_datasource.dart

**Dependents:**
- lib/features/whatsapp_followup/presentation/providers/follow_up_provider.dart

### lib/features/whatsapp_followup/domain/entities/follow_up_entity.dart
**Description:** Domain entity for business logic.

**Dependencies:**
- None

**Dependents:**
- lib/features/whatsapp_followup/data/models/follow_up_model.dart
- lib/features/whatsapp_followup/data/repositories/follow_up_repository_impl.dart
- lib/features/whatsapp_followup/domain/repositories/follow_up_repository.dart
- lib/features/whatsapp_followup/domain/usecases/send_followup_usecase.dart
- lib/features/whatsapp_followup/presentation/providers/follow_up_provider.dart

### lib/features/whatsapp_followup/domain/repositories/follow_up_repository.dart
**Description:** Defines the FollowUpRepository class.

**Dependencies:**
- ../entities/follow_up_entity.dart

**Dependents:**
- lib/features/job_logging/data/repositories/job_repository_impl.dart
- lib/features/whatsapp_followup/data/repositories/follow_up_repository_impl.dart
- lib/features/whatsapp_followup/domain/usecases/send_followup_usecase.dart
- lib/features/whatsapp_followup/presentation/providers/follow_up_provider.dart

### lib/features/whatsapp_followup/domain/usecases/build_followup_message_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- ../../../../core/usecases/use_case.dart
- ../../../../core/constants/whatsapp_constants.dart

**Dependents:**
- lib/features/whatsapp_followup/presentation/providers/follow_up_provider.dart

### lib/features/whatsapp_followup/domain/usecases/send_followup_usecase.dart
**Description:** Domain layer business logic.

**Dependencies:**
- ../../../../core/usecases/use_case.dart
- ../../../../core/utils/whatsapp_launcher.dart
- ../entities/follow_up_entity.dart
- ../repositories/follow_up_repository.dart

**Dependents:**
- lib/features/whatsapp_followup/presentation/providers/follow_up_provider.dart

### lib/features/whatsapp_followup/presentation/providers/follow_up_provider.dart
**Description:** Presentation layer state management.

**Dependencies:**
- package:flutter_riverpod/flutter_riverpod.dart
- package:supabase_flutter/supabase_flutter.dart
- ../../../../core/providers/supabase_provider.dart
- ../../../../core/constants/whatsapp_constants.dart
- ../../data/datasources/follow_up_remote_datasource.dart
- ../../data/repositories/follow_up_repository_impl.dart
- ../../domain/entities/follow_up_entity.dart
- ../../domain/repositories/follow_up_repository.dart
- ../../domain/usecases/send_followup_usecase.dart
- ../../domain/usecases/build_followup_message_usecase.dart

**Dependents:**
- lib/features/job_logging/presentation/providers/job_providers.dart

### lib/features/whatsapp_followup/presentation/screens/job_detail_screen.dart
**Description:** UI screen widget.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/utils/date_formatter.dart
- ../../../../core/widgets/ks_app_bar.dart
- ../../../../core/widgets/ks_offline_banner.dart
- ../../../job_logging/presentation/providers/job_providers.dart
- ../../../customer_history/presentation/providers/customer_providers.dart
- ../widgets/follow_up_button.dart
- ../widgets/follow_up_message_preview.dart

**Dependents:**
- lib/core/router/app_router.dart

### lib/features/whatsapp_followup/presentation/widgets/follow_up_button.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:line_awesome_flutter/line_awesome_flutter.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/utils/whatsapp_launcher.dart
- ../../../../core/constants/whatsapp_constants.dart
- ../../../job_logging/domain/entities/job_entity.dart
- ../../../customer_history/presentation/providers/customer_providers.dart
- ../../../technician_profile/presentation/providers/profile_provider.dart

**Dependents:**
- lib/features/whatsapp_followup/presentation/screens/job_detail_screen.dart

### lib/features/whatsapp_followup/presentation/widgets/follow_up_message_preview.dart
**Description:** Reusable UI component.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- ../../../../core/theme/app_colors.dart
- ../../../../core/theme/app_text_styles.dart
- ../../../../core/constants/whatsapp_constants.dart
- ../../../job_logging/domain/entities/job_entity.dart
- ../../../customer_history/presentation/providers/customer_providers.dart
- ../../../technician_profile/presentation/providers/profile_provider.dart

**Dependents:**
- lib/features/whatsapp_followup/presentation/screens/job_detail_screen.dart

## Root Files

### lib/main.dart
**Description:** Entry point of the application. Initializes Supabase and Hive.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:supabase_flutter/supabase_flutter.dart
- core/constants/supabase_constants.dart
- core/storage/hive_service.dart
- app.dart

**Dependents:**
- None

### lib/app.dart
**Description:** Root widget. Configures theme, router, and error boundary.

**Dependencies:**
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:supabase_flutter/supabase_flutter.dart
- core/router/app_router.dart
- core/theme/app_theme.dart

**Dependents:**
- lib/main.dart

---
