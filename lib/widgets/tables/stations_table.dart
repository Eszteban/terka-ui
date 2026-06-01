import 'package:flutter/material.dart';

class StationsTable extends StatelessWidget {
  const StationsTable({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final stations = [
      {'nev': 'Blaha Lujza tér', 'varos': 'Budapest', 'zona': '1', 'tipus': 'Metró, Busz', 'lat': '47.4963', 'lon': '19.0698'},
      {'nev': 'Deák Ferenc tér', 'varos': 'Budapest', 'zona': '1', 'tipus': 'Metró, Villamos', 'lat': '47.4975', 'lon': '19.0534'},
      {'nev': 'Keleti pályaudvar', 'varos': 'Budapest', 'zona': '1', 'tipus': 'Vonat, Metró, Busz', 'lat': '47.5003', 'lon': '19.0839'},
      {'nev': 'Nagyállomás', 'varos': 'Debrecen', 'zona': '30', 'tipus': 'Vonat, Busz, Villamos', 'lat': '47.5107', 'lon': '21.6278'},
      {'nev': 'Kossuth tér', 'varos': 'Debrecen', 'zona': '30', 'tipus': 'Villamos, Busz', 'lat': '47.5316', 'lon': '21.6244'},
      {'nev': 'Széchenyi tér', 'varos': 'Pécs', 'zona': '60', 'tipus': 'Busz', 'lat': '46.0764', 'lon': '18.2281'},
      {'nev': 'Széll Kálmán tér', 'varos': 'Budapest', 'zona': '1', 'tipus': 'Metró, Villamos, Busz', 'lat': '47.5075', 'lon': '19.0244'},
      {'nev': 'Főpályaudvar', 'varos': 'Szeged', 'zona': '50', 'tipus': 'Vonat, Busz, Villamos', 'lat': '46.2491', 'lon': '20.1456'},
      {'nev': 'Petőfi tér', 'varos': 'Miskolc', 'zona': '40', 'tipus': 'Villamos, Busz', 'lat': '48.1035', 'lon': '20.7784'},
      {'nev': 'Baross tér', 'varos': 'Győr', 'zona': '70', 'tipus': 'Vonat, Busz', 'lat': '47.6849', 'lon': '17.6314'},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('Megállók', style: textTheme.headlineSmall),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: stations.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final stop = stations[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        title: Text(stop['nev']!),
                        subtitle: Text('${stop['varos']} • ${stop['tipus']}'),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('Megállók', style: textTheme.headlineSmall),
              ),
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Megálló neve')),
                      DataColumn(label: Text('Város')),
                      DataColumn(label: Text('Zóna')),
                      DataColumn(label: Text('Típus')),
                      DataColumn(label: Text('Szélesség')),
                      DataColumn(label: Text('Hosszúság')),
                    ],
                    rows: stations
                        .map(
                          (s) => DataRow(
                            cells: [
                              DataCell(Text(s['nev']!)),
                              DataCell(Text(s['varos']!)),
                              DataCell(Text(s['zona']!)),
                              DataCell(Text(s['tipus']!)),
                              DataCell(Text(s['lat']!)),
                              DataCell(Text(s['lon']!)),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
