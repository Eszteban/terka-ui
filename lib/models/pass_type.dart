class PassType {
  final String id;
  final String name;
  final List<String> agencyIds;
  final List<String> agencyNames;
  final String durationType; // 'month' or 'days'
  final int? durationDays;

  const PassType({
    required this.id,
    required this.name,
    required this.agencyIds,
    required this.agencyNames,
    required this.durationType,
    this.durationDays,
  });

  factory PassType.fromJson(Map<String, dynamic> json) {
    return PassType(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      agencyIds: List<String>.from(json['agency_ids'] ?? []),
      agencyNames: List<String>.from(json['agency_names'] ?? []),
      durationType: (json['duration_type'] ?? 'month').toString(),
      durationDays: json['duration_days'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'agency_ids': agencyIds,
        'agency_names': agencyNames,
        'duration_type': durationType,
        'duration_days': durationDays,
      };

  static List<PassType> getPrebakedPassTypes() {
    return const [
      PassType(
        id: 'orszagberlet',
        name: 'Országbérlet',
        agencyIds: [
          'BKK:BKK',
          '1:1164',
          'hkir:hkir_V-30988',
          'hkir:hkir_V-05111',
          'hkir:hkir_V-23603',
          'hkir:hkir_V-25131',
          'hkir:hkir_V',
          '1:198',
          'debrecen:DKV',
          'mvkzrt:MVK',
          '1:134',
        ],
        agencyNames: [
          'BKK',
          'MÁV Személyszállítási Zrt. (HÉV)',
          'MÁV Személyszállítási Zrt. - Érd',
          'MÁV Személyszállítási Zrt. - Csongrád',
          'MÁV Személyszállítási Zrt. - Ercsi',
          'MÁV Személyszállítási Zrt. - Esztergom',
          'MÁV Személyszállítási Zrt. - Helyközi busz',
          'MÁV Személyszállítási Zrt.',
          'DKV Debreceni Közlekedési Zrt.',
          'MVK Zrt.',
          'GYSEV Zrt.',
        ],
        durationType: 'month',
      ),
      PassType(
        id: 'orszagberlet_szeged',
        name: 'Országbérlet + Szeged',
        agencyIds: [
          'BKK:BKK',
          '1:1164',
          'hkir:hkir_V-30988',
          'hkir:hkir_V-05111',
          'hkir:hkir_V-23603',
          'hkir:hkir_V-25131',
          'hkir:hkir_V',
          '1:198',
          'debrecen:DKV',
          'mvkzrt:MVK',
          'hkir:hkir_V-33367',
          'szeged:hkir_V-33367',
          'szeged:SZKT',
          '1:134',
        ],
        agencyNames: [
          'BKK',
          'MÁV Személyszállítási Zrt. (HÉV)',
          'MÁV Személyszállítási Zrt. - Érd',
          'MÁV Személyszállítási Zrt. - Csongrád',
          'MÁV Személyszállítási Zrt. - Ercsi',
          'MÁV Személyszállítási Zrt. - Esztergom',
          'MÁV Személyszállítási Zrt. - Helyközi busz',
          'MÁV Személyszállítási Zrt.',
          'DKV Debreceni Közlekedési Zrt.',
          'MVK Zrt.',
          'MÁV Személyszállítási Zrt. - Szeged',
          'Szegedi Közlekedési Kft.',
          'Szegedi Közlekedési Kft.',
          'GYSEV Zrt.',
        ],
        durationType: 'month',
      ),
    ];
  }
}
