class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship = 'Family',
    this.priority = 1,
    this.isActive = true,
  });

  final String id;
  final String name;

  /// Normalised by `PhoneNumber.normalize` before it is stored.
  final String phone;
  final String relationship;

  /// 1 (highest) .. 5.
  final int priority;
  final bool isActive;

  static const relationships = [
    'Family',
    'Friend',
    'Partner',
    'Campus Security',
    'Colleague',
    'Police',
  ];

  EmergencyContact copyWith({
    String? name,
    String? phone,
    String? relationship,
    int? priority,
    bool? isActive,
  }) =>
      EmergencyContact(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        relationship: relationship ?? this.relationship,
        priority: priority ?? this.priority,
        isActive: isActive ?? this.isActive,
      );

  @override
  bool operator ==(Object other) =>
      other is EmergencyContact &&
      other.id == id &&
      other.name == name &&
      other.phone == phone &&
      other.relationship == relationship &&
      other.priority == priority &&
      other.isActive == isActive;

  @override
  int get hashCode => Object.hash(id, name, phone, relationship, priority, isActive);
}
