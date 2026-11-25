import 'dart:convert';

import 'package:http/http.dart' as http;

const _urlGemini = String.fromEnvironment(
  'GEMINI_API_URL',
  defaultValue: 'http://127.0.0.1:3000/api/gemini',
);

Future<String> consultarGemini({
  required String actividad,
  required String ubicacion,
  required num latitud,
  required num longitud,
}) async {
  final respuesta = await http
      .post(
        Uri.parse('$_urlGemini/planear-actividad'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'actividad': actividad,
          'ubicacion': ubicacion,
          'latitud': latitud,
          'longitud': longitud,
        }),
      )
      .timeout(const Duration(seconds: 45));

  final Object? datos;
  try {
    datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
  } on FormatException {
    throw const FormatException('NestJS devolvió una respuesta inesperada.');
  }

  if (respuesta.statusCode != 200 && respuesta.statusCode != 201) {
    final mensaje = datos is Map ? datos['message'] : null;
    throw FormatException(
      mensaje is String ? mensaje : 'No se pudo obtener la recomendación.',
    );
  }

  final recomendacion = datos is Map ? datos['recomendacion'] : null;
  if (recomendacion is! String || recomendacion.trim().isEmpty) {
    throw const FormatException('Gemini devolvió una respuesta vacía.');
  }

  return recomendacion.trim();
}