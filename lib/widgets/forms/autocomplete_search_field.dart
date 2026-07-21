import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:terka/theme/app_texts.dart';
import 'package:terka/theme/app_tokens.dart';
import '../../constants/search_api.dart';
import '../../utils/stop_details_utils.dart';
import '../../utils/markup_text_utils.dart' as markup;
import '../../services/graphql/graphql_client.dart';
import '../../services/graphql/graphql_queries.dart';
import '../line_badge.dart';

enum SuggestionType { stop, address, route }

class SuggestionEntry {
  final String name;
  final String? id;
  final List<double>? coordinates;
  final List<IconData> icons;
  final SuggestionType type;
  final Map<String, dynamic>? rawData;

  const SuggestionEntry({
    required this.name,
    required this.id,
    required this.coordinates,
    required this.icons,
    required this.type,
    this.rawData,
  });
}

class AutocompleteSearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelText;
  final String hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isCurrentLocationEnabled;
  final bool searchStops;
  final bool searchAddresses;
  final bool searchLines;
  final bool autofocus;
  final bool isFullPage;
  final void Function(SuggestionEntry suggestion) onSuggestionSelected;
  final VoidCallback? onClear;
  final InputDecoration? decoration;
  final void Function(List<SuggestionEntry> suggestions, bool isLoading)? onSuggestionsChanged;

  const AutocompleteSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.labelText,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.isCurrentLocationEnabled = false,
    this.searchStops = true,
    this.searchAddresses = true,
    this.searchLines = false,
    this.autofocus = false,
    this.isFullPage = false,
    required this.onSuggestionSelected,
    this.onClear,
    this.decoration,
    this.onSuggestionsChanged,
  });

  @override
  State<AutocompleteSearchField> createState() => _AutocompleteSearchFieldState();
}

