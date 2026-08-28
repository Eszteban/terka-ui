import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../controllers/route_planner_cubit.dart';
import 'package:terka/theme/app_texts.dart';
import 'package:terka/theme/app_tokens.dart';
import 'autocomplete_search_field.dart';

class PlanSearchResult {
  final bool hasMeaningfulResponse;
  final String responseText;
  final String query;
  final Map<String, dynamic>? requestVariables;
  final Map<String, dynamic>? responseJson;
  final String? nextPageCursor;
  final String? fromPlaceToken;
  final String? toPlaceToken;
  final List<double>? fromCoordinates;
  final List<double>? toCoordinates;

  const PlanSearchResult({
    required this.hasMeaningfulResponse,
    required this.responseText,
    this.query = '',
    this.requestVariables,
    this.responseJson,
    this.nextPageCursor,
    this.fromPlaceToken,
    this.toPlaceToken,
    this.fromCoordinates,
    this.toCoordinates,
  });
}


class RoutePlanForm extends StatefulWidget {
  final TextEditingController fromController;
  final TextEditingController toController;
  final DateTime? selectedDate;
  final double transfers;
  final double maxWalk;
  final Set<String> selectedTransportModes;
  final bool ticketWatch;
  final ValueChanged<PlanSearchResult> onSearch;
  final VoidCallback onPickDate;
  final ValueChanged<double> onTransfersChanged;
  final ValueChanged<double> onMaxWalkChanged;
  final ValueChanged<String> onTransportModeToggle;
  final ValueChanged<bool> onTicketWatchChanged;
  final ValueChanged<bool> onLoadingChanged;

  final String? initialFromPlaceToken;
  final String? initialToPlaceToken;
  final List<double>? initialFromCoordinates;
  final List<double>? initialToCoordinates;
  final bool autofocusFrom;
  final Function(String? token, List<double>? coordinates)? onFromPlaceChanged;
  final Function(String? token, List<double>? coordinates)? onToPlaceChanged;

  const RoutePlanForm({
    super.key,
    required this.fromController,
    required this.toController,
    required this.selectedDate,
    required this.transfers,
    required this.maxWalk,
    required this.selectedTransportModes,
    required this.ticketWatch,
    required this.onSearch,
    required this.onPickDate,
    required this.onTransfersChanged,
    required this.onMaxWalkChanged,
    required this.onTransportModeToggle,
    required this.onTicketWatchChanged,
    required this.onLoadingChanged,
    this.initialFromPlaceToken,
    this.initialToPlaceToken,
    this.initialFromCoordinates,
    this.initialToCoordinates,
    this.autofocusFrom = false,
    this.onFromPlaceChanged,
    this.onToPlaceChanged,
  });

  @override
  State<RoutePlanForm> createState() => _RoutePlanFormState();
}

