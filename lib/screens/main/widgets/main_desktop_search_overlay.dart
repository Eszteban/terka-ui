import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:terka/theme/app_texts.dart';
import 'package:terka/theme/app_tokens.dart';
import '../../../utils/stop_details_utils.dart';
import '../../../utils/markup_text_utils.dart' as markup;
import '../../../widgets/forms/autocomplete_search_field.dart';
import '../../../widgets/line_badge.dart';

class MainDesktopSearchOverlay extends StatefulWidget {
  final ValueChanged<SuggestionEntry> onSuggestionSelected;
  final double width;

  const MainDesktopSearchOverlay({
    super.key,
    required this.onSuggestionSelected,
    this.width = 414.0,
  });

  @override
  State<MainDesktopSearchOverlay> createState() => _MainDesktopSearchOverlayState();
}

class _MainDesktopSearchOverlayState extends State<MainDesktopSearchOverlay> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<SuggestionEntry> _suggestions = const [];
  bool _isLoading = false;
  
  bool _searchStops = true;
  bool _searchAddresses = true;
  bool _searchLines = true;
  
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _searchController.text.isNotEmpty) {
      setState(() {
        _showDropdown = true;
      });
    } else if (!_focusNode.hasFocus) {
      // Small delay to allow tap on suggestions to process
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _showDropdown = false;
          });
        }
      });
    }
  }

  void _triggerSearchRefresh() {
    final currentText = _searchController.text;
    _searchController.text = '';
    Future.microtask(() {
      if (mounted) {
        _searchController.text = currentText;
      }
    });
  }

  void _showSettingsMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(button.size.width + 8, 0), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset(button.size.width + 8, 0)), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<void>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          enabled: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTexts.isHungarian ? 'Megállók' : 'Stops',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(width: AppSpacing.lg),
              StatefulBuilder(
                builder: (context, setStateSB) => Switch(
                  value: _searchStops,
                  onChanged: (value) {
                    setStateSB(() => _searchStops = value);
                    setState(() => _searchStops = value);
                    _triggerSearchRefresh();
                  },
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          enabled: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTexts.isHungarian ? 'Címek' : 'Addresses',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(width: AppSpacing.lg),
              StatefulBuilder(
                builder: (context, setStateSB) => Switch(
                  value: _searchAddresses,
                  onChanged: (value) {
                    setStateSB(() => _searchAddresses = value);
                    setState(() => _searchAddresses = value);
                    _triggerSearchRefresh();
                  },
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          enabled: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTexts.isHungarian ? 'Vonalak' : 'Lines',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(width: AppSpacing.lg),
              StatefulBuilder(
                builder: (context, setStateSB) => Switch(
                  value: _searchLines,
                  onChanged: (value) {
                    setStateSB(() => _searchLines = value);
                    setState(() => _searchLines = value);
                    _triggerSearchRefresh();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final pillColor = isDark 
        ? colorScheme.surface.withValues(alpha: 0.6)
        : colorScheme.surface.withValues(alpha: 0.7);
    
    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: pillColor,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: AutocompleteSearchField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    labelText: '',
                    hintText: AppTexts.isHungarian
                        ? 'Keress bármire...'
                        : 'Search for anything...',
                    isFullPage: true,
                    searchStops: _searchStops,
                    searchAddresses: _searchAddresses,
                    searchLines: _searchLines,
                    isCurrentLocationEnabled: false,
                    onSuggestionsChanged: (suggestions, isLoading) {
                      if (mounted) {
                        setState(() {
                          _suggestions = suggestions;
                          _isLoading = isLoading;
                          if (_searchController.text.isNotEmpty) {
                            _showDropdown = true;
                          }
                        });
                      }
                    },
                    onSuggestionSelected: (suggestion) {
                      widget.onSuggestionSelected(suggestion);
                      _focusNode.unfocus();
                      setState(() {
                        _showDropdown = false;
                        _searchController.clear();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: AppTexts.isHungarian
                          ? 'Keress bármire...'
                          : 'Search for anything...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      filled: false,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _suggestions = const [];
                                  _showDropdown = false;
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Builder(
                builder: (menuContext) => ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(context).withValues(alpha: 0.84),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.tune, color: colorScheme.primary),
                        onPressed: () => _showSettingsMenu(menuContext),
                        tooltip: AppTexts.isHungarian ? 'Keresési szűrők' : 'Search filters',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          if (_showDropdown && _searchController.text.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context).withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Material(
                    color: AppColors.transparent,
                    child: _buildDropdownContent(context, colorScheme),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdownContent(BuildContext context, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _searchController.text.length < 3 ? Icons.search_rounded : Icons.search_off_rounded,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _searchController.text.length < 3
                    ? (AppTexts.isHungarian ? 'Írj be legalább 3 karaktert' : 'Type at least 3 characters')
                    : (AppTexts.isHungarian ? 'Nincs találat' : 'No results found'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.separated(
      shrinkWrap: true,
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
            widget.onSuggestionSelected(suggestion);
            _focusNode.unfocus();
            setState(() {
              _showDropdown = false;
              _searchController.clear();
            });
          },
        );
      },
    );
  }
}
