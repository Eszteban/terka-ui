import 'package:flutter/material.dart';

import '../services/auth_api_service.dart';
import '../theme/app_tokens.dart';

class AddTicketScreen extends StatefulWidget {
  const AddTicketScreen({super.key});

  @override
  State<AddTicketScreen> createState() => _AddTicketScreenState();
}

class _AddTicketScreenState extends State<AddTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _ticketStartController = TextEditingController();
  final _ticketEndController = TextEditingController();
  final AuthApiService _authApiService = const AuthApiService();

  bool _isLoadingOptions = true;
  bool _isSubmitting = false;
  String? _error;

  List<TicketAgencyOption> _agencies = const [];
  List<TicketTypeOption> _ticketTypes = const [];

  String? _selectedAgency;
  String _selectedTicketType = 'vonaljegy';

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _ticketStartController.dispose();
    _ticketEndController.dispose();
    super.dispose();
  }

  bool get _isPass => _selectedTicketType == 'bérlet';

  Future<void> _loadOptions() async {
    setState(() {
      _isLoadingOptions = true;
      _error = null;
    });

    final result = await _authApiService.fetchTicketFormOptions();
    if (!mounted) {
      return;
    }

    if (!result.ok) {
      setState(() {
        _isLoadingOptions = false;
        _error = result.error ?? 'Nem sikerült betölteni az opciókat.';
      });
      return;
    }

    setState(() {
      _isLoadingOptions = false;
      _agencies = result.agencies;
      _ticketTypes = result.ticketTypes;
      _selectedAgency = result.agencies.isNotEmpty ? result.agencies.first.id : null;
      _selectedTicketType = result.ticketTypes.isNotEmpty
          ? result.ticketTypes.first.value
          : _selectedTicketType;
    });
  }

  Future<void> _pickDateTime(TextEditingController controller) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (pickedTime == null || !mounted) {
      return;
    }

    final dt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    controller.text = '$y-$m-${d}T$hh:$mm';
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    if (_selectedAgency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Válassz szolgáltatót.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final quantity = _quantityController.text.trim().isEmpty
        ? null
        : int.tryParse(_quantityController.text.trim());

    final result = await _authApiService.addTicket(
      agency: _selectedAgency!,
      ticketType: _selectedTicketType,
      ticketStart: _isPass ? _ticketStartController.text.trim() : null,
      ticketEnd: _isPass ? _ticketEndController.text.trim() : null,
      quantity: _selectedTicketType == 'vonaljegy' ? quantity : null,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Nem sikerült hozzáadni a jegyet.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Jegy hozzáadva!')),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jegy hozzáadása')),
      body: SafeArea(
        child: _isLoadingOptions
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: _loadOptions,
                        child: const Text('Újrapróbálás'),
                      ),
                    ],
                  ),
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: _selectedAgency,
                                decoration: const InputDecoration(
                                  labelText: 'Szolgáltató',
                                  prefixIcon: Icon(Icons.business_outlined),
                                ),
                                items: _agencies
                                    .map(
                                      (agency) => DropdownMenuItem<String>(
                                        value: agency.id,
                                        child: Text(agency.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedAgency = value;
                                  });
                                },
                                validator: (value) =>
                                    value == null || value.isEmpty ? 'Válassz szolgáltatót.' : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedTicketType,
                                decoration: const InputDecoration(
                                  labelText: 'Jegy típusa',
                                  prefixIcon: Icon(Icons.confirmation_num_outlined),
                                ),
                                items: _ticketTypes
                                    .map(
                                      (type) => DropdownMenuItem<String>(
                                        value: type.value,
                                        child: Text(type.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() {
                                    _selectedTicketType = value;
                                  });
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              if (_isPass) ...[
                                TextFormField(
                                  controller: _ticketStartController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Érvényesség kezdete',
                                    prefixIcon: const Icon(Icons.schedule_outlined),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.calendar_month),
                                      onPressed: () => _pickDateTime(_ticketStartController),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (!_isPass) {
                                      return null;
                                    }
                                    if ((value ?? '').trim().isEmpty) {
                                      return 'Add meg a kezdő dátumot.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextFormField(
                                  controller: _ticketEndController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Érvényesség vége',
                                    prefixIcon: const Icon(Icons.event_available_outlined),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.calendar_month),
                                      onPressed: () => _pickDateTime(_ticketEndController),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (!_isPass) {
                                      return null;
                                    }
                                    if ((value ?? '').trim().isEmpty) {
                                      return 'Add meg a lejárati dátumot.';
                                    }
                                    return null;
                                  },
                                ),
                              ] else ...[
                                TextFormField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Mennyiség',
                                    prefixIcon: Icon(Icons.numbers),
                                  ),
                                  validator: (value) {
                                    if (_selectedTicketType != 'vonaljegy') {
                                      return null;
                                    }
                                    final raw = value?.trim() ?? '';
                                    if (raw.isEmpty) {
                                      return 'Add meg a mennyiséget.';
                                    }
                                    final parsed = int.tryParse(raw);
                                    if (parsed == null || parsed <= 0) {
                                      return 'Pozitív egész számot adj meg.';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              const SizedBox(height: AppSpacing.lg),
                              FilledButton.icon(
                                onPressed: _isSubmitting ? null : _submit,
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.add_card),
                                label: Text(_isSubmitting ? 'Folyamatban...' : 'Hozzáadás'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