class _RoutePlanFormState extends State<RoutePlanForm>
    with TickerProviderStateMixin {
  bool _showAdvancedFields = false;
  bool _planForNow = true;
  bool _isSwapping = false;
  final FocusNode _fromFocusNode = FocusNode();
  final FocusNode _toFocusNode = FocusNode();
  bool _isLoadingPlan = false;
  String? _selectedFromPlaceToken;
  String? _selectedToPlaceToken;
  List<double>? _selectedFromCoordinates;
  List<double>? _selectedToCoordinates;
  TimeOfDay? _departureTime;
  TimeOfDay? _arrivalTime;

  void _onFromTextChanged() {
    if (_isSwapping) return;
    final text = widget.fromController.text.trim();
    final currentTokenName = _selectedFromPlaceToken != null && _selectedFromPlaceToken!.contains('::')
        ? _selectedFromPlaceToken!.split('::').first
        : (_selectedFromPlaceToken ?? '');
    if (text != currentTokenName && text != _selectedFromPlaceToken) {
      _selectedFromPlaceToken = null;
      _selectedFromCoordinates = null;
      debugPrint('DEBUG RoutePlanForm: onFromTextChanged clears token. Calling onFromPlaceChanged(null, null)');
      widget.onFromPlaceChanged?.call(null, null);
    }
  }

  void _onToTextChanged() {
    if (_isSwapping) return;
    final text = widget.toController.text.trim();
    final currentTokenName = _selectedToPlaceToken != null && _selectedToPlaceToken!.contains('::')
        ? _selectedToPlaceToken!.split('::').first
        : (_selectedToPlaceToken ?? '');
    if (text != currentTokenName && text != _selectedToPlaceToken) {
      _selectedToPlaceToken = null;
      _selectedToCoordinates = null;
      debugPrint('DEBUG RoutePlanForm: onToTextChanged clears token. Calling onToPlaceChanged(null, null)');
      widget.onToPlaceChanged?.call(null, null);
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedFromPlaceToken = widget.initialFromPlaceToken;
    if (_selectedFromPlaceToken != null && _selectedFromPlaceToken!.contains('::')) {
      widget.fromController.text = _selectedFromPlaceToken!.split('::').first;
    } else if (_selectedFromPlaceToken != null) {
      widget.fromController.text = _selectedFromPlaceToken!;
    }

    _selectedToPlaceToken = widget.initialToPlaceToken;
    if (_selectedToPlaceToken != null && _selectedToPlaceToken!.contains('::')) {
      widget.toController.text = _selectedToPlaceToken!.split('::').first;
    } else if (_selectedToPlaceToken != null) {
      widget.toController.text = _selectedToPlaceToken!;
    }

    _selectedFromCoordinates = widget.initialFromCoordinates;
    _selectedToCoordinates = widget.initialToCoordinates;

    widget.fromController.addListener(_onFromTextChanged);
    widget.toController.addListener(_onToTextChanged);

    _fromFocusNode.addListener(() {
      setState(() {});
    });
    _toFocusNode.addListener(() {
      setState(() {});
    });

    if (widget.autofocusFrom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fromFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.fromController.removeListener(_onFromTextChanged);
    widget.toController.removeListener(_onToTextChanged);
    _fromFocusNode.dispose();
    _toFocusNode.dispose();
    super.dispose();
  }


  bool _doubleListsEqual(List<double>? a, List<double>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant RoutePlanForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('DEBUG RoutePlanForm didUpdateWidget running!');
    debugPrint(' - oldWidget initialFromPlaceToken: ${oldWidget.initialFromPlaceToken}');
    debugPrint(' - new widget initialFromPlaceToken: ${widget.initialFromPlaceToken}');
    debugPrint(' - oldWidget initialToPlaceToken: ${oldWidget.initialToPlaceToken}');
    debugPrint(' - new widget initialToPlaceToken: ${widget.initialToPlaceToken}');

    if (widget.fromController != oldWidget.fromController) {
      oldWidget.fromController.removeListener(_onFromTextChanged);
      widget.fromController.addListener(_onFromTextChanged);
    }
    if (widget.toController != oldWidget.toController) {
      oldWidget.toController.removeListener(_onToTextChanged);
      widget.toController.addListener(_onToTextChanged);
    }

    if (widget.initialFromPlaceToken != oldWidget.initialFromPlaceToken) {
      _selectedFromPlaceToken = widget.initialFromPlaceToken;
      _isSwapping = true;
      if (_selectedFromPlaceToken != null && _selectedFromPlaceToken!.contains('::')) {
        widget.fromController.text = _selectedFromPlaceToken!.split('::').first;
      } else if (_selectedFromPlaceToken != null) {
        widget.fromController.text = _selectedFromPlaceToken!;
      } else {
        widget.fromController.text = '';
      }
      _isSwapping = false;
    }
    if (widget.initialToPlaceToken != oldWidget.initialToPlaceToken) {
      _selectedToPlaceToken = widget.initialToPlaceToken;
      _isSwapping = true;
      if (_selectedToPlaceToken != null && _selectedToPlaceToken!.contains('::')) {
        widget.toController.text = _selectedToPlaceToken!.split('::').first;
      } else if (_selectedToPlaceToken != null) {
        widget.toController.text = _selectedToPlaceToken!;
      } else {
        widget.toController.text = '';
      }
      _isSwapping = false;
    }
    if (!_doubleListsEqual(widget.initialFromCoordinates, oldWidget.initialFromCoordinates)) {
      _selectedFromCoordinates = widget.initialFromCoordinates;
    }
    if (!_doubleListsEqual(widget.initialToCoordinates, oldWidget.initialToCoordinates)) {
      _selectedToCoordinates = widget.initialToCoordinates;
    }
    if (widget.autofocusFrom != oldWidget.autofocusFrom && widget.autofocusFrom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fromFocusNode.requestFocus();
        }
      });
    }

    final previousDate = oldWidget.selectedDate;
    final currentDate = widget.selectedDate;
    final dateChanged = previousDate == null
        ? currentDate != null
        : currentDate == null ||
              previousDate.year != currentDate.year ||
              previousDate.month != currentDate.month ||
              previousDate.day != currentDate.day;

    if (!dateChanged) {
      return;
    }

    setState(() {
      _arrivalTime = null;
      _departureTime = const TimeOfDay(hour: 0, minute: 0);
      _planForNow = false;
    });
  }

  void _swapRouteLocations() {
    _isSwapping = true;
    setState(() {
      final tempText = widget.fromController.text;
      widget.fromController.text = widget.toController.text;
      widget.toController.text = tempText;

      final tempToken = _selectedFromPlaceToken;
      _selectedFromPlaceToken = _selectedToPlaceToken;
      _selectedToPlaceToken = tempToken;

      final tempCoordinates = _selectedFromCoordinates;
      _selectedFromCoordinates = _selectedToCoordinates;
      _selectedToCoordinates = tempCoordinates;
    });
    widget.onFromPlaceChanged?.call(_selectedFromPlaceToken, _selectedFromCoordinates);
    widget.onToPlaceChanged?.call(_selectedToPlaceToken, _selectedToCoordinates);
    _isSwapping = false;
  }


  Future<void> _submitPlanSearch() async {
    if (_isLoadingPlan) {
      return;
    }

    setState(() {
      _isLoadingPlan = true;
    });
    widget.onLoadingChanged(true);

    final fromPlaceToken =
        widget.initialFromPlaceToken ?? _selectedFromPlaceToken ?? widget.fromController.text.trim();
    final toPlaceToken =
        widget.initialToPlaceToken ?? _selectedToPlaceToken ?? widget.toController.text.trim();
    final fromCoordinates =
        widget.initialFromCoordinates ?? _selectedFromCoordinates;
    final toCoordinates =
        widget.initialToCoordinates ?? _selectedToCoordinates;

    final result = await context.read<RoutePlannerCubit>().searchRoutes(
      fromPlaceToken: fromPlaceToken,
      toPlaceToken: toPlaceToken,
      fromCoordinates: fromCoordinates,
      toCoordinates: toCoordinates,
      selectedDate: widget.selectedDate,
      departureTime: _departureTime,
      arrivalTime: _arrivalTime,
      planForNow: _planForNow,
      selectedTransportModes: widget.selectedTransportModes,
    );

    widget.onLoadingChanged(false);
    widget.onSearch(result);

    if (mounted) {
      setState(() {
        _isLoadingPlan = false;
      });
    }
  }

  String _twoDigits(int value, {int padTo = 2}) {
    return value.toString().padLeft(padTo, '0');
  }

  String _formatTimeLabel(TimeOfDay? time) {
    if (time == null) {
      return AppTexts.formPickTime;
    }
    return '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
  }

  Future<void> _pickTime({required bool isArrival}) async {
    final initialTime = isArrival
        ? (_arrivalTime ?? TimeOfDay.now())
        : (_departureTime ?? TimeOfDay.now());

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _planForNow = false;
      if (isArrival) {
        _arrivalTime = picked;
      } else {
        _departureTime = picked;
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      heightFactor: 1.0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.formMaxWidth),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              (_fromFocusNode.hasFocus ||
                                  _toFocusNode.hasFocus)
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withValues(
                                  alpha: isDark ? 0.3 : 0.4,
                                ),
                          width:
                              (_fromFocusNode.hasFocus ||
                                  _toFocusNode.hasFocus)
                              ? 1.6
                              : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(
                              alpha: isDark ? 0.15 : 0.04,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AutocompleteSearchField(
                            controller: widget.fromController,
                            focusNode: _fromFocusNode,
                            key: const Key('search1'),
                            labelText: AppTexts.formDeparture,
                            hintText: AppTexts.formHintCharCount,
                            searchStops: true,
                            searchAddresses: true,
                            searchLines: false,
                            isCurrentLocationEnabled: true,
                            prefixIcon: IconButton(
                              icon: Icon(
                                Icons.my_location_rounded,
                                color: colorScheme.primary,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              onPressed: () => _setCurrentLocation(true),
                              tooltip: AppTexts.isHungarian ? 'Jelenlegi helyzet használata' : 'Use current location',
                            ),
                            onSuggestionSelected: (entry) {
                              final token = entry.id == 'CURRENT_LOCATION'
                                  ? null
                                  : (entry.id == null ? entry.name : '${entry.name}::${entry.id}');
                              if (entry.id == 'CURRENT_LOCATION') {
                                _setCurrentLocation(true);
                                return;
                              }
                              widget.fromController.text = entry.name;
                              widget.fromController.selection = TextSelection.fromPosition(
                                TextPosition(offset: entry.name.length),
                              );
                              setState(() {
                                _selectedFromPlaceToken = token;
                                _selectedFromCoordinates = entry.coordinates;
                              });
                              debugPrint('DEBUG RoutePlanForm: AutocompleteSearchField(from) onSuggestionSelected -> name: ${entry.name}, id: ${entry.id}, coords: ${entry.coordinates}, token: $token');
                              debugPrint('DEBUG RoutePlanForm: Calling onFromPlaceChanged($token, ${entry.coordinates})');
                              widget.onFromPlaceChanged?.call(token, entry.coordinates);
                              _fromFocusNode.unfocus();
                            },
                            onClear: () {
                              setState(() {
                                _selectedFromPlaceToken = null;
                                _selectedFromCoordinates = null;
                              });
                              debugPrint('DEBUG RoutePlanForm: from onClear -> Calling onFromPlaceChanged(null, null)');
                              widget.onFromPlaceChanged?.call(null, null);
                            },
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: colorScheme.outlineVariant.withValues(
                              alpha: isDark ? 0.25 : 0.3,
                            ),
                            indent: 48,
                            endIndent: 48,
                          ),
                          AutocompleteSearchField(
                            controller: widget.toController,
                            focusNode: _toFocusNode,
                            key: const Key('search2'),
                            labelText: AppTexts.formArrival,
                            hintText: AppTexts.formHintCharCount,
                            searchStops: true,
                            searchAddresses: true,
                            searchLines: false,
                            isCurrentLocationEnabled: true,
                            prefixIcon: IconButton(
                              icon: Icon(
                                Icons.location_on_rounded,
                                color: colorScheme.primary,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              onPressed: () => _setCurrentLocation(false),
                              tooltip: AppTexts.isHungarian ? 'Jelenlegi helyzet használata' : 'Use current location',
                            ),
                            onSuggestionSelected: (entry) {
                              final token = entry.id == 'CURRENT_LOCATION'
                                  ? null
                                  : (entry.id == null ? entry.name : '${entry.name}::${entry.id}');
                              if (entry.id == 'CURRENT_LOCATION') {
                                _setCurrentLocation(false);
                                return;
                              }
                              widget.toController.text = entry.name;
                              widget.toController.selection = TextSelection.fromPosition(
                                TextPosition(offset: entry.name.length),
                              );
                              setState(() {
                                _selectedToPlaceToken = token;
                                _selectedToCoordinates = entry.coordinates;
                              });
                              debugPrint('DEBUG RoutePlanForm: AutocompleteSearchField(to) onSuggestionSelected -> name: ${entry.name}, id: ${entry.id}, coords: ${entry.coordinates}, token: $token');
                              debugPrint('DEBUG RoutePlanForm: Calling onToPlaceChanged($token, ${entry.coordinates})');
                              widget.onToPlaceChanged?.call(token, entry.coordinates);
                              _toFocusNode.unfocus();
                            },
                            onClear: () {
                              setState(() {
                                _selectedToPlaceToken = null;
                                _selectedToCoordinates = null;
                              });
                              debugPrint('DEBUG RoutePlanForm: to onClear -> Calling onToPlaceChanged(null, null)');
                              widget.onToPlaceChanged?.call(null, null);
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 12,
                      child: Material(
                        type: MaterialType.circle,
                        color: colorScheme.surfaceContainerLowest,
                        elevation: 3,
                        shadowColor: AppColors.black.withValues(alpha: 0.3),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: isDark ? 0.4 : 0.5,
                              ),
                              width: 1.0,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.swap_vert,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            onPressed: _swapRouteLocations,
                            tooltip: AppTexts.formSwap,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment<bool>(
                      value: true,
                      icon: const Icon(Icons.bolt),
                      label: Text(AppTexts.formDepartNow),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(AppTexts.formDepartLater),
                    ),
                  ],
                  selected: {_planForNow},
                  onSelectionChanged: (selection) {
                    if (selection.isNotEmpty) {
                      setState(() {
                        _planForNow = selection.first;
                      });
                    }
                  },
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: !_planForNow
                      ? Column(
                          children: [
                            const SizedBox(height: AppSpacing.lg),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.black.withValues(
                                      alpha: isDark ? 0.15 : 0.04,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: colorScheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  onTap: widget.onPickDate,
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: AppTexts.formDate,
                                      suffixIcon: const Icon(
                                        Icons.calendar_today,
                                      ),
                                      filled: true,
                                      fillColor: AppColors.transparent,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          14,
                                        ),
                                        borderSide: BorderSide(
                                          color: colorScheme.outlineVariant
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          14,
                                        ),
                                        borderSide: BorderSide(
                                          color: colorScheme.outlineVariant
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      widget.selectedDate == null
                                          ? AppTexts.formPickDate
                                          : '${widget.selectedDate!.toLocal()}'
                                                .split(' ')[0],
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.black.withValues(
                                            alpha: isDark ? 0.15 : 0.04,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: colorScheme.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(14),
                                      child: InkWell(
                                        onTap: () =>
                                            _pickTime(isArrival: false),
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: AppTexts.formDepartureTime,
                                            suffixIcon: const Icon(
                                              Icons.access_time,
                                            ),
                                            filled: true,
                                            fillColor: AppColors.transparent,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide(
                                                color: colorScheme
                                                    .outlineVariant
                                                    .withValues(alpha: 0.4),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide(
                                                color: colorScheme
                                                    .outlineVariant
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            _formatTimeLabel(_departureTime),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.black.withValues(
                                            alpha: isDark ? 0.15 : 0.04,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: colorScheme.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(14),
                                      child: InkWell(
                                        onTap: () =>
                                            _pickTime(isArrival: true),
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: AppTexts.formArrivalTime,
                                            suffixIcon: const Icon(
                                              Icons.access_time,
                                            ),
                                            filled: true,
                                            fillColor: AppColors.transparent,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide(
                                                color: colorScheme
                                                    .outlineVariant
                                                    .withValues(alpha: 0.4),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide(
                                                color: colorScheme
                                                    .outlineVariant
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            _formatTimeLabel(_arrivalTime),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoadingPlan ? null : _submitPlanSearch,
                    icon: const Icon(Icons.search),
                    label: Text(AppTexts.formSearch),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(
                        AppSpacing.touchTarget,
                        AppSpacing.touchTarget,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAdvancedFields = !_showAdvancedFields;
                      });
                    },
                    icon: Icon(
                      _showAdvancedFields
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                    label: Text(
                      _showAdvancedFields
                          ? AppTexts.formHideAdvanced
                          : AppTexts.formShowAdvanced,
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _showAdvancedFields
                      ? Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: isDark ? 0.3 : 0.4,
                                ),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withValues(
                                    alpha: isDark ? 0.15 : 0.04,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          AppTexts.formTransfers,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                      ),
                                      Expanded(
                                        child: Slider(
                                          value: widget.transfers,
                                          min: 0,
                                          max: 5,
                                          divisions: 5,
                                          label: '${widget.transfers.toInt()}',
                                          onChanged: widget.onTransfersChanged,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          AppTexts.formWalking,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                      ),
                                      Expanded(
                                        child: Slider(
                                          value: widget.maxWalk,
                                          min: 0,
                                          max: 5000,
                                          divisions: 15,
                                          label: '${widget.maxWalk.toInt()}',
                                          onChanged: widget.onMaxWalkChanged,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppTexts.formTransportModes,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Wrap(
                                        spacing: AppSpacing.sm,
                                        runSpacing: AppSpacing.sm,
                                        children: _buildTransportChips(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppTexts.formTicketWatch,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minWidth: 48,
                                          minHeight: 48,
                                        ),
                                        child: FilterChip(
                                          label: Text(AppTexts.formTicketWatch),
                                          selected: widget.ticketWatch,
                                          backgroundColor:
                                              colorScheme.surfaceContainerLowest,
                                          selectedColor: isDark
                                              ? colorScheme.primaryContainer
                                                    .withValues(alpha: 0.3)
                                              : colorScheme.primaryContainer
                                                    .withValues(alpha: 0.6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          side: widget.ticketWatch
                                              ? BorderSide(
                                                  color: colorScheme.primary,
                                                  width: 1.2,
                                                )
                                              : BorderSide(
                                                  color: colorScheme
                                                      .outlineVariant
                                                      .withValues(
                                                        alpha: isDark
                                                            ? 0.4
                                                            : 0.3,
                                                      ),
                                                ),
                                          elevation: 1.5,
                                          pressElevation: 3,
                                          shadowColor:
                                              AppColors.black.withValues(
                                            alpha: isDark ? 0.3 : 0.12,
                                          ),
                                          selectedShadowColor:
                                              AppColors.black.withValues(
                                            alpha: isDark ? 0.3 : 0.12,
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.padded,
                                          onSelected:
                                              widget.onTicketWatchChanged,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTransportChips() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final unselectedBg = colorScheme.surfaceContainerLowest;
    final selectedBg = isDark
        ? colorScheme.primaryContainer.withValues(alpha: 0.3)
        : colorScheme.primaryContainer.withValues(alpha: 0.6);

    const labels = [
      'Helyi busz',
      'Helyközi busz',
      'Vonat',
      'Metró',
      'Troli',
      'Villamos',
      'Hajó',
    ];

    return labels.map((label) {
      final selected = widget.selectedTransportModes.contains(label);
      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: FilterChip(
          label: Text(AppTexts.localizeTransportMode(label)),
          selected: selected,
          backgroundColor: unselectedBg,
          selectedColor: selectedBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: selected
              ? BorderSide(color: colorScheme.primary, width: 1.2)
              : BorderSide(
                  color: colorScheme.outlineVariant.withValues(
                    alpha: isDark ? 0.4 : 0.3,
                  ),
                ),
          elevation: 1.5,
          pressElevation: 3,
          shadowColor: AppColors.black.withValues(alpha: isDark ? 0.3 : 0.12),
          selectedShadowColor: AppColors.black.withValues(
            alpha: isDark ? 0.3 : 0.12,
          ),
          materialTapTargetSize: MaterialTapTargetSize.padded,
          onSelected: (_) => widget.onTransportModeToggle(label),
        ),
      );
    }).toList();
  }

  Future<void> _setCurrentLocation(bool isFromField) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(AppTexts.mapLocationDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(AppTexts.mapPermissionRequired);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(AppTexts.mapPermissionRequired);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      final String name = AppTexts.isHungarian ? 'Jelenlegi helyzet' : 'Current location';
      final String token = '$name::${position.latitude},${position.longitude}';
      final List<double> coords = [position.longitude, position.latitude];

      setState(() {
        if (isFromField) {
          widget.fromController.text = name;
          _selectedFromPlaceToken = token;
          _selectedFromCoordinates = coords;
          widget.onFromPlaceChanged?.call(token, coords);
          _fromFocusNode.unfocus();
        } else {
          widget.toController.text = name;
          _selectedToPlaceToken = token;
          _selectedToCoordinates = coords;
          widget.onToPlaceChanged?.call(token, coords);
          _toFocusNode.unfocus();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString()),
          ),
        );
      }
    }
  }
}

