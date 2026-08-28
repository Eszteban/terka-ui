import 'package:flutter/material.dart';

/// Terka szemantikus színei (késések, riasztások, siker- és hibaállapotok).
///
/// A Material 3 [ColorScheme]-et kiegészítő téma-kiterjesztés,
/// amely konzisztens színeket biztosít világos és sötét módban egyaránt.
@immutable
class TerkaSemanticColors extends ThemeExtension<TerkaSemanticColors> {
  const TerkaSemanticColors({
    required this.onTime,
    required this.delayed,
    required this.early,
    required this.scheduledOnly,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.alertSevere,
    required this.onAlertSevere,
    required this.alertSevereContainer,
    required this.onAlertSevereContainer,
    required this.alertWarning,
    required this.onAlertWarning,
    required this.alertWarningContainer,
    required this.onAlertWarningContainer,
    required this.alertInfo,
    required this.onAlertInfo,
    required this.alertInfoContainer,
    required this.onAlertInfoContainer,
    required this.alertNeutral,
    required this.onAlertNeutral,
    required this.alertNeutralContainer,
    required this.onAlertNeutralContainer,
  });

  // --- Valós idejű menetrend / Késés állapotok ---
  final Color onTime;
  final Color delayed;
  final Color early;
  final Color scheduledOnly;

  // --- Siker állapotok (pl. érvényes jegy, elmentett bérlet) ---
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  // --- Riasztási szintek (GTFS-RT Alert Severity) ---
  final Color alertSevere;
  final Color onAlertSevere;
  final Color alertSevereContainer;
  final Color onAlertSevereContainer;

  final Color alertWarning;
  final Color onAlertWarning;
  final Color alertWarningContainer;
  final Color onAlertWarningContainer;

  final Color alertInfo;
  final Color onAlertInfo;
  final Color alertInfoContainer;
  final Color onAlertInfoContainer;

  final Color alertNeutral;
  final Color onAlertNeutral;
  final Color alertNeutralContainer;
  final Color onAlertNeutralContainer;

