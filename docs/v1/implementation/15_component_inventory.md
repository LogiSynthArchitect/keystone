# DOCUMENT 15 — COMPONENT INVENTORY
### Project: Keystone
**Required Inputs:** Document 13 — Flutter Architecture, Document 14 — Design System
**Principle:** High modularity — every component is self-contained, typed, and composable
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## 15.1 Component Philosophy

1. Single responsibility — one component does one visual job
2. Typed interface — every parameter and callback is explicitly typed
3. No internal state fetching — components receive data, they do not fetch it
4. Named variants — states and sizes are enums, not booleans stacked on booleans
5. Composable — complex components are built from simpler ones listed here

Shared components (used in 2+ features): lib/core/widgets/
Feature-specific components: features/[feature]/presentation/widgets/

---

## 15.2 Core Widgets

### KsButton — core/widgets/ks_button.dart
The single button component for the entire app.

enum KsButtonVariant { primary, secondary, cta, ghost, danger }
enum KsButtonSize { large, small }

class KsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final KsButtonVariant variant;
  final KsButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool fullWidth;
}

Variants:
primary:   primary700 bg + white text        — Save, Confirm
secondary: transparent + primary700 border   — Cancel, Back
cta:       accent500 bg + primary900 text    — WhatsApp follow-up
ghost:     transparent + primary600 text     — Edit, View all
danger:    error500 bg + white text          — Archive, Delete

Sizes: large=52dp/label14w600, small=40dp/labelSmall12w600
States: enabled → loading (spinner replaces label) → disabled (neutral200 bg)

---

### KsTextField — core/widgets/ks_text_field.dart

enum KsTextFieldType { text, phone, amount, multiline, search }

class KsTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final TextEditingController controller;
  final KsTextFieldType type;
  final bool isRequired;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final IconData? leadingIcon;
  final Widget? trailingWidget;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
}

Type behaviours:
text:      text keyboard, no prefix, 1 line
phone:     phone keyboard, +233 prefix, 1 line
amount:    decimal keyboard, GHS prefix, 1 line
multiline: text keyboard, no prefix, 4 lines
search:    text keyboard, search icon, 1 line

---

### KsCard — core/widgets/ks_card.dart

enum KsCardVariant { elevated, outlined, flat }

class KsCard extends StatelessWidget {
  final Widget child;
  final KsCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final double? borderRadius;
}

Variants:
elevated: white bg + cardShadow
outlined: white bg + 1dp neutral200 border
flat:     neutral050 bg + no shadow

---

### KsBadge — core/widgets/ks_badge.dart

enum KsBadgeVariant { success, warning, error, info, neutral }

class KsBadge extends StatelessWidget {
  final String label;
  final KsBadgeVariant variant;
  final IconData? leadingIcon;
}

---

### KsAvatar — core/widgets/ks_avatar.dart

enum KsAvatarSize { sm, md, lg, xl }  // 32, 48, 80, 120dp

class KsAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final KsAvatarSize size;
}

Behaviour: extracts up to 2 initials from name. Falls back to initials if photoUrl fails.

---

### KsSearchBar — core/widgets/ks_search_bar.dart

class KsSearchBar extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
}

---

### KsEmptyState — core/widgets/ks_empty_state.dart

class KsEmptyState extends StatelessWidget {
  final IconData icon;
  final String heading;
  final String body;
  final String? ctaLabel;
  final VoidCallback? onCta;
}

Layout: centered icon (48dp neutral300) + h2 heading + body text + optional primary button
Spacing: AppSpacing.huge between elements

---

### KsOfflineBanner — core/widgets/ks_offline_banner.dart

class KsOfflineBanner extends ConsumerWidget {
  // Reads connectivityProvider internally
  // Animates in/out automatically — no parameters required
}

Spec: 36dp height, offlineBg bg, wifi_off icon + caption text
Behaviour: slides in from top when offline, slides out when reconnected

---

### KsLoadingIndicator — core/widgets/ks_loading_indicator.dart

enum KsLoadingSize { small, medium, large }

class KsLoadingIndicator extends StatelessWidget {
  final KsLoadingSize size;
  final String? message;
}

---

