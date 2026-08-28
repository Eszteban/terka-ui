import 'dart:async';
import 'package:flutter/material.dart';
import 'package:terka/theme/app_texts.dart';
import 'package:terka/theme/app_tokens.dart';
import '../../injection_container.dart';
import '../../models/suggestion_entry.dart';
import '../../repositories/search_repository.dart';
import '../../utils/stop_details_utils.dart';
import '../../utils/markup_text_utils.dart' as markup;
import '../line_badge.dart';

export '../../models/suggestion_entry.dart';

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
  final SearchRepository? searchRepository;

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
    this.searchRepository,
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
  int _searchRequestId = 0;

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
    final currentRequestId = ++_searchRequestId;
    _updateSuggestionsState(isLoading: true);

    try {
      final repository = widget.searchRepository ?? sl<SearchRepository>();
      final newEntries = await repository.searchAll(
        query: query,
        includeStops: widget.searchStops,
        includeAddresses: widget.searchAddresses,
        includeLines: widget.searchLines,
        isCurrentLocationEnabled: widget.isCurrentLocationEnabled,
      );

      if (!mounted || currentRequestId != _searchRequestId) {
        return;
      }

      _updateSuggestionsState(
        entries: newEntries,
        isLoading: false,
      );
    } catch (_) {
      if (mounted && currentRequestId == _searchRequestId) {
        _updateSuggestionsState(isLoading: false);
      }
    }
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
                    widget.onClear?.call();
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
                    separatorBuilder: (_, _) => const Divider(height: 1),
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
                        separatorBuilder: (_, _) => const Divider(height: 1),
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
        ? (AppTexts.isHungarian ? 'Megálló' : 'Cím')
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
