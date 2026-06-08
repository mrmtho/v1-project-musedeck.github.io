import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SongProvider()),
      ],
      child: const MuseDeckApp(),
    ),
  );
}

class MuseDeckApp extends StatelessWidget {
  const MuseDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MuseDeck',
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
