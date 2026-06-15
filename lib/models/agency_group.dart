class AgencyGroup {
  final String name;
  final List<String> agencyIds;

  const AgencyGroup({required this.name, required this.agencyIds});

  factory AgencyGroup.fromJson(Map<String, dynamic> json) {
    return AgencyGroup(
      name: (json['name'] ?? '').toString(),
      agencyIds: List<String>.from(json['agency_ids'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'agency_ids': agencyIds};

  static List<AgencyGroup> getPrebakedGroups() {
    return const [
      AgencyGroup(
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
      ),
      AgencyGroup(
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
      ),
      AgencyGroup(
        name: 'Szeged',
        agencyIds: ['hkir:hkir_V-33367', 'szeged:hkir_V-33367', 'szeged:SZKT'],
      ),
    ];
  }
}
