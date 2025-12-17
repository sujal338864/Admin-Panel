class SpecField {
  final int fieldId;
  final int sectionId;
  final String name;
  final String inputType;
  final int sortOrder;
  final List<String> options;

  SpecField({
    required this.fieldId,
    required this.sectionId,
    required this.name,
    required this.inputType,
    required this.sortOrder,
    required this.options,
  });

  factory SpecField.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];

    final List<String> opts = rawOptions == null
        ? <String>[]
        : rawOptions
            .toString()
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    return SpecField(
      fieldId: json['field_id'] ?? json['FieldID'] ?? 0,
      sectionId: json['section_id'] ?? json['SectionID'] ?? 0,
      name: (json['name'] ?? '').toString(),
      inputType: (json['input_type'] ?? 'text').toString(),
      sortOrder: json['sort_order'] ?? 0,
      options: opts,
    );
  }
}


class SpecSection {
  final int sectionId;
  final String name;
  final int sortOrder;
  final List<SpecField> fields;

  SpecSection({
    required this.sectionId,
    required this.name,
    required this.sortOrder,
    required this.fields,
  });

  factory SpecSection.fromJson(Map<String, dynamic> json) {
    final fieldsJson = (json['fields'] as List?) ?? [];

    return SpecSection(
      sectionId: json['section_id'] ?? 0,      // ✅ NEVER NULL
      name: (json['name'] ?? '').toString(),
      sortOrder: json['sort_order'] ?? 0,      // ✅ FIX FOR CRASH
      fields: fieldsJson
          .map((e) => SpecField.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
