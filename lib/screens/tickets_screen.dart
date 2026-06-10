import 'package:flutter/material.dart';

import '../services/auth_api_service.dart';
import '../theme/app_tokens.dart';
import '../theme/app_texts.dart';
import 'add_ticket_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final AuthApiService _authApiService = const AuthApiService();

  bool _isLoading = true;
  String? _error;
  List<TicketItem> _tickets = const [];
  List<PassType> _passTypes = const [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final results = await Future.wait([
      _authApiService.fetchTickets(),
      _authApiService.fetchPassTypes(),
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
    final bool? updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddTicketScreen(ticket: ticket),
      ),
    );

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
      final result = await _authApiService.deleteTicket(ticket.id);
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
    final cardColor = isDark ? const Color(0xFF1A1615) : Colors.white;
    final cardElevation = isDark ? 0.0 : 2.0;
    final cardShadowColor = Colors.black.withValues(alpha: isDark ? 0.3 : 0.08);

    return Scaffold(
      appBar: AppBar(title: Text(AppTexts.ticketsTitle)),
      body: SafeArea(
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
                                          const SizedBox(width: 8),
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
                                          const SizedBox(width: 8),
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
    );
  }
}
