import 'package:flutter/material.dart';
import 'package:terka/theme/app_texts.dart';
import '../../widgets/forms/autocomplete_search_field.dart';
import '../../utils/stop_details_utils.dart';
import '../../utils/markup_text_utils.dart' as markup;
import '../../widgets/line_badge.dart';
import 'package:terka/theme/app_tokens.dart';

class GeneralSearchScreen extends StatefulWidget {
  const GeneralSearchScreen({super.key});

  @override
  State<GeneralSearchScreen> createState() => _GeneralSearchScreenState();
}

class _GeneralSearchScreenState extends State<GeneralSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _searchStops = true;
  bool _searchAddresses = true;
  bool _searchLines = true;

  List<SuggestionEntry> _suggestions = [];
  bool _isLoading = false;

  void _triggerSearchRefresh() {
    final currentText = _searchController.text;
    _searchController.text = '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchController.text = currentText;
      }
    });
  }

  void _showFilterDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.tune, color: colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    AppTexts.isHungarian ? 'Keresési szűrők' : 'Search filters',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    secondary: Icon(Icons.directions_bus, color: colorScheme.primary),
                    title: Text(AppTexts.isHungarian ? 'Megállók' : 'Stops'),
                    value: _searchStops,
                    activeColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onChanged: (bool? value) {
                      if (value != null) {
                        setDialogState(() {
                          _searchStops = value;
                        });
                        setState(() {
                          _searchStops = value;
                        });
                        _triggerSearchRefresh();
                      }
                    },
                  ),
                  CheckboxListTile(
                    secondary: Icon(Icons.place, color: colorScheme.primary),
                    title: Text(AppTexts.isHungarian ? 'Címek' : 'Addresses'),
                    value: _searchAddresses,
                    activeColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onChanged: (bool? value) {
                      if (value != null) {
                        setDialogState(() {
                          _searchAddresses = value;
                        });
                        setState(() {
                          _searchAddresses = value;
                        });
                        _triggerSearchRefresh();
                      }
                    },
                  ),
                  CheckboxListTile(
                    secondary: Icon(Icons.alt_route, color: colorScheme.primary),
                    title: Text(AppTexts.isHungarian ? 'Vonalak' : 'Lines'),
                    value: _searchLines,
                    activeColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onChanged: (bool? value) {
                      if (value != null) {
                        setDialogState(() {
                          _searchLines = value;
                        });
                        setState(() {
                          _searchLines = value;
                        });
                        _triggerSearchRefresh();
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppTexts.isHungarian ? 'Kész' : 'Done',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.transparent,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AutocompleteSearchField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    labelText: '',
                    hintText: AppTexts.isHungarian
                        ? 'Keresés megállóra, címre, vonalra...'
                        : 'Search for stops, addresses, lines...',
                    autofocus: true,
                    isFullPage: true,
                    searchStops: _searchStops,
                    searchAddresses: _searchAddresses,
                    searchLines: _searchLines,
                    isCurrentLocationEnabled: false,
                    onSuggestionsChanged: (suggestions, isLoading) {
                      setState(() {
                        _suggestions = suggestions;
                        _isLoading = isLoading;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: AppTexts.isHungarian
                          ? 'Keresés...'
                          : 'Search...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      filled: false,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _suggestions = [];
                                });
                              },
                            )
                          : null,
                    ),
                    onSuggestionSelected: (suggestion) {
                      Navigator.of(context).pop(suggestion);
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.tune,
                    color: colorScheme.primary,
                  ),
                  tooltip: AppTexts.isHungarian ? 'Keresési szűrők' : 'Search filters',
                  onPressed: () => _showFilterDialog(context),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoading)
              const LinearProgressIndicator(),
            if (_suggestions.isEmpty && _searchController.text.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 64,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        AppTexts.isHungarian
                            ? 'Írj be legalább 3 karaktert a kereséshez'
                            : 'Type at least 3 characters to search',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_suggestions.isEmpty && _searchController.text.isNotEmpty && !_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        AppTexts.isHungarian
                            ? 'Nincs találat'
                            : 'No results found',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    
                    Widget leading;
                    String titleText = markup.plainTextFromHtml(suggestion.name);
                    
                    if (suggestion.type == SuggestionType.route && suggestion.rawData != null) {
                      final raw = suggestion.rawData!;
                      final colorHex = raw['color']?.toString() ?? '0A84FF';
                      final textColorHex = raw['textColor']?.toString() ?? 'FFFFFF';
                      final shortName = raw['shortName']?.toString() ?? '-';
                      final plainShortName = markup.plainTextFromHtml(shortName).trim();
                      
                      leading = LineBadge(
                        lineLabel: plainShortName,
                        routeColor: StopDetailsUtils.hexColor(colorHex),
                        routeTextColor: StopDetailsUtils.hexColor(textColorHex),
                        useSpanFont: markup.containsSpanMarkup(shortName),
                      );
                      
                      if (titleText.startsWith('$plainShortName - ')) {
                        titleText = titleText.substring(plainShortName.length + 3).trim();
                      }
                    } else {
                      final iconColor = colorScheme.primary;
                      if (suggestion.icons.length > 1) {
                        leading = Row(
                          mainAxisSize: MainAxisSize.min,
                          children: suggestion.icons
                              .map((icon) => Icon(icon, color: iconColor, size: 20))
                              .toList(),
                        );
                      } else if (suggestion.icons.isNotEmpty) {
                        leading = Icon(suggestion.icons.first, color: iconColor);
                      } else {
                        leading = Icon(
                          suggestion.type == SuggestionType.stop
                              ? Icons.directions_bus
                              : Icons.place,
                          color: iconColor,
                        );
                      }
                    }

                    return ListTile(
                      leading: leading,
                      title: Text(
                        titleText,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        suggestion.type == SuggestionType.stop
                            ? (AppTexts.isHungarian ? 'Megálló' : 'Stop')
                            : suggestion.type == SuggestionType.route
                                ? (AppTexts.isHungarian ? 'Vonal' : 'Line')
                                : (AppTexts.isHungarian ? 'Cím' : 'Address'),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      onTap: () {
                        Navigator.of(context).pop(suggestion);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
