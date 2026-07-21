import 'package:flutter/material.dart';

import '../models/pass_type.dart';
import '../repositories/pass_type_repository.dart';
import '../injection_container.dart';
import 'package:terka/theme/app_tokens.dart';
import 'package:terka/theme/app_texts.dart';
import '../utils/layout_provider.dart';
import '../widgets/layout/screen_header.dart';
import '../widgets/layout/desktop_sidebar_wrapper.dart';
import 'pass_type_editor_screen.dart';

class ManagePassTypesScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final ValueChanged<PassType?>? onOpenPassTypeEditor;

  const ManagePassTypesScreen({
    super.key,
    this.onBack,
    this.onOpenPassTypeEditor,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = LayoutProvider.isDesktop(context, breakpoint: 600.0);
    return DesktopSidebarWrapper(
      backgroundAlpha: 1.0,
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: SafeArea(
          child: ManagePassTypesView(
            onBack: onBack,
            onOpenPassTypeEditor: onOpenPassTypeEditor,
          ),
        ),
      ),
    );
  }
}

class ManagePassTypesView extends StatefulWidget {
  final VoidCallback? onBack;
  final ValueChanged<PassType?>? onOpenPassTypeEditor;

  const ManagePassTypesView({
    super.key,
    this.onBack,
    this.onOpenPassTypeEditor,
  });

  @override
  State<ManagePassTypesView> createState() => _ManagePassTypesViewState();
}

class _ManagePassTypesViewState extends State<ManagePassTypesView> {
  final PassTypeRepository _passTypeRepository = sl<PassTypeRepository>();
  List<PassType> _passTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPassTypes();
  }

  Future<void> _loadPassTypes() async {
    setState(() {
      _isLoading = true;
    });
    final types = await _passTypeRepository.fetchPassTypes();
    if (mounted) {
      setState(() {
        _passTypes = types;
        _isLoading = false;
      });
    }
  }

  Future<void> _openPassTypeEditor([PassType? passType]) async {
    if (widget.onOpenPassTypeEditor != null) {
      widget.onOpenPassTypeEditor!(passType);
      return;
    }

    final isDesktop = LayoutProvider.isDesktop(context, breakpoint: 700);
    final bool? result;
    if (isDesktop) {
      result = await showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
            child: PassTypeEditorScreen(passType: passType),
          ),
        ),
      );
    } else {
      result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => PassTypeEditorScreen(passType: passType),
        ),
      );
    }
    if (result == true) {
      _loadPassTypes();
    }
  }

  Future<void> _confirmDelete(PassType passType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTexts.managePassTypesDeleteTitle),
        content: Text(AppTexts.managePassTypesDeleteContent(passType.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppTexts.ticketsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(AppTexts.managePassTypesDeleteButton),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        _isLoading = true;
      });
      await _passTypeRepository.deletePassType(passType.id);
      _loadPassTypes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bentoShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.4),
        width: 1,
      ),
    );
    final cardColor = isDark ? const Color(0xFF1A1615) : AppColors.white;
    final cardElevation = isDark ? 0.0 : 2.0;
    final cardShadowColor = AppColors.black.withValues(alpha: isDark ? 0.3 : 0.08);

    return Column(
      children: [
        ScreenHeader(
          title: Text(AppTexts.managePassTypesTitle),
          onBack: widget.onBack,
        ),
        Expanded(
          child: Stack(
            children: [
              _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _passTypes.isEmpty
                ? Center(child: Text(AppTexts.managePassTypesEmpty))
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _passTypes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
                    itemBuilder: (context, index) {
                      final p = _passTypes[index];
                      final isPrebaked = p.id == 'orszagberlet' || p.id == 'orszagberlet_szeged';
                      final durationStr = p.durationType == 'month'
                          ? AppTexts.authPassTypeMonth
                          : AppTexts.authPassTypeDays(p.durationDays?.toString() ?? '30');

                      return Card(
                        elevation: cardElevation,
                        shadowColor: cardShadowColor,
                        shape: bentoShape,
                        color: cardColor,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (isPrebaked)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.none,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        AppTexts.system,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else ...[
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _openPassTypeEditor(p),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: colorScheme.error,
                                      ),
                                      onPressed: () => _confirmDelete(p),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(AppTexts.managePassTypesDuration(durationStr)),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                AppTexts.managePassTypesAgencies(p.agencyNames),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () => _openPassTypeEditor(),
                tooltip: AppTexts.managePassTypesNew,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
        ),
      ],
    );
  }
}
