import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'providers/song_provider.dart';
import 'screens/landing_page.dart';
import 'screens/all_artists.dart';
import 'screens/dashboard.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingPageScreen(),
    ),
    GoRoute(
      path: '/artists',
      builder: (context, state) => const AllArtistsScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return DashboardScreen(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          redirect: (context, state) => '/dashboard/library',
        ),
        GoRoute(
          path: '/dashboard/:view',
          builder: (context, state) {
            final view = state.pathParameters['view'] ?? 'library';
            return DashboardViewContainer(viewName: view);
          },
        ),
      ],
    ),
  ],
);

void main() {
  usePathUrlStrategy(); // Remove '#' hash from URL pathing
  runApp(
    ProviderScope(
      child: legacy.MultiProvider(
        providers: [
          legacy.ChangeNotifierProvider(create: (_) => SongProvider()),
        ],
        child: const StudduoApp(),
      ),
    ),
  );
}

class StudduoApp extends StatefulWidget {
  const StudduoApp({super.key});

  @override
  State<StudduoApp> createState() => _StudduoAppState();
}

class _StudduoAppState extends State<StudduoApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb) {
        try {
          js.context.callMethod('onFlutterAppAppeared');
        } catch (e) {
          debugPrint('Failed to notify index.html: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Studduo',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF8A2BE2),
        scaffoldBackgroundColor: const Color(0xFF0D0D14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8A2BE2),
          secondary: Color(0xFF00FFCC),
          surface: Color(0xFF13131A),
          background: const Color(0xFF0D0D14),
          error: Colors.redAccent,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Outfit', color: Colors.white),
          bodyMedium: TextStyle(fontFamily: 'Outfit', color: Colors.white70),
          titleLarge: TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.bold),
        ),
        tabBarTheme: TabBarThemeData(
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(color: Color(0xFF00FFCC), width: 2),
          ),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Color(0xFF00FFCC),
          inactiveTrackColor: Color(0xFF2D2D3D),
          thumbColor: Color(0xFF00FFCC),
          overlayColor: Color(0x2900FFCC),
        ),
      ),
    );
  }
}
