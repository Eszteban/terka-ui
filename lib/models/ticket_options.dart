class TicketAgencyOption {
  final String id;
  final String name;

  const TicketAgencyOption({required this.id, required this.name});

  factory TicketAgencyOption.fromJson(Map<String, dynamic> json) {
    return TicketAgencyOption(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class TicketTypeOption {
  final String value;
  final String label;

  const TicketTypeOption({required this.value, required this.label});

  factory TicketTypeOption.fromJson(Map<String, dynamic> json) {
    return TicketTypeOption(
      value: (json['value'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
    );
  }
}
