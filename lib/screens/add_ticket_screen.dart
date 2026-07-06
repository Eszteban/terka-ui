import 'package:flutter/material.dart';

import '../models/ticket_item.dart';
import '../models/pass_type.dart';
import '../models/ticket_options.dart';
import '../models/auth_results.dart';
import '../repositories/ticket_repository.dart';
import '../injection_container.dart';
import '../repositories/pass_type_repository.dart';
import '../theme/app_tokens.dart';
import '../theme/app_texts.dart';

class AddTicketScreen extends StatefulWidget {
  final TicketItem? ticket;
  final VoidCallback? onBack;
  final VoidCallback? onSaved;

  const AddTicketScreen({
    super.key,
    this.ticket,
    this.onBack,
    this.onSaved,
  });

  @override
  State<AddTicketScreen> createState() => _AddTicketScreenState();
}

class _AddTicketScreenState extends State<AddTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _ticketStartController = TextEditingController();
  final TicketRepository _ticketRepository = sl<TicketRepository>();
  final PassTypeRepository _passTypeRepository = sl<PassTypeRepository>();

  bool _isLoadingOptions = true;
  bool _isSubmitting = false;
  String? _error;

  List<TicketAgencyOption> _agencies = const [];
  List<PassType> _passTypes = const [];

  String? _selectedAgency;
  String _selectedTicketType = 'vonaljegy';
  String? _selectedPassType;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _ticketStartController.dispose();
    super.dispose();
  }

  bool get _isPass => _selectedTicketType == 'bérlet';

  Future<void> _loadOptions() async {
    setState(() {
      _isLoadingOptions = true;
      _error = null;
    });

    final result = await _ticketRepository.fetchTicketFormOptions();
    if (!mounted) {
      return;
    }

    if (!result.ok) {
      setState(() {
        _isLoadingOptions = false;
        _error = result.error ?? AppTexts.addTicketOptionsLoadFailed;
      });
      return;
    }

    final passTypes = await _passTypeRepository.fetchPassTypes();
    if (!mounted) {
      return;
    }

    final sortedAgencies = List<TicketAgencyOption>.from(result.agencies)
      ..sort((a, b) {
        final normA = _normalize(a.name);
        final normB = _normalize(b.name);
        final cmp = normA.compareTo(normB);
        if (cmp != 0) return cmp;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    setState(() {
      _isLoadingOptions = false;
      _agencies = sortedAgencies;
      _passTypes = passTypes;

      final t = widget.ticket;
      if (t != null) {
        _selectedTicketType = t.ticketType;
        if (t.ticketType == 'vonaljegy') {
          _selectedAgency = t.agencyId;
          _quantityController.text = t.quantity?.toString() ?? '';

          if (passTypes.isNotEmpty) {
            _selectedPassType = passTypes.first.id;
          }
        } else {
          _selectedAgency = sortedAgencies.isNotEmpty ? sortedAgencies.first.id : null;
          _ticketStartController.text = t.ticketStart ?? '';
          _selectedPassType = _findMatchingPassType(t, passTypes) ??
              (passTypes.isNotEmpty ? passTypes.first.id : null);
        }
      } else {
        _selectedAgency = sortedAgencies.isNotEmpty ? sortedAgencies.first.id : null;
        _selectedTicketType = result.ticketTypes.isNotEmpty
            ? result.ticketTypes.first.value
            : _selectedTicketType;

        if (passTypes.isNotEmpty) {
          _selectedPassType = passTypes.first.id;
        }
      }
    });
  }

  String? _findMatchingPassType(TicketItem ticket, List<PassType> passTypes) {
    final ticketIds = Set<String>.from(ticket.agencyIds ?? []);
    if (ticketIds.isEmpty) return null;

    for (final pt in passTypes) {
      final ptIds = Set<String>.from(pt.agencyIds);
      if (ticketIds.length == ptIds.length && ticketIds.containsAll(ptIds)) {
        return pt.id;
      }
    }
    return null;
  }

  String _normalize(String s) {
    const Map<String, String> accents = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ö': 'o', 'ő': 'o', 'ú': 'u', 'ü': 'u', 'ű': 'u',
      'Á': 'a', 'É': 'e', 'Í': 'i', 'Ó': 'o', 'Ö': 'o', 'Ő': 'o', 'Ú': 'u', 'Ü': 'u', 'Ű': 'u'
    };
    final sb = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final char = s[i];
      sb.write(accents[char] ?? char.toLowerCase());
    }
    return sb.toString();
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

  String _calculatePassEndDateStr(String startStr, PassType passType) {
    final parsed = DateTime.tryParse(startStr);
    if (parsed == null) return '';

    if (passType.durationType == 'month') {
      int year = parsed.year;
      int month = parsed.month + 1;
      if (month > 12) {
        month = 1;
        year += 1;
      }

      int day = parsed.day;
      int maxDays = DateTime(year, month + 1, 0).day;
      if (day > maxDays) {
        day = maxDays;
      }

      final nextMonthSameDay = DateTime(year, month, day, parsed.hour, parsed.minute);
      final endDate = nextMonthSameDay.subtract(const Duration(days: 1));

      final y = endDate.year.toString().padLeft(4, '0');
      final m = endDate.month.toString().padLeft(2, '0');
      final d = endDate.day.toString().padLeft(2, '0');
      final hh = endDate.hour.toString().padLeft(2, '0');
      final mm = endDate.minute.toString().padLeft(2, '0');
      return '$y-$m-${d}T$hh:$mm';
    } else {
      final days = passType.durationDays ?? 30;
      final endDate = parsed.add(Duration(days: days)).subtract(const Duration(minutes: 1));

      final y = endDate.year.toString().padLeft(4, '0');
      final m = endDate.month.toString().padLeft(2, '0');
      final d = endDate.day.toString().padLeft(2, '0');
      final hh = endDate.hour.toString().padLeft(2, '0');
      final mm = endDate.minute.toString().padLeft(2, '0');
      return '$y-$m-${d}T$hh:$mm';
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    if (!_isPass) {
      if (_selectedAgency == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppTexts.addTicketAgencyValidator)),
        );
        return;
      }
    } else {
      if (_selectedPassType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppTexts.addTicketPassTypeValidator)),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    final quantity = _quantityController.text.trim().isEmpty
        ? null
        : int.tryParse(_quantityController.text.trim());

    final String? startVal = _isPass ? _ticketStartController.text.trim() : null;
    String? endVal;
    List<String>? selectedAgencyIds;

    if (_isPass) {
      final selectedPt = _passTypes.firstWhere(
        (p) => p.id == _selectedPassType,
        orElse: () => _passTypes.first,
      );
      endVal = _calculatePassEndDateStr(startVal!, selectedPt);
      selectedAgencyIds = selectedPt.agencyIds;
    }

    final AuthActionResult result;
    if (widget.ticket != null) {
      result = await _ticketRepository.updateTicket(
        TicketItem(
          id: widget.ticket!.id,
          agencyId: _isPass ? (selectedAgencyIds?.isNotEmpty == true ? selectedAgencyIds!.first : '') : (_selectedAgency ?? ''),
          agencyName: '',
          agencyIds: _isPass ? selectedAgencyIds : null,
          agencyNames: null,
          ticketType: _selectedTicketType,
          ticketStart: startVal,
          ticketEnd: endVal,
          quantity: _selectedTicketType == 'vonaljegy' ? quantity : null,
        ),
      );
    } else {
      result = await _ticketRepository.addTicket(
        agency: _selectedAgency ?? '',
        ticketType: _selectedTicketType,
        ticketStart: startVal,
        ticketEnd: endVal,
        quantity: _selectedTicketType == 'vonaljegy' ? quantity : null,
        agencyIds: _isPass ? selectedAgencyIds : null,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? AppTexts.addTicketFailed)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? (widget.ticket != null ? AppTexts.authUpdateTicketSuccess : AppTexts.addTicketSuccess))),
    );
    if (widget.onSaved != null) {
      widget.onSaved!();
    } else {
      Navigator.of(context).pop(true);
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
    final cardColor = isDark ? const Color(0xFF1A1615) : Colors.white;
    final cardElevation = isDark ? 0.0 : 2.0;
    final cardShadowColor = Colors.black.withValues(alpha: isDark ? 0.3 : 0.08);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticket != null ? AppTexts.managePassTypesEditTitle : AppTexts.managePassTypesNewTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
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
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton(
                            onPressed: _loadOptions,
                            child: Text(AppTexts.retry),
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
                          elevation: cardElevation,
                          shadowColor: cardShadowColor,
                          shape: bentoShape,
                          color: cardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    AppTexts.addTicketTypeLabel,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  SegmentedButton<String>(
                                    segments: [
                                      ButtonSegment<String>(
                                        value: 'vonaljegy',
                                        icon: const Icon(Icons.confirmation_num_outlined),
                                        label: Text(AppTexts.addTicketTypeSingle),
                                      ),
                                      ButtonSegment<String>(
                                        value: 'bérlet',
                                        icon: const Icon(Icons.card_membership_outlined),
                                        label: Text(AppTexts.addTicketTypePass),
                                      ),
                                    ],
                                    selected: {_selectedTicketType},
                                    onSelectionChanged: (selection) {
                                      if (selection.isNotEmpty) {
                                        setState(() {
                                          _selectedTicketType = selection.first;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  if (!_isPass) ...[
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedAgency,
                                      isExpanded: true,
                                      isDense: false,
                                      itemHeight: 84.0,
                                      decoration: InputDecoration(
                                        labelText: AppTexts.addTicketAgencyLabel,
                                        prefixIcon: const Icon(Icons.business_outlined),
                                      ),
                                      selectedItemBuilder: (BuildContext context) {
                                        return _agencies.map<Widget>((agency) {
                                          return Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              agency.name,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList();
                                      },
                                      items: _agencies
                                          .map(
                                            (agency) => DropdownMenuItem<String>(
                                              value: agency.id,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(
                                                  vertical: 8.0,
                                                ),
                                                child: Text(
                                                  agency.name,
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedAgency = value;
                                        });
                                      },
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                              ? AppTexts.addTicketAgencyValidator
                                              : null,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    TextFormField(
                                      controller: _quantityController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: AppTexts.addTicketQuantityLabel,
                                        prefixIcon: const Icon(Icons.numbers),
                                      ),
                                      validator: (value) {
                                        if (_selectedTicketType != 'vonaljegy') {
                                          return null;
                                        }
                                        final raw = value?.trim() ?? '';
                                        if (raw.isEmpty) {
                                          return AppTexts.addTicketQuantityEmpty;
                                        }
                                        final parsed = int.tryParse(raw);
                                        if (parsed == null || parsed <= 0) {
                                          return AppTexts.addTicketQuantityPositive;
                                        }
                                        return null;
                                      },
                                    ),
                                  ] else ...[
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedPassType,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: AppTexts.addTicketPassTypeLabel,
                                        prefixIcon: const Icon(Icons.card_membership_outlined),
                                      ),
                                      items: _passTypes
                                          .map(
                                            (pt) => DropdownMenuItem<String>(
                                              value: pt.id,
                                              child: Text(pt.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedPassType = value;
                                        });
                                      },
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                              ? AppTexts.addTicketPassTypeValidator
                                              : null,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    TextFormField(
                                      controller: _ticketStartController,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        labelText: AppTexts.addTicketValidityStartLabel,
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
                                          return AppTexts.addTicketValidityStartValidator;
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
                                        : Icon(widget.ticket != null ? Icons.save : Icons.add_card),
                                    label: Text(
                                      _isSubmitting
                                          ? AppTexts.processInProgress
                                          : (widget.ticket != null ? AppTexts.save : AppTexts.addTicketAdd),
                                    ),
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
