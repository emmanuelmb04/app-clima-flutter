import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' show ClientException;

import '../reglas/reglas_clima.dart';
import '../service/clima_service.dart';
import '../service/gemini_service.dart';

class PantallaClima extends StatefulWidget {
  const PantallaClima({super.key});

  @override
  State<PantallaClima> createState() => _PantallaClimaState();
}

class _PantallaClimaState extends State<PantallaClima> {
  final campoCiudad = TextEditingController();
  final campoActividad = TextEditingController();
  ({String actividad, String mensaje})? resultadoActividad;
  Map<String, dynamic>? clima;
  String lugar = '';
  ({num latitud, num longitud})? coordenadas;
  String? error;
  String? aviso;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarUbicacionInicial();
  }

  @override
  void dispose() {
    campoCiudad.dispose();
    campoActividad.dispose();
    super.dispose();
  }

  Future<void> cargarUbicacionInicial() async {
    Position? posicion;

    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        var permiso = await Geolocator.checkPermission();
        if (permiso == LocationPermission.denied) {
          permiso = await Geolocator.requestPermission();
        }
        if (permiso != LocationPermission.denied &&
            permiso != LocationPermission.deniedForever) {
          posicion = await Geolocator.getCurrentPosition()
              .timeout(const Duration(seconds: 8));
        }
      }
    } on Exception {
      // Zitácuaro sirve como respaldo si falla la ubicación.
    }

    if (!mounted) return;

    try {
      if (posicion == null) {
        setState(() {
          aviso = 'No pudimos obtener tu ubicación. Mostramos Zitácuaro.';
        });
        await cargarClima(19.43657, -100.35639, 'Heróica Zitácuaro, Michoacán');
      } else {
        await cargarClima(posicion.latitude, posicion.longitude, 'Mi ubicación');
      }
    } on Exception catch (problema) {
      mostrarError(problema);
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> cargarClima(num latitud, num longitud, String nombre) async {
    final datos = await consultarClimaApi('/clima', {
      'latitud': '$latitud',
      'longitud': '$longitud',
    }) as Map<String, dynamic>;

    if (!mounted) return;

    setState(() {
      clima = datos;
      lugar = nombre;
      coordenadas = (latitud: latitud, longitud: longitud);
      resultadoActividad = null;
    });
  }

  String nombreCompleto(Map<String, dynamic> ciudad) {
    return [ciudad['name'], ciudad['admin1'], ciudad['country']]
        .whereType<String>()
        .where((texto) => texto.isNotEmpty)
        .join(', ');
  }

  Future<void> buscarCiudad() async {
    if (cargando) return;

    final nombre = campoCiudad.text.trim();
    if (nombre.length < 2) {
      setState(() => error = 'Escribe al menos dos letras de la ciudad.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final respuesta =
          await consultarClimaApi('/ciudades', {'nombre': nombre}) as List;
      final ciudades = respuesta.cast<Map<String, dynamic>>();
      if (!mounted) return;

      if (ciudades.isEmpty) {
        setState(() => error = 'No se encontró la ciudad.');
        return;
      }

      final ciudad = ciudades.length == 1
          ? ciudades.first
          : await showDialog<Map<String, dynamic>>(
              context: context,
              builder: (contextoDialogo) => SimpleDialog(
                title: const Text('Elige una ciudad'),
                children: [
                  for (final opcion in ciudades)
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(contextoDialogo, opcion),
                      child: Text(nombreCompleto(opcion)),
                    ),
                ],
              ),
            );

      if (ciudad == null || !mounted) return;

      await cargarClima(
        ciudad['latitude'] as num,
        ciudad['longitude'] as num,
        nombreCompleto(ciudad),
      );

      if (mounted) setState(() => aviso = null);
    } on Exception catch (problema) {
      mostrarError(problema);
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  void mostrarError(Exception problema) {
    if (!mounted) return;

    setState(() {
      error = switch (problema) {
        TimeoutException() => 'La consulta tardó demasiado. Intenta de nuevo.',
        ClientException() =>
          'No se pudo conectar. Revisa tu conexión y que FastAPI esté encendido.',
        FormatException(message: final mensaje) => mensaje,
        _ => 'Ocurrió un error al consultar el clima.',
      };
    });
  }

  Widget listaConsejos(List<String> consejos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final consejo in consejos)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(consejo)),
              ],
            ),
          ),
      ],
    );
  }

  Widget indicador(IconData icono, String titulo, String valor) {
    final tema = Theme.of(context);
    final (fondo, acento) = switch (icono) {
      Icons.thermostat => (const Color(0xFFFFEEE5), const Color(0xFF9A3D1D)),
      Icons.water_drop_outlined =>
        (const Color(0xFFE4F4FF), const Color(0xFF175B87)),
      Icons.speed => (const Color(0xFFF1EAFF), const Color(0xFF63439A)),
      Icons.air => (const Color(0xFFE1F5EE), const Color(0xFF19634E)),
      _ => (const Color(0xFFE8EEFF), const Color(0xFF354E9A)),
    };

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: fondo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: acento.withAlpha(42)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: CircleAvatar(
                radius: 17,
                backgroundColor: Colors.white,
                foregroundColor: acento,
                child: Icon(icono, size: 18),
              ),
            ),
            const SizedBox(height: 8),
            Text(titulo, style: tema.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              valor,
              style: tema.textTheme.titleMedium?.copyWith(
                color: acento,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget mostrarIndicadores(
    Map<String, dynamic> actual,
    num? lluvia,
    String horaLluvia,
  ) {
    final tarjetas = [
      indicador(
        Icons.thermostat,
        'Sensación térmica',
        dato(actual['apparent_temperature'], '°C'),
      ),
      indicador(
        Icons.water_drop_outlined,
        'Humedad',
        dato(actual['relative_humidity_2m'], '%'),
      ),
      indicador(
        Icons.speed,
        'Presión atmosférica',
        dato(actual['surface_pressure'], 'hPa'),
      ),
      indicador(
        Icons.air,
        'Velocidad del viento',
        dato(actual['wind_speed_10m'], 'km/h'),
      ),
      indicador(
        Icons.umbrella_outlined,
        'Probabilidad de lluvia',
        lluvia == null ? 'No disponible' : '$lluvia % hasta las $horaLluvia',
      ),
    ];

    return LayoutBuilder(
      builder: (context, espacio) {
        const separacion = 10.0;
        final ancho = espacio.maxWidth;
        final columnas = ancho >= 900 ? 5 : (ancho >= 300 ? 2 : 1);
        final anchoTarjeta = (ancho - separacion * (columnas - 1)) / columnas;

        return Wrap(
          spacing: separacion,
          runSpacing: separacion,
          children: [
            for (final tarjeta in tarjetas)
              SizedBox(width: anchoTarjeta, child: tarjeta),
          ],
        );
      },
    );
  }

  Widget mostrarPronostico(Map<String, dynamic> diario) {
    final fechas = diario['time'] as List;

    return LayoutBuilder(
      builder: (context, espacio) {
        final enFila = espacio.maxWidth >= 760;
        final tarjetas = [
          for (var i = 1; i < fechas.length; i++)
            tarjetaPronostico(diario, i, enFila: enFila),
        ];

        if (enFila) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final tarjeta in tarjetas) Expanded(child: tarjeta),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: tarjetas,
        );
      },
    );
  }

  Widget tarjetaPronostico(
    Map<String, dynamic> diario,
    int indice, {
    required bool enFila,
  }) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    final fecha = DateTime.parse(diario['time'][indice] as String);
    final dia = dias[fecha.weekday - 1];
    final fechaCorta = '${fecha.day}/${fecha.month}';
    final codigo = diario['weather_code'][indice] as int?;
    final maxima = diario['temperature_2m_max'][indice] as num?;
    final minima = diario['temperature_2m_min'][indice] as num?;
    final lluvia = diario['precipitation_probability_max'][indice] as num?;
    final condicion = descripcion(codigo);
    final emoji = emojiClima(codigo, maxima);
    final textoMinima = 'Mín. ${dato(minima, '°C')}';
    final textoMaxima = 'Máx. ${dato(maxima, '°C')}';
    final textoLluvia = 'Probabilidad máxima de lluvia: ${dato(lluvia, '%')}';
    final tema = Theme.of(context);

    void abrirDetalle() {
      final consejos = recomendacionesClima(
        codigo: codigo,
        temperatura: maxima,
        minima: minima,
        probabilidadLluvia: lluvia,
      );

      showDialog<void>(
        context: context,
        builder: (contextoDialogo) => AlertDialog(
          scrollable: true,
          title: Text('Consejos para $dia $fechaCorta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$emoji $condicion', style: tema.textTheme.titleMedium),
              const SizedBox(height: 12),
              listaConsejos(consejos),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextoDialogo),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }

    final fondoPronostico = Color.lerp(
      const Color(0xFFE4EFFF),
      const Color(0xFFE0F4F2),
      ((indice - 1) / 4).clamp(0.0, 1.0).toDouble(),
    );

    if (!enFila) {
      return Card(
        color: fondoPronostico,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Text(emoji, style: const TextStyle(fontSize: 30)),
          title: Text('$dia $fechaCorta · $condicion'),
          subtitle: Text('$textoMinima · $textoMaxima\n$textoLluvia'),
          trailing: const Icon(Icons.chevron_right),
          onTap: abrirDetalle,
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      color: fondoPronostico,
      child: InkWell(
        onTap: abrirDetalle,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                dia,
                style: tema.textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              Text(fechaCorta),
              const SizedBox(height: 8),
              Text(emoji, style: const TextStyle(fontSize: 34)),
              Text(condicion, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(textoMaxima, textAlign: TextAlign.center),
              Text(textoMinima, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                lluvia == null ? 'Lluvia sin datos' : '☔ $lluvia %',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> planearActividad() async {
    final nombre = campoActividad.text.trim();
    final ubicacion = coordenadas;

    if (ubicacion == null || cargando) return;

    if (nombre.length < 2) {
      setState(() {
        resultadoActividad = (
          actividad: '',
          mensaje: 'Escribe la actividad que quieres planear.',
        );
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      cargando = true;
      resultadoActividad = (
        actividad: nombre,
        mensaje: 'Consultando el pronóstico con Gemini…',
      );
    });

    String mensaje;
    try {
      mensaje = await consultarGemini(
        actividad: nombre,
        ubicacion: lugar,
        latitud: ubicacion.latitud,
        longitud: ubicacion.longitud,
      );
    } on TimeoutException {
      mensaje = 'Gemini tardó demasiado. Intenta de nuevo.';
    } on ClientException {
      mensaje = 'No se pudo conectar con Gemini. Revisa que NestJS esté activo.';
    } on FormatException catch (problema) {
      mensaje = problema.message;
    } on Exception {
      mensaje = 'No se pudo planear la actividad. Intenta de nuevo.';
    }

    if (!mounted) return;

    setState(() {
      resultadoActividad = (actividad: nombre, mensaje: mensaje);
      cargando = false;
    });
  }

  Widget mostrarPlanificador() {
    final resultado = resultadoActividad;

    return Card(
      color: const Color(0xFFE6EDFF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Planear actividad',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF23488B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: campoActividad,
                    maxLength: 80,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => planearActividad(),
                    decoration: const InputDecoration(
                      labelText: 'Actividad',
                      hintText: 'Ej. tender ropa',
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FilledButton(
                    onPressed: cargando ? null : planearActividad,
                    child: const Text(
                      'Planear actividad',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            if (resultado != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (resultado.actividad.isNotEmpty) ...[
                        Text(
                          resultado.actividad,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(resultado.mensaje),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget mostrarClima(Map<String, dynamic> datos) {
    final actual = datos['current'] as Map<String, dynamic>;
    final horas = datos['hourly'] as Map<String, dynamic>;
    final diario = datos['daily'] as Map<String, dynamic>;
    final temperatura = actual['temperature_2m'] as num?;
    final codigo = actual['weather_code'] as int?;
    final esDeDia = actual['is_day'] == 1;
    final tiempos = horas['time'] as List;
    final horaActual = actual['time'] as String;
    final siguiente = tiempos.indexWhere(
      (hora) => (hora as String).compareTo(horaActual) > 0,
    );
    final lluvia = siguiente < 0
        ? null
        : horas['precipitation_probability'][siguiente] as num?;
    final horaLluvia = siguiente < 0
        ? ''
        : (tiempos[siguiente] as String).split('T').last;
    final tema = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: esDeDia
                  ? const [Color(0xFF173F91), Color(0xFF14748E)]
                  : const [Color(0xFF18234E), Color(0xFF494580)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  lugar,
                  textAlign: TextAlign.center,
                  style: tema.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  emojiClima(codigo, temperatura, esDeDia: esDeDia),
                  style: const TextStyle(fontSize: 54),
                ),
                Text(
                  dato(temperatura, '°C'),
                  style: tema.textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  descripcion(codigo, esDeDia: esDeDia),
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        mostrarIndicadores(actual, lluvia, horaLluvia),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: const Color(0xFFFFF3D9),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recomendaciones para hoy',
                  style: tema.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF794800),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                listaConsejos(
                  recomendacionesClima(
                    codigo: codigo,
                    temperatura:
                        (actual['apparent_temperature'] as num?) ?? temperatura,
                    probabilidadLluvia: lluvia,
                    esDeDia: esDeDia,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        mostrarPlanificador(),
        const SizedBox(height: 16),
        Text('Próximos días', style: tema.textTheme.titleLarge),
        const SizedBox(height: 8),
        mostrarPronostico(diario),
        const SizedBox(height: 12),
        const Text('Datos de Open-Meteo', textAlign: TextAlign.center),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final datos = clima;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.cloud_outlined),
            SizedBox(width: 10),
            Text('App Clima', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1060),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: campoCiudad,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => buscarCiudad(),
                          decoration: const InputDecoration(
                            labelText: 'Ciudad',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 2,
                        child: FilledButton(
                          onPressed: cargando ? null : buscarCiudad,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 56),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            'Consultar clima',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (cargando) const LinearProgressIndicator(),
                  if (aviso != null) Text(aviso!),
                  if (error != null)
                    Text(
                      error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  if (datos != null) mostrarClima(datos),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}