import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maternal_health_app/main.dart';
import 'package:maternal_health_app/screens/mother_home_screen.dart';
import 'package:maternal_health_app/widgets/baby_growth_viewer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/shared_preferences'),
            (call) async =>
                call.method == 'getAll' ? <String, Object>{} : true);
    final fontFile = File(Platform.environment['MATRUCARE_QA_FONT'] ?? '');
    if (await fontFile.exists()) {
      final fontBytes = ByteData.sublistView(await fontFile.readAsBytes());
      for (final family in ['Roboto', 'Ahem']) {
        await (FontLoader(family)..addFont(Future.value(fontBytes))).load();
      }
    }

    final iconPath = Platform.environment['MATRUCARE_QA_ICONS'];
    if (iconPath != null) {
      await (FontLoader('MaterialIcons')
            ..addFont(Future.value(
                ByteData.sublistView(await File(iconPath).readAsBytes()))))
          .load();
    }
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-public-key',
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        persistSession: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
    );
  });
  tearDownAll(() async => Supabase.instance.dispose());

  Future<void> screenshot(WidgetTester tester, String name) async {
    final directory = Platform.environment['MATRUCARE_QA_DIR'];
    if (directory == null) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('capture')));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$directory/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Widget capture(Widget child) =>
      RepaintBoundary(key: const ValueKey('capture'), child: child);

  testWidgets(
      'mother navigation separates Today, Baby and Care at mobile width',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(capture(Builder(
        builder: (context) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: (const MaternalHealthApp().build(context) as MaterialApp)
                  .theme,
              home: const MotherHomeScreen(),
            ))));
    await tester.pumpAndSettle();
    expect(find.text('Start daily check-in'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(3));
    expect(find.text('Doctor'), findsNothing);
    await screenshot(tester, 'today-mobile');
    await tester.tap(find.text('Baby'));
    await tester.pumpAndSettle();
    expect(find.byType(BabyGrowthViewer), findsOneWidget);
    await screenshot(tester, 'baby-mobile');
    await tester.tap(find.text('Care'));
    await tester.pumpAndSettle();
    expect(find.text('Partner, sharing & messages'), findsOneWidget);
    expect(find.byType(BabyGrowthViewer), findsNothing);
    await screenshot(tester, 'care-mobile');
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('Start daily check-in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'viewer supports rotation, motion, reset, still view and week selection',
      (tester) async {
    var week = 24;
    await tester.pumpWidget(capture(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            body: SingleChildScrollView(
          child: StatefulBuilder(
              builder: (context, setState) =>
                  NotificationListener<GrowthWeekNotification>(
                    onNotification: (event) {
                      setState(() => week = event.week);
                      return true;
                    },
                    child: BabyGrowthViewer(week: week),
                  )),
        )))));
    await tester.pumpAndSettle();
    final painter = tester
        .widget<CustomPaint>(find.byKey(const ValueKey('baby-mesh')))
        .painter;
    await tester.tap(find.widgetWithIcon(IconButton, Icons.rotate_right));
    await tester.pump();
    final rotated = tester
        .widget<CustomPaint>(find.byKey(const ValueKey('baby-mesh')))
        .painter;
    expect(rotated!.shouldRepaint(painter!), isTrue);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.play_arrow));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.widgetWithIcon(IconButton, Icons.pause), findsOneWidget);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.restart_alt));
    await tester.pumpAndSettle();
    expect(find.widgetWithIcon(IconButton, Icons.play_arrow), findsOneWidget);
    await tester.tap(find.text('Womb context'));
    await tester.pumpAndSettle();
    await screenshot(tester, 'baby-viewer-desktop');
    await tester.tap(find.text('Still view'));
    await tester.pumpAndSettle();
    expect(find.text('Still illustration'), findsOneWidget);
    expect(
        tester
            .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.rotate_left))
            .onPressed,
        isNull);
    await tester.ensureVisible(find.byType(Slider));
    await tester.drag(find.byType(Slider), const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(week, lessThan(9));
    expect(find.text('Early development · concept view'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'reduced motion disables playback and narrow layouts remain usable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(
          disableAnimations: true, textScaler: TextScaler.linear(1.3)),
      child: const Scaffold(
          body: SingleChildScrollView(child: BabyGrowthViewer(week: 40))),
    )));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.play_arrow))
            .onPressed,
        isNull);
    await tester.ensureVisible(find.text('Still view'));
    await tester.tap(find.text('Still view'));
    await tester.pumpAndSettle();
    expect(find.text('Still illustration'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