  /// Világos módú szemantikus színek
  static const TerkaSemanticColors light = TerkaSemanticColors(
    onTime: Color(0xFF2E7D32),
    delayed: Color(0xFFC62828),
    early: Color(0xFF1565C0),
    scheduledOnly: Color(0xFF5C5856),
    success: Color(0xFF2E7D32),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFE8F5E9),
    onSuccessContainer: Color(0xFF1B5E20),
    alertSevere: Color(0xFFD32F2F),
    onAlertSevere: Color(0xFFFFFFFF),
    alertSevereContainer: Color(0xFFFDE8E8),
    onAlertSevereContainer: Color(0xFFB71C1C),
    alertWarning: Color(0xFFE65100),
    onAlertWarning: Color(0xFFFFFFFF),
    alertWarningContainer: Color(0xFFFFF3E0),
    onAlertWarningContainer: Color(0xFFBF360C),
    alertInfo: Color(0xFF1976D2),
    onAlertInfo: Color(0xFFFFFFFF),
    alertInfoContainer: Color(0xFFE3F2FD),
    onAlertInfoContainer: Color(0xFF0D47A1),
    alertNeutral: Color(0xFF546E7A),
    onAlertNeutral: Color(0xFFFFFFFF),
    alertNeutralContainer: Color(0xFFECEFF1),
    onAlertNeutralContainer: Color(0xFF263238),
  );

  /// Sötét módú szemantikus színek (a Terka meleg antracit stílusához igazítva)
  static const TerkaSemanticColors dark = TerkaSemanticColors(
    onTime: Color(0xFF81C784),
    delayed: Color(0xFFEF5350),
    early: Color(0xFF64B5F6),
    scheduledOnly: Color(0xFFA8A29E),
    success: Color(0xFF81C784),
    onSuccess: Color(0xFF003912),
    successContainer: Color(0xFF1C2C1F),
    onSuccessContainer: Color(0xFFA5D6A7),
    alertSevere: Color(0xFFEF5350),
    onAlertSevere: Color(0xFF490003),
    alertSevereContainer: Color(0xFF2C1E1D),
    onAlertSevereContainer: Color(0xFFFFCDD2),
    alertWarning: Color(0xFFFFB74D),
    onAlertWarning: Color(0xFF4A2800),
    alertWarningContainer: Color(0xFF2C2216),
    onAlertWarningContainer: Color(0xFFFFE0B2),
    alertInfo: Color(0xFF64B5F6),
    onAlertInfo: Color(0xFF003258),
    alertInfoContainer: Color(0xFF182430),
    onAlertInfoContainer: Color(0xFFBBDEFB),
    alertNeutral: Color(0xFFB0BEC5),
    onAlertNeutral: Color(0xFF21272B),
    alertNeutralContainer: Color(0xFF202426),
    onAlertNeutralContainer: Color(0xFFCFD8DC),
  );

  @override
  TerkaSemanticColors copyWith({
    Color? onTime,
    Color? delayed,
    Color? early,
    Color? scheduledOnly,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? alertSevere,
    Color? onAlertSevere,
    Color? alertSevereContainer,
    Color? onAlertSevereContainer,
    Color? alertWarning,
    Color? onAlertWarning,
    Color? alertWarningContainer,
    Color? onAlertWarningContainer,
    Color? alertInfo,
    Color? onAlertInfo,
    Color? alertInfoContainer,
    Color? onAlertInfoContainer,
    Color? alertNeutral,
    Color? onAlertNeutral,
    Color? alertNeutralContainer,
    Color? onAlertNeutralContainer,
  }) {
    return TerkaSemanticColors(
      onTime: onTime ?? this.onTime,
      delayed: delayed ?? this.delayed,
      early: early ?? this.early,
      scheduledOnly: scheduledOnly ?? this.scheduledOnly,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      alertSevere: alertSevere ?? this.alertSevere,
      onAlertSevere: onAlertSevere ?? this.onAlertSevere,
      alertSevereContainer: alertSevereContainer ?? this.alertSevereContainer,
      onAlertSevereContainer:
          onAlertSevereContainer ?? this.onAlertSevereContainer,
      alertWarning: alertWarning ?? this.alertWarning,
      onAlertWarning: onAlertWarning ?? this.onAlertWarning,
      alertWarningContainer:
          alertWarningContainer ?? this.alertWarningContainer,
      onAlertWarningContainer:
          onAlertWarningContainer ?? this.onAlertWarningContainer,
      alertInfo: alertInfo ?? this.alertInfo,
      onAlertInfo: onAlertInfo ?? this.onAlertInfo,
      alertInfoContainer: alertInfoContainer ?? this.alertInfoContainer,
      onAlertInfoContainer: onAlertInfoContainer ?? this.onAlertInfoContainer,
      alertNeutral: alertNeutral ?? this.alertNeutral,
      onAlertNeutral: onAlertNeutral ?? this.onAlertNeutral,
      alertNeutralContainer:
          alertNeutralContainer ?? this.alertNeutralContainer,
      onAlertNeutralContainer:
          onAlertNeutralContainer ?? this.onAlertNeutralContainer,
    );
  }

  @override
  TerkaSemanticColors lerp(
    covariant ThemeExtension<TerkaSemanticColors>? other,
    double t,
  ) {
    if (other is! TerkaSemanticColors) return this;
    return TerkaSemanticColors(
      onTime: Color.lerp(onTime, other.onTime, t)!,
      delayed: Color.lerp(delayed, other.delayed, t)!,
      early: Color.lerp(early, other.early, t)!,
      scheduledOnly: Color.lerp(scheduledOnly, other.scheduledOnly, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      alertSevere: Color.lerp(alertSevere, other.alertSevere, t)!,
      onAlertSevere: Color.lerp(onAlertSevere, other.onAlertSevere, t)!,
      alertSevereContainer:
          Color.lerp(alertSevereContainer, other.alertSevereContainer, t)!,
      onAlertSevereContainer:
          Color.lerp(onAlertSevereContainer, other.onAlertSevereContainer, t)!,
      alertWarning: Color.lerp(alertWarning, other.alertWarning, t)!,
      onAlertWarning: Color.lerp(onAlertWarning, other.onAlertWarning, t)!,
      alertWarningContainer:
          Color.lerp(alertWarningContainer, other.alertWarningContainer, t)!,
      onAlertWarningContainer:
          Color.lerp(onAlertWarningContainer, other.onAlertWarningContainer, t)!,
      alertInfo: Color.lerp(alertInfo, other.alertInfo, t)!,
      onAlertInfo: Color.lerp(onAlertInfo, other.onAlertInfo, t)!,
      alertInfoContainer:
          Color.lerp(alertInfoContainer, other.alertInfoContainer, t)!,
      onAlertInfoContainer:
          Color.lerp(onAlertInfoContainer, other.onAlertInfoContainer, t)!,
      alertNeutral: Color.lerp(alertNeutral, other.alertNeutral, t)!,
      onAlertNeutral: Color.lerp(onAlertNeutral, other.onAlertNeutral, t)!,
      alertNeutralContainer:
          Color.lerp(alertNeutralContainer, other.alertNeutralContainer, t)!,
      onAlertNeutralContainer:
          Color.lerp(onAlertNeutralContainer, other.onAlertNeutralContainer, t)!,
    );
  }
}

/// Kényelmi extension [BuildContext]-hez a szemantikus színek elérésére.
extension TerkaSemanticThemeX on BuildContext {
  TerkaSemanticColors get semanticColors =>
      Theme.of(this).extension<TerkaSemanticColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? TerkaSemanticColors.dark
          : TerkaSemanticColors.light);
}
