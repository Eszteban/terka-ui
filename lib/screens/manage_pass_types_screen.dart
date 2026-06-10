import 'package:flutter/material.dart';

import '../services/auth_api_service.dart';
import '../theme/app_tokens.dart';
import '../theme/app_texts.dart';

class ManagePassTypesScreen extends StatefulWidget {
  const ManagePassTypesScreen({super.key});

  @override
  State<ManagePassTypesScreen> createState() => _ManagePassTypesScreenState();
}

class _ManagePassTypesScreenState extends State<ManagePassTypesScreen> {
  final AuthApiService _authApiService = const AuthApiService();
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
    final types = await _authApiService.fetchPassTypes();
    if (mounted) {
      setState(() {
        _passTypes = types;
        _isLoading = false;
      });
    }
  }

  Future<void> _addOrEditPassType([PassType? passType]) async {
    final bool? result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEditPassTypeScreen(passType: passType),
      ),
    );
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
      await _authApiService.deletePassType(passType.id);
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
    final cardColor = isDark ? const Color(0xFF1A1615) : Colors.white;
    final cardElevation = isDark ? 0.0 : 2.0;
    final cardShadowColor = Colors.black.withValues(alpha: isDark ? 0.3 : 0.08);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTexts.managePassTypesTitle),
      ),
      body: SafeArea(
        child: _isLoading
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
                                        horizontal: 8,
                                        vertical: 2,
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
                                      onPressed: () => _addOrEditPassType(p),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditPassType(),
        tooltip: AppTexts.managePassTypesNew,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddEditPassTypeScreen extends StatefulWidget {
  final PassType? passType;
  const AddEditPassTypeScreen({super.key, this.passType});

  @override
  State<AddEditPassTypeScreen> createState() => _AddEditPassTypeScreenState();
}

class _AddEditPassTypeScreenState extends State<AddEditPassTypeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _daysController = TextEditingController();
  final _searchController = TextEditingController();
  final AuthApiService _authApiService = const AuthApiService();

  bool _isLoading = true;
  String? _error;

  List<TicketAgencyOption> _agencies = [];
  Set<String> _selectedAgencies = {};
  String _durationType = 'month'; // 'month' or 'days'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.passType != null) {
      _nameController.text = widget.passType!.name;
      _durationType = widget.passType!.durationType;
      if (_durationType == 'days') {
        _daysController.text = widget.passType!.durationDays?.toString() ?? '30';
      }
      _selectedAgencies = Set<String>.from(widget.passType!.agencyIds);
    }
    _loadAgencies();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _daysController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  Future<void> _loadAgencies() async {
    final result = await _authApiService.fetchTicketFormOptions();
    if (mounted) {
      if (result.ok) {
        setState(() {
          _agencies = result.agencies;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result.error ?? AppTexts.managePassTypesLoadAgenciesFailed;
          _isLoading = false;
        });
      }
    }
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAgencies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTexts.managePassTypesSelectMinOneAgency)),
      );
      return;
    }

    final String name = _nameController.text.trim();
    final int? days = _durationType == 'days' ? int.tryParse(_daysController.text.trim()) : null;

    final List<String> agencyIds = _selectedAgencies.toList();
    final List<String> agencyNames = [];
    for (final id in agencyIds) {
      final match = _agencies.firstWhere(
        (a) => a.id == id,
        orElse: () => TicketAgencyOption(id: id, name: id),
      );
      agencyNames.add(match.name);
    }

    final id = widget.passType?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final newPassType = PassType(
      id: id,
      name: name,
      agencyIds: agencyIds,
      agencyNames: agencyNames,
      durationType: _durationType,
      durationDays: days,
    );

    await _authApiService.savePassType(newPassType);
    if (mounted) {
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

    Widget content;
    if (_isLoading) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (_error != null) {
      content = Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(child: Text(_error!)),
      );
    } else {
      content = Form(
        key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppTexts.managePassTypesNameLabel,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? AppTexts.managePassTypesNameValidator : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppTexts.managePassTypesDurationTypeLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment<String>(
                    value: 'month',
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(AppTexts.managePassTypesDurationMonth),
                  ),
                  ButtonSegment<String>(
                    value: 'days',
                    icon: const Icon(Icons.today_outlined),
                    label: Text(AppTexts.managePassTypesDurationCustom),
                  ),
                ],
                selected: {_durationType},
                onSelectionChanged: (selection) {
                  if (selection.isNotEmpty) {
                    setState(() {
                      _durationType = selection.first;
                    });
                  }
                },
              ),
              if (_durationType == 'days') ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppTexts.managePassTypesCustomDaysLabel,
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return AppTexts.managePassTypesCustomDaysEmpty;
                    }
                    final parsed = int.tryParse(val.trim());
                    if (parsed == null || parsed <= 0) {
                      return AppTexts.managePassTypesCustomDaysPositive;
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (_selectedAgencies.isNotEmpty) ...[
                Text(
                  AppTexts.managePassTypesSelectedAgencies,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.xs),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _agencies
                        .where((agency) => _selectedAgencies.contains(agency.id))
                        .map((agency) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InputChip(
                          label: Text(
                            agency.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onDeleted: () {
                            setState(() {
                              _selectedAgencies.remove(agency.id);
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: AppTexts.managePassTypesSearchAgency,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppTexts.managePassTypesAgenciesList,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: LayoutBuilder(
                  builder: (context, boxConstraints) {
                    final maxLabelWidth = boxConstraints.maxWidth - 48;
                    final query = _normalize(_searchQuery.trim());
                    final filtered = _agencies.where((agency) {
                      if (query.isEmpty) return true;
                      return _normalize(agency.name).contains(query);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            AppTexts.managePassTypesNoAgenciesFound,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(8.0),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: filtered.map((agency) {
                          final isSelected = _selectedAgencies.contains(agency.id);
                          return FilterChip(
                            label: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: maxLabelWidth > 0 ? maxLabelWidth : 200,
                              ),
                              child: Text(
                                agency.name,
                                softWrap: true,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedAgencies.add(agency.id);
                                } else {
                                  _selectedAgencies.remove(agency.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(AppTexts.managePassTypesSavePassType),
              ),
            ],
        ),
      );
    }

    final cardElevation = isDark ? 0.0 : 2.0;
    final cardShadowColor = Colors.black.withValues(alpha: isDark ? 0.3 : 0.08);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.passType != null ? AppTexts.managePassTypesEditTitle : AppTexts.managePassTypesNewTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 580),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Card(
                          elevation: cardElevation,
                          shadowColor: cardShadowColor,
                          shape: bentoShape,
                          color: cardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: content,
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