class _AutocompleteSearchFieldState extends State<AutocompleteSearchField> {
  Timer? _debounce;
  bool _isLoadingSuggestions = false;
  List<SuggestionEntry> _suggestionEntries = [];
  late final FocusNode _internalFocusNode;
  bool _showSuggestionsOverlay = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _showSuggestionsOverlay = _internalFocusNode.hasFocus;
    _internalFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    } else {
      _internalFocusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  int _compareAlphanumeric(String a, String b) {
    final regExp = RegExp(r'(\d+|\D+)');
    final matchesA = regExp.allMatches(a).map((m) => m.group(0)!).toList();
    final matchesB = regExp.allMatches(b).map((m) => m.group(0)!).toList();
    
    for (int i = 0; i < matchesA.length && i < matchesB.length; i++) {
      final partA = matchesA[i];
      final partB = matchesB[i];
      
      final numA = int.tryParse(partA);
      final numB = int.tryParse(partB);
      
      if (numA != null && numB != null) {
        if (numA != numB) return numA.compareTo(numB);
      } else {
        final cmp = partA.compareTo(partB);
        if (cmp != 0) return cmp;
      }
    }
    return matchesA.length.compareTo(matchesB.length);
  }

  void _onFocusChange() {
    if (_internalFocusNode.hasFocus) {
      if (mounted) {
        setState(() {
          _showSuggestionsOverlay = true;
        });
        _onQueryChanged(widget.controller.text);
      }
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _showSuggestionsOverlay = false;
          });
        }
      });
    }
  }

  void _updateSuggestionsState({
    List<SuggestionEntry>? entries,
    bool? isLoading,
  }) {
    if (!mounted) return;
    setState(() {
      if (entries != null) _suggestionEntries = entries;
      if (isLoading != null) _isLoadingSuggestions = isLoading;
    });
    widget.onSuggestionsChanged?.call(_suggestionEntries, _isLoadingSuggestions);
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      if (widget.isCurrentLocationEnabled) {
        final name = AppTexts.isHungarian ? 'Jelenlegi helyzet' : 'Current location';
        _updateSuggestionsState(
          entries: [
            SuggestionEntry(
              name: name,
              id: 'CURRENT_LOCATION',
              coordinates: null,
              icons: const [Icons.my_location],
              type: SuggestionType.address,
            ),
          ],
          isLoading: false,
        );
      } else {
        _updateSuggestionsState(
          entries: [],
          isLoading: false,
        );
      }
      return;
    }

    final hasDigits = RegExp(r'\d').hasMatch(trimmedQuery);
    if (trimmedQuery.length < 3 && !hasDigits) {
      _updateSuggestionsState(
        entries: [],
        isLoading: false,
      );
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetchSuggestions(trimmedQuery);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (!mounted) return;
    _updateSuggestionsState(isLoading: true);

    final newEntries = <SuggestionEntry>[];

    // Prepend current location if enabled and query is empty
    if (query.isEmpty && widget.isCurrentLocationEnabled) {
      final name = AppTexts.isHungarian ? 'Jelenlegi helyzet' : 'Current location';
      newEntries.add(
        SuggestionEntry(
          name: name,
          id: 'CURRENT_LOCATION',
          coordinates: null,
          icons: const [Icons.my_location],
          type: SuggestionType.address,
        ),
      );
    }

    try {
      final futures = <Future>[];

      // 1. Station geocoder search
      Future<void>? stopsFuture;
      if (widget.searchStops) {
        final baseStationUri = Uri.parse(searchApiUrl);
        final stationUri = baseStationUri.replace(queryParameters: {
          ...baseStationUri.queryParameters,
          'q': query,
          'limit': '10',
          'lang': 'hu',
        });
        stopsFuture = http.get(stationUri, headers: apiRequestHeaders).timeout(const Duration(seconds: 5)).then((response) {
          if (response.statusCode == 200) {
            final dynamic body = jsonDecode(response.body);
            if (body is Map && body['features'] is List) {
              for (final item in body['features']) {
                if (item is Map) {
                  final properties = item['properties'];
                  final geometry = item['geometry'];
                  String? id = item['id']?.toString();
                  String? name;
                  List<double>? coord;
                  List<String> modes = const [];
                  
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
                    newEntries.add(
                      SuggestionEntry(
                        name: name,
                        id: id,
                        coordinates: coord,
                        icons: _iconsForModes(modes),
                        type: SuggestionType.stop,
                      ),
                    );
                  }
                }
              }
            }
          }
        }).catchError((_) {});
        futures.add(stopsFuture);
      }

      // 2. Photon address geocoder search
      Future<void>? addressFuture;
      if (widget.searchAddresses) {
        final basePhotonUri = Uri.parse(photonApiUrl);
        final photonUri = basePhotonUri.replace(queryParameters: {
          ...basePhotonUri.queryParameters,
          'limit': '10',
          'q': query,
          'location_bias_scale': '0.1',
          'osm_tag': '!place:region',
          'zoom': '12',
          'bbox': '16,45.273,23,48.7',
          'lang': 'hu',
        });
        addressFuture = http.get(photonUri, headers: apiRequestHeaders).timeout(const Duration(seconds: 5)).then((response) {
          if (response.statusCode == 200) {
            final dynamic body = jsonDecode(response.body);
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
                    newEntries.add(
                      SuggestionEntry(
                        name: formattedName,
                        id: '$lat,$lon',
                        coordinates: coord,
                        icons: const [Icons.place],
                        type: SuggestionType.address,
                      ),
                    );
                  }
                }
              }
            }
          }
        }).catchError((_) {});
        futures.add(addressFuture);
      }

      // 3. Lines search via GraphQL
      Future<void>? linesFuture;
      if (widget.searchLines) {
        linesFuture = const GraphqlClient().execute(
          query: searchRoutesQuery,
          variables: {'name': query},
        ).timeout(const Duration(seconds: 5)).then((response) {
          if (response.isSuccess && response.json != null) {
            final data = response.json!['data'];
            final routes = data is Map ? data['routes'] : null;
            if (routes is List) {
              routes.sort((a, b) {
                final sA = (a is Map ? a['shortName']?.toString() : '') ?? '';
                final sB = (b is Map ? b['shortName']?.toString() : '') ?? '';
                return _compareAlphanumeric(sA, sB);
              });
              for (final r in routes) {
                if (r is Map) {
                  final gtfsId = r['gtfsId']?.toString();
                  final shortName = r['shortName']?.toString() ?? '-';
                  final longName = r['longName']?.toString();
                  final mode = r['mode']?.toString();
                  final color = r['color']?.toString() ?? '0A84FF';
                  final textColor = r['textColor']?.toString() ?? 'FFFFFF';
                  final agency = r['agency'] is Map ? r['agency']['name']?.toString() : null;

                  newEntries.add(
                    SuggestionEntry(
                      name: longName != null && longName.isNotEmpty ? '$shortName - $longName' : shortName,
                      id: gtfsId,
                      coordinates: null,
                      icons: const [Icons.directions_bus],
                      type: SuggestionType.route,
                      rawData: {
                        'gtfsId': gtfsId,
                        'shortName': shortName,
                        'longName': longName,
                        'mode': mode,
                        'color': color,
                        'textColor': textColor,
                        'agency': agency,
                      },
                    ),
                  );
                }
              }
            }
          }
        }).catchError((_) {});
        futures.add(linesFuture);
      }

      await Future.wait(futures);

      _updateSuggestionsState(
        entries: newEntries,
        isLoading: false,
      );
    } catch (_) {
      _updateSuggestionsState(isLoading: false);
    }
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

  String _formatPhotonName(Map<String, dynamic> properties) {
    final name = properties['name']?.toString() ?? '';
    final street = properties['street']?.toString() ?? '';
    final houseNumber = properties['housenumber']?.toString() ?? '';
    final city = properties['city']?.toString() ?? '';
    final postcode = properties['postcode']?.toString() ?? '';

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

    return parts.isEmpty
        ? (AppTexts.isHungarian ? 'Ismeretlen hely' : 'Unknown location')
        : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final inputDecoration = widget.decoration ??
        InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          filled: true,
          fillColor: AppColors.transparent,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    widget.controller.clear();
                    if (widget.onClear != null) {
                      widget.onClear!();
                    }
                    _onQueryChanged('');
                  },
                )
              : widget.suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        );

    final showSuggestions = widget.onSuggestionsChanged == null &&
        _showSuggestionsOverlay &&
        (_suggestionEntries.isNotEmpty || _isLoadingSuggestions);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _internalFocusNode,
          autofocus: widget.autofocus,
          decoration: inputDecoration,
          onChanged: (val) {
            setState(() {});
            _onQueryChanged(val);
          },
        ),
        if (_isLoadingSuggestions && widget.onSuggestionsChanged == null)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: LinearProgressIndicator(),
          ),
        if (showSuggestions && _suggestionEntries.isNotEmpty)
          widget.isFullPage
              ? Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    itemCount: _suggestionEntries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) => _buildSuggestionTile(ctx, idx, isDark, colorScheme),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: Card(
                      elevation: 4,
                      shadowColor: AppColors.black.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: isDark ? 0.25 : 0.3,
                          ),
                        ),
                      ),
                      margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _suggestionEntries.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, idx) => _buildSuggestionTile(ctx, idx, isDark, colorScheme),
                      ),
                    ),
                  ),
                ),
      ],
    );
  }

  Widget _buildSuggestionTile(
    BuildContext context,
    int index,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final entry = _suggestionEntries[index];
    final isCurrentLocation = entry.id == 'CURRENT_LOCATION';

    if (isCurrentLocation) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
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
              entry.name,
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
            onTap: () {
              _internalFocusNode.unfocus();
              widget.onSuggestionSelected(entry);
              setState(() {
                _suggestionEntries = [];
              });
            },
          ),
        ),
      );
    }

    if (entry.type == SuggestionType.route && entry.rawData != null) {
      final raw = entry.rawData!;
      final colorHex = raw['color']?.toString() ?? '0A84FF';
      final textHex = raw['textColor']?.toString() ?? 'FFFFFF';
      final shortName = raw['shortName']?.toString() ?? '-';
      final longName = raw['longName']?.toString() ?? '';
      final agency = raw['agency']?.toString();

      final parsedColor = StopDetailsUtils.hexColor(colorHex);
      final parsedTextColor = StopDetailsUtils.hexColor(textHex);
      final useSpan = markup.containsSpanMarkup(shortName);
      final cleanShortName = markup.plainTextFromHtml(shortName).trim();

      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        leading: LineBadge(
          lineLabel: cleanShortName,
          routeColor: parsedColor,
          routeTextColor: parsedTextColor,
          useSpanFont: useSpan,
        ),
        title: Text(
          longName.isNotEmpty ? longName : (AppTexts.isHungarian ? 'Vonal' : 'Line'),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: agency != null
            ? Text(
                agency,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              )
            : null,
        onTap: () {
          _internalFocusNode.unfocus();
          widget.onSuggestionSelected(entry);
          setState(() {
            _suggestionEntries = [];
          });
        },
      );
    }

    // Default stops and addresses tile
    final subtitleText = entry.type == SuggestionType.stop
        ? (AppTexts.isHungarian ? 'Megálló' : 'Stop')
        : (AppTexts.isHungarian ? 'Cím' : 'Address');

    Widget leadingWidget;
    if (entry.type == SuggestionType.stop && entry.icons.isNotEmpty) {
      if (entry.icons.length == 1) {
        leadingWidget = Icon(entry.icons.first, color: colorScheme.primary);
      } else {
        leadingWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: entry.icons.map((ico) => Icon(ico, size: 18, color: colorScheme.primary)).toList(),
        );
      }
    } else {
      leadingWidget = Icon(
        entry.type == SuggestionType.stop ? Icons.directions_bus : Icons.place,
        color: colorScheme.primary,
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      leading: leadingWidget,
      title: Text(
        entry.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitleText,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
      onTap: () {
        _internalFocusNode.unfocus();
        widget.onSuggestionSelected(entry);
        setState(() {
          _suggestionEntries = [];
          _showSuggestionsOverlay = false;
        });
      },
    );
  }
}
