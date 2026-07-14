/// A utility class to resolve Hungarian train vehicle type names by their UIC series codes.
class VehicleTypeLookup {
  /// The input code (can be a 4-digit series or a full UIC number).
  final String code;

  /// Creates a [VehicleTypeLookup] instance for the given [code].
  const VehicleTypeLookup(this.code);

  /// Getter that returns the resolved vehicle type name.
  /// This getter "expects" a string by accessing the [code] provided to the instance.
  String get vehicleType => lookup(code);

  /// Helper getter that returns the vehicle type name.
  String get name => lookup(code);

  /// Index operator lookup on a default instance.
  /// Allows lookup using `const VehicleTypeLookup('')[uicSeries]`.
  String operator [](String key) => lookup(key);

  /// Callable class lookup.
  /// Allows lookup using `const VehicleTypeLookup('')(uicSeries)`.
  String call(String key) => lookup(key);

  /// Map of 4-digit UIC series codes to Hungarian vehicle type names.
  static const Map<String, String> vehicleTypeByUicSeries = {
    // Villamosmozdonyok
    "0431": "V43 Szili",
    "0432": "V43 Papagáj",
    "0433": "V43 Cirmos",
    "0460": "V46 Szöcske",
    "0630": "Ganz-MÁVAG-GIGANT",
    "0470": "Siemens-TAURUS",
    "0480": "Bombardier-TRAXX",
    "0490": "Alstom-ASTRIDE",
    "0182": "Siemens-TAURUS",
    "6182": "Siemens-TAURUS",
    "0186": "Siemens-TAURUS",
    "0471": "Siemens-VECTRON",
    "1116": "Siemens-TAURUS (ÖBB)",
    "6193": "Siemens-VECTRON",
    "7193": "Siemens-VECTRON",
    "0187": "Bombardier-TRAXX",
    "0241": "Softronic-Transmontana",
    "0242": "Softronic-Transmontana",
    "0400": "Softronic-LEMA",
    "1141": "ASEA-Csaurusz",
    "0430": "GANZ-MÁVAG-SZILI (GYSEV)",
    "1136": "Studenka Vagonka-IkerBZ",
    "1293": "Siemens-VECTRON MS (ÖBB)",
    "0477": "ASEA-Csaurusz",
    "0481": "Softronic-LEMA (CFR)",
    "0482": "Reloc-ELASMO (CFR)",

    // Dízelmozdonyok
    "0288": "M28 Mazsola",
    "0408": "M40 Púpos",
    "0418": "M41 Csörgő",
    "0438": "M43 Kis Dacia",
    "0448": "M44 Bobó",
    "0478": "M47 Nagy Dacia",
    "0628": "M62 Szergej",
    "0648": "Ludmilla",
    "0651": "Effiliner 1600",
    "0740": "ČKD Kocúr / Dongó",
    "0742": "ČKD Kocúr / Dongó",
    "2016": "Siemens Herkules",
    "9281": "Siemens Herkules",
    "9280": "Siemens Vectron DE",
    "0127": "Studenka Vagonka-IP Bz",
    "1232": "Ludmilla (BR 232 / BR 233)",
    "0001": "Henschel-TME Viking",
    "0618": "NOHAB-Di.3a",

    // Villamos motorvonatok
    "0414": "BDVmot Hernyó",
    "0415": "Stadler-FLIRT",
    "1415": "Stadler-FLIRT",
    "2415": "Stadler-FLIRT",
    "3415": "Stadler-FLIRT",
    "4415": "Stadler-FLIRT",
    "0434": "BVmot Samu",
    "0424": "BVhmot Kis Samu",
    "1435": "Stadler-FLIRT3",
    "0435": "Stadler-FLIRT3",
    "0815": "Stadler KISS",
    "1815": "Stadler KISS",
    "2815": "Stadler KISS",
    "3815": "Stadler KISS",
    "4815": "Stadler KISS",
    "5815": "Stadler KISS",
    "6815": "Stadler KISS",
    "1406": "Stadler-TRAMTRAIN",
    "1425": "Bombardier-TALENT",

    "1488": "BDVmot Hernyó / Bmx pót",
    "8055": "BDt vezérlőkocsi (V43/Szili inga)",
    "2105": "BDVmot vezérlőkocsi",

    // Dízel motorvonatok és motorkocsik
    "0117": "Bzmot",
    "5047": "Jenbacher motorvonat",
    "5147": "Iker-Jenbacher motorvonat",
    "1446": "Iker-Jenbacher motorvonat",
    "0247": "Jenbacher motorvonat",
    "0416": "Uzsgyi",
    "6341": "Uzsgyi",
    "0426": "Siemens Desiro",
    "6342": "Siemens Desiro",
    "1416": "Uzsgyi",
    "1426": "Siemens Desiro",
    "5711": "Metrowagonmash-Szerb Uzsgyi",

    // Speciális járművek
    "8005": "Dunakeszi Járműjavító-FECSKE VEZÉRLŐ",
    "8076": "Schlieren Vezérlő",

    // Keskeny nyomközű járművek
    "2948": "Mk48",
    "8276": "Mk45",
    "8279": "Mk45",
    "2920": "C-50",
  };

  /// Resolves the vehicle type name by code or full UIC number.
  ///
  /// Supports:
  /// - Exact series code matching (e.g., "0431")
  /// - Digits extraction for full UIC format (e.g., "915504310123" -> series "0431")
  /// - Finding a known series code substring within the input
  static String lookup(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return 'Ismeretlen';
    }

    // Direct lookup of the exact input string
    if (vehicleTypeByUicSeries.containsKey(trimmed)) {
      return vehicleTypeByUicSeries[trimmed]!;
    }

    // Strip non-digit characters (to parse UIC formats like 91 55 0431 012-3)
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');

    // Standard 12-digit UIC train number format contains the series code at digits 5-8 (index 4 to 8)
    if (digits.length >= 8) {
      final candidateSeries = digits.substring(4, 8);
      if (vehicleTypeByUicSeries.containsKey(candidateSeries)) {
        return vehicleTypeByUicSeries[candidateSeries]!;
      }
    }

    // Fallback: search for any known series code within the input string
    for (final series in vehicleTypeByUicSeries.keys) {
      if (trimmed.contains(series)) {
        return vehicleTypeByUicSeries[series]!;
      }
    }

    return 'Ismeretlen';
  }
}
