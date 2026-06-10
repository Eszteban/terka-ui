import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../constants/search_api.dart';
import '../../controllers/plan_response_controller.dart';
import '../../services/graphql/graphql_client.dart';
import '../../services/graphql/graphql_queries.dart';

import '../../theme/app_texts.dart';
import '../../theme/app_tokens.dart';

enum _ActiveSearchField { none, from, to }

class PlanSearchResult {
  final bool hasMeaningfulResponse;
  final String responseText;
  final String query;
  final Map<String, dynamic>? requestVariables;
  final Map<String, dynamic>? responseJson;
  final String? nextPageCursor;

  const PlanSearchResult({
    required this.hasMeaningfulResponse,
    required this.responseText,
    this.query = '',
    this.requestVariables,
    this.responseJson,
    this.nextPageCursor,
  });
}

class _SuggestionEntry {
  final String name;
  final String? id;
  final List<double>? coordinates;
  final List<IconData> icons;

  const _SuggestionEntry({
    required this.name,
    required this.id,
    required this.coordinates,
    required this.icons,
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
  });

  @override
  State<RoutePlanForm> createState() => _RoutePlanFormState();
}

class _RoutePlanFormState extends State<RoutePlanForm>
    with TickerProviderStateMixin {
  static const bool _useLocalSearch = false;
  static const bool _deduplicateSuggestions = false;

  bool _showAdvancedFields = false;
  bool _planForNow = true;
  final FocusNode _fromFocusNode = FocusNode();
  final FocusNode _toFocusNode = FocusNode();
  Timer? _debounce;
  bool _isLoadingSuggestions = false;
  bool _isLoadingPlan = false;
  List<String> _suggestions = [];
  List<List<IconData>> _suggestionIcons = [];
  List<_SuggestionEntry> _suggestionEntries = [];
  String? _selectedFromPlaceToken;
  String? _selectedToPlaceToken;
  List<double>? _selectedFromCoordinates;
  List<double>? _selectedToCoordinates;
  TimeOfDay? _departureTime;
  TimeOfDay? _arrivalTime;
  _ActiveSearchField _activeSearchField = _ActiveSearchField.none;
  final GraphqlClient _graphqlClient = const GraphqlClient();

  static const List<String> _localStationSuggestions = [
    'Budapest',
    'Debrecen',
    'Szeged',
    'Miskolc',
    'Pécs',
    'Győr',
    'Nyíregyháza',
    'Kecskemét',
    'Székesfehérvár',
    'Szombathely',
    'Tatabánya',
    'Kaposvár',
    'Békéscsaba',
    'Eger',
    'Zalaegerszeg',
    'Nagykanizsa',
    'Dunaújváros',
    'Sopron',
    'Veszprém',
    'Szolnok',
  ];

  @override
  void initState() {
    super.initState();
    _fromFocusNode.addListener(() {
      setState(() {});
      if (_fromFocusNode.hasFocus) {
        setState(() {
          _activeSearchField = _ActiveSearchField.from;
        });
        _onQueryChanged(widget.fromController.text);
      }
    });
    _toFocusNode.addListener(() {
      setState(() {});
      if (_toFocusNode.hasFocus) {
        setState(() {
          _activeSearchField = _ActiveSearchField.to;
        });
        _onQueryChanged(widget.toController.text);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fromFocusNode.dispose();
    _toFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RoutePlanForm oldWidget) {
    super.didUpdateWidget(oldWidget);

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

  void _swapStartAndDestination() {
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

      _suggestions = const [];
      _suggestionIcons = const [];
      _suggestionEntries = const [];
      _isLoadingSuggestions = false;
    });
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();

    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      final name = AppTexts.isHungarian ? 'Jelenlegi helyzet' : 'Current location';
      setState(() {
        _suggestions = [name];
        _suggestionIcons = [[Icons.my_location]];
        _suggestionEntries = [
          _SuggestionEntry(
            name: name,
            id: 'CURRENT_LOCATION',
            coordinates: null,
            icons: const [Icons.my_location],
          )
        ];
        _isLoadingSuggestions = false;
      });
      return;
    }

    if (trimmedQuery.length < 3) {
      setState(() {
        _suggestions = [];
        _suggestionIcons = [];
        _suggestionEntries = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetchSuggestions(trimmedQuery);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() {
      _isLoadingSuggestions = true;
    });

    if (_useLocalSearch) {
      final filtered = _localStationSuggestions
          .where((name) => name.toLowerCase().contains(query.toLowerCase()))
          .take(10)
          .toList();

      final entries = filtered
          .map(
            (name) => _SuggestionEntry(
              name: name,
              id: null,
              coordinates: null,
              icons: const [Icons.directions_bus],
            ),
          )
          .toList();

      setState(() {
        _suggestions = entries.map((entry) => entry.name).toList();
        _suggestionIcons = entries.map((entry) => entry.icons).toList();
        _suggestionEntries = entries;
        _isLoadingSuggestions = false;
      });
      return;
    }

    try {
      final stationUri = Uri.parse(searchApiUrl).replace(queryParameters: {'q': query, 'limit': '10', 'lang': 'hu'});
      final photonUri = Uri.parse('https://mavplusz.hu//photon/api').replace(queryParameters: {
        'limit': '10',
        'q': query,
        'location_bias_scale': '0.1',
        'osm_tag': '!place:region',
        'zoom': '12',
        'bbox': '16,45.273,23,48.7',
        'lang': 'hu',
      });

      final results = await Future.wait([
        http
            .get(stationUri, headers: apiRequestHeaders)
            .timeout(const Duration(seconds: 5))
            .catchError((_) => http.Response('{"features":[]}', 500)),
        http
            .get(photonUri, headers: apiRequestHeaders)
            .timeout(const Duration(seconds: 5))
            .catchError((_) => http.Response('{"features":[]}', 500)),
      ]);

      final stationResponse = results[0];
      final photonResponse = results[1];

      final entries = <_SuggestionEntry>[];

      // Prepend current location option
      final currentLocName = AppTexts.isHungarian ? 'Jelenlegi helyzet' : 'Current location';
      entries.add(
        _SuggestionEntry(
          name: currentLocName,
          id: 'CURRENT_LOCATION',
          coordinates: null,
          icons: const [Icons.my_location],
        ),
      );

      // 1. Parse station suggestions
      if (stationResponse.statusCode == 200) {
        final dynamic body = jsonDecode(stationResponse.body);
        if (body is Map && body['features'] is List) {
          for (final item in body['features']) {
            if (item is Map) {
              final properties = item['properties'];
              final geometry = item['geometry'];
              String? id;
              String? name;
              List<double>? coord;
              List<String> modes = const [];
              final rawId = item['id'];
              if (rawId is String) {
                id = rawId;
              }
              if (properties is Map) {
                final n = properties['name'];
                if (n is String) name = n;
                final m = properties['modes'];
                if (m is List) {
                  modes = m.whereType<String>().toList();
                }
              }
              if (geometry is Map && geometry['coordinates'] is List) {
                final c = geometry['coordinates'];
                if (c.length == 2 && c[0] is num && c[1] is num) {
                  coord = [c[0].toDouble(), c[1].toDouble()];
                }
              }
              if (name != null) {
                entries.add(
                  _SuggestionEntry(
                    name: name,
                    id: id,
                    coordinates: coord,
                    icons: _iconsForModes(modes),
                  ),
                );
              }
            }
          }
        }
      }

      // 2. Parse Photon address suggestions
      if (photonResponse.statusCode == 200) {
        final dynamic body = jsonDecode(photonResponse.body);
        if (body is Map && body['features'] is List) {
          for (final item in body['features']) {
            if (item is Map) {
              final properties = item['properties'];
              final geometry = item['geometry'];
              List<double>? coord;
              if (geometry is Map && geometry['coordinates'] is List) {
                final c = geometry['coordinates'];
                if (c.length == 2 && c[0] is num && c[1] is num) {
                  coord = [c[0].toDouble(), c[1].toDouble()];
                }
              }
              if (properties is Map && coord != null) {
                final formattedName = _formatPhotonName(properties.cast<String, dynamic>());
                final lat = coord[1];
                final lon = coord[0];
                entries.add(
                  _SuggestionEntry(
                    name: formattedName,
                    id: '$lat,$lon',
                    coordinates: coord,
                    icons: const [Icons.place],
                  ),
                );
              }
            }
          }
        }
      }

      List<_SuggestionEntry> finalEntries = entries;

      if (_deduplicateSuggestions) {
        final seenByName = <String, int>{};
        final dedupEntries = <_SuggestionEntry>[];

        for (var i = 0; i < entries.length; i++) {
          final entry = entries[i];
          final existingIndex = seenByName[entry.name];

          if (existingIndex == null) {
            seenByName[entry.name] = dedupEntries.length;
            dedupEntries.add(entry);
          } else {
            final existing = dedupEntries[existingIndex];
            dedupEntries[existingIndex] = _SuggestionEntry(
              name: existing.name,
              id: existing.id ?? entry.id,
              coordinates: existing.coordinates ?? entry.coordinates,
              icons: _mergeUniqueIcons(existing.icons, entry.icons),
            );
          }
        }

        finalEntries = dedupEntries;
      }

      final limitedEntries = finalEntries.take(12).toList();

      setState(() {
        _suggestions = limitedEntries.map((entry) => entry.name).toList();
        _suggestionIcons = limitedEntries.map((entry) => entry.icons).toList();
        _suggestionEntries = limitedEntries;
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      debugPrint('API exception: $e');
      setState(() {
        _suggestions = [];
        _suggestionIcons = [];
        _suggestionEntries = [];
        _isLoadingSuggestions = false;
      });
    }
  }

  Future<void> _submitPlanSearch() async {
    if (_isLoadingPlan) {
      return;
    }

    setState(() {
      _isLoadingPlan = true;
    });
    widget.onLoadingChanged(true);

    final result = await _fetchPlanResponse();
    if (mounted) {
      setState(() {
        _isLoadingPlan = false;
      });
    }
    widget.onLoadingChanged(false);
    widget.onSearch(result);
  }

  Future<PlanSearchResult> _fetchPlanResponse() async {
    try {
      final now = DateTime.now();
      final selectedDate = _planForNow ? now : (widget.selectedDate ?? now);
      final fallbackTime = TimeOfDay.fromDateTime(now);
      final effectiveTime = _planForNow
          ? fallbackTime
          : (_arrivalTime ?? _departureTime ?? fallbackTime);
      final arriveBy = !_planForNow && _arrivalTime != null;
      final dateString =
          '${_twoDigits(selectedDate.year, padTo: 4)}-${_twoDigits(selectedDate.month)}-${_twoDigits(selectedDate.day)}';
      final timeString =
          '${_twoDigits(effectiveTime.hour)}:${_twoDigits(effectiveTime.minute)}';
      final fromPlaceToken =
          _selectedFromPlaceToken ?? widget.fromController.text.trim();
      final toPlaceToken =
          _selectedToPlaceToken ?? widget.toController.text.trim();

      final variables = <String, dynamic>{
        'arriveBy': arriveBy,
        'banned': <String, dynamic>{},
        'bikeReluctance': 1.0,
        'carReluctance': 1.0,
        'date': dateString,
        'fromPlace': fromPlaceToken,
        'modes': _toApiTransportModes(widget.selectedTransportModes),
        'numItineraries': 15,
        'preferred': <String, dynamic>{},
        'time': timeString,
        'toPlace': toPlaceToken,
        'unpreferred': <String, dynamic>{},
        'walkReluctance': 1.0,
        'walkSpeed': 1.3888888888888888,
        'wheelchair': false,
        'minTransferTime': 0,
        'transitPassFilter': <String>[],
        'comfortLevels': <String>[],
        'searchParameters': <String>[],
        'distributionChannel': 'ERTEKESITESI_CSATORNA#INTERNET',
        'distributionSubChannel': 'ERTEKESITESI_ALCSATORNA#EMMA',
        'pageCursor': '',
      };

      if (_selectedFromCoordinates != null || _selectedToCoordinates != null) {
        debugPrint(
          'Selected coords -> from: ${_selectedFromCoordinates ?? 'n/a'}, to: ${_selectedToCoordinates ?? 'n/a'}',
        );
      }

      final response = await _graphqlClient.execute(
        query: planQuery,
        variables: variables,
      );

      if (!response.isSuccess) {
        debugPrint(
          'Plan API error: status ${response.statusCode}, body: ${response.rawBody}',
        );
        return PlanSearchResult(
          hasMeaningfulResponse: false,
          query: planQuery,
          requestVariables: Map<String, dynamic>.from(variables),
          responseText:
              'HTTP ${response.statusCode}\n${response.rawBody.isNotEmpty ? response.rawBody : AppTexts.apiNoResponseBody}',
        );
      }

      final bodyMap = response.json;
      if (bodyMap == null) {
        return PlanSearchResult(
          hasMeaningfulResponse: false,
          responseText: AppTexts.apiResponseNotJson,
          query: planQuery,
          requestVariables: Map<String, dynamic>.from(variables),
        );
      }

      final data = bodyMap['data'];
      if (data is! Map) {
        return PlanSearchResult(
          hasMeaningfulResponse: false,
          responseText: _prettyJson(bodyMap),
          query: planQuery,
          requestVariables: Map<String, dynamic>.from(variables),
          responseJson: bodyMap,
        );
      }

      final plan = data['plan'];
      if (plan is! Map) {
        return PlanSearchResult(
          hasMeaningfulResponse: false,
          responseText: _prettyJson(bodyMap),
          query: planQuery,
          requestVariables: Map<String, dynamic>.from(variables),
          responseJson: bodyMap,
        );
      }

      final itineraries = plan['itineraries'];
      final nextPageCursor = PlanResponseController.extractNextPageCursor(
        plan.cast<String, dynamic>(),
      );
      return PlanSearchResult(
        hasMeaningfulResponse: itineraries is List && itineraries.isNotEmpty,
        responseText: _prettyJson(bodyMap),
        query: planQuery,
        requestVariables: Map<String, dynamic>.from(variables),
        responseJson: bodyMap,
        nextPageCursor: nextPageCursor,
      );
    } catch (e) {
      debugPrint('Plan API exception: $e');
      return PlanSearchResult(
        hasMeaningfulResponse: false,
        responseText: AppTexts.apiException(e.toString()),
        query: planQuery,
      );
    }
  }

  String _prettyJson(Object body) {
    try {
      return const JsonEncoder.withIndent('  ').convert(body);
    } catch (_) {
      return body.toString();
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

    if (picked == null) {
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

  List<Map<String, String>> _toApiTransportModes(Set<String> selectedModes) {
    const mapping = <String, List<String>>{
      'Helyi busz': ['BUS'],
      'Helyközi busz': ['COACH'],
      'Vonat': [
        'RAIL',
        'SUBURBAN_RAILWAY',
        'TRAMTRAIN',
        'RAIL_REPLACEMENT_BUS',
      ],
      'Metró': ['SUBWAY'],
      'Troli': ['TROLLEYBUS'],
      'Villamos': ['TRAM'],
      'Hajó': ['FERRY'],
    };

    final modes = <String>[];
    for (final modeLabel in selectedModes) {
      final mappedModes = mapping[modeLabel];
      if (mappedModes == null) {
        continue;
      }
      for (final mode in mappedModes) {
        if (!modes.contains(mode)) {
          modes.add(mode);
        }
      }
    }

    if (modes.isEmpty) {
      modes.addAll([
        'RAIL',
        'RAIL_REPLACEMENT_BUS',
        'SUBURBAN_RAILWAY',
        'TRAMTRAIN',
        'SUBWAY',
        'TRAM',
        'TROLLEYBUS',
        'BUS',
        'FERRY',
        'COACH',
      ]);
    }

    return modes.map((mode) => {'mode': mode}).toList();
  }

  void _onSuggestionTap(int index) {
    if (index < 0 || index >= _suggestionEntries.length) {
      return;
    }
    final entry = _suggestionEntries[index];
    if (entry.id == 'CURRENT_LOCATION') {
      _setCurrentLocation(_activeSearchField == _ActiveSearchField.from);
      return;
    }
    final token = entry.id == null ? entry.name : '${entry.name}::${entry.id}';

    if (_activeSearchField == _ActiveSearchField.from) {
      widget.fromController.text = entry.name;
      widget.fromController.selection = TextSelection.fromPosition(
        TextPosition(offset: entry.name.length),
      );
      _selectedFromPlaceToken = token;
      _selectedFromCoordinates = entry.coordinates;
      _fromFocusNode.unfocus();
    } else if (_activeSearchField == _ActiveSearchField.to) {
      widget.toController.text = entry.name;
      widget.toController.selection = TextSelection.fromPosition(
        TextPosition(offset: entry.name.length),
      );
      _selectedToPlaceToken = token;
      _selectedToCoordinates = entry.coordinates;
      _toFocusNode.unfocus();
    }

    setState(() {
      _suggestions = [];
      _suggestionIcons = [];
      _suggestionEntries = [];
      _activeSearchField = _ActiveSearchField.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.formMaxWidth),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: 4,
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
                        color: isDark
                            ? const Color(0xFF1A1615)
                            : Colors.white,
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
                            color: Colors.black.withValues(
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
                          TextField(
                            controller: widget.fromController,
                            focusNode: _fromFocusNode,
                            key: const Key('search1'),
                            decoration: InputDecoration(
                              labelText: AppTexts.formDeparture,
                              hintText: AppTexts.formHintCharCount,
                              filled: true,
                              fillColor: Colors.transparent,
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
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            onChanged: (value) {
                              _selectedFromPlaceToken = null;
                              _selectedFromCoordinates = null;
                              _onQueryChanged(value);
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
                          TextField(
                            controller: widget.toController,
                            focusNode: _toFocusNode,
                            key: const Key('search2'),
                            decoration: InputDecoration(
                              labelText: AppTexts.formArrival,
                              hintText: AppTexts.formHintCharCount,
                              filled: true,
                              fillColor: Colors.transparent,
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
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            onChanged: (value) {
                              _selectedToPlaceToken = null;
                              _selectedToCoordinates = null;
                              _onQueryChanged(value);
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 12,
                      child: Material(
                        type: MaterialType.circle,
                        color: isDark
                            ? const Color(0xFF1E1A19)
                            : Colors.white,
                        elevation: 3,
                        shadowColor: Colors.black.withValues(alpha: 0.3),
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
                            onPressed: _swapStartAndDestination,
                            tooltip: AppTexts.formSwap,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isLoadingSuggestions)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.md),
                    child: LinearProgressIndicator(),
                  ),
                if (_suggestions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: Card(
                        child: ListView.separated(
                          itemCount: _suggestions.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final entry = _suggestionEntries[index];
                            final suggestion = _suggestions[index];
                            final vehicleTypes =
                                index < _suggestionIcons.length
                                ? _suggestionIcons[index]
                                : const [Icons.directions_bus];

                            final isCurrentLocation = entry.id == 'CURRENT_LOCATION';

                            if (isCurrentLocation) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer.withValues(alpha: isDark ? 0.15 : 0.25),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.4),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.my_location_rounded,
                                        color: colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      suggestion,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    subtitle: Text(
                                      AppTexts.isHungarian
                                          ? 'Pozíció meghatározása GPS-szel'
                                          : 'Determine position using GPS',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    onTap: () => _onSuggestionTap(index),
                                  ),
                                ),
                              );
                            }

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              title: Row(
                                children: [
                                  ...vehicleTypes.map(
                                    (iconData) => Padding(
                                      padding: const EdgeInsets.only(
                                        right: 4,
                                      ),
                                      child: Icon(iconData, size: 24),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(suggestion)),
                                ],
                              ),
                              onTap: () => _onSuggestionTap(index),
                            );
                          },
                        ),
                      ),
                    ),
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
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.15 : 0.04,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: isDark
                                    ? const Color(0xFF1A1615)
                                    : Colors.white,
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
                                      fillColor: Colors.transparent,
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
                                          color: Colors.black.withValues(
                                            alpha: isDark ? 0.15 : 0.04,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: isDark
                                          ? const Color(0xFF1A1615)
                                          : Colors.white,
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
                                            fillColor: Colors.transparent,
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
                                          color: Colors.black.withValues(
                                            alpha: isDark ? 0.15 : 0.04,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: isDark
                                          ? const Color(0xFF1A1615)
                                          : Colors.white,
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
                                            fillColor: Colors.transparent,
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
                              color: isDark
                                  ? const Color(0xFF1A1615)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: isDark ? 0.3 : 0.4,
                                ),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
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
                                          backgroundColor: isDark
                                              ? const Color(0xFF1A1615)
                                              : Colors.white,
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
                                              Colors.black.withValues(
                                            alpha: isDark ? 0.3 : 0.12,
                                          ),
                                          selectedShadowColor:
                                              Colors.black.withValues(
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

    final unselectedBg = isDark ? const Color(0xFF1A1615) : Colors.white;
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
          shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
          selectedShadowColor: Colors.black.withValues(
            alpha: isDark ? 0.3 : 0.12,
          ),
          materialTapTargetSize: MaterialTapTargetSize.padded,
          onSelected: (_) => widget.onTransportModeToggle(label),
        ),
      );
    }).toList();
  }

  List<IconData> _iconsForModes(List<String> modes) {
    if (modes.isEmpty) {
      return const [Icons.directions_bus];
    }

    final mapped = <IconData>[];
    for (final mode in modes) {
      switch (mode) {
        case 'RAIL':
        case 'SUBURBAN_RAILWAY':
          mapped.add(Icons.train);
          break;
        case 'RAIL_REPLACEMENT_BUS':
          mapped.add(Icons.bus_alert);
          break;
        case 'BUS':
          mapped.add(Icons.airport_shuttle);
          break;
        case 'COACH':
          mapped.add(Icons.directions_bus);
          break;
        case 'SUBWAY':
          mapped.add(Icons.directions_subway);
          break;
        case 'TRAM':
        case 'TRAMTRAIN':
          mapped.add(Icons.tram);
          break;
        case 'TROLLEYBUS':
          mapped.add(Icons.directions_bus);
          break;
        case 'FERRY':
          mapped.add(Icons.directions_boat);
          break;
      }
    }

    final unique = <IconData>[];
    for (final icon in mapped) {
      if (!unique.contains(icon)) {
        unique.add(icon);
      }
    }

    return unique.isEmpty ? const [Icons.directions_bus] : unique;
  }

  List<IconData> _mergeUniqueIcons(
    List<IconData> first,
    List<IconData> second,
  ) {
    final merged = <IconData>[...first];
    for (final icon in second) {
      if (!merged.contains(icon)) {
        merged.add(icon);
      }
    }
    return merged;
  }

  Future<void> _setCurrentLocation(bool isFromField) async {
    setState(() {
      _isLoadingSuggestions = true;
    });

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
          _fromFocusNode.unfocus();
        } else {
          widget.toController.text = name;
          _selectedToPlaceToken = token;
          _selectedToCoordinates = coords;
          _toFocusNode.unfocus();
        }
        _suggestions = [];
        _suggestionIcons = [];
        _suggestionEntries = [];
        _activeSearchField = _ActiveSearchField.none;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString()),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  String _formatPhotonName(Map<String, dynamic> properties) {
    final name = properties['name']?.toString() ?? '';
    final street = properties['street']?.toString() ?? '';
    final houseNumber = properties['housenumber']?.toString() ?? '';
    final city = properties['city']?.toString() ?? '';
    final postcode = properties['postcode']?.toString() ?? '';

    // If name is just the house number, treat it as empty to avoid redundancy
    final cleanName = (name.isNotEmpty && RegExp(r'^\d+$').hasMatch(name)) ? '' : name;

    final parts = <String>[];

    if (cleanName.isNotEmpty) {
      parts.add(cleanName);
      if (street.isNotEmpty) {
        if (houseNumber.isNotEmpty) {
          parts.add('$street $houseNumber');
        } else {
          parts.add(street);
        }
      }
    } else if (street.isNotEmpty) {
      if (houseNumber.isNotEmpty) {
        parts.add('$street $houseNumber');
      } else {
        parts.add(street);
      }
    }

    if (city.isNotEmpty && !parts.contains(city)) {
      parts.add(city);
    }

    if (postcode.isNotEmpty) {
      parts.add(postcode);
    }

    return parts.isEmpty ? (AppTexts.isHungarian ? 'Ismeretlen hely' : 'Unknown location') : parts.join(', ');
  }
}