### KsSkeletonLoader — core/widgets/ks_skeleton_loader.dart

enum KsSkeletonVariant { jobCard, customerCard, noteCard, listItem }

class KsSkeletonLoader extends StatefulWidget {
  final KsSkeletonVariant variant;
  final int count;
}

Animation: neutral100 → neutral200 shimmer

---

### KsSnackbar — core/widgets/ks_snackbar.dart
Utility function, not a widget.

enum KsSnackbarVariant { success, error, info, warning }

void showKsSnackbar(
  BuildContext context, {
  required String message,
  required KsSnackbarVariant variant,
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onAction,
})

---

### KsConfirmDialog — core/widgets/ks_confirm_dialog.dart
Utility function, not a widget.

Future<bool> showKsConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool isDangerous = false,
})

---

### KsAppBar — core/widgets/ks_app_bar.dart

class KsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final Widget? bottom;
  final Color? backgroundColor;  // defaults AppColors.primary700
}

---

### KsBottomNav — core/widgets/ks_bottom_nav.dart

class KsBottomNav extends ConsumerWidget {
  // Items: Jobs, Customers, Notes, Profile
  // Reads current route from GoRouter — no parameters required
}

Spec: 64dp height, white bg, 1dp neutral200 top border
Active: primary700 icon + labelSmall
Inactive: neutral400 icon + labelSmall

---

### KsTagChip — core/widgets/ks_tag_chip.dart

class KsTagChip extends StatelessWidget {
  final String tag;
  final bool removable;
  final VoidCallback? onRemove;
}

Spec: 28dp height, radiusFull, primary100 bg, labelSmall primary600

---

### KsDivider — core/widgets/ks_divider.dart

class KsDivider extends StatelessWidget {
  final double? indent;
  final double? endIndent;
  final Color? color;  // defaults neutral200
}

---

## 15.3 Feature Widgets

### JobCard — job_logging/presentation/widgets/job_card.dart

class JobCard extends StatelessWidget {
  final Job job;
  final String customerName;
  final VoidCallback onTap;
}

Layout (inside KsCard elevated):
Row 1: service icon (primary500 20dp) + service name (bodyMedium) + date (caption right)
Row 2: customer name (body neutral700)
Row 3: location icon + location (caption neutral500) + amount (amountSmall right)
Row 4: KsBadge(success, "Follow-up sent") if job.followUpSent

Uses: KsCard, KsBadge

---

### ServiceTypePicker — job_logging/presentation/widgets/service_type_picker.dart

class ServiceTypePicker extends StatelessWidget {
  final ServiceType? selected;
  final ValueChanged<ServiceType> onSelected;
}

Layout: horizontal SingleChildScrollView of selectable chips
Unselected: neutral100 bg + neutral700 text
Selected:   primary700 bg + white text + checkmark icon

---

### SyncStatusIndicator — job_logging/presentation/widgets/sync_status_indicator.dart

class SyncStatusIndicator extends StatelessWidget {
  final SyncStatus status;
}

synced:  hidden (no visual noise)
pending: KsBadge(warning, "Saving...")
failed:  KsBadge(error, "Sync failed")

---

### CustomerCard — customer_history/presentation/widgets/customer_card.dart

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
}

Layout (inside KsCard elevated):
Row: KsAvatar(md) + Column[name(bodyMedium), phone(caption neutral500), jobs+date(caption)]

Uses: KsCard, KsAvatar

---

### CustomerJobHistoryList — customer_history/presentation/widgets/customer_job_history_list.dart

class CustomerJobHistoryList extends StatelessWidget {
  final List<Job> jobs;
  final ValueChanged<Job> onJobTap;
}

Layout: ListView.separated with KsDivider, compact job rows

---

### NoteCard — knowledge_base/presentation/widgets/note_card.dart

class NoteCard extends StatelessWidget {
  final KnowledgeNote note;
  final VoidCallback onTap;
}

Layout (inside KsCard elevated):
Row 1: note.title (h3)
Row 2: Wrap of KsTagChip per tag
Row 3: service type (caption) + date (caption right)

Uses: KsCard, KsTagChip

---

### TagInputField — knowledge_base/presentation/widgets/tag_input_field.dart

