import 'dart:convert';

import 'package:http/http.dart' as http;

const _servidor = String.fromEnvironment(
  'BACKEND',
  defaultValue: '127.0.0.1:3000',
);

Future<dynamic> consultarClimaApi(
  String ruta,
  Map<String, String> parametros,
) async {
  final respuesta = await http
      .get(Uri.http(_servidor, '/api$ruta', parametros))
      .timeout(const Duration(seconds: 12));

  final Object? datos;

  try {
    datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
  } on FormatException {
    throw const FormatException('NestJS devolvió una respuesta inesperada.');
  }

  if (respuesta.statusCode != 200) {
    final mensaje = datos is Map ? datos['message'] : null;
    throw FormatException(
      mensaje is String
          ? mensaje
          : 'El servidor no pudo completar la consulta.',
    );
  }

  return datos;
}