import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'package:rest/features/ova/models/ova_models.dart';
import 'package:rest/features/ova/widgets/ova_resource_view.dart';

Widget _host(OvaRecurso recurso) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, _) => MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Scaffold(
        body: SingleChildScrollView(child: OvaResourceView(recurso: recurso)),
      ),
    ),
  );
}

void main() {
  testWidgets('R2 sin dominio muestra que la actividad no está disponible', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const OvaRecurso(
          fuente: OvaFuente.cloudflareR2,
          originalUrl: 'ovas/abc.mp4',
          resolvedUrl: 'ovas/abc.mp4',
        ),
      ),
    );

    expect(find.textContaining('no está disponible'), findsOneWidget);
  });

  testWidgets('un audio se ofrece para abrir fuera de la app', (tester) async {
    await tester.pumpWidget(
      _host(
        const OvaRecurso(
          fuente: OvaFuente.cloudflareR2,
          originalUrl: 'ovas/abc.mp3',
          resolvedUrl: 'https://cdn.test/ovas/abc.mp3',
        ),
      ),
    );

    expect(find.text('Escuchar audio'), findsOneWidget);
    expect(find.textContaining('fuera de la app'), findsOneWidget);
  });

  testWidgets('un PDF muestra el botón para abrir el documento', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const OvaRecurso(
          fuente: OvaFuente.cloudflareR2,
          originalUrl: 'ovas/guia.pdf',
          resolvedUrl: 'https://cdn.test/ovas/guia.pdf',
        ),
      ),
    );

    expect(find.text('Abrir documento'), findsOneWidget);
  });

  testWidgets('YouTube sin video_id cae al enlace', (tester) async {
    await tester.pumpWidget(
      _host(
        const OvaRecurso(
          fuente: OvaFuente.youtube,
          originalUrl: 'https://example.com/video',
          resolvedUrl: 'https://example.com/video',
          videoId: '',
        ),
      ),
    );

    expect(find.text('Abrir enlace'), findsOneWidget);
  });
}
