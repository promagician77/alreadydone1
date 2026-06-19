import 'dart:async';
import 'dart:math' as math;

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/revenuecat_service.dart';
import '/services/fcm_service.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flutter_flow/nav/nav.dart';
import '/widgets/app_upgrade_alert.dart';
import '/widgets/force_update_gate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '/env_loader.dart';
import '/services/app_toast.dart';
import '/services/server_toast.dart';
import '/services/backend_client.dart';
import '/services/supabase_service.dart';
import '/services/sleep_mode_notifier.dart';
import '/services/nav_lock_notifier.dart';
import '/widgets/pressable.dart';
import '/pages/player/coachmark/done_library_coachmark_nav.dart';
import '/widgets/swipe_delete_tutorial_dialog.dart';
import '/pages/home_dashboard/coachmark/new_manifestation_coachmark_nav.dart';
import 'index.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> _initializeAppCritical() async {
  WidgetsFlutterBinding.ensureInitialized();

  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await FlutterFlowTheme.initialize();

  try {
    await loadEnv();
  } catch (e) {
    debugPrint('dotenv load failed: $e');
    rethrow;
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseUrl.isEmpty || supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
    throw Exception('SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env');
  }
  debugPrint('🔍 Initializing Supabase...');
  await SupabaseService.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  debugPrint('✅ Supabase initialized successfully');

  BackendClient.initialize(baseUrl: dotenv.env['BACKEND_URL']);

  debugPrint('🔍 Initializing AuthListener...');
  AppStateNotifier.instance.initAuthListener();
  debugPrint('✅ AuthListener initialized successfully');
}

Future<void> _initializeAppDeferred() async {
  debugPrint('🔍 Deferred: Firebase...');
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
    debugPrint('✅ Firebase initialized successfully');
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  } catch (e, st) {
    debugPrint('❌ Firebase initialization failed: $e');
    debugPrint('$st');
  }

  debugPrint('🔍 Deferred: RevenueCat...');
  try {
    RevenueCatService.logFlow('Startup', 'deferred configure() (anonymous until auth)');
    await RevenueCatService.instance.configure();
    RevenueCatService.logFlow(
      'Startup',
      'deferred configure finished isConfigured=${RevenueCatService.instance.isConfigured}',
    );
    debugPrint('✅ RevenueCat initialized successfully');
  } catch (e, st) {
    RevenueCatService.logFlow('Startup', 'deferred configure FAILED: $e');
    debugPrint('RevenueCat configure error: $e');
    debugPrint('$st');
  }

  debugPrint('🔍 Deferred: Backend connection check...');
  try {
    final connected = await BackendClient.checkConnection();
    if (connected) {
      debugPrint('Backend connected at ${BackendClient.baseUrl}');
    } else {
      debugPrint('Backend unreachable at ${BackendClient.baseUrl}');
    }
  } catch (e) {
    debugPrint('Backend check failed: $e');
  }

  if (!kIsWeb && firebaseInitialized) {
    debugPrint('🔍 Deferred: FCM...');
    try {
      await FcmService.initialize();
      debugPrint('✅ FCM initialized successfully');
    } catch (e) {
      debugPrint('FCM init failed: $e');
    }
  }
}

void main() async {
  runZonedGuarded(() async {
    await _initializeAppCritical();
    runApp(MyApp());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAppDeferred();
    });
  }, (error, stack) {
    debugPrint('Uncaught error in main: $error');
    debugPrint('$stack');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ServerToast.show();
    });
  });
}

class _ErrorApp extends StatelessWidget {
  const _ErrorApp({required this.message, required this.stack});

