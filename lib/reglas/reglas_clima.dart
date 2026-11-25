String descripcion(int? codigo, {bool esDeDia = true}) {
  return switch (codigo) {
    0 => esDeDia ? 'Soleado' : 'Despejado',
    1 || 2 => 'Parcialmente nublado',
    3 => 'Nublado',
    45 || 48 => 'Niebla',
    51 || 53 || 55 => 'Llovizna',
    56 || 57 => 'Llovizna helada',
    61 || 63 || 65 => 'Lluvia',
    66 || 67 => 'Lluvia helada',
    71 || 73 || 75 || 77 || 85 || 86 => 'Nieve',
    80 || 81 || 82 => 'Chubascos',
    95 || 96 || 99 => 'Tormenta',
    _ => 'Condición no disponible',
  };
}

String emojiClima(int? codigo, num? temperatura, {bool esDeDia = true}) {
  final fenomeno = switch (codigo) {
    95 || 96 || 99 => '⛈️',
    71 || 73 || 75 || 77 || 85 || 86 => '🌨️',
    56 || 57 || 66 || 67 => '❄️',
    51 || 53 || 55 || 61 || 63 || 65 => '🌧️',
    80 || 81 || 82 => '🌦️',
    45 || 48 => '🌫️',
    _ => null,
  };
  if (fenomeno != null) return fenomeno;
  if (temperatura != null && temperatura <= 0) return '🥶';
  if (temperatura != null && temperatura >= 32) return '🥵';

  return switch (codigo) {
    0 => esDeDia ? '☀️' : '🌙',
    1 => esDeDia ? '🌤️' : '☁️',
    2 => '⛅',
    3 => '☁️',
    _ => '🌡️',
  };
}

String dato(Object? valor, String unidad) {
  return valor == null ? 'No disponible' : '$valor $unidad';
}

List<String> recomendacionesClima({
  required int? codigo,
  required num? temperatura,
  required num? probabilidadLluvia,
  num? minima,
  bool esDeDia = true,
}) {
  final consejos = <String>[];
  final hayTormenta = const [95, 96, 99].contains(codigo);
  final hayNieve = const [71, 73, 75, 77, 85, 86].contains(codigo);
  final hayLluvia = const [
    51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82,
  ].contains(codigo);
  final haySol = esDeDia && const [0, 1].contains(codigo);
  final haceCalor = temperatura != null && temperatura >= 28;
  final haceFrio = (minima ?? temperatura ?? double.infinity) <= 12;

  if (hayTormenta) {
    consejos.add('Si tienes planes al aire libre, muévelos a un espacio cerrado.');
  } else if (hayNieve) {
    consejos.add('Si vas a salir, usa calzado impermeable con suela antideslizante.');
  } else if (hayLluvia || (probabilidadLluvia ?? 0) >= 50) {
    consejos.add(
      'Si vas a salir, lleva un paraguas o un impermeable ligero. '
      'Si vas a caminar, elige calzado con buen agarre.',
    );
  }

  if (const [45, 48].contains(codigo)) {
    consejos.add('Si vas a trasladarte, reserva más tiempo por la baja visibilidad.');
  }
  if (haySol || haceCalor) {
    consejos.add(
      'Si vas a salir, lleva una botella de agua y usa ropa ligera y transpirable.',
    );
  }
  if (haySol) {
    consejos.add('Si pasarás tiempo al aire libre, usa protector solar y lleva una gorra.');
  }
  if (haceFrio) {
    consejos.add(
      minima == null
          ? 'Lleva una chamarra si vas a salir.'
          : 'Lleva una chamarra si sales temprano o regresas por la noche.',
    );
  }
  if (consejos.isEmpty) {
    consejos.add('Si pasarás varias horas fuera, lleva una capa ligera por si refresca.');
  }
  return consejos;
}
