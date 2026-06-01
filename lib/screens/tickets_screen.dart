import 'package:flutter/material.dart';

import '../services/auth_api_service.dart';
import '../theme/app_tokens.dart';

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

    final result = await _authApiService.fetchTickets();
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _error = result.ok ? null : (result.error ?? 'Nem sikerült lekérni a jegyeket.');
      _tickets = result.tickets;
    });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Jegyeim')),
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
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: _loadTickets,
                      child: const Text('Újrapróbálás'),
                    ),
                  ],
                )
              : _tickets.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: const [
                    Text('Nincs még jegyed. A Profil -> Jegy hozzáadása gombbal tudsz felvenni.'),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _tickets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final ticket = _tickets[index];
                    final isSingle = ticket.ticketType == 'vonaljegy';
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ticket.agencyName, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: AppSpacing.xs),
                            Text('Típus: ${ticket.ticketType}'),
                            const SizedBox(height: AppSpacing.xs),
                            Text('Kezdet: ${isSingle ? '-' : _formatDateTime(ticket.ticketStart)}'),
                            const SizedBox(height: AppSpacing.xs),
                            Text('Lejárat: ${isSingle ? '-' : _formatDateTime(ticket.ticketEnd)}'),
                            const SizedBox(height: AppSpacing.xs),
                            Text('Mennyiség: ${ticket.quantity ?? '-'}'),
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