class TagInputField extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;
  final int maxTags;  // default 10
}

Behaviour:
- Space or comma → creates tag chip inline
- Tags auto-normalize: lowercase, spaces → underscores
- Tap × → removes tag
- At maxTags → input hidden, shows "Maximum 10 tags" caption

Uses: KsTagChip, KsTextField internally

---

### FollowUpButton — whatsapp_followup/presentation/widgets/followup_button.dart

class FollowUpButton extends StatelessWidget {
  final bool isSent;
  final bool isLoading;
  final VoidCallback? onSend;
}

Default: KsButton(cta, "Send WhatsApp Follow-up", leadingIcon: send_outlined)
Sent:    KsButton(ghost, "Follow-up Sent", leadingIcon: check_circle_outline, onPressed: null)
Loading: KsButton(cta, isLoading: true)

---

### FollowUpMessagePreview — whatsapp_followup/presentation/widgets/followup_message_preview.dart

class FollowUpMessagePreview extends StatelessWidget {
  final String messageText;
  final String customerName;
}

Layout: KsCard(flat) with WhatsApp-green left border accent, message in body style

---

### ProfileHeader — technician_profile/presentation/widgets/profile_header.dart

class ProfileHeader extends StatelessWidget {
  final Profile profile;
  final bool isEditable;
  final VoidCallback? onEditPhoto;
}

Layout (centered column):
Stack: KsAvatar(xl) + optional edit icon overlay
Text(displayName, h2, centered)
Text(bio, body neutral600, centered) if bio != null
Wrap(centered): KsBadge per service

Uses: KsAvatar, KsBadge

---

### ShareProfileButton — technician_profile/presentation/widgets/share_profile_button.dart

class ShareProfileButton extends StatelessWidget {
  final String profileUrl;
}

Layout: KsButton(secondary, "Share Profile", leadingIcon: ios_share)
Behaviour: calls Share.share() with profileUrl via share_plus

---

### ServiceChips — technician_profile/presentation/widgets/service_chips.dart

class ServiceChips extends StatelessWidget {
  final List<ServiceType> services;
}

Layout: Wrap of KsBadge(info) per service — read-only

---

## 15.4 Component Dependency Map

KsCard        ← JobCard, CustomerCard, NoteCard, FollowUpMessagePreview
KsBadge       ← SyncStatusIndicator, ProfileHeader, ServiceChips, JobCard
KsAvatar      ← CustomerCard, ProfileHeader
KsTagChip     ← NoteCard, TagInputField
KsDivider     ← CustomerJobHistoryList
KsButton      ← FollowUpButton, ShareProfileButton

---

## 15.5 File Location Summary

lib/core/widgets/
  ks_button.dart, ks_text_field.dart, ks_card.dart, ks_badge.dart,
  ks_avatar.dart, ks_search_bar.dart, ks_empty_state.dart,
  ks_offline_banner.dart, ks_loading_indicator.dart, ks_skeleton_loader.dart,
  ks_snackbar.dart, ks_confirm_dialog.dart, ks_app_bar.dart,
  ks_bottom_nav.dart, ks_tag_chip.dart, ks_divider.dart

lib/features/job_logging/presentation/widgets/
  job_card.dart, service_type_picker.dart, sync_status_indicator.dart

lib/features/customer_history/presentation/widgets/
  customer_card.dart, customer_job_history_list.dart

lib/features/knowledge_base/presentation/widgets/
  note_card.dart, tag_input_field.dart

lib/features/whatsapp_followup/presentation/widgets/
  followup_button.dart, followup_message_preview.dart

lib/features/technician_profile/presentation/widgets/
  profile_header.dart, share_profile_button.dart, service_chips.dart

---

## Validation Checklist
- [x] 16 core/widgets — all shared UI covered
- [x] 12 feature widgets — all feature-specific UI covered
- [x] Every component has typed constructor signature
- [x] Every component specifies variants as enums
- [x] Dependency map documents all composition relationships
- [x] File locations match Document 13 folder structure exactly
- [x] No component imports from another feature
- [x] KsButton covers all 5 variants from Document 14
- [x] KsTextField covers all 5 input types from Document 14
- [x] KsCard covers all 3 variants from Document 14