  final String message;
  final String stack;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Startup error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(message, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 24),
                  const Text('Stack trace:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SelectableText(stack, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    _initAuthDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      FcmService.onAppResumed();
    }
  }

  void _initAuthDeepLinks() {
    final appLinks = AppLinks();
    void handleLink(Uri? uri) async {
      if (uri == null) return;
      try {
        if (!uri.toString().contains('auth/callback')) return;
        final userIdStr = uri.queryParameters['userId'];
        final userId = userIdStr != null && userIdStr.isNotEmpty
            ? int.tryParse(userIdStr)
            : null;

        final newEmail = await SupabaseService.handleAuthCallbackUrl(uri.toString());
        if (newEmail == null) return;

        if (userId != null) {
          try {
            await BackendClient.updateUserProfile(userId, email: newEmail);
          } catch (_) {}
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = appNavigatorKey.currentContext;
          if (ctx != null) {
            AppToast.success(ctx, 'Email updated successfully!');
            GoRouter.of(ctx).go('/');
          }
        });
      } catch (_) {}
    }

    appLinks.getInitialLink().then(handleLink);
    appLinks.uriLinkStream.listen(handleLink);
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Already Done',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: false,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
      builder: (context, child) {
        if (kIsWeb) {
          return child ?? const SizedBox.shrink();
        }
        return ForceUpdateGate(
          child: AppUpgradeAlert(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class _NavColors {
  static const surface = Color(0xFFFEFDFB);
  static const inkSoft = Color(0xFF78716C);
  static const gold = Color(0xFFB8861E);  
  static const sleepSurface = Color(0xFF1A1F3A);
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.active, required this.sleepStyle});

  final IconData icon;
  final bool active;
  final bool sleepStyle;

  @override
  Widget build(BuildContext context) {
    final color = sleepStyle
        ? (active ? const Color(0xFFC4B5FD) : Colors.white.withValues(alpha: 0.5))
        : (active ? _NavColors.gold : _NavColors.inkSoft);
    return Icon(icon, size: 20, color: color);
  }
}

class NavBarPage extends StatefulWidget {
  NavBarPage({
    Key? key,
    this.initialPage,
    this.page,
    this.disableResizeToAvoidBottomInset = false,
  }) : super(key: key);

  final String? initialPage;
  final Widget? page;
  final bool disableResizeToAvoidBottomInset;

  @override
  _NavBarPageState createState() => _NavBarPageState();
}

class _NavBarPageState extends State<NavBarPage>
    with SingleTickerProviderStateMixin {
  String _currentPageName = 'HomeDashboard';
  late Widget? _currentPage;

  late final AnimationController _newManifestationNavPulse;

  @override
  void initState() {
    super.initState();
    _currentPageName = widget.initialPage ?? _currentPageName;
    _currentPage = widget.page;
    _newManifestationNavPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    newManifestationCoachmarkVisible.addListener(_syncNewManifestationNavPulse);
    if (newManifestationCoachmarkVisible.value) {
      _newManifestationNavPulse.repeat(reverse: true);
    }
  }

  void _syncNewManifestationNavPulse() {
    if (newManifestationCoachmarkVisible.value) {
      _newManifestationNavPulse.repeat(reverse: true);
    } else {
      _newManifestationNavPulse
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    newManifestationCoachmarkVisible.removeListener(_syncNewManifestationNavPulse);
    _newManifestationNavPulse.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    final tabKeys = ['HomeDashboard', 'Player', 'Desires', 'Profile'];
    safeSetState(() {
      _currentPage = null;
      _currentPageName = tabKeys[index];
    });
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    int currentIndex,
    bool sleepStyle,
    VoidCallback? onTap, {
    GlobalKey? libraryCoachmarkKey,
    GlobalKey? newManifestationHomeKey,
  }) {
    final selectedColor = sleepStyle ? const Color(0xFFC4B5FD) : _NavColors.gold;
    final unselectedColor = sleepStyle ? Colors.white.withValues(alpha: 0.5) : _NavColors.inkSoft;
    final active = currentIndex == index;

    Widget buildCore(bool tipActive) {
      final activeOrTip = active || tipActive;
      final color = activeOrTip ? selectedColor : unselectedColor;
      final labelWeight =
          (tipActive && (libraryCoachmarkKey != null || newManifestationHomeKey != null))
              ? FontWeight.w700
              : FontWeight.w500;
      return Pressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: labelWeight,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (newManifestationHomeKey != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: newManifestationCoachmarkVisible,
        builder: (context, tipActive, _) {
          Widget inner = buildCore(tipActive);
          if (tipActive) {
            inner = AnimatedBuilder(
              animation: _newManifestationNavPulse,
              builder: (context, child) {
                final t = (math.sin(_newManifestationNavPulse.value * math.pi * 2) +
                        1) /
                    2;
                final spread = 1.0 + t * 3.0;
                final blur = 22.0 + t * 18.0;
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF3DF),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB8862F)
                            .withValues(alpha: 0.35 + 0.35 * t),
                        blurRadius: blur,
                        spreadRadius: spread,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: inner,
            );
          }
          return KeyedSubtree(key: newManifestationHomeKey, child: inner);
        },
      );
    }

    if (libraryCoachmarkKey != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: doneLibraryCoachmarkVisible,
        builder: (context, libraryTipActive, _) {
          Widget inner = buildCore(libraryTipActive);
          if (libraryTipActive) {
            inner = Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFDF3DF),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB8862F).withValues(alpha: 0.45),
                    blurRadius: 22,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: inner,
            );
          }
          return KeyedSubtree(key: libraryCoachmarkKey, child: inner);
        },
      );
    }

    return buildCore(false);
  }

  @override
  Widget build(BuildContext context) {
    final tabKeys = ['HomeDashboard', 'Player', 'Desires', 'Profile'];
    final tabs = {
      'HomeDashboard': HomeDashboardWidget(),
      'Player': PlayerWidget(),
      'Desires': DesiresWidget(),
      'Profile': ProfileWidget(),
    };
    final currentIndex = tabKeys.indexOf(_currentPageName);
    final isPlayerSleepMode = _currentPageName == 'Player';

    return ValueListenableBuilder<bool>(
      valueListenable: sleepModeNotifier,
      builder: (context, sleepMode, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: navLockNotifier,
          builder: (context, navLocked, __) {
            final useSleepStyle = isPlayerSleepMode && sleepMode;
            final barColor = useSleepStyle ? _NavColors.sleepSurface : _NavColors.surface;

            return Scaffold(
              resizeToAvoidBottomInset: !widget.disableResizeToAvoidBottomInset,
              body: Column(
                children: [
                  Expanded(child: _currentPage ?? tabs[_currentPageName]!),
                  _buildNavBar(context, barColor, currentIndex, useSleepStyle, navLocked),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNavBar(
    BuildContext context,
    Color barColor,
    int currentIndex,
    bool useSleepStyle,
    bool navLocked,
  ) {
    return ColoredBox(
      color: barColor,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(useSleepStyle ? 0.2 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context,
                    Icons.home_rounded,
                    'Home',
                    0,
                    currentIndex,
                    useSleepStyle,
                    navLocked
                        ? null
                        : () async {
                            await newManifestationCoachmarkOnHomeTabDuringCoachmark
                                ?.call();
                            _onNavTap(0);
                          },
                    newManifestationHomeKey: newManifestationCoachmarkHomeTabKey,
                  ),
                  _buildNavItem(
                    context,
                    Icons.play_arrow,
                    'Player',
                    1,
                    currentIndex,
                    useSleepStyle,
                    navLocked ? null : () => _onNavTap(1),
                  ),
                  _buildNavItem(
                    context,
                    Icons.check,
                    'Done',
                    2,
                    currentIndex,
                    useSleepStyle,
                    navLocked
                        ? null
                        : () async {
                            await doneLibraryCoachmarkOnDoneTabDismiss?.call();
                            _onNavTap(2);
                            await SwipeDeleteTutorial.setPendingAfterDoneNavTap();
                          },
                    libraryCoachmarkKey: doneLibraryCoachmarkTabKey,
                  ),
                  _buildNavItem(
                    context,
                    Icons.density_medium,
                    'Profile',
                    3,
                    currentIndex,
                    useSleepStyle,
                    navLocked ? null : () => _onNavTap(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
