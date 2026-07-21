import 'package:flutter/material.dart';

import '../models/ticket_item.dart';
import '../extensions/ticket_extensions.dart';
import '../models/pass_type.dart';
import '../models/auth_results.dart';
import '../repositories/ticket_repository.dart';
import '../injection_container.dart';
import '../repositories/pass_type_repository.dart';
import 'package:terka/theme/app_tokens.dart';
import 'package:terka/theme/app_texts.dart';
import '../utils/layout_provider.dart';
import '../widgets/layout/screen_header.dart';
import '../widgets/layout/desktop_sidebar_wrapper.dart';
import 'add_ticket_screen.dart';

class TicketsScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final ValueChanged<TicketItem>? onEditTicket;

  const TicketsScreen({
    super.key,
    this.onBack,
    this.onEditTicket,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = LayoutProvider.isDesktop(context, breakpoint: 600.0);
    return DesktopSidebarWrapper(
      backgroundAlpha: 1.0,
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: SafeArea(
          child: TicketsView(
            onBack: onBack,
            onEditTicket: onEditTicket,
          ),
        ),
      ),
    );
  }
}

class TicketsView extends StatefulWidget {
  final VoidCallback? onBack;
  final ValueChanged<TicketItem>? onEditTicket;

  const TicketsView({
    super.key,
    this.onBack,
    this.onEditTicket,
  });

  @override
  State<TicketsView> createState() => _TicketsViewState();
}

class _TicketsViewState extends State<TicketsView> {
  final TicketRepository _ticketRepository = sl<TicketRepository>();
  List<TicketItem> _tickets = const [];
  List<PassType> _passTypes = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
    });

    final results = await Future.wait([
      _ticketRepository.fetchTickets(),
      sl<PassTypeRepository>().fetchPassTypes(),
    ]);

    if (!mounted) {
      return;
    }

    final ticketsResult = results[0] as TicketsResult;
    final passTypesResult = results[1] as List<PassType>;

    setState(() {
      _isLoading = false;
      _error = ticketsResult.ok ? null : (ticketsResult.error ?? AppTexts.ticketsLoadFailed);
      _tickets = ticketsResult.tickets;
      _passTypes = passTypesResult;
    });
  }

  Future<void> _editTicket(TicketItem ticket) async {
    if (widget.onEditTicket != null) {
      widget.onEditTicket!(ticket);
      return;
    }

    final isDesktop = LayoutProvider.isDesktop(context, breakpoint: 700);
    final bool? updated;
    if (isDesktop) {
      updated = await showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
            child: AddTicketScreen(ticket: ticket),
          ),
        ),
      );
    } else {
      updated = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AddTicketScreen(ticket: ticket),
        ),
      );
    }

    if (updated == true && mounted) {
      _loadTickets();
    }
  }

  Future<void> _confirmDeleteTicket(TicketItem ticket) async {
    final name = ticket.getDisplayName(_passTypes);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTexts.ticketsDeleteConfirmTitle),
        content: Text(AppTexts.ticketsDeleteConfirmContent(name)),
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
            child: Text(AppTexts.ticketsDelete),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        _isLoading = true;
      });
      final result = await _ticketRepository.deleteTicket(ticket.id);
      if (mounted) {
        if (result.ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTexts.ticketsDeleteSuccess)),
          );
          _loadTickets();
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error ?? AppTexts.ticketsDeleteFailed)),
          );
        }
      }
    }
  }

  String _formatDateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }
    final y = parsed.year.toString().padLeft(4, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    final d = parsed.day.toString().padLeft(2, '0');
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
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
          title: Text(AppTexts.ticketsTitle),
          onBack: widget.onBack,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTickets,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      Text(_error!, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        onPressed: _loadTickets,
                        child: Text(AppTexts.retry),
                      ),
                    ],
                  )
                : _tickets.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      Text(AppTexts.ticketsEmpty),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _tickets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
                    itemBuilder: (context, index) {
                      final ticket = _tickets[index];
                      final isSingle = ticket.ticketType == 'vonaljegy';
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      ticket.getDisplayName(_passTypes),
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editTicket(ticket);
                                      } else if (value == 'delete') {
                                        _confirmDeleteTicket(ticket);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.edit_outlined, size: 20),
                                            const SizedBox(width: AppSpacing.sm),
                                            Text(AppTexts.ticketsModify),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              color: Theme.of(context).colorScheme.error,
                                              size: 20,
                                            ),
                                            const SizedBox(width: AppSpacing.sm),
                                            Text(
                                              AppTexts.ticketsDelete,
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(AppTexts.ticketsType(ticket.ticketType)),
                              const SizedBox(height: AppSpacing.xs),
                              Text(AppTexts.ticketsStart(isSingle ? '-' : _formatDateTime(ticket.ticketStart))),
                              const SizedBox(height: AppSpacing.xs),
                              Text(AppTexts.ticketsEnd(isSingle ? '-' : _formatDateTime(ticket.ticketEnd))),
                              const SizedBox(height: AppSpacing.xs),
                              Text(AppTexts.ticketsQuantity(ticket.quantity?.toString() ?? '-')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
