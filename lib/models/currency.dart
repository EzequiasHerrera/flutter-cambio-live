class Currency {
  final String code;
  final String name;

  Currency({required this.code, required this.name});

  // Centralizamos el mapeo aquí
  String get flagCode {
    if (code == 'EUR') return 'EU'; // Excepción Euro
    if (code == 'CUSTOM') return 'CUSTOM'; // Tu moneda personalizada

    // Regla general: ARS -> AR, USD -> US
    return code.length >= 2 ? code.substring(0, 2) : code;
  }
}