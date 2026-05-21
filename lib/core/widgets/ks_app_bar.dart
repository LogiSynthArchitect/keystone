import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';
import '../providers/sync_status_provider.dart';

class KsAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? bottom;
  final bool searchable;
  final String searchHint;
  final Widget? searchPanel;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClear;

  const KsAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
    this.showBack = false,
    this.onBack,
    this.bottom,
    this.searchable = false,
    this.searchHint = 'SEARCH...',
    this.searchPanel,
    this.searchController,
    this.onSearchChanged,
    this.onSearchClear,
  });

  @override
  ConsumerState<KsAppBar> createState() => _KsAppBarState();

  @override
  Size get preferredSize {
    double h = 56;
    if (bottom != null) h += 48;
    return Size.fromHeight(h);
  }
}

class _KsAppBarState extends ConsumerState<KsAppBar> with SingleTickerProviderStateMixin {
  bool _searchOpen = false;
  late AnimationController _slideCtrl;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (_searchOpen) {
        _slideCtrl.forward();
      } else {
        _slideCtrl.reverse();
        widget.searchController?.clear();
        widget.onSearchClear?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = ref.watch(syncStatusProvider);
    final hasSearchIcon = widget.searchable || widget.onSearchChanged != null;

    // Build search button as an action
    final actionWidgets = <Widget>[
      if (hasSearchIcon)
        IconButton(
          icon: Icon(
            _searchOpen ? LineAwesomeIcons.times_solid : LineAwesomeIcons.search_solid,
            color: _searchOpen ? context.ksc.accent500 : context.ksc.neutral500,
            size: 20,
          ),
          onPressed: _toggleSearch,
        ),
      if (pendingCount > 0)
        Center(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: context.ksc.accent500.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LineAwesomeIcons.sync_solid, size: 12, color: context.ksc.accent500),
                const SizedBox(width: 6),
                Text(
                  '$pendingCount PENDING',
                  style: AppTextStyles.caption.copyWith(
                    color: context.ksc.accent500,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ...?widget.actions,
    ];

    return AppBar(
      backgroundColor: context.ksc.primary900,
      foregroundColor: context.ksc.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      title: widget.titleWidget ?? Text(
        widget.title,
        style: AppTextStyles.h3.copyWith(
          color: context.ksc.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      leading: widget.showBack
          ? IconButton(
              icon: const Icon(LineAwesomeIcons.angle_left_solid, size: 22),
              onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      automaticallyImplyLeading: widget.showBack,
      actions: actionWidgets,
      bottom: _searchOpen && widget.searchPanel != null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: SizeTransition(
                sizeFactor: _slideAnim,
                axisAlignment: -1,
                child: widget.searchPanel!,
              ),
            )
          : widget.bottom != null
              ? PreferredSize(preferredSize: const Size.fromHeight(48), child: widget.bottom!)
              : null,
    );
  }
}
