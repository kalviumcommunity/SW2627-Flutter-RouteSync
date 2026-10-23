abstract final class UserRoles {
  static const invalid = 'INVALID';
  static const dispatcher = 'DISPATCHER';
  static const executive = 'EXECUTIVE';

  static const values = <String>[dispatcher, executive];

  static String normalize(String? value) {
    final normalized = value?.trim().toUpperCase();
    return switch (normalized) {
      dispatcher => dispatcher,
      executive => executive,
      'DELIVERY EXECUTIVE' => executive,
      _ => invalid,
    };
  }
}

abstract final class DeliveryStatuses {
  static const invalid = 'INVALID';
  static const assigned = 'ASSIGNED';
  static const pickedUp = 'PICKED UP';
  static const outForDelivery = 'OUT FOR DELIVERY';
  static const delivered = 'DELIVERED';
  static const failed = 'FAILED';

  static const values = <String>[
    assigned,
    pickedUp,
    outForDelivery,
    delivered,
    failed,
  ];

  static String normalize(String? value) {
    final normalized = value?.trim().toUpperCase().replaceAll('_', ' ');
    if (normalized == null || normalized.isEmpty) {
      return invalid;
    }
    return normalized;
  }

  static bool canTransition(String current, String next) {
    return switch (current) {
      assigned => next == pickedUp,
      pickedUp => next == outForDelivery,
      outForDelivery => next == delivered || next == failed,
      _ => false,
    };
  }
}

abstract final class EscalationValues {
  static const invalid = 'INVALID';
  static const open = 'OPEN';
  static const resolved = 'RESOLVED';
  static const statuses = <String>[open, resolved];

  static const low = 'LOW';
  static const medium = 'MEDIUM';
  static const high = 'HIGH';
  static const priorities = <String>[low, medium, high];

  static String normalizeStatus(String? value) {
    final normalized = value?.trim().toUpperCase();
    return normalized != null && statuses.contains(normalized)
        ? normalized
        : invalid;
  }

  static String normalizePriority(String? value) {
    final normalized = value?.trim().toUpperCase();
    return normalized != null && priorities.contains(normalized)
        ? normalized
        : invalid;
  }
}

const failureReasons = <String>[
  'Customer unavailable',
  'Incorrect address',
  'Customer refused delivery',
  'Vehicle issue',
  'Delivery area inaccessible',
  'Other',
];
